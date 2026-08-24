import Foundation
import SwiftData

/// A user-defined tag attached to notes through a nullify relationship.
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var notes: [Note]

    init(id: UUID = UUID(), name: String, notes: [Note] = []) {
        self.id = id
        self.name = name
        self.notes = notes
    }

    /// Returns the existing tag matching the trimmed name (case-insensitive),
    /// or creates it. Callers always reuse the first tag whose name compares
    /// equal, so "Work" and "work" can never become two tags.
    static func findOrCreate(named name: String, in context: ModelContext) throws -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = try context.fetch(FetchDescriptor<Tag>())
        if let existing = all.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let tag = Tag(name: trimmed)
        context.insert(tag)
        try context.save()
        return tag
    }
}
