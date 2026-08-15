import AppKit
import SwiftUI

/// Hosts ShelfView in a borderless, always-on-top NSPanel that stays hidden until
/// summoned. Reveal is triggered either by DragShakeDetector (shaking a dragged item)
/// or the manual status-bar menu item, shown right next to the cursor so the same drag
/// can continue straight onto the tray. Once revealed it stays on screen — no auto-hide —
/// until the user explicitly closes it (the tray's ✕ button, or the menu toggle).
final class ShelfPanelController {
    private let panel: FloatingPanel
    private let viewModel: ShelfViewModel
    private let shakeDetector = DragShakeDetector()

    private let traySize = NSSize(width: 208, height: 320)
    private lazy var dragTracker = WindowDragTracker(window: panel)

    init(viewModel: ShelfViewModel) {
        self.viewModel = viewModel
        panel = FloatingPanel(contentRect: NSRect(origin: .zero, size: traySize))
        panel.contentView = NSHostingView(rootView: ShelfView(viewModel: viewModel))

        viewModel.onHideRequested = { [weak self] in self?.hide() }
        viewModel.onDragBegin = { [weak self] in self?.dragTracker.begin() }
        viewModel.onDragChanged = { [weak self] in self?.dragTracker.update() }

        shakeDetector.onShakeDetected = { [weak self] point in
            self?.reveal(near: point)
        }
    }

    func start() {
        shakeDetector.start()
    }

    func stop() {
        shakeDetector.stop()
    }

    var isVisible: Bool { panel.isVisible }

    func toggleVisibility() {
        if isVisible {
            hide()
        } else {
            reveal(near: NSEvent.mouseLocation)
        }
    }

    /// Only repositions the panel if it isn't already showing — once it's out and
    /// visible, a fresh shake elsewhere on screen shouldn't yank it out from under
    /// whatever the user is doing with it.
    private func reveal(near point: NSPoint) {
        guard !isVisible else { return }

        let visible = (NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        var origin = NSPoint(x: point.x - traySize.width / 2, y: point.y + 16)
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - traySize.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - traySize.height - 8)

        panel.setFrame(NSRect(origin: origin, size: traySize), display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}
