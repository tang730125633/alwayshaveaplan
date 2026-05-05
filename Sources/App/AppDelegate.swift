import AppKit
import ServiceManagement
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appController: AppController?
    private var statusItem: NSStatusItem?
    private var globalHotKeyManager: GlobalHotKeyManager?

    private let openMainWindowShortcut = GlobalHotKeyManager.Shortcut(
        keyCode: UInt32(kVK_ANSI_O),
        modifiers: [.command, .shift, .control]
    )
    private let openFocusModeShortcut = GlobalHotKeyManager.Shortcut(
        keyCode: UInt32(kVK_ANSI_F),
        modifiers: [.command, .shift, .control]
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("Application did finish launching. bundleURL=\(Bundle.main.bundleURL.path)")
        if !Bootstrapper.shouldContinueInProcess() {
            Log.info("Exiting bootstrap process after launching app bundle.")
            NSApp.terminate(nil)
            return
        }

        // Auto-register as a login item (macOS 13+).
        // Only register if not already registered to avoid duplicate entries.
        let loginItemStatus = SMAppService.mainApp.status
        if loginItemStatus == .notRegistered {
            do {
                try SMAppService.mainApp.register()
                Log.info("Login item registered. status=\(SMAppService.mainApp.status.rawValue)")
            } catch {
                Log.error("Failed to register login item: \(error)")
            }
        } else {
            Log.info("Login item already registered. status=\(loginItemStatus.rawValue)")
        }

        // Disable Command+Q
        disableCommandQ()

        appController = AppController()
        setupGlobalHotKeys()
        setupMenuBar()
    }

    private func setupGlobalHotKeys() {
        let hotKeyManager = GlobalHotKeyManager()
        hotKeyManager.register(.openMainWindow, shortcut: openMainWindowShortcut) { [weak self] in
            self?.openMainWindow()
        }
        hotKeyManager.register(.openFocusMode, shortcut: openFocusModeShortcut) { [weak self] in
            self?.openFocusMode()
        }
        globalHotKeyManager = hotKeyManager
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "calendar.circle", accessibilityDescription: "FlowPlan")
        }

        let menu = NSMenu()
        menu.addItem(makeMenuItem(title: "打开主窗口", action: #selector(openMainWindow), keyEquivalent: "o", shortcut: openMainWindowShortcut))
        menu.addItem(makeMenuItem(title: "进入专注模式", action: #selector(openFocusMode), keyEquivalent: "f", shortcut: openFocusModeShortcut))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func makeMenuItem(
        title: String,
        action: Selector,
        keyEquivalent: String,
        shortcut: GlobalHotKeyManager.Shortcut
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = shortcut.modifiers
        item.target = self
        return item
    }

    @objc private func openMainWindow() {
        appController?.triggerCheck()
    }

    @objc private func openFocusMode() {
        appController?.openFocusMode()
    }

    private func disableCommandQ() {
        // Remove the Quit menu item's key equivalent
        if let appMenu = NSApp.mainMenu?.items.first?.submenu {
            for item in appMenu.items {
                if item.action == #selector(NSApplication.terminate(_:)) {
                    item.keyEquivalent = ""
                }
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Prevent Command+Q from quitting the app
        Log.info("Terminate request blocked")
        return .terminateCancel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Log.info("Application reopen requested from Dock/app switcher hasVisibleWindows=\(flag)")
        appController?.reopenPrimaryWindow()
        return true
    }
}
