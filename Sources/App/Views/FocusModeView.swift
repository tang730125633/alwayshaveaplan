import SwiftUI
import AppKit

// MARK: - Focus Mode View
struct FocusModeView: View {
    let taskTitle: String
    @State private var weatherMode: WeatherMode = .snow
    @State private var noteText = ""
    @State private var remainingSeconds = 1500
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    let onExit: () -> Void

    var body: some View {
        ZStack {
            ParticleBackgroundView(mode: $weatherMode)
                .ignoresSafeArea()
                .opacity(0.8)

            VStack(spacing: 60) {
                Spacer()

                // 任务标题
                Text(taskTitle)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                // 极简写作框
                MinimalWritingSpace(text: $noteText)

                // 番茄钟（极简）
                MinimalTimer(
                    remainingSeconds: $remainingSeconds,
                    isRunning: $isTimerRunning,
                    onStart: startTimer,
                    onPause: pauseTimer
                )

                Spacer()
            }

            // 关闭按钮（右上角）
            VStack {
                HStack {
                    Spacer()
                    Button(action: onExit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                pauseTimer()
                // 番茄钟结束提示
                NSSound.beep()
            }
        }
    }

    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        remainingSeconds = 1500
    }
}

// MARK: - Minimal Writing Space
struct MinimalWritingSpace: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 18, design: .serif))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .frame(maxWidth: 700, minHeight: 300)
            .padding(40)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .focused($isFocused)
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
        HStack(spacing: 20) {
            Text(timeString)
                .font(.system(size: 16, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))

            Button(action: isRunning ? onPause : onStart) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Pomodoro Timer
struct PomodoroTimer: View {
    @Binding var remainingSeconds: Int
    @Binding var isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 环形进度条
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.coral500, .sage500],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text(isRunning ? "专注中" : "暂停")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // 控制按钮
            HStack(spacing: 20) {
                Button(action: isRunning ? onPause : onStart) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)

                Button(action: onReset) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var progress: CGFloat {
        CGFloat(remainingSeconds) / 1500.0
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Writing Space
struct WritingSpace: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("任务拆解")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("详细列出要做的事情：")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))

            TextEditor(text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(maxWidth: 600, minHeight: 250, maxHeight: 350)
                .padding(20)
                .background(
                    ZStack {
                        VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                        Color.white.opacity(0.1)
                    }
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
