# Pocket Drafts

Pocket Drafts is a native macOS menu-bar app for fast, private note capture. Notes and tags are stored locally with SwiftData. There are no accounts, analytics, cloud sync, AI features, or network calls.

## Requirements

- macOS 15 or later
- Xcode 26 or later
- XcodeGen 2.45 or later

## Generate and build

```sh
export DEVELOPER_DIR=/Volumes/omarchyuser/Applications/Xcode.app/Contents/Developer
xcodegen generate --spec project.yml
xcodebuild -project PocketDrafts.xcodeproj -scheme PocketDrafts -destination 'platform=macOS' build
```

## Test

```sh
export DEVELOPER_DIR=/Volumes/omarchyuser/Applications/Xcode.app/Contents/Developer
xcodebuild test -project PocketDrafts.xcodeproj -scheme PocketDrafts -destination 'platform=macOS'
```

## Release build

```sh
export DEVELOPER_DIR=/Volumes/omarchyuser/Applications/Xcode.app/Contents/Developer
xcodebuild -project PocketDrafts.xcodeproj -scheme PocketDrafts -configuration Release -destination 'platform=macOS' -derivedDataPath DerivedData build
```

The local release app is produced at `DerivedData/Build/Products/Release/PocketDrafts.app`.

## Privacy and storage

- SwiftData stores notes and tags locally in the app's Application Support directory.
- Import reads only the plain-text file selected in `NSOpenPanel`.
- Export writes only to the path selected in `NSSavePanel`.
- Pocket Drafts contains no network, telemetry, analytics, cloud, or AI integration.

See [USERGUIDE.md](USERGUIDE.md) for workflows, shortcuts, accessibility notes, and the manual validation checklist.
