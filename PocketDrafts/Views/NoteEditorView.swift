import SwiftUI
import SwiftData

/// Create/edit form for a single note: title, content, tags and pin state.
/// `note == nil` means create mode; otherwise the passed note is edited.
/// An edited note can be exported from the header via NSSavePanel.
struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.deletionUndoService) private var deletionUndoService

    let note: Note?
    let onClose: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    @State private var tagNames: [String]
    @State private var newTagName = ""
    @State private var confirmingDelete = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    private let service = NoteService()

    init(note: Note?, onClose: @escaping () -> Void) {
        self.note = note
        self.onClose = onClose
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _tagNames = State(initialValue: note?.tags.map(\.name) ?? [])
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                Form {
                    TextField("Title", text: $title, prompt: Text("Note title"))
                        .accessibilityIdentifier("titleField")
                    TextEditor(text: $content)
                        .font(.body)
                        .frame(minHeight: 140)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Write your note…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityIdentifier("contentEditor")
                    Toggle("Pinned", isOn: $isPinned)
                        .accessibilityIdentifier("pinToggle")
                    tagsSection
                }
                .formStyle(.grouped)
            }
        }
        .confirmationDialog(
            "Delete this note?",
            isPresented: $confirmingDelete
        ) {
            Button("Delete", role: .destructive) { deleteNote() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The note will be deleted. You can undo for 10 seconds.")
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(note == nil ? "New Note" : "Edit Note")
                .font(.headline)
            Spacer()
            if note != nil {
                Button {
                    exportNote()
                } label: {
                    Label("Export…", systemImage: "square.and.arrow.up")
                }
                .help("Export this note as a plain-text file")
                .accessibilityIdentifier("exportButton")
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .help("Delete this note (⌘⌫)")
                .accessibilityIdentifier("deleteButton")
            }
            Button("Cancel") {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
            .accessibilityIdentifier("cancelButton")
            Button("Save") {
                save()
            }
            .keyboardShortcut(.defaultAction)
            .keyboardShortcut("s", modifiers: .command)
            .disabled(trimmedTitle.isEmpty && trimmedContent.isEmpty)
            .accessibilityIdentifier("saveButton")
        }
        .padding(10)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")
                .font(.subheadline)
            HStack {
                TextField("Add tag", text: $newTagName)
                    .onSubmit(addTag)
                    .accessibilityIdentifier("tagField")
                Button("Add", action: addTag)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("addTagButton")
            }
            if !tagNames.isEmpty {
                FlowChips(tagNames: tagNames) { name in
                    tagNames.removeAll { $0 == name }
                }
                .accessibilityIdentifier("tagChips")
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if !tagNames.contains(where: { $0.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            tagNames.append(name)
        }
        newTagName = ""
    }

    private func save() {
        do {
            if let note {
                service.update(note, title: trimmedTitle, content: content)
                note.isPinned = isPinned
                try service.applyTags(tagNames, to: note, in: context)
            } else {
                try service.createNote(
                    title: trimmedTitle,
                    content: content,
                    isPinned: isPinned,
                    tagNames: tagNames,
                    in: context
                )
            }
            onClose()
        } catch {
            alertTitle = "Save Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func exportNote() {
        guard let note else { return }
        let defaultName = ImportExportService.suggestedExportFilename(for: note)
        guard let url = FilePanelPresenter.pickExportURL(defaultName: defaultName) else { return }
        do {
            try ImportExportService.exportNote(note, to: url)
        } catch {
            alertTitle = "Export Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func deleteNote() {
        if let note {
            deletionUndoService.delete(note, in: context)
        }
        onClose()
    }
}

/// Minimal wrapping layout for tag chips.
private struct FlowChips: View {
    let tagNames: [String]
    let onRemove: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tagNames, id: \.self) { name in
                HStack(spacing: 3) {
                    Text(name)
                        .lineLimit(1)
                    Button {
                        onRemove(name)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove tag \"\(name)\"")
                    .accessibilityLabel("Remove tag \(name)")
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(.quaternary))
            }
        }
    }
}

/// A simple left-to-right wrapping layout.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
