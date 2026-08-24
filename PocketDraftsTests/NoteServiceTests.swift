import XCTest
import SwiftData
@testable import PocketDrafts

@MainActor
final class NoteServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, Tag.self, configurations: configuration)
        return ModelContext(container)
    }

    @discardableResult
    private func makeNote(
        title: String,
        content: String,
        pinned: Bool = false,
        tagNames: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        in context: ModelContext
    ) throws -> Note {
        let note = Note(title: title, content: content, createdAt: createdAt, updatedAt: updatedAt, isPinned: pinned)
        note.tags = try tagNames.map { try Tag.findOrCreate(named: $0, in: context) }
        context.insert(note)
        try context.save()
        return note
    }

    private func fetchNote(id: UUID, in context: ModelContext) throws -> Note? {
        try context.fetch(FetchDescriptor<Note>(predicate: #Predicate { $0.id == id })).first
    }

    /// Mutable wall clock for expiry tests; avoids brittle sleeps.
    private final class TestClock {
        var now = Date()
    }

    // MARK: - Search

    func testSearchMatchesTitleContentAndTag() throws {
        let context = try makeContext()
        try makeNote(title: "Weekly plan", content: "ship the release", tagNames: ["work"], in: context)
        try makeNote(title: "Groceries", content: "milk and eggs", tagNames: ["home"], in: context)
        let all = try context.fetch(FetchDescriptor<Note>())
        let service = NoteService()

        XCTAssertEqual(service.filter(all, query: "weekly").count, 1)
        XCTAssertEqual(service.filter(all, query: "WEEKLY").count, 1, "search is case-insensitive")
        XCTAssertEqual(service.filter(all, query: "eggs").count, 1, "matches content")
        XCTAssertEqual(service.filter(all, query: "work").count, 1, "matches tag names")
        XCTAssertEqual(service.filter(all, query: "zzz").count, 0)
        XCTAssertEqual(service.filter(all, query: "   ").count, 2, "blank query returns everything")
    }

    // MARK: - Pinned-first ordering

    func testSortedPutsPinnedFirst() throws {
        let context = try makeContext()
        let t1 = Date(timeIntervalSince1970: 1_700_000_000)
        let t2 = t1.addingTimeInterval(60)
        let t3 = t2.addingTimeInterval(60)
        let oldPinned = try makeNote(title: "Old pinned", content: "", pinned: true, updatedAt: t1, in: context)
        let newestUnpinned = try makeNote(title: "New unpinned", content: "", updatedAt: t2, in: context)
        let newestPinned = try makeNote(title: "New pinned", content: "", pinned: true, updatedAt: t3, in: context)
        let service = NoteService()

        let sorted = service.sorted([newestUnpinned, oldPinned, newestPinned])
        XCTAssertEqual(sorted.map(\.id), [newestPinned.id, oldPinned.id, newestUnpinned.id])
    }

    // MARK: - Tags

    func testAddAndRemoveTags() throws {
        let context = try makeContext()
        let note = try makeNote(title: "Tagged", content: "", in: context)
        let service = NoteService()

        let work = try service.addTag(named: "work", to: note, in: context)
        XCTAssertTrue(note.tags.contains { $0.id == work.id })

        let again = try service.addTag(named: "work", to: note, in: context)
        XCTAssertEqual(work.id, again.id, "adding the same tag twice reuses it")
        XCTAssertEqual(note.tags.count, 1)

        let other = try makeNote(title: "Other", content: "", in: context)
        let shared = try service.addTag(named: "work", to: other, in: context)
        XCTAssertEqual(shared.id, work.id, "same tag is shared across notes")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 1)

        try service.removeTag(work, from: note, in: context)
        XCTAssertFalse(note.tags.contains { $0.id == work.id })
        XCTAssertEqual(work.notes.count, 1, "tag remains on the other note")
    }

    // MARK: - Tag case-insensitivity and dedupe

    func testFindOrCreateTagIsCaseInsensitive() throws {
        let context = try makeContext()
        let service = NoteService()
        let first = try makeNote(title: "First", content: "", in: context)
        let second = try makeNote(title: "Second", content: "", in: context)

        let work = try service.addTag(named: "Work", to: first, in: context)
        let lower = try service.addTag(named: "work", to: second, in: context)

        XCTAssertEqual(work.id, lower.id, "find-or-create must be case-insensitive")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 1)
    }

    func testCreateNoteDeduplicatesTagsCaseInsensitively() throws {
        let context = try makeContext()
        let service = NoteService()
        let note = try service.createNote(
            title: "Deduped",
            content: "",
            isPinned: false,
            tagNames: ["Work", "work", "  ", "Personal"],
            in: context
        )

        XCTAssertEqual(note.tags.count, 2, "blank and case-duplicate tag names are collapsed")
    }

    // MARK: - Delete prunes orphaned tags

    func testDeletePrunesOrphanedTagsAndUndoRestoresThem() throws {
        let context = try makeContext()
        let service = DeletionUndoService()
        let note = try makeNote(title: "Only", content: "", tagNames: ["unique"], in: context)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 1)

        service.delete(note, in: context)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 0, "orphaned tag is pruned")

        let restored = try service.undo(in: context)
        XCTAssertNotNil(restored)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 1, "undo recreates the tag")
    }

    // MARK: - Edit timestamps

    func testUpdateSetsTitleContentAndTimestamp() throws {
        let context = try makeContext()
        let note = try makeNote(title: "Before", content: "old", in: context)
        let service = NoteService()
        let fixed = Date(timeIntervalSince1970: 1_800_000_000)

        service.update(note, title: "After", content: "new", now: fixed)

        XCTAssertEqual(note.title, "After")
        XCTAssertEqual(note.content, "new")
        XCTAssertEqual(note.updatedAt, fixed)
        XCTAssertNotEqual(note.createdAt, fixed)
    }

    // MARK: - Delete + undo restores the same note

    func testDeleteAndUndoRestoresSameNote() throws {
        let context = try makeContext()
        let clock = TestClock()
        let service = DeletionUndoService(undoWindow: 10, now: { clock.now })
        let note = try makeNote(title: "Restore me", content: "content", pinned: true, tagNames: ["work", "home"], in: context)
        let noteID = note.id

        service.delete(note, in: context)
        XCTAssertNil(try fetchNote(id: noteID, in: context))
        XCTAssertTrue(service.canUndo)

        let restored = try service.undo(in: context)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, noteID, "undo reinserts the same UUID")
        XCTAssertEqual(restored?.title, "Restore me")
        XCTAssertEqual(restored?.content, "content")
        XCTAssertEqual(restored?.isPinned, true)
        XCTAssertEqual(Set(restored?.tags.map(\.name) ?? []), Set(["work", "home"]))
        XCTAssertEqual(try fetchNote(id: noteID, in: context)?.id, noteID)
        XCTAssertFalse(service.canUndo, "undo consumes the snapshot")
    }

    // MARK: - Expiry

    func testUndoExpiresAfterWindow() throws {
        let context = try makeContext()
        let clock = TestClock()
        let service = DeletionUndoService(undoWindow: 10, now: { clock.now })
        let note = try makeNote(title: "Expires", content: "", in: context)
        let noteID = note.id

        service.delete(note, in: context)
        XCTAssertTrue(service.canUndo)

        clock.now = clock.now.addingTimeInterval(11)
        XCTAssertFalse(service.canUndo)
        XCTAssertNil(try service.undo(in: context), "expired deletion cannot be undone")
        XCTAssertNil(try fetchNote(id: noteID, in: context), "note stays deleted")
    }

    func testWallClockExpiryWithBoundedDelay() async throws {
        let context = try makeContext()
        let service = DeletionUndoService(undoWindow: 0.05)
        let note = try makeNote(title: "Expires fast", content: "", in: context)
        let noteID = note.id

        service.delete(note, in: context)
        XCTAssertTrue(service.canUndo)

        try await Task.sleep(for: .milliseconds(200))
        XCTAssertFalse(service.canUndo)
        XCTAssertNil(try service.undo(in: context))
        XCTAssertNil(try fetchNote(id: noteID, in: context))
    }

    // MARK: - Newer deletion supersedes older

    func testNewerDeletionSupersedesOlder() throws {
        let context = try makeContext()
        let clock = TestClock()
        let service = DeletionUndoService(undoWindow: 10, now: { clock.now })
        let first = try makeNote(title: "First", content: "", in: context)
        let second = try makeNote(title: "Second", content: "", in: context)

        service.delete(first, in: context)
        service.delete(second, in: context)
        XCTAssertTrue(service.canUndo)

        let restored = try service.undo(in: context)
        XCTAssertEqual(restored?.id, second.id, "undo restores the most recent deletion")
        XCTAssertNil(try fetchNote(id: first.id, in: context), "the earlier deletion is gone for good")
        XCTAssertFalse(service.canUndo)
    }
}
