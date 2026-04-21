---
id: BDR-0014
title: Import by drag-and-drop onto the popover; copy the folder into the managed packs directory
status: accepted
date: 2026-04-21
summary: The only import mechanism is dragging a pack folder onto the menu-bar popover's drop target. The drop copies the folder into `~/Library/Application Support/Thockspace/packs/`. The source is not tracked afterwards.
---

**Feature**: sounds/features/pack-import.feature
**Rule**: Packs are imported by dragging a folder onto the popover drop target; Import copies the folder into the managed packs directory

## Context

F3 needs a way for the user to add packs without a new app release. The mechanism shapes the user's mental model — is the app a passive viewer of a directory they manage, or an active owner of installed packs?

## Behaviours Considered

### Option A: Drag-and-drop onto the popover + copy into managed directory
One interaction, discoverable. The app owns the data after import. Source folder can be moved or deleted without consequence.

### Option B: "Import Pack..." button + file picker + copy
Standard macOS pattern but adds a modal picker flow. More code than A.

### Option C: Auto-scan a watched directory
Zero UI. User drops packs into `~/Library/Application Support/Thockspace/packs/` via Finder. App auto-picks up. Lowest implementation cost; least discoverable.

### Option D: Reference source folder instead of copying
No duplication on disk. Fragile if user moves/deletes the source. Needs stale-path handling.

## Decision

**Option A**. Drag-and-drop is the sole import entry point. A drop target is visible in the menu-bar popover. On drop, the folder is copied into `~/Library/Application Support/Thockspace/packs/<folder-name>/`. If the folder name collides with an existing pack, a suffix is appended (see BDR-0015).

After import, the source folder is forgotten — moving or deleting it has no effect on the installed pack.

## Rejected Alternatives

- **Option B** rejected because it adds a modal picker without user-visible advantage over drag-drop.
- **Option C** rejected because it makes import invisible ("did anything happen?") and complicates external change detection.
- **Option D** rejected because stale-path bugs (moved source, disconnected network volume) would dominate the lifecycle code.
