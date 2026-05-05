import SwiftUI
import AppKit

final class FocusSessionState: ObservableObject {
    let taskTitle: String
    let startedAt: Date
    @Published var noteText: String

    init(taskTitle: String, noteText: String = "", startedAt: Date = Date()) {
        self.taskTitle = taskTitle
        self.noteText = noteText
        self.startedAt = startedAt
    }
}

// MARK: - Focus Mode View
struct FocusModeView: View {
    @ObservedObject var session: FocusSessionState
    let initialFocusSeconds: Int
    let locksExitUntilTimerEnds: Bool
    @State private var weatherMode: WeatherMode = .snow
    @State private var remainingSeconds: Int
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var selectedFont: DeckFontOption = .serif
    @State private var selectedFontSize: DeckFontSize = .large
    @State private var backgroundBlur: Double = 6
    @State private var particleIntensity: Double = 0.95
    @State private var deckOpacity: Double = 0.08
    @State private var topHoverActive = false
    @State private var toolbarHovered = false
    @State private var fontPanelHovered = false
    @State private var bottomMixerHovered = false
    @State private var ambientVolume: Double = 0.7
    @State private var mousePosition: CGPoint = CGPoint(x: 0.5, y: 0.2)
    @State private var isHoveringDeck = false
    @State private var wallpaperVersion = 0
    let onExit: () -> Void
    let onMinimumFocusCompleted: (() -> Void)?
    @State private var hasUnlockedExit: Bool

    init(
        session: FocusSessionState,
        initialFocusSeconds: Int = 1500,
        locksExitUntilTimerEnds: Bool = false,
        onExit: @escaping () -> Void,
        onMinimumFocusCompleted: (() -> Void)? = nil
    ) {
        self.session = session
        self.initialFocusSeconds = initialFocusSeconds
        self.locksExitUntilTimerEnds = locksExitUntilTimerEnds
        self.onExit = onExit
        self.onMinimumFocusCompleted = onMinimumFocusCompleted
        _remainingSeconds = State(initialValue: initialFocusSeconds)
        _hasUnlockedExit = State(initialValue: !locksExitUntilTimerEnds)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ParticleBackgroundView(
                    mode: $weatherMode,
                    blurRadius: 0,
                    particleIntensity: particleIntensity,
                    dimOpacity: deckDimOpacity,
                    mousePosition: normalizedMousePoint(in: geometry.size),
                    respondsToMouse: !isHoveringDeck,
                    wallpaperVersion: wallpaperVersion
                )
                .ignoresSafeArea()

                deckGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topRevealZone
                    Spacer(minLength: 24)

                    VStack(spacing: 18) {
                        headerSection

                        FocusDeck(
                            text: $session.noteText,
                            selectedFont: $selectedFont,
                            selectedFontSize: $selectedFontSize,
                            deckOpacity: deckOpacity,
                            remainingSeconds: $remainingSeconds,
                            isRunning: $isTimerRunning,
                            canExit: canExit,
                            exitHint: exitHint,
                            showsExitHint: locksExitUntilTimerEnds,
                            onStart: startTimer,
                            onPause: pauseTimer,
                            onExit: attemptExit,
                            onHoverChanged: { hovering in
                                isHoveringDeck = hovering
                            }
                        )

                        BottomEnvironmentMixer(
                            mode: $weatherMode,
                            particleIntensity: $particleIntensity,
                            backgroundBlur: $backgroundBlur,
                            deckOpacity: $deckOpacity,
                            ambientVolume: $ambientVolume,
                            isVisible: bottomMixerHovered,
                            onWallpaperChange: { wallpaperVersion += 1 },
                            onHoverChanged: { hovering in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    bottomMixerHovered = hovering
                                }
                            }
                        )
                    }
                    .frame(maxWidth: 1120)
                    .padding(.horizontal, 36)

                    Spacer(minLength: 28)
                }

                VStack {
                    HStack {
                        FontOrbPanel(
                            selectedFont: $selectedFont,
                            selectedFontSize: $selectedFontSize,
                            isExpanded: fontPanelHovered,
                            onHoverChanged: { hovering in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    fontPanelHovered = hovering
                                }
                            }
                        )
                        .padding(.leading, 16)
                        .padding(.top, 14)

                        Spacer()
                    }
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    mousePosition = location
                case .ended:
                    mousePosition = CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.2)
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    private func normalizedMousePoint(in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return CGPoint(x: 0.5, y: 0.5) }
        return CGPoint(x: mousePosition.x / size.width, y: mousePosition.y / size.height)
    }

    private var resolvedTaskTitle: String {
        let trimmed = session.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "此刻只做这一件事" : trimmed
    }

    private var deckDimOpacity: Double {
        let baseOpacity = 0.0
        return locksExitUntilTimerEnds ? min(0.26, baseOpacity + 0.04) : min(0.22, baseOpacity)
    }

    private var deckGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.14),
                    Color(red: 0.08, green: 0.1, blue: 0.12).opacity(0.05),
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear
                ],
                center: .top,
                startRadius: 40,
                endRadius: 860
            )
            .blendMode(.screen)
        }
    }

    private var topRevealZone: some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(height: 72)
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.22)) {
                        topHoverActive = hovering
                    }
                }

            TopControlBar(
                mode: $weatherMode,
                isVisible: topHoverActive || toolbarHovered,
                onHoverChanged: { hovering in
                    withAnimation(.easeOut(duration: 0.22)) {
                        toolbarHovered = hovering
                    }
                }
            )
            .padding(.top, 16)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(currentDateLine)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .tracking(1.4)
                .foregroundColor(.white.opacity(0.48))

            Text(resolvedTaskTitle)
                .font(.system(size: 34, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    private var currentDateLine: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    private func startTimer() {
        timer?.invalidate()
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                pauseTimer()
                unlockExitIfNeeded()
                NSSound.beep()
            }
        }
    }

    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private var canExit: Bool {
        hasUnlockedExit
    }

    private var exitHint: String {
        if canExit {
            return "25 分钟专注已完成，现在可以退出。"
        }

        return "先完成 25 分钟专注，再离开这个窗口。"
    }

    private func attemptExit() {
        guard canExit else { return }
        onExit()
    }

    private func unlockExitIfNeeded() {
        guard !hasUnlockedExit else { return }
        hasUnlockedExit = true
        onMinimumFocusCompleted?()
    }
}

enum DeckFontOption: String, CaseIterable, Identifiable {
    case serif
    case sans
    case rounded
    case mono
    case klee
    case compact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .serif:
            return "霞鹜文楷"
        case .sans:
            return "Sans"
        case .rounded:
            return "圆体"
        case .mono:
            return "等宽"
        case .klee:
            return "Klee"
        case .compact:
            return "紧凑"
        }
    }

    func font(size: DeckFontSize) -> Font {
        let base = size.baseSize
        switch self {
        case .serif:
            return .system(size: base + 2, weight: .regular, design: .serif)
        case .sans:
            return .system(size: base + 1, weight: .regular, design: .default)
        case .rounded:
            return .system(size: base + 1, weight: .regular, design: .rounded)
        case .mono:
            return .system(size: base - 1, weight: .regular, design: .monospaced)
        case .klee:
            return .custom("Klee One", size: base + 1)
        case .compact:
            return .system(size: base, weight: .medium, design: .default)
        }
    }
}

enum DeckFontSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small:
            return "小"
        case .medium:
            return "中"
        case .large:
            return "大"
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .small:
            return 20
        case .medium:
            return 23
        case .large:
            return 30
        }
    }
}

private struct FocusDeck: View {
    @Binding var text: String
    @Binding var selectedFont: DeckFontOption
    @Binding var selectedFontSize: DeckFontSize
    let deckOpacity: Double
    @Binding var remainingSeconds: Int
    @Binding var isRunning: Bool
    let canExit: Bool
    let exitHint: String
    let showsExitHint: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onExit: () -> Void
    let onHoverChanged: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(max(0.06, deckOpacity * 0.5)))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.58),
                                    Color.white.opacity(0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.18), radius: 50, x: 0, y: 24)

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    MinimalTimer(
                        remainingSeconds: $remainingSeconds,
                        isRunning: $isRunning,
                        onStart: onStart,
                        onPause: onPause
                    )

                    Spacer(minLength: 20)

                    Button(action: onExit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(canExit ? 0.72 : 0.24))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canExit)
                }

                MinimalWritingSpace(
                    text: $text,
                    selectedFont: selectedFont,
                    selectedFontSize: selectedFontSize
                )

                if showsExitHint {
                    Text(exitHint)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(canExit ? 0.62 : 0.42))
                }
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 30)
        }
        .frame(maxWidth: 1030, minHeight: 610)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onHover { hovering in
            onHoverChanged(hovering)
        }
    }
}

// MARK: - Minimal Writing Space
struct MinimalWritingSpace: View {
    @Binding var text: String
    let selectedFont: DeckFontOption
    let selectedFontSize: DeckFontSize
    @FocusState private var isFocused: Bool
    private let editorTopInset: CGFloat = 14
    private let editorLeadingInset: CGFloat = 8

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(selectedFont.font(size: selectedFontSize))
                .foregroundColor(.white.opacity(0.92))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(maxWidth: .infinity, minHeight: 430)
                .padding(.top, editorTopInset)
                .padding(.leading, editorLeadingInset)
                .focused($isFocused)

            if text.isEmpty {
                Text("青青子衿，悠悠我心")
                    .font(selectedFont.font(size: selectedFontSize))
                    .foregroundColor(.white.opacity(0.24))
                    .padding(.top, editorTopInset + 2)
                    .padding(.leading, editorLeadingInset + 4)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 430)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Minimal Timer
struct MinimalTimer: View {
    @Binding var remainingSeconds: Int
    @Binding var isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(timeString)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.82))
                .monospacedDigit()

            Button(action: isRunning ? onPause : onStart) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.76))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct TopControlBar: View {
    @Binding var mode: WeatherMode
    let isVisible: Bool
    let onHoverChanged: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            TopModeButton(
                title: "Rainy",
                icon: "cloud.rain",
                isSelected: mode == .rain,
                action: { mode = .rain }
            )

            DividerCapsule()

            TopModeButton(
                title: "Snowy",
                icon: "snowflake",
                isSelected: mode == .snow,
                action: { mode = .snow }
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .background(
            VisualEffectBlur(material: .menu, blendingMode: .withinWindow)
                .clipShape(Capsule())
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 8)
        .opacity(isVisible ? 1 : 0.16)
        .offset(y: isVisible ? 0 : -8)
        .animation(.easeOut(duration: 0.22), value: isVisible)
        .allowsHitTesting(isVisible)
        .contentShape(Capsule())
        .onHover { hovering in
            onHoverChanged(hovering)
        }
    }
}

private struct DividerCapsule: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 18)
    }
}

private struct TopModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white.opacity(isSelected ? 0.92 : 0.64))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isSelected ? Color.white.opacity(0.10) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FontOrbPanel: View {
    @Binding var selectedFont: DeckFontOption
    @Binding var selectedFontSize: DeckFontSize
    let isExpanded: Bool
    let onHoverChanged: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isExpanded ? 0.10 : 0.05))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))

                Text("T")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(isExpanded ? 0.92 : 0.62))
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("字体")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))
                        .padding(.bottom, 2)

                    ForEach(DeckFontOption.allCases) { option in
                        Button(action: { selectedFont = option }) {
                            Text(option.label)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(selectedFont == option ? 0.95 : 0.56))
                                .lineLimit(1)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedFont == option ? Color.white.opacity(0.10) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    DividerCapsule()
                        .frame(height: 1)

                    Text("字号")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))

                    HStack(spacing: 8) {
                        ForEach(DeckFontSize.allCases) { size in
                            Button(action: { selectedFontSize = size }) {
                                Text(size.label)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(selectedFontSize == size ? 0.95 : 0.56))
                                    .frame(width: 28, height: 28)
                                    .background(selectedFontSize == size ? Color.white.opacity(0.10) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .frame(width: 132)
                .background(Color.white.opacity(0.05))
                .background(
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
        }
        .frame(width: isExpanded ? 132 : 40, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { hovering in
            onHoverChanged(hovering)
        }
        .animation(.easeOut(duration: 0.22), value: isExpanded)
    }
}

private struct BottomEnvironmentMixer: View {
    @Binding var mode: WeatherMode
    @Binding var particleIntensity: Double
    @Binding var backgroundBlur: Double
    @Binding var deckOpacity: Double
    @Binding var ambientVolume: Double
    let isVisible: Bool
    let onWallpaperChange: () -> Void
    let onHoverChanged: (Bool) -> Void

    private let blurRange: ClosedRange<Double> = 0...36

    var body: some View {
        HStack(spacing: 18) {
            Text(mode == .snow ? "SNOW" : "RAIN")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .tracking(1.6)
                .foregroundColor(.white.opacity(0.58))

            Text(intensityText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.78))

            Slider(value: $particleIntensity, in: 0.4...1.6)
                .frame(width: 140)
                .tint(.white.opacity(0.82))

            DividerCapsule()

            Text("CLEAR")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .tracking(1.6)
                .foregroundColor(.white.opacity(0.58))

            Text(clarityText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.78))

            Slider(value: clarityBinding, in: blurRange)
                .frame(width: 120)
                .tint(.white.opacity(0.82))

            DividerCapsule()

            Text("GLASS")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .tracking(1.6)
                .foregroundColor(.white.opacity(0.58))

            Text(glassText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.78))

            Slider(value: $deckOpacity, in: 0.01...0.18)
                .frame(width: 100)
                .tint(.white.opacity(0.82))

            DividerCapsule()

            Button(action: onWallpaperChange) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.56))
            }
            .buttonStyle(.plain)
            .help("换一张壁纸")

            DividerCapsule()

            Image(systemName: "speaker.wave.2")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.56))

            Text(volumeText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.78))

            Slider(value: $ambientVolume, in: 0...1)
                .frame(width: 120)
                .tint(.white.opacity(0.82))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0.22)
        .offset(y: isVisible ? 0 : 8)
        .animation(.easeOut(duration: 0.22), value: isVisible)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onHover { hovering in
            onHoverChanged(hovering)
        }
    }

    private var intensityText: String {
        "\(Int((particleIntensity / 1.6) * 100))%"
    }

    private var clarityBinding: Binding<Double> {
        Binding(
            get: { blurRange.upperBound - backgroundBlur },
            set: { clarity in
                backgroundBlur = blurRange.upperBound - clarity
            }
        )
    }

    private var clarityText: String {
        "\(Int((clarityBinding.wrappedValue / blurRange.upperBound) * 100))%"
    }

    private var glassText: String {
        "\(Int((deckOpacity / 0.18) * 100))%"
    }

    private var volumeText: String {
        "\(Int(ambientVolume * 100))%"
    }
}
