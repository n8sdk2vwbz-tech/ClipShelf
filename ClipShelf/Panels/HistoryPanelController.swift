import AppKit
import SwiftUI

final class HistoryPanelController: NSObject, NSWindowDelegate {
    private let panel: FloatingPanel
    private let monitor: ClipboardMonitor
    private let store: ClipboardStore
    private let shelfViewModel: ShelfViewModel
    private var localKeyMonitor: Any?
    private var hasCustomPosition = false
    private lazy var dragTracker = WindowDragTracker(window: panel)

    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    init(monitor: ClipboardMonitor, store: ClipboardStore, shelfViewModel: ShelfViewModel) {
        self.monitor = monitor
        self.store = store
        self.shelfViewModel = shelfViewModel
        self.panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 460))
        super.init()

        panel.delegate = self
        panel.contentView = NSHostingView(rootView: makeContent())
    }

    private func makeContent() -> some View {
        HistoryListView(
            monitor: monitor,
            store: store,
            shelfViewModel: shelfViewModel,
            onPasteSelected: { [weak self] item in
                self?.hide()
                PasteboardWriter.copyAndPaste(item, store: self?.store ?? ClipboardStore())
                self?.monitor.syncAfterOwnWrite()
            },
            onCopySelected: { [weak self] item in
                PasteboardWriter.copy(item, store: self?.store ?? ClipboardStore())
                self?.monitor.syncAfterOwnWrite()
                self?.hide()
            },
            onOpenSettings: { [weak self] in
                self?.hide()
                self?.onOpenSettings?()
            },
            onQuit: { [weak self] in
                self?.onQuit?()
            },
            onClose: { [weak self] in
                self?.hide()
            },
            onDragBegin: { [weak self] in
                self?.dragTracker.begin()
            },
            onDragChanged: { [weak self] in
                self?.dragTracker.update()
                self?.hasCustomPosition = true
            }
        )
    }

    var isVisible: Bool { panel.isVisible }

    func toggle(anchorTo view: NSStatusBarButton?) {
        if panel.isVisible {
            hide()
        } else {
            show(anchorTo: view)
        }
    }

    func show(anchorTo statusBarButton: NSStatusBarButton?) {
        if !hasCustomPosition {
            positionPanel(anchorTo: statusBarButton)
        }
        present()
    }

    func showAtMouseLocation() {
        if !hasCustomPosition {
            positionPanel(at: NSEvent.mouseLocation)
        }
        present()
    }

    private func present() {
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installLocalMonitor()
    }

    func hide() {
        panel.orderOut(nil)
        removeLocalMonitor()
    }

    private func positionPanel(anchorTo statusBarButton: NSStatusBarButton?) {
        guard let button = statusBarButton, let buttonWindow = button.window else {
            positionPanel(at: NSEvent.mouseLocation)
            return
        }
        let buttonFrameInScreen = buttonWindow.convertToScreen(button.frame)
        let x = buttonFrameInScreen.midX - panel.frame.width / 2
        let y = buttonFrameInScreen.minY - panel.frame.height - 4
        panel.setFrameOrigin(clampToScreen(NSPoint(x: x, y: y), size: panel.frame.size, near: buttonFrameInScreen.origin))
    }

    private func positionPanel(at point: NSPoint) {
        let x = point.x - panel.frame.width / 2
        let y = point.y - panel.frame.height - 12
        panel.setFrameOrigin(clampToScreen(NSPoint(x: x, y: y), size: panel.frame.size, near: point))
    }

    private func clampToScreen(_ origin: NSPoint, size: NSSize, near referencePoint: NSPoint) -> NSPoint {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(referencePoint) }) ?? NSScreen.main else {
            return origin
        }
        let frame = screen.visibleFrame
        var result = origin
        result.x = min(max(result.x, frame.minX + 8), frame.maxX - size.width - 8)
        result.y = min(max(result.y, frame.minY + 8), frame.maxY - size.height - 8)
        return result
    }

    private func installLocalMonitor() {
        removeLocalMonitor()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hide()
                return nil
            }
            return event
        }
    }

    private func removeLocalMonitor() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
        localKeyMonitor = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    func windowDidMove(_ notification: Notification) {
        hasCustomPosition = true
    }
}
