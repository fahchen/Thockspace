---
id: BDR-0018
title: Tiered import validation — structural errors reject; partial errors warn
status: accepted
date: 2026-04-21
summary: Structural problems (not a folder, no config.json, unparseable JSON, missing required fields) reject the whole import with an NSAlert. Partial problems (some missing or broken sample files) import with a non-blocking warning; the pack plays whatever samples loaded.
---

**Feature**: sounds/features/pack-import.feature
**Rule**: Import validation is tiered — structural errors reject; partial errors warn

## Context

A drop may bring anything — a valid pack, an incomplete pack, a random folder, or a single file. The import layer needs a policy for how much imperfection to tolerate.

## Behaviours Considered

### Option A: Strict — reject on any issue
Any missing sample or unreferenced key fails the whole import. Safe but over-aggressive: Mechvibes packs in the wild often omit less-common keys (F13–F24, international keys), and strict mode would reject them all.

### Option B: Lenient — accept everything
Even a random folder becomes an "imported pack" (with no playable samples). Creates dangling entries in the picker that make no sound, confusing the user.

### Option C: Tiered — structural errors reject; partial errors warn
Distinguishes between "this is not a pack at all" (reject) and "this is a pack with incomplete samples" (accept with warning). Matches `MechvibesLoader`'s existing behaviour of silently skipping `loadWavBuffer` failures via `compactMap`.

## Decision

**Option C**. Structural errors reject the whole import with an `NSAlert` explaining the cause. Structural errors are:

- The drop target is not a directory.
- No `config.json` in the directory.
- `config.json` is not valid JSON.
- `config.json` is missing required fields (`sound` / `defines`).

Partial errors allow the import to proceed and surface a non-blocking warning. Partial errors are:

- One or more referenced `.wav` files are missing.
- One or more referenced `.wav` files fail to decode.

Format mismatches (wrong sample rate or channel count) are transparently converted by `MechvibesLoader` and do not warn.

## Rejected Alternatives

- **Option A** rejected because many real-world Mechvibes packs intentionally omit rare keys; strict mode would reject them and frustrate the user.
- **Option B** rejected because dangling "packs" with no playable sound pollute the picker and create confusion ("why doesn't this profile make noise?").
