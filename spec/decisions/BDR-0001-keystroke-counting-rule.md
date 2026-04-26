---
id: BDR-0001
title: Count each OS keyDown as one keystroke; auto-repeat counts; keyUp does not
status: accepted
date: 2026-04-21
summary: A keystroke is one OS-emitted keyDown event. Auto-repeat events each count; keyUp never does. Modifier down-transitions count.
---

**Feature**: stats/features/recording.feature
**Rule**: Each OS keyDown event counts as one keystroke

## Context

The recording feature needs a precise definition of "one keystroke" so that counts in the heatmap are deterministic and explainable. The app already consumes events from a `CGEventTap` listening to `keyDown`, `keyUp`, and `flagsChanged`. Without a clear rule, "Holy Panda" and "Cherry MX Blue" profiles could record different totals depending on when the audio layer happens to fire.

## Behaviours Considered

### Option A: Each OS `keyDown` = one keystroke (auto-repeat included, keyUp excluded)
Straightforward. Matches what most users mentally picture when they "press a key". Modifier keys use `flagsChanged` down-transitions as their equivalent of keyDown.

### Option B: Pair (keyDown + keyUp) = one keystroke
Requires tracking in-flight keys and pairing them up. Handles auto-repeat awkwardly (one down, one up far later, but N auto-repeat downs in between).

### Option C: Count both keyDown and keyUp separately
Doubles every number. Confuses the user ("I typed 100 letters but the stats say 200").

### Option D: Deduplicate auto-repeat (one press = one keystroke regardless of hold duration)
Requires tracking the most recent keyDown per key and ignoring subsequent keyDowns until a keyUp arrives. Hides a legitimate activity signal: holding a key *is* typing activity.

## Decision

**Option A**. Each OS-emitted `keyDown` event contributes exactly one keystroke to the store. Auto-repeat events count because they represent real activity. Modifier keys count their down-transitions via `flagsChanged`. `keyUp` events are ignored by the recorder.

This rule applies uniformly to keyboard and mouse button events. Mouse buttons generate one keystroke per button-down, recorded with a synthetic code (see BDR-0002).

## Rejected Alternatives

- **Option B** was rejected because pairing logic adds complexity and fails for held keys with long auto-repeat sequences.
- **Option C** was rejected because it produces counts that contradict user intuition.
- **Option D** was rejected because it erases a meaningful signal about sustained activity (e.g., holding backspace to delete a long line) and complicates the recorder's state.
