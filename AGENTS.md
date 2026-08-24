# AGENTS.md

## Read Order
- PRD.md
- ARD.md
- TRD.md
- TASKS.md
- AGENTS.md

## Hard Stack Contract
- Preset id: native-macos-swiftui
- Preset label: Native macOS App
- Swift
- SwiftUI 6
- SwiftData when persistence is needed
- native macOS app architecture
- Xcode-style project
- xcodebuild validation
- local-first/privacy-first design
- AppKit bridge only when SwiftUI cannot handle native macOS APIs
- local-first by default
- SwiftData
- native macOS
- local-first

## Must Use
- Swift
- SwiftUI 6
- SwiftData when persistence is needed
- Xcode-style native macOS project
- ModelContainer or PersistenceController for local persistence
- AppKit bridge only where SwiftUI cannot access required native macOS APIs

## Must Not Use
- React
- Electron
- Tauri
- WebView shell
- Node backend
- browser-first architecture
- Package.swift
- swift build

## Architecture Rules
- Agent must enforce: Use SwiftUI scenes and native macOS app lifecycle.
- Agent must enforce: Use an Xcode project as the native macOS app contract.
- Agent must enforce: Use SwiftData as the canonical persistent store when persistence is needed.
- Agent must enforce: Keep the app local-first and privacy-first with local-only persistence by default.
- Agent must enforce: No cloud sync by default.
- Agent must enforce: No telemetry by default.
- Agent must enforce: Use AppKit bridges only for permissions/activity monitoring when SwiftUI cannot provide the API.
- Agent must enforce: Use SwiftData for persistent domain data.
- Agent must enforce: Use ModelContainer/ModelContext for the local store.
- Agent must enforce: Use UserDefaults only for small preferences.
- Agent must enforce: Use files only for import/export or explicit document storage.
- Agent must enforce: Do not enable cloud sync, external analytics, or cloud AI by default.
- Agent must enforce: Use an Xcode-style native macOS project, not SwiftPM.
- Agent must enforce: Model the app around SwiftUI app entry, RootView/DashboardView, SwiftData @Model types, and ModelContainer or PersistenceController setup.
- Agent must enforce: Use local-only persistence rules with no cloud sync or telemetry by default.

## File Rules
- <AppName>.xcodeproj/project.pbxproj
- <AppName>/<AppName>App.swift
- <AppName>/Views/RootView.swift
- <AppName>/Views/DashboardView.swift
- <AppName>/Models/*.swift
- <AppName>/Storage/PersistenceController.swift
- <AppName>/Assets.xcassets/Contents.json
- <AppName>/Assets.xcassets/AppIcon.appiconset/Contents.json
- <AppName>Tests/*.swift
- Use a real Xcode app target with <AppName>.xcodeproj/project.pbxproj.
- Separate App, Models, Views, Services, Storage, Assets, and Tests.
- Wire Info.plist and entitlements only when the app explicitly needs permissions.
- Include Assets.xcassets and AppIcon.appiconset when icon acceptance is required.

## Task Execution Rules
- Implement tasks in TASKS.md phase order.
- Start with Phase 1 and create the Xcode project foundation before feature expansion.
- Keep generated application source outside this documentation packet until a downstream build task starts.
- Do not substitute the selected preset or add unrequested cloud services.

## Validation Rules
- Run the validation command listed on each task before marking that task complete.
- Use xcodebuild as the packet-level acceptance baseline for build validation.
- Use xcodebuild test when test files exist.
- Treat missing Xcode project files, SwiftData models, ModelContainer/PersistenceController setup, or AppIcon assets as task failures.

## Stop Conditions
- Stop if a task asks for a technology listed under Must Not Use.
- Stop if Phase 1 cannot produce the named Xcode project foundation files.
- Stop if validation uses a non-Xcode build command for the native macOS app.
- Stop if a validation command fails and the failure is not documented with a concrete fix path.
