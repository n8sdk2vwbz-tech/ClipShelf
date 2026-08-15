import AppKit

/// Writes a ClipboardItem back to the system pasteboard, and optionally simulates
/// a ⌘V keystroke so the item lands directly in the frontmost app.
enum PasteboardWriter {
    static func copy(_ item: ClipboardItem, store: ClipboardStore) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.kind {
        case .text:
            pb.setString(item.text ?? "", forType: .string)
        case .fileURLs:
            let urls = (item.fileURLs ?? []).map { $0 as NSURL }
            guard !urls.isEmpty else { return }
            pb.writeObjects(urls)
        case .image:
            guard let image = store.image(for: item) else { return }
            pb.writeObjects([image])
        }
    }

    /// Requests Accessibility permission if not already granted. `prompt: true` shows
    /// the system dialog; pass false for silent checks.
    @discardableResult
    static func hasAccessibilityPermission(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Copies the item, then simulates ⌘V into whatever app is currently frontmost.
    /// Requires Accessibility permission; does nothing (silently) if not granted.
    static func copyAndPaste(_ item: ClipboardItem, store: ClipboardStore) {
        copy(item, store: store)
        guard hasAccessibilityPermission(prompt: false) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            simulatePasteKeystroke()
        }
    }

    private static func simulatePasteKeystroke() {
        let vKeyCode: CGKeyCode = 9 // ANSI 'v'
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }
}
