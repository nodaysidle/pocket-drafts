# Pocket Drafts User Guide

## Open Pocket Drafts

Launch the app, then select the note icon in the macOS menu bar. Pocket Drafts opens as a compact popover and does not create a normal main window.

## Create and edit notes

1. Select **New Note** or press **Command-N**.
2. Enter a title or content.
3. Optionally pin the note and add tags.
4. Select **Save** or press **Command-S**.
5. Select a note in the list to edit it. Press **Escape** to cancel editing.

Pinned notes appear before unpinned notes. Search matches note titles, content, and tags.

## Delete and undo

Open a note and select **Delete**, or use **Delete…** in its context menu. Confirm the deletion. The dashboard shows an **Undo** action for 10 seconds; using it restores the note, its tags, pin state, timestamps, and identity.

## Import and export

- Select **Import…**, then choose a UTF-8 plain-text file. Pocket Drafts creates a new note only after the selected file is read successfully.
- Open a note and select **Export…**, or use **Export…** in the note's context menu. Choose the destination in the macOS save panel.

Pocket Drafts never scans folders or accesses files automatically.

## Settings

Select the gear button in the popover or press **Command-,**. The Settings window can show relative timestamps in the note list.

## Keyboard and accessibility

- **Command-N**: new note
- **Command-S**: save note
- **Command-Delete**: request deletion while editing
- **Escape**: cancel editing or close the active action
- **Command-,**: Settings
- **Tab / Shift-Tab**: move through controls
- **Arrow keys**: navigate native list and form controls

Buttons, fields, note rows, tag-removal actions, alerts, and settings controls expose accessibility labels or identifiers for VoiceOver and keyboard users.

## Manual validation checklist

- [ ] Launching the app shows only the menu-bar item; selecting it opens the popover.
- [ ] Creating a titled note with content takes under five seconds from opening the popover.
- [ ] Quit and relaunch; the created note is still present.
- [ ] Search finds notes by title and content.
- [ ] Adding and removing tags works; tag search finds the note.
- [ ] Pinning moves a note above unpinned notes; unpinning restores date order.
- [ ] Delete requires confirmation; Undo restores the note within 10 seconds and expires afterward.
- [ ] Import opens `NSOpenPanel`; the selected UTF-8 text becomes a new note.
- [ ] Export opens `NSSavePanel`; the selected note is written to the chosen path.
- [ ] The gear button and Command-, open Settings.
- [ ] Command-N, Command-S, Command-Delete, Escape, Tab, Shift-Tab, and arrow-key navigation work.
- [ ] VoiceOver announces the search field, note controls, pin state, tag-removal actions, import/export, undo, and settings controls.
- [ ] No crash report is created during launch, create/edit/search/pin/delete/undo/import/export, quit, or relaunch.

## Troubleshooting

- **Import fails:** confirm the selected file is valid UTF-8 plain text.
- **Export fails:** choose a writable destination in the save panel.
- **No notes after a fresh install:** notes are local to this Mac and are not synced from another device.
