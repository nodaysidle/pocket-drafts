import SwiftUI
import SwiftData
import AppKit
import CoreFoundation

@main
struct PocketDraftsApp: App {
    /// Shared with the AppKit status-item delegate that hosts the popover.
    static let deletionUndoService = DeletionUndoService()
    static var container: ModelContainer!

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        do {
            Self.container = try PersistenceController.makeContainer()
        } catch {
            // Degrade to an in-memory store instead of crashing at launch;
            // the on-disk failure is logged to Console for diagnosis.
            NSLog("Pocket Drafts: could not open on-disk store (%@); using in-memory fallback.", error.localizedDescription)
            Self.container = PersistenceController.inMemoryFallback()
        }
    }

    var body: some Scene {
        // The settings window (PRD: the only full window). Registering this
        // scene also provides the ⌘, "Settings…" command in the app menu.
        Settings {
            SettingsView()
        }
    }
}

/// Hosts the SwiftUI interface in a floating, rounded panel.
///
/// SwiftUI's `MenuBarExtra` scene terminates the process (exit 0) inside an
/// LSUIElement app on the current macOS build, so the status item is created
/// directly with AppKit — the menu-bar-extra bridge ARD permits. The SwiftUI
/// views are hosted in a floating panel at the top-right of the current
/// screen, so the app works in hidden-menu-bar setups (e.g., SketchyBar)
/// where an `NSPopover` cannot attach to a visible status item.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(togglePanel(_:))
            button.toolTip = "Pocket Drafts"
            button.setAccessibilityLabel("Pocket Drafts")
        }
        statusItem = item
        observeOpenNotification()
    }

    /// Opens the popover when another app (e.g., a SketchyBar item) requests
    /// it via the `pocketdrafts://open` URL scheme.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard urls.contains(where: { $0.scheme?.lowercased() == "pocketdrafts" }) else { return }
        NSLog("Pocket Drafts: popover requested via URL scheme.")
        togglePanel(nil)
    }

    /// Bulletproof trigger for menu-bar-less setups: a Darwin notification
    /// needs no AppleEvent delivery or automation permission, so the panel
    /// opens even when URL-scheme routing is stale or unavailable.
    private func observeOpenNotification() {
        let name = "com.nodaysidle.pocketdrafts.open" as CFString
        let callback: @convention(c) (CFNotificationCenter?, UnsafeMutableRawPointer?, CFNotificationName?, UnsafeRawPointer?, CFDictionary?) -> Void = { _, observer, _, _, _ in
            guard let observer else { return }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
            Task { @MainActor in
                NSLog("Pocket Drafts: popover requested via notification.")
                delegate.togglePanel(nil)
            }
        }
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            callback,
            name,
            nil,
            .deliverImmediately
        )
    }

    @objc private func togglePanel(_ sender: Any?) {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        NSLog("Pocket Drafts: showing panel.")
        NSApp.activate(ignoringOtherApps: true)
        let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        let panel = self.panel ?? makePanel(on: screen)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel(on screen: NSScreen) -> NSWindow {
        let size = NSSize(width: 380, height: 520)
        let origin = NSPoint(x: screen.frame.maxX - size.width - 8, y: screen.frame.maxY - size.height - 8)
        let window = PocketDraftsPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let root = RootView()
            .modelContainer(PocketDraftsApp.container)
            .environment(\.deletionUndoService, PocketDraftsApp.deletionUndoService)
            .background(Color(nsColor: .windowBackgroundColor))
        let host = NSHostingView(rootView: root)
        host.wantsLayer = true
        host.layer?.cornerRadius = 12
        host.layer?.masksToBounds = true
        window.contentView = host
        self.panel = window
        return window
    }
}

/// Borderless window that can still become key so text fields receive focus.
private final class PocketDraftsPanel: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
