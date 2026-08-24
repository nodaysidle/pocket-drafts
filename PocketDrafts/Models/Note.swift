import Foundation
import SwiftData

/// A single locally-stored draft note. The model is the canonical schema;
/// PersistenceController owns the on-disk store in Application Support.
@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    @Relationship(deleteRule: .nullify, inverse: \Tag.notes)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        tags: [Tag] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.tags = tags
    }

    /// One-line preview used by the list row.
    var snippet: String {
        let singleLine = content.replacingOccurrences(of: "\n", with: " ")
        return String(singleLine.trimmingCharacters(in: .whitespaces).prefix(80))
    }
}
