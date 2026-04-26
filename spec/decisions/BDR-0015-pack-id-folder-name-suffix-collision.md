---
id: BDR-0015
title: Pack id is the folder name; collisions resolve by suffixing
status: accepted
date: 2026-04-21
summary: A pack's id is the directory name under `packs/`. Display name comes from `config.json`'s `name` field (fallback to folder name). On name collision, the copy destination gets `-2`, `-3`, ... appended; the source is not modified.
---

**Feature**: sounds/features/pack-import.feature
**Rule**: The pack id is the folder name under the packs directory; the display name is the config.json "name" field or the folder name; On id collision, the destination folder name is suffixed until unique

## Context

Packs need a stable identifier for `@AppStorage selectedProfile` persistence and a human-friendly name for the picker. The two concerns (identity vs presentation) deserve independent answers.

## Behaviours Considered

### Option A: Folder name is both id and display name
Simple. Forces the folder name to look good in the picker.

### Option B: Folder name as id; config.json `name` as display name with folder fallback
Separates concerns. Matches how the bundled packs already work (bundled id "cherry-mx-blue" vs display "Cherry MX Blue").

### Option C: UUID as id; config.json `name` as display
Guaranteed unique. Folder names become opaque (`<uuid>/config.json`), breaking the "self-build" workflow where the user inspects or edits files.

### Option D: Prompt the user for a name on each import
Extra UI step. User may not know the canonical name yet.

## Decision

**Option B**. The id is the destination folder name inside the managed packs directory. The display name is read from `config.json`'s `name` field on load, falling back to the folder name when absent. Collision on the destination folder name during import is resolved by appending `-2`, `-3`, ... until the name is unique; the source folder on the user's disk is never touched.

## Rejected Alternatives

- **Option A** was rejected because forcing a single string to be both id (persistence key, filesystem-safe) and display name (capitalization, spaces, etc.) is awkward.
- **Option C** was rejected because opaque UUIDs hurt the "open Finder, look at your packs" workflow the user explicitly wants.
- **Option D** was rejected because drag-and-drop should be a one-gesture import — adding a modal prompt defeats the interaction.
