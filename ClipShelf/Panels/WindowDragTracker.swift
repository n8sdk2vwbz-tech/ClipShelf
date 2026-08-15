import AppKit

/// Tracks a window drag using absolute screen mouse coordinates (`NSEvent.mouseLocation`)
/// rather than accumulated SwiftUI gesture deltas. The delta approach flickers/jitters
/// because a SwiftUI DragGesture's coordinate space is anchored to the very window being
/// moved — moving the window mid-gesture shifts the reference frame the next delta is
/// measured against, creating a feedback loop. Reading the absolute mouse position each
/// time sidesteps that entirely.
final class WindowDragTracker {
    private weak var window: NSWindow?
    private var startMouseLocation: NSPoint?
    private var startWindowOrigin: NSPoint?

    init(window: NSWindow) {
        self.window = window
    }

    func begin() {
        startMouseLocation = NSEvent.mouseLocation
        startWindowOrigin = window?.frame.origin
    }

    func update() {
        guard let window, let startMouseLocation, let startWindowOrigin else { return }
        let current = NSEvent.mouseLocation
        let newOrigin = NSPoint(
            x: startWindowOrigin.x + (current.x - startMouseLocation.x),
            y: startWindowOrigin.y + (current.y - startMouseLocation.y)
        )
        window.setFrameOrigin(newOrigin)
    }
}
