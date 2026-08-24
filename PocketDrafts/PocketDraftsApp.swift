import SwiftUI
import SwiftData

@main
struct PocketDraftsApp: App {
    private let container: ModelContainer
    /// App-owned so the pending deletion survives popover close/reopen.
    private let deletionUndoService = DeletionUndoService()

    init() {
        do {
            container = try PersistenceController.makeContainer()
        } catch {
            // Degrade to an in-memory store instead of crashing at launch;
            // the on-disk failure is logged to Console for diagnosis.
            NSLog("Pocket Drafts: could not open on-disk store (%@); using in-memory fallback.", error.localizedDescription)
            container = PersistenceController.inMemoryFallback()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .modelContainer(container)
                .environment(\.deletionUndoService, deletionUndoService)
                .frame(width: 380, height: 520)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
                .accessibilityLabel("Pocket Drafts")
        }
        .menuBarExtraStyle(.window)

        // The settings window (PRD: the only full window). Registering this
        // scene also provides the ⌘, "Settings…" command in the app menu.
        Settings {
            SettingsView()
        }
    }
}
