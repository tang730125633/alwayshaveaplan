import SwiftUI
import SpriteKit
import AppKit

// MARK: - Particle Background View
struct ParticleBackgroundView: View {
    @Binding var mode: WeatherMode
    @State private var scene = ParticleScene(mode: .snow)

    var body: some View {
        ZStack {
            // 壁纸背景
            WallpaperBackgroundView(mode: mode)
                .ignoresSafeArea()

            // 粒子层（雨/雪）
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea()

            // 模式切换器
            VStack {
                ModeSwitcher(mode: $mode)
                    .padding(.top, 20)
                Spacer()
            }
        }
        .onAppear {
            scene.updateMode(mode)
        }
        .onChange(of: mode) { _, newMode in
            scene.updateMode(newMode)
        }
    }
}

// MARK: - Wallpaper Background
struct WallpaperBackgroundView: View {
    let mode: WeatherMode
    @State private var currentImage: NSImage?
    private static var cachedImage: NSImage?
    private static let wallpaperPath = "/Users/tang/Library/Mobile Documents/com~apple~CloudDocs/Desktop/桌面系统项目合集（含壁纸文件）/8k 壁纸带黑框"

    var body: some View {
        Group {
            if let image = currentImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
                    .opacity(0.3)
            } else {
                Color.black.opacity(0.8)
            }
        }
        .onAppear {
            loadRandomWallpaperIfNeeded()
        }
    }

    private func loadRandomWallpaperIfNeeded() {
        if let cachedImage = Self.cachedImage {
            currentImage = cachedImage
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: Self.wallpaperPath) else {
                return
            }

            let imageFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") }
            guard let randomFile = imageFiles.randomElement() else {
                return
            }

            let fullPath = "\(Self.wallpaperPath)/\(randomFile)"
            guard let image = NSImage(contentsOfFile: fullPath) else {
                return
            }

            DispatchQueue.main.async {
                Self.cachedImage = image
                currentImage = image
            }
        }
    }
}

// MARK: - Weather Mode
enum WeatherMode {
    case rain
    case snow
}

// MARK: - Mode Switcher
struct ModeSwitcher: View {
    @Binding var mode: WeatherMode
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 20) {
            Button("Rain") {
                mode = .rain
            }
            .foregroundColor(mode == .rain ? .white : .white.opacity(0.5))

            Text("/")
                .foregroundColor(.white.opacity(0.3))

            Button("Snow") {
                mode = .snow
            }
            .foregroundColor(mode == .snow ? .white : .white.opacity(0.5))
        }
        .font(.system(size: 14, weight: .medium))
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
        .opacity(isHovered ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Particle Scene
class ParticleScene: SKScene {
    private var mode: WeatherMode
    private var particleLayers: [SKEmitterNode] = []

    init(mode: WeatherMode) {
        self.mode = mode
        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        setupParticles()
    }

    func updateMode(_ newMode: WeatherMode) {
        guard mode != newMode else { return }
        mode = newMode

        guard view != nil else { return }
        setupParticles()
    }

    private func setupParticles() {
        removeAllChildren()
        particleLayers.removeAll()

        switch mode {
        case .rain:
            setupRain()
        case .snow:
            setupSnow()
        }
    }

    private func setupRain() {
        // 3层雨滴，模拟景深
        let layers = [
            (count: 200, speed: 800.0, alpha: 0.3, scale: 0.08),
            (count: 150, speed: 600.0, alpha: 0.5, scale: 0.12),
            (count: 100, speed: 400.0, alpha: 0.7, scale: 0.15)
        ]

        for (index, layer) in layers.enumerated() {
            let emitter = SKEmitterNode()

            // 用代码生成雨滴纹理
            let raindropTexture = createRaindropTexture()
            emitter.particleTexture = raindropTexture

            emitter.particleBirthRate = CGFloat(layer.count)
            emitter.particleLifetime = 2.0
            emitter.particleSpeed = CGFloat(layer.speed)
            emitter.particleSpeedRange = 100
            emitter.emissionAngle = .pi * 1.5
            emitter.emissionAngleRange = 0.1
            emitter.particleAlpha = CGFloat(layer.alpha)
            emitter.particleScale = CGFloat(layer.scale)
            emitter.particleScaleRange = 0.02
            emitter.particleColor = .white
            emitter.particleColorBlendFactor = 1.0
            emitter.position = CGPoint(x: size.width / 2, y: size.height)
            emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
            emitter.zPosition = CGFloat(index)

            addChild(emitter)
            particleLayers.append(emitter)
        }
    }

    private func setupSnow() {
        // Fewer layers keep the effect while reducing entry cost.
        for i in 0..<24 {
            let emitter = SKEmitterNode()

            // 用代码生成雪花纹理
            let snowflakeTexture = createSnowflakeTexture()
            emitter.particleTexture = snowflakeTexture

            emitter.particleBirthRate = 2
            emitter.particleLifetime = 20
            emitter.particleSpeed = 30 + CGFloat(i) * 2
            emitter.particleSpeedRange = 10
            emitter.emissionAngle = .pi * 1.5
            emitter.emissionAngleRange = 0.2
            emitter.particleAlpha = 0.6 - CGFloat(i) * 0.01
            emitter.particleScale = 0.05 + CGFloat(i) * 0.01
            emitter.particleScaleRange = 0.02
            emitter.particleColor = .white
            emitter.particleColorBlendFactor = 1.0
            emitter.position = CGPoint(x: size.width / 2, y: size.height)
            emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
            emitter.zPosition = CGFloat(i)

            emitter.xAcceleration = CGFloat.random(in: -5...5)

            addChild(emitter)
            particleLayers.append(emitter)
        }
    }

    private func createRaindropTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 20)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.white.setFill()
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 2, yRadius: 2)
        path.fill()
        image.unlockFocus()

        return SKTexture(image: image)
    }

    private func createSnowflakeTexture() -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.white.setFill()
        let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
        path.fill()
        image.unlockFocus()

        return SKTexture(image: image)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setupParticles()
    }
}
