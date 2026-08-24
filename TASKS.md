# TASKS.md

## Implementation Phases
### phase-1 - Project Foundation and Core UI
- task_id: phase-1
- objective: Set up the Xcode project, SwiftUI app entry, menu bar popover, SwiftData models, and basic note list/create functionality.
- files_to_create:
  - PocketDrafts.xcodeproj/project.pbxproj
  - PocketDrafts/PocketDraftsApp.swift
  - PocketDrafts/Views/RootView.swift
  - PocketDrafts/Views/DashboardView.swift
  - PocketDrafts/Models/Note.swift
  - PocketDrafts/Models/Tag.swift
  - PocketDrafts/Storage/PersistenceController.swift
  - PocketDrafts/Assets.xcassets/Contents.json
  - PocketDrafts/Assets.xcassets/AppIcon.appiconset/Contents.json
- files_to_modify:
  []
- acceptance_criteria:
- App launches as a menu bar app with a popover.
- User can create a new note with title and content.
- Notes are persisted in SwiftData and appear after restart.
- xcodebuild build succeeds.
- validation_cmd: xcodebuild -project PocketDrafts.xcodeproj -scheme PocketDrafts -destination 'platform=macOS' build
- task_prompt: Create the Xcode project and implement the basic menu bar app with SwiftUI, SwiftData models, and a simple note list and editor.

### phase-2 - Core Features: Search, Tagging, Pinning, Delete with Undo
- task_id: phase-2
- objective: Implement search, tagging, pinning, and delete with confirmation and undo.
- files_to_create:
  - PocketDrafts/Views/NoteEditorView.swift
  - PocketDrafts/Views/NoteListView.swift
  - PocketDrafts/Services/NoteService.swift
  - PocketDrafts/Services/UndoManager.swift
- files_to_modify:
  - PocketDrafts/Views/DashboardView.swift
  - PocketDrafts/Models/Note.swift
  - PocketDrafts/Models/Tag.swift
- acceptance_criteria:
- User can search notes by title or content.
- User can add/remove tags on a note.
- User can pin/unpin notes; pinned notes appear at top.
- Deleting a note shows confirmation and allows undo for 10 seconds.
- xcodebuild build succeeds.
- validation_cmd: xcodebuild -project PocketDrafts.xcodeproj -scheme PocketDrafts -destination 'platform=macOS' build
- task_prompt: Implement search, tagging, pinning, and delete with undo in the existing SwiftUI views and services.

### phase-3 - Import/Export, Settings, and UX Polish
- task_id: phase-3
- objective: Add plain-text import/export, a settings window, and refine the user experience with keyboard navigation and accessibility.
- files_to_create:
  - PocketDrafts/Views/SettingsView.swift
  - PocketDrafts/Services/ImportExportService.swift
- files_to_modify:
  - PocketDrafts/PocketDraftsApp.swift
  - PocketDrafts/Views/RootView.swift
  - PocketDrafts/Views/DashboardView.swift
- acceptance_criteria:
- User can import a plain-text file via NSOpenPanel; content becomes a new note.
- User can export a selected note as a plain-text file via NSSavePanel.
- Settings window is accessible from the menu bar menu.
- Keyboard navigation works (Tab, arrows, shortcuts).
- xcodebuild build succeeds.
- validation_cmd: xcodebuild -project PocketDrafts.xcodeproj -scheme PocketDrafts -destination 'platform=macOS' build
- task_prompt: Implement import/export using NSOpenPanel/NSSavePanel, add a settings window, and polish the UI for keyboard navigation and accessibility.

### phase-4 - Testing and Validation
- task_id: phase-4
- objective: Write unit tests for models and services, ensure xcodebuild test passes, and document manual validation steps.
- files_to_create:
  - PocketDraftsTests/NoteModelTests.swift
  - PocketDraftsTests/NoteServiceTests.swift
  - PocketDraftsTests/ImportExportServiceTests.swift
- files_to_modify:
  []
- acceptance_criteria:
- Unit tests cover Note model CRUD, search/filter logic, and import/export service.
- xcodebuild test passes.
- Manual validation notes are documented in README or comments.
- validation_cmd: xcodebuild test -project PocketDrafts.xcodeproj -scheme PocketDrafts -destination 'platform=macOS'
- task_prompt: Write unit tests for the Note model, NoteService, and ImportExportService. Ensure all tests pass with xcodebuild test.
