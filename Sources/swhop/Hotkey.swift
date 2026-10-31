// The global hotkey (cmd+space) through Carbon's RegisterEventHotKey: no
// Accessibility permission needed, delivered on the main run loop.

import AppKit
import Carbon

enum Hotkey {
    private static var onPress: (() -> Void)?

    /// Call `onPress` on every cmd+space. Returns nil on success; an error
    /// message if another app holds it (Spotlight, Alfred): turn their
    /// shortcut off first.
    static func register(_ onPress: @escaping () -> Void) -> String? {
        self.onPress = onPress
        let target = GetApplicationEventTarget()
        var spec = EventTypeSpec(
            eventClass: EventClass(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        var handlerRef: EventHandlerRef?
        guard InstallEventHandler(target, hotkeyHandler, 1, &spec, nil, &handlerRef) == noErr else {
            return "cannot install the hotkey handler"
        }
        let id = EventHotKeyID(signature: fourCC("swhp"), id: 1)
        var hotkey: EventHotKeyRef?
        let err = RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey), id, target, 0, &hotkey)
        guard err == noErr else {
            return "cmd+space is taken (error \(err)): turn off Spotlight's or Alfred's shortcut"
        }
        return nil
    }

    static func press() {
        onPress?()
    }

    private static func fourCC(_ s: String) -> FourCharCode {
        s.utf8.reduce(0) { $0 << 8 | UInt32($1) }
    }
}

private func hotkeyHandler(
    _ call: EventHandlerCallRef?,
    _ event: EventRef?,
    _ user: UnsafeMutableRawPointer?
) -> OSStatus {
    Hotkey.press()
    return noErr
}
