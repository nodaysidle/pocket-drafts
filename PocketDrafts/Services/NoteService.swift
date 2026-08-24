import Foundation
import SwiftData

/// In-memory business logic for notes: search, pinned-first ordering,
/// tag management and edits. Views stay thin; all mutations flow through here.
struct NoteService {

    // MARK: - Search

    func matches(_ note: Note, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let needle = trimmed.localizedLowercase
        if note.title.localizedLowercase.contains(needle) { return true }
        if note.content.localizedLowercase.contains(needle) { return true }
        return note.tags.contains { $0.name.localizedLowercase.contains(needle) }
    }

    func filter(_ notes: [Note], query: String) -> [Note] {
        notes.filter { matches($0, query: query) }
    }

    // MARK: - Ordering

    /// Pinned notes first; within each group, most recently updated first.
    func sorted(_ notes: [Note]) -> [Note] {
        notes.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            if a.updatedAt != b.updatedAt { return a.updatedAt > b.updatedAt }
            return a.createdAt > b.createdAt
        }
    }

    // MARK: - Tags

    func findOrCreateTag(named name: String, in context: ModelContext) throws -> Tag {
        try Tag.findOrCreate(named: name, in: context)
    }

    @discardableResult
    func addTag(named name: String, to note: Note, in context: ModelContext) throws -> Tag {
        let tag = try findOrCreateTag(named: name, in: context)
        if !note.tags.contains(where: { $0.id == tag.id }) {
            note.tags.append(tag)
        }
        try context.save()
        return tag
    }

    func removeTag(_ tag: Tag, from note: Note, in context: ModelContext) throws {
        note.tags.removeAll { $0.id == tag.id }
        try context.save()
    }

    /// Replaces the note's tag set with deduplicated, trimmed tags.
    func applyTags(_ names: [String], to note: Note, in context: ModelContext) throws {
        var seen = Set<String>()
        var result: [Tag] = []
        for raw in names {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = name.localizedLowercase
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(try findOrCreateTag(named: name, in: context))
        }
        note.tags = result
        try context.save()
    }

    // MARK: - Edits

    /// Updates title/content and stamps `updatedAt` (injectable for tests).
    func update(_ note: Note, title: String, content: String, now: Date = .now) {
        note.title = title
        note.content = content
        note.updatedAt = now
    }

    func setPinned(_ pinned: Bool, on note: Note) {
        note.isPinned = pinned
    }

    // MARK: - Create

    @discardableResult
    func createNote(
        title: String,
        content: String,
        isPinned: Bool,
        tagNames: [String],
        in context: ModelContext,
        now: Date = .now
    ) throws -> Note {
        let note = Note(title: title, content: content, createdAt: now, updatedAt: now, isPinned: isPinned)
        var seen = Set<String>()
        var tags: [Tag] = []
        for raw in tagNames {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = name.localizedLowercase
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            tags.append(try findOrCreateTag(named: name, in: context))
        }
        note.tags = tags
        context.insert(note)
        try context.save()
        return note
    }
}
