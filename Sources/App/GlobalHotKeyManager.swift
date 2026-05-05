import AppKit
import Carbon

final class GlobalHotKeyManager {
    struct Shortcut {
        let keyCode: UInt32
        let modifiers: NSEvent.ModifierFlags
    }

    enum ActionID: UInt32 {
        case openMainWindow = 1
        case openFocusMode = 2
    }

    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [ActionID: EventHotKeyRef?] = [:]
    private var handlers: [ActionID: () -> Void] = [:]
    private let signature: OSType = 0x464C4F57 // 'FLOW'

    init() {
        installHandlerIfNeeded()
    }

    deinit {
        for hotKeyRef in hotKeyRefs.values {
            if let hotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
            }
        }

        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    func register(_ actionID: ActionID, shortcut: Shortcut, handler: @escaping () -> Void) {
        if let existingRef = hotKeyRefs[actionID] ?? nil {
            UnregisterEventHotKey(existingRef)
        }

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: actionID.rawValue)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            carbonModifiers(from: shortcut.modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            Log.error("Failed to register hotkey for action=\(actionID.rawValue) status=\(status)")
            return
        }

        hotKeyRefs[actionID] = hotKeyRef
        handlers[actionID] = handler
        Log.info("Registered global hotkey action=\(actionID.rawValue)")
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard parameterStatus == noErr else {
                    return parameterStatus
                }

                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotKey(id: hotKeyID)
                return noErr
            },
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handlerRef
        )

        if status != noErr {
            Log.error("Failed to install global hotkey event handler status=\(status)")
        }
    }

    private func handleHotKey(id: EventHotKeyID) {
        guard id.signature == signature, let actionID = ActionID(rawValue: id.id) else { return }
        handlers[actionID]?()
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0

        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }

        return modifiers
    }
}