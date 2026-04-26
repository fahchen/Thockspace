---
id: BDR-0002
title: Unify keyboard and mouse events in one store via synthetic codes
status: accepted
date: 2026-04-21
summary: Mouse button events are stored alongside keyboard events in the same sample store, identified by reserved synthetic codes instead of a dedicated mouse table.
---

**Feature**: stats/features/recording.feature
**Rule**: Mouse button-down events are stored alongside keyboard events via synthetic codes

## Context

The app is adding mouse click sounds (F2) and keystroke statistics (F1) around the same time. The statistics layer needs to decide whether mouse events live in their own table or share the keyboard store. This choice affects the heatmap pipeline, query paths, and the upcoming F2 discovery.

## Behaviours Considered

### Option A: Unified store with synthetic codes for mouse
One schema, one ingestion path, one aggregation query. Real keycodes from `CGKeyCode` occupy their natural range. Mouse buttons use reserved codes that never collide with real keyboard values (e.g. negative integers, or a well-known high range). The five synthetic codes are `mouse-left`, `mouse-right`, `mouse-middle`, `mouse-back`, `mouse-forward` (per BDR-0007).

### Option B: Separate tables for keyboard and mouse
Two ingestion paths, two aggregation queries. The heatmap would either render separate layers or union-query at read time.

### Option C: Record keyboard only; mouse is sound-only
Mouse sounds without recording. The F1 heatmap would ignore mouse activity entirely.

## Decision

**Option A**. Mouse button events are ingested into the same store as keyboard keystrokes, identified by synthetic codes (`mouse-left`, `mouse-right`, `mouse-middle`, `mouse-back`, `mouse-forward` — see BDR-0007 for the full scope). The heatmap pipeline treats them identically to keyboard keystrokes.

This keeps the ingestion path simple (one writer, one table), makes the heatmap a single query, and lets the user see total input activity without having to toggle data layers.

## Rejected Alternatives

- **Option B** was rejected because it doubles the query surface with no user-visible benefit — the user asked to "see mouse alongside keyboard", not "see mouse separately".
- **Option C** was rejected because the user explicitly asked for mouse clicks to be counted in the stats.
