import EventKit
import SwiftUI
import AppKit

// MARK: - Visual Effect Blur (macOS Native Blur)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Color Theme
extension Color {
    // Warm neutrals
    static let stone50 = Color(red: 0.98, green: 0.98, blue: 0.976)
    static let stone100 = Color(red: 0.96, green: 0.96, blue: 0.953)
    static let stone200 = Color(red: 0.906, green: 0.898, blue: 0.894)
    static let stone300 = Color(red: 0.839, green: 0.827, blue: 0.82)
    static let stone400 = Color(red: 0.659, green: 0.635, blue: 0.62)
    static let stone500 = Color(red: 0.471, green: 0.443, blue: 0.424)
    static let stone600 = Color(red: 0.341, green: 0.325, blue: 0.306)
    static let stone700 = Color(red: 0.267, green: 0.251, blue: 0.235)
    static let stone800 = Color(red: 0.161, green: 0.145, blue: 0.141)

    // Primary accent - Warm coral
    static let coral400 = Color(red: 1.0, green: 0.541, blue: 0.42)
    static let coral500 = Color(red: 0.957, green: 0.427, blue: 0.29)
    static let coral600 = Color(red: 0.886, green: 0.329, blue: 0.208)

    // Secondary - Sage green
    static let sage50 = Color(red: 0.965, green: 0.969, blue: 0.957)
    static let sage200 = Color(red: 0.831, green: 0.855, blue: 0.776)
    static let sage400 = Color(red: 0.588, green: 0.651, blue: 0.478)
    static let sage500 = Color(red: 0.478, green: 0.549, blue: 0.365)
    static let sage600 = Color(red: 0.373, green: 0.435, blue: 0.282)
    static let sage700 = Color(red: 0.29, green: 0.341, blue: 0.227)
}

// MARK: - Main View
struct FloatingPromptView: View {
    @ObservedObject var model: FloatingPromptModel
    let onCheck: () -> Void
    let onClose: (() -> Void)?

    var body: some View {
        ZStack {
            // Blurred background with vibrancy effect
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            // Subtle gradient overlay for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color(red: 0.98, green: 0.973, blue: 0.961).opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative gradient orbs (more subtle with blur)
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.coral500.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.4
                        )
                    )
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                    .offset(x: geometry.size.width * 0.4, y: -geometry.size.height * 0.2)
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.sage500.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.35
                        )
                    )
                    .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.15, y: geometry.size.height * 0.5)
                    .blur(radius: 60)
            }

            // Main content
            if model.currentEvents.isEmpty {
                NoEventsView(onCheck: onCheck)
                    .environmentObject(model)
            } else if let event = model.currentEvents.first {
                EventView(event: event) {
                    model.lastCreatedTaskTitle = event.title ?? "当前计划"
                    model.onOpenFocus?()
                } onClose: {
                    onClose?()
                }
            }

            // Time display
            VStack {
                HStack {
                    Spacer()
                    Text(currentTimeString)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .monospacedDigit()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.top, 24)
                        .padding(.trailing, 28)
                }
                Spacer()
            }
        }
    }

    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - No Events View
struct NoEventsView: View {
    let onCheck: () -> Void
    @State private var appeared = false
    @State private var eventTitle = ""
    @State private var startHour = Calendar.current.component(.hour, from: Date())
    @State private var startMinute = Calendar.current.component(.minute, from: Date())
    @State private var endHour = Calendar.current.component(.hour, from: Date().addingTimeInterval(3600))
    @State private var endMinute = Calendar.current.component(.minute, from: Date().addingTimeInterval(3600))
    @State private var showingCreationSuccess = false
    @State private var errorMessage: String?
    @EnvironmentObject var model: FloatingPromptModel

    var body: some View {
        ZStack {
            // Background question mark
            Text("?")
                .font(.system(size: 280, weight: .black, design: .serif))
                .foregroundColor(.coral500.opacity(0.04))

            VStack(spacing: 0) {
                Spacer()

                Text("你正在成为什么样的人？")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.stone800)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6), value: appeared)

                Text("你此时要做什么事情别着急，请好好思考一下，\n当下最重要的事情是什么？")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.top, 28)
                    .padding(.horizontal, 80)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)

                Spacer()
                    .frame(minHeight: 30)

                // 快速创建日程区域
                VStack(spacing: 16) {
                    // 时间选择器
                    HStack(spacing: 20) {
                        // 开始时间
                        VStack(spacing: 8) {
                            Text("开始时间")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.stone600)
                            HStack(spacing: 8) {
                                Picker("", selection: $startHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d", hour)).tag(hour)
                                    }
                                }
                                .frame(width: 60)
                                .labelsHidden()
                                Text(":")
                                    .foregroundColor(.stone500)
                                Picker("", selection: $startMinute) {
                                    ForEach(0..<60) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .frame(width: 60)
                                .labelsHidden()
                            }
                        }

                        Text("→")
                            .foregroundColor(.stone300)
                            .font(.system(size: 18))

                        // 结束时间
                        VStack(spacing: 8) {
                            Text("结束时间")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.stone600)
                            HStack(spacing: 8) {
                                Picker("", selection: $endHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d", hour)).tag(hour)
                                    }
                                }
                                .frame(width: 60)
                                .labelsHidden()
                                Text(":")
                                    .foregroundColor(.stone500)
                                Picker("", selection: $endMinute) {
                                    ForEach(0..<60) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .frame(width: 60)
                                .labelsHidden()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)

                    // 任务输入框
                    TextField("输入你要做的事情...", text: $eventTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.stone800)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.sage200, lineWidth: 1)
                        )

                    // 创建按钮
                    Button(action: createEvent) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("创建日程")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: eventTitle.isEmpty ? [.stone300, .stone400] : [.sage500, .sage600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: eventTitle.isEmpty ? .clear : .sage500.opacity(0.25), radius: 15, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(eventTitle.isEmpty)
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.15), value: appeared)

                Spacer()
                    .frame(minHeight: 20)

                // 按钮组
                HStack(spacing: 20) {
                    // 进入专注模式按钮
                    Button(action: {
                        model.lastCreatedTaskTitle = eventTitle.isEmpty ? "此刻最重要的事" : eventTitle
                        model.onEnterForcedFocus?()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 18, weight: .semibold))
                            Text("进入专注模式")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.purple.opacity(0.7), .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .purple.opacity(0.25), radius: 15, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    // 打开日历按钮
                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "x-apple-reminderkit://")!)
                        // 或者使用日历应用
                        if let calendarURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
                            NSWorkspace.shared.open(calendarURL)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text("打开日历")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.sage500, .sage600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .sage500.opacity(0.25), radius: 15, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    // 检查日程按钮
                    Button(action: onCheck) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .semibold))
                            Text("检查日程")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.coral500, .coral600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .coral500.opacity(0.25), radius: 15, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)

                Spacer()
            }
            .padding(40)
        }
        .onAppear {
            appeared = true
        }
        .alert("无法创建日程", isPresented: Binding(get: {
            errorMessage != nil
        }, set: { isPresented in
            if !isPresented {
                errorMessage = nil
            }
        })) {
            Button("知道了", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func createEvent() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var startComponents = DateComponents()
        startComponents.year = calendar.component(.year, from: today)
        startComponents.month = calendar.component(.month, from: today)
        startComponents.day = calendar.component(.day, from: today)
        startComponents.hour = startHour
        startComponents.minute = startMinute

        var endComponents = DateComponents()
        endComponents.year = calendar.component(.year, from: today)
        endComponents.month = calendar.component(.month, from: today)
        endComponents.day = calendar.component(.day, from: today)
        endComponents.hour = endHour
        endComponents.minute = endMinute

        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents),
              endDate > startDate else {
            errorMessage = "结束时间必须晚于开始时间。"
            return
        }

        let calendarManager = CalendarManager()
        calendarManager.createEvent(title: eventTitle, startDate: startDate, endDate: endDate) { success, error in
            if let error {
                Log.error("Create event failed: \(error.localizedDescription)")
            }

            if success {
                let createdTitle = eventTitle
                DispatchQueue.main.async {
                    self.model.lastCreatedTaskTitle = createdTitle
                    self.showingCreationSuccess = true
                    self.eventTitle = ""

                    // 创建成功后刷新到当前日程页，由用户决定是否进入专注模式。
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onCheck()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = error?.localizedDescription ?? "创建失败，请检查日历权限和默认日历设置。"
                }
            }
        }
    }
}

// MARK: - Event View
struct EventView: View {
    let event: EKEvent
    let onFocus: () -> Void
    let onClose: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Event card - centered
            VStack(alignment: .center, spacing: 20) {
                Text(event.title ?? "(无标题)")
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundColor(.stone800)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Time range
                HStack(spacing: 12) {
                    TimeBadge(time: formatTime(event.startDate), showIcon: true)
                    Text("→")
                        .foregroundColor(.stone300)
                        .font(.system(size: 14))
                    TimeBadge(time: formatTime(event.endDate), showIcon: false)
                }
                .padding(.bottom, 32)

                // Progress section
                VStack(spacing: 10) {
                    HStack {
                        Text("进度")
                            .font(.system(size: 13))
                            .foregroundColor(.stone500)
                        Spacer()
                        Text("\(Int(progressPercentage))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.coral600)
                            .monospacedDigit()
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.sage400, .coral400],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progressPercentage / 100, height: 8)
                        }
                    }
                    .frame(height: 8)
                }

                // Remaining time
                HStack {
                    Spacer()
                    Text("还剩 ")
                        .foregroundColor(.secondary)
                    + Text(remainingTimeString)
                        .foregroundColor(.coral600)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .font(.system(size: 14))
                .padding(.top, 8)

                Button(action: onFocus) {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 16, weight: .semibold))
                        Text("继续专注 / 打开写作窗口")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.sage500, .sage600],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .sage500.opacity(0.25), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Button(action: onClose) {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                        Text("关闭主页")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.stone600)
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 40)
            .padding(.vertical, 44)
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    Color.white.opacity(0.5)
                }
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)
            .animation(.easeOut(duration: 0.5), value: appeared)

            // Header - absolute positioned at top
            VStack {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.sage500)
                            .frame(width: 8, height: 8)
                        Text("当前日程")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.sage600)
                            .tracking(2)
                            .textCase(.uppercase)
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                Spacer()
            }
        }
        .onAppear {
            appeared = true
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var progressPercentage: Double {
        let now = Date()
        let totalDuration = event.endDate.timeIntervalSince(event.startDate)
        let elapsed = now.timeIntervalSince(event.startDate)

        guard totalDuration > 0 else { return 0 }
        return min(max(elapsed / totalDuration * 100, 0), 100)
    }

    private var remainingTimeString: String {
        let now = Date()
        let remaining = event.endDate.timeIntervalSince(now)

        guard remaining > 0 else { return "已结束" }

        let minutes = Int(remaining / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) 小时"
            }
            return "\(hours) 小时 \(mins) 分钟"
        }
        return "\(minutes) 分钟"
    }
}

// MARK: - Time Badge Component
struct TimeBadge: View {
    let time: String
    let showIcon: Bool

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .opacity(0.7)
            }
            Text(time)
                .font(.system(size: 15, weight: .medium))
                .monospacedDigit()
        }
        .foregroundColor(.sage700)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.sage50)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.sage200, lineWidth: 1)
        )
        .cornerRadius(10)
    }
}
