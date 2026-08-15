import AppKit

/// Watches global mouse movement (no Accessibility permission needed for mouse-only
/// monitors) for the classic "shake" gesture — several quick left/right reversals —
/// while an actual drag-and-drop payload is on the system drag pasteboard. This is how
/// apps like Dropover reveal their shelf: it only appears when you shake an item you're
/// currently dragging, never sitting permanently on screen.
final class DragShakeDetector {
    var onShakeDetected: ((NSPoint) -> Void)?

    // A global monitor only sees events destined for OTHER apps, so a drag that starts
    // inside one of ClipShelf's own panels (e.g. dragging a history row) would otherwise
    // go completely unnoticed. A local monitor covers that case; together they see every
    // drag regardless of where it started.
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastLocation: NSPoint?
    private var lastDirection: Int = 0
    private var segmentStartX: CGFloat = 0
    private var reversalTimestamps: [Date] = []
    private var lastTriggerDate: Date?

    private let reversalWindow: TimeInterval = 0.6
    private let cooldown: TimeInterval = 1.2
    private let minSegmentDistance: CGFloat = 18
    private let requiredReversals = 4

    func start() {
        stop()
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            reset()
        case .leftMouseDragged:
            processDrag()
        case .leftMouseUp:
            reset()
        default:
            break
        }
    }

    private func reset() {
        lastLocation = nil
        lastDirection = 0
        reversalTimestamps.removeAll()
    }

    private func processDrag() {
        let location = NSEvent.mouseLocation
        defer { lastLocation = location }

        guard let last = lastLocation else {
            segmentStartX = location.x
            return
        }

        let dx = location.x - last.x
        guard abs(dx) > 1 else { return }
        let direction = dx > 0 ? 1 : -1

        if lastDirection == 0 {
            lastDirection = direction
            segmentStartX = last.x
            return
        }

        guard direction != lastDirection else { return }

        let segmentDistance = abs(last.x - segmentStartX)
        if segmentDistance >= minSegmentDistance {
            registerReversal()
        }
        lastDirection = direction
        segmentStartX = last.x
    }

    private func registerReversal() {
        let now = Date()
        reversalTimestamps.append(now)
        reversalTimestamps.removeAll { now.timeIntervalSince($0) > reversalWindow }

        guard reversalTimestamps.count >= requiredReversals else { return }
        if let lastTriggerDate, now.timeIntervalSince(lastTriggerDate) < cooldown { return }

        // Only fire if there's actually something being dragged system-wide right now.
        guard let items = NSPasteboard(name: .drag).pasteboardItems, !items.isEmpty else { return }

        lastTriggerDate = now
        reversalTimestamps.removeAll()
        onShakeDetected?(NSEvent.mouseLocation)
    }
}
