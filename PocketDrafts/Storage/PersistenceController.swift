import Foundation
import SwiftData

/// Owns the SwiftData stack. The local store lives in Application Support
/// and is the single source of truth for all notes and tags. No cloud sync.
enum PersistenceController {
    /// Creates the container backed by the on-disk store in Application Support.
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([Note.self, Tag.self])
        let configuration = ModelConfiguration(
            "PocketDrafts",
            schema: schema,
            url: defaultStoreURL(),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Last-resort store used only when the on-disk store cannot be opened.
    /// Keeps the app usable (notes are ephemeral) and surfaces the failure
    /// in Console instead of crashing at launch.
    static func inMemoryFallback() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: Note.self, Tag.self, configurations: configuration)
        } catch {
            fatalError("Unable to create in-memory fallback container: \(error)")
        }
    }

    /// The local store URL, inside Application Support.
    static func defaultStoreURL() -> URL {
        let directory = URL.applicationSupportDirectory
            .appending(path: "PocketDrafts", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "PocketDrafts.store")
    }
}
