import XCTest
import SwiftData
@testable import PocketDrafts

@MainActor
final class NoteModelTests: XCTestCase {

    // MARK: - Helpers

    /// Fresh in-memory container per test.
    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, Tag.self, configurations: configuration)
        return ModelContext(container)
    }

    // MARK: - Defaults

    func testDefaultValues() throws {
        let context = try makeInMemoryContext()
        let before = Date()
        let note = Note()
        let other = Note()
        context.insert(note)
        context.insert(other)
        try context.save()

        XCTAssertNotEqual(note.id, other.id)
        XCTAssertEqual(note.title, "")
        XCTAssertEqual(note.content, "")
        XCTAssertFalse(note.isPinned)
        XCTAssertGreaterThanOrEqual(note.createdAt, before)
        XCTAssertLessThanOrEqual(note.createdAt, Date())
        XCTAssertGreaterThanOrEqual(note.updatedAt, note.createdAt)
    }

    // MARK: - CRUD and timestamps

    func testInsertFetchUpdateDelete() throws {
        let context = try makeInMemoryContext()
        let note = Note(title: "Draft", content: "Body")
        context.insert(note)
        try context.save()

        var fetched = try context.fetch(FetchDescriptor<Note>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].title, "Draft")
        XCTAssertEqual(fetched[0].content, "Body")

        let originalCreatedAt = note.createdAt
        note.title = "Updated"
        note.updatedAt = originalCreatedAt.addingTimeInterval(60)
        try context.save()

        fetched = try context.fetch(FetchDescriptor<Note>())
        XCTAssertEqual(fetched[0].title, "Updated")
        XCTAssertEqual(fetched[0].createdAt, originalCreatedAt)
        XCTAssertEqual(fetched[0].updatedAt, originalCreatedAt.addingTimeInterval(60))
        XCTAssertGreaterThan(fetched[0].updatedAt, fetched[0].createdAt)

        context.delete(note)
        try context.save()
        XCTAssertTrue(try context.fetch(FetchDescriptor<Note>()).isEmpty)
    }

    // MARK: - Bidirectional tag relationship

    func testBidirectionalTagRelationship() throws {
        let context = try makeInMemoryContext()
        let note = Note(title: "Alpha")
        let tag = Tag(name: "work")
        context.insert(note)
        context.insert(tag)
        note.tags.append(tag)
        try context.save()

        XCTAssertEqual(note.tags.count, 1)
        XCTAssertEqual(tag.notes.count, 1)
        XCTAssertEqual(tag.notes.first?.id, note.id)

        let secondNote = Note(title: "Beta")
        context.insert(secondNote)
        secondNote.tags.append(tag)
        try context.save()
        XCTAssertEqual(tag.notes.count, 2)

        note.tags.removeAll { $0.id == tag.id }
        try context.save()
        XCTAssertEqual(tag.notes.count, 1)
        XCTAssertEqual(tag.notes.first?.id, secondNote.id)

        // Deleting the note nullifies the relationship and the tag survives.
        context.delete(secondNote)
        try context.save()
        XCTAssertEqual(tag.notes.count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 1)
    }

    // MARK: - Tag find-or-create uniqueness

    func testTagFindOrCreateUniqueness() throws {
        let context = try makeInMemoryContext()
        let first = try Tag.findOrCreate(named: "work", in: context)
        let second = try Tag.findOrCreate(named: "work", in: context)

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 1)

        let other = try Tag.findOrCreate(named: "personal", in: context)
        XCTAssertNotEqual(first.id, other.id)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Tag>()).count, 2)
    }

    // MARK: - Disk persistence across containers

    func testDiskPersistenceAcrossContainers() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PocketDrafts-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("Test.store")
        defer { try? FileManager.default.removeItem(at: directory) }

        let noteID = UUID()
        do {
            let configuration = ModelConfiguration(url: storeURL)
            let container = try ModelContainer(for: Note.self, Tag.self, configurations: configuration)
            let context = ModelContext(container)
            let note = Note(id: noteID, title: "Persisted", content: "On disk", isPinned: true)
            let tag = Tag(name: "keep")
            note.tags.append(tag)
            context.insert(note)
            context.insert(tag)
            try context.save()
        }

        do {
            let configuration = ModelConfiguration(url: storeURL)
            let container = try ModelContainer(for: Note.self, Tag.self, configurations: configuration)
            let context = ModelContext(container)

            let notes = try context.fetch(FetchDescriptor<Note>())
            XCTAssertEqual(notes.count, 1)
            XCTAssertEqual(notes[0].id, noteID)
            XCTAssertEqual(notes[0].title, "Persisted")
            XCTAssertEqual(notes[0].content, "On disk")
            XCTAssertTrue(notes[0].isPinned)

            let tags = try context.fetch(FetchDescriptor<Tag>())
            XCTAssertEqual(tags.count, 1)
            XCTAssertEqual(tags[0].name, "keep")
            XCTAssertEqual(tags[0].notes.first?.id, noteID)
        }
    }
}
