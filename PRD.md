# PRD.md

## Product Summary
Pocket Drafts is a native macOS menu bar app for quickly saving short notes while working. It provides a compact popover for creating, editing, searching, tagging, and pinning notes, with all data stored locally on the Mac.

## Target User
- Professionals who need to jot down quick notes without leaving their current workflow
- Users who prefer local-first, privacy-focused note-taking tools

## Problem
Existing note-taking apps are often heavy, require full windows, or rely on cloud sync, making quick capture disruptive and raising privacy concerns.

## Goals
- Provide instant access to notes from the menu bar
- Keep all data local and private
- Support fast note creation, search, tagging, and pinning
- Allow import/export of plain-text files with user-selected paths

## Non-Goals
- No cloud sync or accounts
- No sharing or collaboration
- No subscriptions or analytics
- No AI features
- No full-window interface except for settings

## Core Features
- Menu bar icon with popover interface
- Create, edit, delete, search, tag, and pin notes
- Local persistence with SwiftData
- Import plain-text file and export selected note as plain-text
- Delete confirmation with undo
- Keyboard navigation and accessibility support

## Success Criteria
- User can create a note in under 5 seconds from menu bar
- All notes persist across app restarts
- Import/export works with user-selected files only
- App passes xcodebuild build and test commands
