import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

/// Plain-text import/export for notes.
///
/// Documented file format (UTF-8 only):
///
///     Pocket Drafts Note
///
///     Title: <title>
///
///     <content>
///
/// Files that do not start with the documented header are imported
/// wholesale: the title is derived from the filename and the entire
/// file becomes the content. Import never touches the store until the
/// file has been read and decoded successfully.
enum ImportExportService {

    nonisolated static let headerLine = "Pocket Drafts Note"
    nonisolated static let titlePrefix = "Title: "

    /// Result of a pure file read.
    struct ImportedText: Sendable {
        let title: String
        let content: String
    }

    enum ImportExportError: LocalizedError {
        case notUTF8
        case writeFailed(String)

        var errorDescription: String? {
            switch self {
            case .notUTF8:
                return "The file is not valid UTF-8 plain text."
            case .writeFailed(let detail):
                return "The file could not be written: \(detail)"
            }
        }
    }

    // MARK: - Pure URL I/O (nonisolated so it is callable without a store)

    nonisolated static func writePlainText(title: String, content: String, to url: URL) throws {
        let sanitizedTitle = title
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let text = "\(headerLine)\n\n\(titlePrefix)\(sanitizedTitle)\n\n\(content)\n"
        guard let data = text.data(using: .utf8) else {
            throw ImportExportError.notUTF8
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ImportExportError.writeFailed(error.localizedDescription)
        }
    }

    nonisolated static func readPlainText(from url: URL) throws -> ImportedText {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw error
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportExportError.notUTF8
        }
        var title = url.deletingPathExtension().lastPathComponent
        var content = text
        let lines = text.components(separatedBy: "\n")
        if lines.first == headerLine, lines.count >= 3, lines[2].hasPrefix(titlePrefix) {
            title = String(lines[2].dropFirst(titlePrefix.count))
            if lines.count > 3, lines[3].isEmpty {
                content = lines.dropFirst(4).joined(separator: "\n")
                if content.hasSuffix("\n") {
                    content.removeLast()
                }
            }
        }
        return ImportedText(title: title, content: content)
    }

    // MARK: - Note-level operations

    /// Exports the note as documented UTF-8 plain text.
    static func exportNote(_ note: Note, to url: URL) throws {
        try writePlainText(title: note.title, content: note.content, to: url)
    }

    /// Reads the file first; only a successful read creates the note.
    @discardableResult
    static func importNote(from url: URL, into context: ModelContext) throws -> Note {
        let imported = try readPlainText(from: url)
        let note = Note(title: imported.title, content: imported.content)
        context.insert(note)
        try context.save()
        return note
    }

    /// Safe filename (".txt") suggested for the export panel.
    static func suggestedExportFilename(for note: Note) -> String {
        let trimmedTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle
        let forbidden = CharacterSet(charactersIn: "/:?*<>|\"")
        let sanitized = base
            .components(separatedBy: forbidden)
            .joined(separator: "-")
            .replacingOccurrences(of: "\r", with: "-")
            .replacingOccurrences(of: "\n", with: "-")
            .replacingOccurrences(of: "\t", with: "-")
            .replacingOccurrences(of: "\0", with: "-")
        return "\(sanitized).txt"
    }
}

/// User-selected-file presenters. Only these two entry points open file
/// panels; nothing else touches the filesystem without user selection.
enum FilePanelPresenter {

    /// NSOpenPanel for picking one plain-text file to import.
    static func pickImportURL() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Import Note"
        panel.prompt = "Import"
        panel.allowedContentTypes = [.plainText, .text]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }

    /// NSSavePanel for choosing where to export the note.
    static func pickExportURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Export Note"
        panel.prompt = "Export"
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        NSApp.activate(ignoringOtherApps: true)
        return panel.runModal() == .OK ? panel.url : nil
    }
}
