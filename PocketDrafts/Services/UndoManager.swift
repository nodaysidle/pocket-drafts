import Foundation
import SwiftData
import SwiftUI

/// Tracks the most recent deletion so it can be undone within a short
/// window (10 seconds by default). The wall clock is authoritative:
/// once the window has passed, the deletion becomes permanent. A new
/// deletion always supersedes the pending one.
///
/// The type is named `DeletionUndoService` to avoid colliding with
/// Foundation's `UndoManager`. It lives in the app struct so it survives
/// popover close/reopen.
final class DeletionUndoService {

    /// Everything needed to reconstruct a deleted note with the same identity.
    struct Snapshot {
        let noteID: UUID
        let title: String
        let content: String
        let isPinned: Bool
        let createdAt: Date
        let updatedAt: Date
        let tagNames: [String]
        let deletedAt: Date
    }

    private let undoWindow: TimeInterval
    private let now: () -> Date
    private(set) var pendingDeletion: Snapshot?

    /// - Parameters:
    ///   - undoWindow: how long a deletion stays undoable (seconds).
    ///   - now: injectable clock for tests; defaults to the wall clock.
    init(undoWindow: TimeInterval = 10, now: @escaping () -> Date = { Date() }) {
        self.undoWindow = undoWindow
        self.now = now
    }

    /// True while a deletion can still be undone.
    var canUndo: Bool {
        guard let pendingDeletion else { return false }
        return now().timeIntervalSince(pendingDeletion.deletedAt) <= undoWindow
    }

    /// Seconds remaining in the undo window, or nil when nothing is pending.
    var timeRemaining: TimeInterval? {
        guard let pendingDeletion, canUndo else { return nil }
        return max(0, undoWindow - now().timeIntervalSince(pendingDeletion.deletedAt))
    }

    /// Snapshots the note, deletes it and persists the deletion.
    /// Always supersedes any pending deletion.
    func delete(_ note: Note, in context: ModelContext) {
        let snapshot = Snapshot(
            noteID: note.id,
            title: note.title,
            content: note.content,
            isPinned: note.isPinned,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            tagNames: note.tags.map(\.name),
            deletedAt: now()
        )
        context.delete(note)
        do {
            try context.save()
        } catch {
            context.rollback()
            pendingDeletion = nil
            return
        }
        pruneOrphanedTags(named: snapshot.tagNames, in: context)
        pendingDeletion = snapshot
    }

    /// Best-effort cleanup so tags with no remaining notes do not accumulate.
    /// A failure here only leaves the tags in place; it never un-deletes.
    private func pruneOrphanedTags(named names: [String], in context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<Tag>()) else { return }
        for tag in all where tag.notes.isEmpty
            && names.contains(where: { $0.localizedCaseInsensitiveCompare(tag.name) == .orderedSame }) {
            context.delete(tag)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    /// Reinserts the deleted note with its original UUID, content, pin state
    /// and tags. Returns nil when nothing is pending or the window expired.
    @discardableResult
    func undo(in context: ModelContext) throws -> Note? {
        guard let snapshot = pendingDeletion else { return nil }
        guard canUndo else {
            pendingDeletion = nil
            return nil
        }
        let note = Note(
            id: snapshot.noteID,
            title: snapshot.title,
            content: snapshot.content,
            createdAt: snapshot.createdAt,
            updatedAt: snapshot.updatedAt,
            isPinned: snapshot.isPinned
        )
        var tags: [Tag] = []
        for name in snapshot.tagNames {
            tags.append(try Tag.findOrCreate(named: name, in: context))
        }
        note.tags = tags
        context.insert(note)
        do {
            try context.save()
        } catch {
            context.rollback()
            return nil
        }
        pendingDeletion = nil
        return note
    }
}

extension EnvironmentValues {
    /// The app-owned undo service; injected from `PocketDraftsApp` so it
    /// stays alive across popover close/reopen.
    @Entry var deletionUndoService: DeletionUndoService = DeletionUndoService()
}
