# TRD.md

## Technical Summary
The technical plan maps the native macOS SwiftUI 6 app into Xcode project files, SwiftData models, local persistence, native services, permissions, and xcodebuild validation.

## Routes / Interfaces
- Menu bar popover: RootView -> DashboardView (list) -> NoteEditorView (detail)
- Settings window: SettingsView (opened via menu command)
- Import/Export: handled by ImportExportService using NSOpenPanel/NSSavePanel

## Data Models
- Note: @Model class with attributes: id (UUID), title (String), content (String), createdAt (Date), updatedAt (Date), isPinned (Bool), tags (Array of Tag)
- Tag: @Model class with attributes: id (UUID), name (String), notes (Array of Note)

## State Management
- Use @State for transient UI state (search text, selected note, etc.)
- Use @Query for fetching notes from SwiftData.
- Use @Environment(\.modelContext) for CRUD operations.
- Undo manager tracks deletions for undo within a short period (e.g., 10 seconds).

## Persistence
- SwiftData is the source of truth for all notes and tags.
- UserDefaults stores only small preferences (e.g., last used tag, window size).
- Files are used only for import/export; no automatic file access.
- No cloud sync or telemetry.

## Validation Commands
- xcodebuild -project <AppName>.xcodeproj -scheme <AppName> -destination 'platform=macOS' build
- xcodebuild test -project <AppName>.xcodeproj -scheme <AppName> -destination 'platform=macOS' when tests exist

## Implementation Constraints
- All Swift code must compile with xcodebuild.
- Tests must pass with xcodebuild test.
- App must not access files without user selection.
- App must not make network calls.
