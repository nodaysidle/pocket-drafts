import XCTest
import SwiftData
@testable import PocketDrafts

@MainActor
final class ImportExportServiceTests: XCTestCase {

    // MARK: - Helpers

    /// In-memory store whose container is strongly held for the whole test,
    /// so a released container can never leave the context dangling.
    private struct StoreFixture {
        let container: ModelContainer
        let context: ModelContext
    }

    private func makeStore() throws -> StoreFixture {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, Tag.self, configurations: configuration)
        return StoreFixture(container: container, context: ModelContext(container))
    }

    private func tempFile(name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PocketDrafts-\(UUID().uuidString)-\(name)")
    }

    private func write(_ text: String, to url: URL) throws {
        try text.data(using: .utf8)!.write(to: url)
    }

    // MARK: - UTF-8 export/import roundtrip

    /// The single store-backed import test: importNote must create a second
    /// note in the store. The container is held strongly for the whole test.
    func testExportImportRoundtrip() throws {
        let store = try makeStore()
        let context = store.context
        let note = Note(title: "Café ☕ Notes", content: "line one\nline two")
        context.insert(note)
        try context.save()

        let url = tempFile(name: "roundtrip.txt")
        defer { try? FileManager.default.removeItem(at: url) }

        try ImportExportService.exportNote(note, to: url)

        // The exported file must be valid UTF-8 plain text.
        let raw = try Data(contentsOf: url)
        XCTAssertNotNil(String(data: raw, encoding: .utf8))

        let imported = try ImportExportService.importNote(from: url, into: context)
        XCTAssertEqual(imported.title, "Café ☕ Notes")
        XCTAssertEqual(imported.content, "line one\nline two")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Note>()).count, 2, "import creates a new note")
    }

    // MARK: - Title derived from filename

    /// Exercises title derivation through the pure `readPlainText(from:)`
    /// path, so this test needs no SwiftData container at all. The
    /// store-backed import path is covered by the roundtrip test above.
    func testImportDerivesTitleFromFilename() throws {
        // Unique directory (avoids collisions) with a clean basename so the
        // derived title is exactly the filename without its extension.
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PocketDrafts-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("My Groceries.txt")
        try write("Buy milk and eggs", to: url)

        let imported = try ImportExportService.readPlainText(from: url)
        XCTAssertEqual(imported.title, "My Groceries")
        XCTAssertEqual(imported.content, "Buy milk and eggs")
    }

    // MARK: - Missing file throws and leaves the store untouched

    func testMissingFileThrowsAndLeavesStoreUntouched() throws {
        let store = try makeStore()
        let context = store.context
        let existing = Note(title: "Keep me", content: "safe")
        context.insert(existing)
        try context.save()
        let before = try context.fetch(FetchDescriptor<Note>()).count

        let missing = tempFile(name: "does-not-exist.txt")
        // The pure read fails before any store interaction…
        XCTAssertThrowsError(try ImportExportService.readPlainText(from: missing))
        // …and the note-level entry point therefore never inserts anything.
        XCTAssertThrowsError(try ImportExportService.importNote(from: missing, into: context))

        XCTAssertEqual(try context.fetch(FetchDescriptor<Note>()).count, before, "store untouched after failed import")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Note>()).first?.title, "Keep me")
    }

    // MARK: - Documented plain-text format

    func testExportWritesDocumentedPlainTextFormat() throws {
        let store = try makeStore()
        let context = store.context
        let note = Note(title: "Format check", content: "body text")
        context.insert(note)
        try context.save()

        let url = tempFile(name: "format.txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try ImportExportService.exportNote(note, to: url)

        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("Pocket Drafts Note"), "exported file carries the documented header")
        XCTAssertTrue(text.contains("Title: Format check"), "exported file carries the title")
        XCTAssertTrue(text.contains("body text"), "exported file carries the content")
    }

    // MARK: - Export filename sanitization

    func testSuggestedExportFilenameSanitizesSpecialCharacters() {
        let note = Note(title: "Q: A/B? * <x> | \"q\"", content: "")
        XCTAssertEqual(
            ImportExportService.suggestedExportFilename(for: note),
            "Q- A-B- - -x- - -q-.txt"
        )
    }

    func testSuggestedExportFilenameFallsBackToUntitled() {
        let note = Note(title: "   ", content: "")
        XCTAssertEqual(ImportExportService.suggestedExportFilename(for: note), "Untitled.txt")
    }
}
