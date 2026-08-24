import SwiftUI
import SwiftData

/// Main list view: search field, note list, undo banner and the toolbar.
/// A single @Query feeds in-memory filtering; nothing heavy runs in body.
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.deletionUndoService) private var deletionUndoService

    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var searchText = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    let onCreate: () -> Void
    let onEdit: (Note) -> Void

    private let service = NoteService()

    private var visibleNotes: [Note] {
        service.sorted(service.filter(notes, query: searchText))
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(10)
            Divider()
            NoteListView(
                notes: visibleNotes,
                onSelect: onEdit,
                onDelete: { note in deletionUndoService.delete(note, in: context) },
                onExport: exportNote
            )
            Divider()
            undoBanner
            HStack(spacing: 12) {
                Button {
                    onCreate()
                } label: {
                    Label("New Note", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("Create a new note (⌘N)")
                .accessibilityIdentifier("newNoteButton")
                Button {
                    importNote()
                } label: {
                    Label("Import…", systemImage: "square.and.arrow.down")
                }
                .help("Import a plain-text file as a new note")
                .accessibilityIdentifier("importButton")
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings (⌘,)")
                .accessibilityIdentifier("settingsButton")
            }
            .padding(8)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Import/Export

    /// Imports the user-selected plain-text file as a new note. The file is
    /// only ever read after NSOpenPanel returns a URL chosen by the user.
    private func importNote() {
        guard let url = FilePanelPresenter.pickImportURL() else { return }
        do {
            try ImportExportService.importNote(from: url, into: context)
            // @Query refreshes the list automatically; the new note appears.
            present(
                title: "Note Imported",
                message: "“\(url.deletingPathExtension().lastPathComponent)” was added to your notes."
            )
        } catch {
            present(title: "Import Failed", error: error)
        }
    }

    /// Exports the given note through NSSavePanel at a user-chosen path.
    private func exportNote(_ note: Note) {
        let defaultName = ImportExportService.suggestedExportFilename(for: note)
        guard let url = FilePanelPresenter.pickExportURL(defaultName: defaultName) else { return }
        do {
            try ImportExportService.exportNote(note, to: url)
        } catch {
            present(title: "Export Failed", error: error)
        }
    }

    private func present(title: String, error: Error) {
        present(title: title, message: error.localizedDescription)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search notes", text: $searchText)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("searchField")
                .accessibilityLabel("Search notes by title, content or tag")
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear search")
                .accessibilityIdentifier("clearSearchButton")
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
    }

    @ViewBuilder
    private var undoBanner: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            if deletionUndoService.canUndo {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundStyle(.secondary)
                    Text(deletionUndoService.timeRemaining.map { "Note deleted · \(Int($0.rounded()))s" } ?? "Note deleted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Undo") {
                        do {
                            _ = try deletionUndoService.undo(in: context)
                        } catch {
                            present(title: "Undo Failed", error: error)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityIdentifier("undoButton")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.18))
                .accessibilityIdentifier("undoBanner")
            }
        }
    }
}
