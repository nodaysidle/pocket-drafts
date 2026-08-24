import SwiftUI
import SwiftData
import AppKit

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

/// Hosts the SwiftUI popover from an AppKit status item.
///
/// SwiftUI's `MenuBarExtra` scene terminates the process (exit 0) inside an
/// LSUIElement app on the current macOS build, so the status item is created
/// directly with AppKit — the menu-bar-extra bridge ARD permits — and the
/// existing SwiftUI views are hosted in an `NSPopover` unchanged.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.toolTip = "Pocket Drafts"
            button.setAccessibilityLabel("Pocket Drafts")
        }
        statusItem = item
    }

    @objc private func togglePopover(_ sender: Any?) {
        if let popover, popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        let popover = self.popover ?? makePopover()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func makePopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 520)
        popover.contentViewController = NSHostingController(
            rootView: RootView()
                .modelContainer(PocketDraftsApp.container)
                .environment(\.deletionUndoService, PocketDraftsApp.deletionUndoService)
        )
        self.popover = popover
        return popover
    }
}
