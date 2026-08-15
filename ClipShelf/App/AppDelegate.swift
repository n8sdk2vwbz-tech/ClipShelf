import AppKit
import Carbon.HIToolbox
import Sparkle
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    private static let hasSeenOnboardingKey = "ClipShelf.hasSeenOnboarding"

    private let clipboardStore = ClipboardStore()
    private let shelfStore = ShelfStore()

    private lazy var clipboardMonitor = ClipboardMonitor(store: clipboardStore)
    private lazy var shelfViewModel = ShelfViewModel(store: shelfStore)
    private lazy var historyPanelController = HistoryPanelController(
        monitor: clipboardMonitor,
        store: clipboardStore,
        shelfViewModel: shelfViewModel
    )
    private lazy var shelfPanelController = ShelfPanelController(viewModel: shelfViewModel)
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private var historyHotKeyID: UInt32?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()

        historyPanelController.onOpenSettings = { [weak self] in self?.showSettings() }
        historyPanelController.onQuit = { NSApp.terminate(nil) }

        clipboardMonitor.start()
        shelfPanelController.start()
        _ = updaterController // starts Sparkle's background update checks

        historyHotKeyID = HotKeyManager.shared.register(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | shiftKey)
        ) { [weak self] in
            self?.historyPanelController.showAtMouseLocation()
        }

        showOnboardingIfNeeded()
    }

    private func showOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.hasSeenOnboardingKey) else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ClipShelf"
        window.isReleasedWhenClosed = false
        let hostingView = NSHostingView(
            rootView: OnboardingView(onDismiss: { [weak self] in
                self?.dismissOnboarding()
            })
        )
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        window.center()
        onboardingWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func dismissOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.hasSeenOnboardingKey)
        onboardingWindow?.close()
        onboardingWindow = nil
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        shelfPanelController.stop()
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipShelf")
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showStatusMenu()
        } else {
            historyPanelController.toggle(anchorTo: sender)
        }
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Verlauf öffnen (⌘⇧V)", action: #selector(openHistoryFromMenu), keyEquivalent: "").target = self
        menu.addItem(NSMenuItem.separator())
        let shelfTitle = shelfPanelController.isVisible ? "Ablage ausblenden" : "Ablage einblenden"
        menu.addItem(withTitle: shelfTitle, action: #selector(toggleShelfFromMenu), keyEquivalent: "").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Einstellungen…", action: #selector(openSettingsFromMenu), keyEquivalent: "").target = self
        let updateItem = menu.addItem(withTitle: "Nach Updates suchen…", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        updateItem.isEnabled = updaterController.updater.canCheckForUpdates
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Beenden", action: #selector(quit), keyEquivalent: "").target = self

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openHistoryFromMenu() {
        historyPanelController.showAtMouseLocation()
    }

    @objc private func toggleShelfFromMenu() {
        shelfPanelController.toggleVisibility()
    }

    @objc private func openSettingsFromMenu() {
        showSettings()
    }

    @objc private func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 280),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "ClipShelf – Einstellungen"
            window.contentView = NSHostingView(rootView: SettingsView(monitor: clipboardMonitor))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
