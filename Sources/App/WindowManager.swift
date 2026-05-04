import AppKit
import SwiftUI
import EventKit

final class WindowManager: NSObject, NSWindowDelegate {
    private var floatingWindowController: NSWindowController?
    private let floatingModel = FloatingPromptModel()
    private var autoHideWorkItem: DispatchWorkItem?
    private var canCloseWindow = false
    private var focusModeWindowController: NSWindowController?

    func showFloatingPrompt(onCheck: @escaping () -> Void) {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
        canCloseWindow = false

        // 设置创建日程后的回调
        floatingModel.onEventCreated = { [weak self] in
            self?.showFocusMode()
        }

        if floatingWindowController == nil {
            Log.info("Showing floating prompt window")
            let hosting = NSHostingView(rootView: FloatingPromptView(model: floatingModel, onCheck: onCheck, onClose: { [weak self] in
                self?.hideFloatingWindow()
            }))

            let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
            let size = NSSize(width: screen.width * 0.9, height: min(screen.height * 0.5, 500))
            let origin = NSPoint(
                x: screen.midX - size.width / 2,
                y: screen.midY - size.height / 2
            )

            let window = NSWindow(
                contentRect: NSRect(origin: origin, size: size),
                styleMask: [.titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.standardWindowButton(.closeButton)?.isHidden = !canCloseWindow
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.delegate = self
            window.contentView = hosting
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)

            floatingWindowController = NSWindowController(window: window)
        } else {
            Log.info("Reusing existing floating prompt window")
            if let window = floatingWindowController?.window {
                window.standardWindowButton(.closeButton)?.isHidden = !canCloseWindow
                window.contentView = NSHostingView(rootView: FloatingPromptView(model: floatingModel, onCheck: onCheck, onClose: { [weak self] in
                    self?.hideFloatingWindow()
                }))
            }
            NSApp.activate(ignoringOtherApps: true)
            floatingWindowController?.showWindow(nil)
        }
    }

    func showFloatingEvents(_ events: [EKEvent], autoHideAfter seconds: TimeInterval?) {
        Log.info("Showing floating events autoHideAfter=\(seconds.map { "\($0)s" } ?? "manual") count=\(events.count)")
        updateFloatingEvents(events)
        showFloatingPrompt(onCheck: {})
        allowFloatingWindowClose()

        autoHideWorkItem?.cancel()
        guard let seconds else { return }

        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Only auto-hide if we still have events showing.
            guard !self.floatingModel.currentEvents.isEmpty else { return }
            self.floatingModel.currentEvents = []
            self.floatingWindowController?.window?.orderOut(nil)
            Log.info("Auto-hid floating events window")
        }
        autoHideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    func updateFloatingEvents(_ events: [EKEvent]) {
        floatingModel.currentEvents = events
    }

    func hideFloatingWindow() {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
        floatingModel.currentEvents = []
        floatingWindowController?.window?.orderOut(nil)
        Log.info("Hid floating window")
    }

    private func closeFloatingPrompt() {
        floatingWindowController?.close()
        floatingWindowController = nil
    }

    private func allowFloatingWindowClose() {
        canCloseWindow = true
        floatingWindowController?.window?.standardWindowButton(.closeButton)?.isHidden = false
    }

    func allowWindowClose() {
        canCloseWindow = true
        floatingWindowController?.window?.orderOut(nil)
    }

    // MARK: - NSWindowDelegate
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender === floatingWindowController?.window {
            return canCloseWindow
        }

        return true
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        if window === focusModeWindowController?.window {
            focusModeWindowController = nil
        }

        if window === floatingWindowController?.window, canCloseWindow {
            floatingWindowController = nil
        }
    }

    func showFocusMode() {
        if let window = focusModeWindowController?.window {
            Log.info("Reusing existing focus mode window")
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let taskTitle = floatingModel.lastCreatedTaskTitle
        let hosting = NSHostingView(rootView: FocusModeView(taskTitle: taskTitle, onExit: { [weak self] in
            self?.hideFocusMode()
        }))

        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let window = NSWindow(
            contentRect: screen,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .normal
        window.collectionBehavior = [.canJoinAllSpaces]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = hosting

        let controller = NSWindowController(window: window)
        focusModeWindowController = controller

        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        floatingWindowController?.window?.orderOut(nil)
    }

    func hideFocusMode() {
        focusModeWindowController?.close()
    }

    func reopenPrimaryWindow() -> Bool {
        return false
    }
}

final class FloatingPromptModel: ObservableObject {
    @Published var currentEvents: [EKEvent] = []
    var onEventCreated: (() -> Void)?
    var lastCreatedTaskTitle: String = ""
}
