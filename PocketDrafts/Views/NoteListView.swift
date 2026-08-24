import SwiftUI
import SwiftData

/// The note list: stable row IDs, title/snippet/tag chips, pin affordance,
/// context menu (pin, export, delete) and keyboard navigation via List.
struct NoteListView: View {
    let notes: [Note]
    let onSelect: (Note) -> Void
    let onDelete: (Note) -> Void
    var onExport: (Note) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @AppStorage("showTimestamps") private var showTimestamps = false
    @State private var noteToDelete: Note?
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false

    private let service = NoteService()

    private func togglePin(_ note: Note) {
        do {
            service.setPinned(!note.isPinned, on: note)
            try context.save()
        } catch {
            errorTitle = "Couldn't Update Note"
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    var body: some View {
        List {
            if notes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Press ⌘N to create a note.")
                )
                .accessibilityIdentifier("emptyState")
            }
            ForEach(notes, id: \.id) { note in
                HStack(alignment: .top, spacing: 8) {
                    Button {
                        togglePin(note)
                    } label: {
                        Image(systemName: note.isPinned ? "pin.fill" : "pin")
                            .foregroundStyle(note.isPinned ? .orange : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(note.isPinned ? "Unpin note" : "Pin note")
                    .accessibilityLabel(note.isPinned ? "Unpin note" : "Pin note")
                    .accessibilityIdentifier("pinButton-\(note.id.uuidString)")

                    Button {
                        onSelect(note)
                    } label: {
                        NoteRowContent(note: note, showTimestamp: showTimestamps)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open note \(note.title.isEmpty ? "Untitled" : note.title)")
                }
                .contextMenu {
                    Button {
                        togglePin(note)
                    } label: {
                        Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                    }
                    Button {
                        onExport(note)
                    } label: {
                        Label("Export…", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        noteToDelete = note
                    } label: {
                        Label("Delete…", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.inset)
        .confirmationDialog(
            "Delete this note?",
            isPresented: Binding(
                get: { noteToDelete != nil },
                set: { if !$0 { noteToDelete = nil } }
            ),
            presenting: noteToDelete
        ) { note in
            Button("Delete", role: .destructive) {
                onDelete(note)
                noteToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
            }
        } message: { note in
            Text("\"\(note.title.isEmpty ? "Untitled" : note.title)\" will be deleted. You can undo for 10 seconds.")
        }
        .alert(errorTitle, isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .accessibilityIdentifier("noteList")
    }
}

/// Combined row: title, optional timestamp, snippet and tag chips.
private struct NoteRowContent: View {
    let note: Note
    let showTimestamp: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                if showTimestamp {
                    Spacer()
                    Text(note.updatedAt, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if !note.snippet.isEmpty {
                Text(note.snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if !note.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(note.tags.sorted { $0.name < $1.name }.prefix(3), id: \.id) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.quaternary))
                    }
                    if note.tags.count > 3 {
                        Text("+\(note.tags.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}
