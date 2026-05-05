import SwiftUI
import AppKit

// MARK: - Particle Background View
struct ParticleBackgroundView: View {
    @Binding var mode: WeatherMode
    let blurRadius: Double
    let particleIntensity: Double
    let dimOpacity: Double
    let mousePosition: CGPoint
    let respondsToMouse: Bool
    let wallpaperVersion: Int

    var body: some View {
        ZStack {
            WallpaperBackgroundView(
                mode: mode,
                blurRadius: blurRadius,
                dimOpacity: dimOpacity,
                wallpaperVersion: wallpaperVersion
            )
            .ignoresSafeArea()

            if mode == .snow {
                ShaderSnowOverlay(
                    intensity: particleIntensity,
                    mousePosition: mousePosition,
                    respondsToMouse: respondsToMouse
                )
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                GlassRainOverlay(
                    intensity: particleIntensity,
                    mousePosition: mousePosition,
                    respondsToMouse: respondsToMouse
                )
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
    }
}

private struct GlassRainOverlay: View {
    let intensity: Double
    let mousePosition: CGPoint
    let respondsToMouse: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 36.0, paused: false)) { context in
            Canvas(opaque: false, rendersAsynchronously: true) { canvas, size in
                drawRain(on: canvas, size: size, time: context.date.timeIntervalSinceReferenceDate)
            }
            .blendMode(.screen)
        }
    }

    private func drawRain(on canvas: GraphicsContext, size: CGSize, time: TimeInterval) {
        let settledCount = max(90, Int(160 * intensity))
        let movingCount = max(18, Int(34 * intensity))
        let mergedCount = max(8, Int(14 * intensity))
        let pointerX = respondsToMouse ? (mousePosition.x - 0.5) : 0
        let pointerY = respondsToMouse ? (mousePosition.y - 0.5) : 0
        let horizontalParallax = CGFloat(pointerX * 14)
        let verticalParallax = CGFloat(pointerY * 6)

        for index in 0..<settledCount {
            let seed = Double(index) * 1.913
            let baseX = CGFloat(hashed(seed + 0.41)) * size.width
            let baseY = CGFloat(hashed(seed + 1.07)) * size.height
            let width = CGFloat(1.8 + hashed(seed + 2.31) * 7.6)
            let height = width * CGFloat(1.15 + hashed(seed + 3.73) * 0.95)
            let shimmer = 0.92 + sin(time * (0.25 + hashed(seed + 4.91) * 0.22) + seed) * 0.08
            let point = CGPoint(
                x: baseX + horizontalParallax * CGFloat(0.18 + hashed(seed + 5.37) * 0.12),
                y: baseY + verticalParallax * CGFloat(0.12 + hashed(seed + 6.27) * 0.08)
            )

            drawBead(
                on: canvas,
                at: point,
                width: width,
                height: height,
                alpha: CGFloat(0.10 + hashed(seed + 7.13) * 0.18) * CGFloat(shimmer)
            )
        }

        for index in 0..<mergedCount {
            let seed = 7000 + Double(index) * 4.117
            let depth = 0.78 + hashed(seed + 0.19) * 0.46
            let baseX = CGFloat(hashed(seed + 1.11)) * size.width
            let startY = -CGFloat(120 + hashed(seed + 2.03) * 320)
            let beadWidth = CGFloat(8.5 + hashed(seed + 3.27) * 11.5) / CGFloat(depth)
            let beadHeight = beadWidth * CGFloat(1.18 + hashed(seed + 4.51) * 0.72)
            let cycleDuration = 11.0 + hashed(seed + 5.83) * 15.0
            let holdRatio = 0.62 + hashed(seed + 6.37) * 0.20
            let phase = (time / cycleDuration + hashed(seed + 7.09)).truncatingRemainder(dividingBy: 1)
            let progress = slidingProgress(for: phase, holdRatio: holdRatio)
            let slant = CGFloat((hashed(seed + 8.91) - 0.5) * 18)
            let sway = CGFloat(sin(time * (0.15 + hashed(seed + 9.47) * 0.09) + seed) * 2.6)
            let x = baseX + horizontalParallax / CGFloat(depth) + sway + slant * progress
            let y = startY + progress * (size.height + 360) + verticalParallax / CGFloat(depth)
            let dripLength = CGFloat(120 + progress * (220 + hashed(seed + 10.13) * 180)) / CGFloat(depth)
            let dripWidth = max(1.8, beadWidth * 0.28)
            let alpha = CGFloat(0.16 + hashed(seed + 11.71) * 0.18)

            if progress > 0.015 {
                drawTrail(
                    on: canvas,
                    at: CGPoint(x: x + dripWidth * 0.08, y: y - dripLength + beadHeight * 0.22),
                    length: dripLength,
                    width: dripWidth,
                    alpha: alpha * CGFloat(0.32 + progress * 0.22)
                )
            }

            drawBead(
                on: canvas,
                at: CGPoint(x: x, y: y),
                width: beadWidth,
                height: beadHeight,
                alpha: alpha * 1.1
            )

            if hashed(seed + 12.93) > 0.54 {
                drawDrop(
                    on: canvas,
                    at: CGPoint(x: x + beadWidth * 0.04, y: y - beadHeight * 0.18),
                    length: beadHeight * 0.75,
                    width: beadWidth * 0.32,
                    alpha: alpha * 0.9
                )
            }
        }

        for index in 0..<movingCount {
            let seed = Double(index) * 3.271
            let depth = 0.84 + hashed(seed + 0.29) * 0.72
            let baseX = CGFloat(hashed(seed + 1.01)) * size.width
            let startY = -CGFloat(40 + hashed(seed + 2.17) * 240)
            let dropWidth = CGFloat(4.2 + hashed(seed + 3.63) * 6.4) / CGFloat(depth)
            let dropLength = CGFloat(18 + hashed(seed + 4.81) * 24) / CGFloat(depth)
            let cycleDuration = 6.5 + hashed(seed + 5.93) * 10.5
            let holdRatio = 0.56 + hashed(seed + 6.71) * 0.24
            let phase = (time / cycleDuration + hashed(seed + 7.39)).truncatingRemainder(dividingBy: 1)
            let slant = CGFloat((hashed(seed + 8.27) - 0.5) * 22)
            let microDrift = CGFloat(sin(time * (0.22 + hashed(seed + 9.11) * 0.18) + seed) * 3.5)
            let progress = slidingProgress(for: phase, holdRatio: holdRatio)
            let span = size.height + 220
            let y = startY + progress * span + verticalParallax / CGFloat(depth)
            let x = baseX + microDrift + horizontalParallax / CGFloat(depth) + slant * progress
            let trailLength = max(0, (24 + progress * (72 + hashed(seed + 10.17) * 44)) / CGFloat(depth))
            let alpha = CGFloat(0.18 + hashed(seed + 11.33) * 0.20)

            drawDrop(
                on: canvas,
                at: CGPoint(x: x, y: y),
                length: dropLength,
                width: dropWidth,
                alpha: alpha
            )

            if progress > 0.02 {
                drawTrail(
                    on: canvas,
                    at: CGPoint(x: x + dropWidth * 0.08, y: y - trailLength + dropWidth * 0.4),
                    length: trailLength,
                    width: max(1.2, dropWidth * 0.42),
                    alpha: alpha * CGFloat(0.28 + progress * 0.22)
                )
            }
        }
    }

    private func slidingProgress(for phase: Double, holdRatio: Double) -> CGFloat {
        guard phase > holdRatio else {
            let idle = phase / max(holdRatio, 0.001)
            return CGFloat(idle * idle * 0.018)
        }

        let raw = (phase - holdRatio) / max(1 - holdRatio, 0.001)
        let eased = raw * raw * (3 - 2 * raw)
        return CGFloat(eased)
    }

    private func drawBead(on canvas: GraphicsContext, at point: CGPoint, width: CGFloat, height: CGFloat, alpha: CGFloat) {
        let glowRect = CGRect(x: point.x - width * 0.9, y: point.y - height * 0.25, width: width * 1.8, height: height * 1.35)
        let coreRect = CGRect(x: point.x - width * 0.5, y: point.y - height * 0.12, width: width, height: height)
        let highlightRect = CGRect(x: point.x - width * 0.22, y: point.y + height * 0.22, width: width * 0.28, height: height * 0.22)
        let rimRect = CGRect(x: point.x - width * 0.56, y: point.y - height * 0.16, width: width * 1.12, height: height * 1.08)

        var glowCanvas = canvas
        glowCanvas.addFilter(.blur(radius: width * 0.95))
        glowCanvas.fill(Path(ellipseIn: glowRect), with: .color(.white.opacity(alpha * 0.34)))

        var rimCanvas = canvas
        rimCanvas.addFilter(.blur(radius: width * 0.16))
        rimCanvas.stroke(Path(ellipseIn: rimRect), with: .color(.white.opacity(alpha * 0.62)), lineWidth: max(0.6, width * 0.08))

        var beadCanvas = canvas
        beadCanvas.addFilter(.blur(radius: width * 0.08))
        beadCanvas.fill(Path(ellipseIn: coreRect), with: .color(.white.opacity(alpha)))
        beadCanvas.fill(Path(ellipseIn: highlightRect), with: .color(.white.opacity(alpha * 1.15)))
    }

    private func drawDrop(on canvas: GraphicsContext, at point: CGPoint, length: CGFloat, width: CGFloat, alpha: CGFloat) {
        let glowRect = CGRect(x: point.x - width, y: point.y - 4, width: width * 2, height: length + 10)
        let coreRect = CGRect(x: point.x - width * 0.42, y: point.y, width: width * 0.84, height: length)
        let beadRect = CGRect(x: point.x - width * 0.78, y: point.y + length - width * 0.6, width: width * 1.56, height: width * 1.56)

        var glowCanvas = canvas
        glowCanvas.addFilter(.blur(radius: width * 0.9))
        glowCanvas.fill(Path(roundedRect: glowRect, cornerRadius: width), with: .color(.white.opacity(alpha * 0.55)))

        var coreCanvas = canvas
        coreCanvas.addFilter(.blur(radius: width * 0.18))
        coreCanvas.fill(Path(roundedRect: coreRect, cornerRadius: width * 0.48), with: .color(.white.opacity(alpha)))
        coreCanvas.fill(Path(ellipseIn: beadRect), with: .color(.white.opacity(alpha * 1.3)))
    }

    private func drawTrail(on canvas: GraphicsContext, at point: CGPoint, length: CGFloat, width: CGFloat, alpha: CGFloat) {
        let trailRect = CGRect(x: point.x - width * 0.5, y: point.y, width: width, height: length)
        var trailCanvas = canvas
        trailCanvas.addFilter(.blur(radius: width * 0.7))
        trailCanvas.fill(Path(roundedRect: trailRect, cornerRadius: width * 0.45), with: .color(.white.opacity(alpha)))
    }

    private func hashed(_ value: Double) -> Double {
        let sine = sin(value * 12.9898) * 43758.5453
        return sine - floor(sine)
    }
}

private struct ShaderSnowOverlay: View {
    let intensity: Double
    let mousePosition: CGPoint
    let respondsToMouse: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            Canvas(opaque: false, rendersAsynchronously: true) { canvas, size in
                drawSnow(on: canvas, size: size, time: context.date.timeIntervalSinceReferenceDate)
            }
            .blendMode(.screen)
        }
    }

    private func drawSnow(on canvas: GraphicsContext, size: CGSize, time: TimeInterval) {
        let layers = max(22, Int(50 * intensity))
        let dof = 5.0 * sin(time * 0.1)
        let pointerX = respondsToMouse ? (mousePosition.x - 0.5) : 0
        let pointerY = respondsToMouse ? (mousePosition.y - 0.5) : 0

        for layer in 0..<layers {
            let layerDepth = 1.0 + Double(layer) * 0.5
            let layerCount = 8 + Int(Double(layer) * 0.45)
            let laneDrift = (Double(layer).truncatingRemainder(dividingBy: 9) / 9.0 - 0.5) * 26.0
            let diagonalDrift = (Double(layer).truncatingRemainder(dividingBy: 5) / 5.0 - 0.4) * 8.0
            let fallSpeed = 0.94 + Double(layer) * 0.035
            let focus = min(1.0, abs(Double(layer) - 5.0 - dof) * 0.5)
            let softness = 0.55 + focus * 1.4
            let parallaxShift = CGFloat(pointerX * Double(16 + layer))
            let verticalShift = CGFloat(pointerY * Double(6 + layer) * 0.45)

            for flake in 0..<layerCount {
                let seed = Double(layer * 97 + flake * 37)
                let randomX = hashed(seed + 0.17)
                let randomY = hashed(seed + 3.91)
                let rawSize = hashed(seed + 7.37)
                // 非线性分布：多数雪花小，少数很大
                let randomSize = rawSize * rawSize * rawSize + rawSize * 0.15
                let horizontalNoise = hashed(seed + 11.73)

                var x = randomX * size.width
                x += CGFloat(laneDrift)
                x += CGFloat((horizontalNoise - 0.5) * 18.0)
                x += parallaxShift / CGFloat(layerDepth)

                // 大雪花（randomSize 大）落得更快
                let sizeSpeedFactor = 0.72 + randomSize * 0.68
                var y = (randomY * size.height) + CGFloat(time * 195.0 * fallSpeed * sizeSpeedFactor / layerDepth)
                y.formTruncatingRemainder(dividingBy: size.height + 140)
                y -= 70
                y += verticalShift / CGFloat(layerDepth)

                x += CGFloat((y / max(size.height, 1)) * diagonalDrift)

                // 尺寸分布更宽：最小 1.6，最大可达 14
                let baseSize = CGFloat(1.6 + randomSize * 12.4 + Double(layer) * 0.065)
                let width = baseSize * CGFloat(0.92 + softness * 0.26)
                let height = baseSize * CGFloat(1.14 + softness * 0.42)
                let alpha = max(0.08, 0.82 / CGFloat(1.0 + 0.045 * Double(layer)) * CGFloat(0.45 + randomX * 0.65))
                let blur = CGFloat(softness * 0.92)
                let rect = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)

                var flakeCanvas = canvas
                flakeCanvas.addFilter(.blur(radius: blur))
                flakeCanvas.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
    }

    private func hashed(_ value: Double) -> Double {
        let sine = sin(value * 12.9898) * 43758.5453
        return sine - floor(sine)
    }
}

// MARK: - Wallpaper Background
struct WallpaperBackgroundView: View {
    let mode: WeatherMode
    let blurRadius: Double
    let dimOpacity: Double
    let wallpaperVersion: Int
    @State private var currentImage: NSImage?
    private static var cachedImage: NSImage?
    private static let wallpaperPath = "/Users/tang/Library/Mobile Documents/com~apple~CloudDocs/Desktop/桌面系统项目合集（含壁纸文件）/8k 壁纸带黑框"

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let elapsed = context.date.timeIntervalSinceReferenceDate
                let xDrift = CGFloat(sin(elapsed / 14.0)) * 28
                let yDrift = CGFloat(cos(elapsed / 18.0)) * 18
                let secondaryX = CGFloat(cos(elapsed / 20.0)) * 22
                let secondaryY = CGFloat(sin(elapsed / 16.0)) * 12
                let glowOffset = CGFloat(sin(elapsed / 12.0)) * 140

                ZStack {
                    baseLayer(size: geometry.size)
                        .offset(x: xDrift, y: yDrift)

                    baseLayer(size: geometry.size)
                        .scaleEffect(1.08)
                        .blur(radius: blurRadius + 4)
                        .opacity(0.18)
                        .offset(x: secondaryX, y: secondaryY)

                    fogLayer(size: geometry.size, glowOffset: glowOffset)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(dimOpacity * 0.7),
                            Color.black.opacity(dimOpacity),
                            Color.black.opacity(dimOpacity + 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [
                            Color.white.opacity(mode == .snow ? 0.10 : 0.06),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 620
                    )
                    .blendMode(.screen)

                    vignette
                }
                .clipped()
            }
        }
        .onAppear {
            loadRandomWallpaperIfNeeded()
        }
        .onChange(of: wallpaperVersion) { _ in
            Self.cachedImage = nil
            currentImage = nil
            loadRandomWallpaperIfNeeded()
        }
    }

    @ViewBuilder
    private func baseLayer(size: CGSize) -> some View {
        if let image = currentImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width * 1.08, height: size.height * 1.08)
                .blur(radius: blurRadius)
                .saturation(0.88)
                .brightness(-0.02)
        } else {
            Color.black
        }
    }

    private func fogLayer(size: CGSize, glowOffset: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(mode == .snow ? 0.10 : 0.07))
                .frame(width: size.width * 0.72, height: size.height * 0.34)
                .blur(radius: 72)
                .offset(x: -size.width * 0.12, y: -size.height * 0.22)

            Ellipse()
                .fill(Color(red: 0.72, green: 0.78, blue: 0.82).opacity(0.10))
                .frame(width: size.width * 0.65, height: size.height * 0.28)
                .blur(radius: 84)
                .offset(x: glowOffset, y: size.height * 0.08)
        }
        .blendMode(.screen)
    }

    private var vignette: some View {
        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.18),
                Color.black.opacity(0.34)
            ],
            center: .center,
            startRadius: 200,
            endRadius: 1200
        )
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

