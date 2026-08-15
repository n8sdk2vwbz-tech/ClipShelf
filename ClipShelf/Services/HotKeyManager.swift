import Carbon.HIToolbox
import AppKit

/// Thin wrapper around the Carbon RegisterEventHotKey API for global keyboard shortcuts.
/// Carbon hotkeys keep working system-wide without needing Accessibility/Input-Monitoring
/// permission, which is why every menu-bar utility (Alfred, Rectangle, Maccy, …) still
/// relies on this API instead of NSEvent global monitors.
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?

    private init() {
        installDispatcher()
    }

    private func installDispatcher() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handlers[hotKeyID.id]?()
            return noErr
        }, 1, &eventType, selfPointer, &eventHandlerRef)
    }

    /// Registers a global hotkey. `keyCode` is a `kVK_*` virtual key code, `modifiers`
    /// a Carbon modifier mask (`cmdKey`, `shiftKey`, `optionKey`, `controlKey`, combined with `|`).
    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> UInt32 {
        let id = nextID
        nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x434c5348), id: id) // 'CLSH'
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[id] = ref
            handlers[id] = handler
        }
        return id
    }

    func unregister(_ id: UInt32) {
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeValue(forKey: id)
        handlers.removeValue(forKey: id)
    }
}
