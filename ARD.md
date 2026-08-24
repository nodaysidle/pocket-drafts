# ARD.md

## Architecture Summary
Pocket Drafts uses a SwiftUI menu bar app with a popover as the main interface. SwiftData provides local persistence. The app follows a clean separation of concerns: App entry, Views, Models, Services, Storage, and Tests.

## Selected Preset
- native-macos-swiftui - Native macOS App

## Required Stack
- Use Native macOS App as the architecture preset.
- Keep the app native macOS with SwiftUI app lifecycle, SwiftData persistence, and local-first privacy defaults.
- Use an Xcode project boundary with xcodebuild validation, not SwiftPM.

## System Boundaries
- Menu bar popover is the primary UI; no main window except for settings.
- All data is stored locally via SwiftData; no network access.
- File import/export only via user-selected file URLs using NSOpenPanel/NSSavePanel.
- AppKit bridge only if needed for menu bar extras or accessibility; otherwise SwiftUI only.

## Folder Structure
- PocketDrafts/App/PocketDraftsApp.swift - app entry and menu bar setup
- PocketDrafts/Views/ - SwiftUI views (RootView, DashboardView, NoteEditorView, etc.)
- PocketDrafts/Models/ - SwiftData @Model types (Note, Tag, etc.)
- PocketDrafts/Services/ - business logic (NoteService, ImportExportService, UndoManager)
- PocketDrafts/Storage/ - PersistenceController and SwiftData setup
- PocketDrafts/Assets.xcassets/ - app icon and asset catalog
- PocketDraftsTests/ - unit tests for models and services

## Rendering/Data Flow Model
- SwiftUI views observe SwiftData model context and update reactively.
- Popover content is driven by a single RootView that switches between list and editor states.
- Search and filter are performed in-memory on the fetched notes.

## Trade-offs
- Menu bar popover limits screen space; use compact layouts and keyboard shortcuts.
- SwiftData is used for persistence; for very large note collections, consider indexing but not needed for MVP.
- No cloud sync simplifies architecture but limits cross-device access.

## Architecture Rules
- Architecture rule: Use SwiftUI scenes and native macOS app lifecycle.
- Architecture rule: Use an Xcode project as the native macOS app contract.
- Architecture rule: Use SwiftData as the canonical persistent store when persistence is needed.
- Architecture rule: Keep the app local-first and privacy-first with local-only persistence by default.
- Architecture rule: No cloud sync by default.
- Architecture rule: No telemetry by default.
- Architecture rule: Use AppKit bridges only for permissions/activity monitoring when SwiftUI cannot provide the API.
- Architecture rule: Use SwiftData for persistent domain data.
- Architecture rule: Use ModelContainer/ModelContext for the local store.
- Architecture rule: Use UserDefaults only for small preferences.
- Architecture rule: Use files only for import/export or explicit document storage.
- Architecture rule: Do not enable cloud sync, external analytics, or cloud AI by default.
- Architecture rule: Use an Xcode-style native macOS project, not SwiftPM.
- Architecture rule: Model the app around SwiftUI app entry, RootView/DashboardView, SwiftData @Model types, and ModelContainer or PersistenceController setup.
- Architecture rule: Use local-only persistence rules with no cloud sync or telemetry by default.
