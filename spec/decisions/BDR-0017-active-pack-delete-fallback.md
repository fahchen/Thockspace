---
id: BDR-0017
title: Deleting the active pack is allowed with a fallback-aware confirmation
status: accepted
date: 2026-04-21
summary: Delete of the currently-selected imported pack is allowed. The confirmation dialog notes that playback will fall back to Cherry MX Blue. On confirm, the pack is removed and `selectedProfile` is reassigned to `cherry-mx-blue`.
---

## Scope

**Feature**: sounds/features/pack-import.feature
**Rule**: Deleting the currently-active imported pack is allowed with a confirmation; playback falls back to Cherry MX Blue

## Reason

Blocking deletion of the active pack would force a "switch, then delete" dance for an operation the user has already decided on. A confirmation dialog with a contextual note about the fallback is enough to prevent accidents while respecting intent. Cherry MX Blue is the correct fallback because it is the default `selectedProfile` initializer in `AppState` and is always present in the bundle. After fallback, the user can re-select any other pack; the fallback is merely a valid-state guarantee, not a preference.
