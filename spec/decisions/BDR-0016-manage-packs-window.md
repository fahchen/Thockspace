---
id: BDR-0016
title: Pack deletion lives in a dedicated "Manage Packs" window
status: accepted
date: 2026-04-21
summary: Imported packs are deleted via a dedicated "Manage Packs" window launched from the menu-bar popover. Bundled packs do not appear there. Follows the same "separate NSWindow launched from the popover" pattern as the F1 stats window.
---

## Scope

**Feature**: sounds/features/pack-import.feature
**Rule**: A dedicated "Manage Packs" window lists imported packs for deletion; bundled packs are not shown

## Reason

The popover stays compact (consistent with F1's stats window choice). A dedicated window has room for per-pack metadata (display name, source path, number of defined keys) and a clear delete control. Bundled packs are structurally un-removable (they live inside the app bundle), so listing them there with a disabled control would be confusing — the window's purpose is "packs I added, which I can remove". The alternative of a right-click context menu on profile picker rows was rejected in favour of a formal panel: it gives a stable surface for future features like pack metadata display or reorder.
