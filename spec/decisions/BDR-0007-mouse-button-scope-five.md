---
id: BDR-0007
title: Mouse input scope is five buttons (left, right, middle, back, forward); scroll and move excluded
status: accepted
date: 2026-04-21
summary: Both mouse sounds (F2) and keystroke stats (F1) recognize the same five mouse buttons — left, right, middle, back (Button 4), forward (Button 5). Scroll wheel and mouse movement are excluded for v1.
---

**Feature**: sounds/features/mouse-sounds.feature, stats/features/recording.feature
**Rule**: Five mouse buttons are in scope; scroll and move are ignored

## Context

F1 (keystroke stats) and F2 (mouse sounds) must agree on which mouse inputs the app recognizes. If the two features disagreed, a click could appear in the heatmap without sounding (or vice versa), creating a confusing asymmetry. F1 stores mouse events under synthetic codes; F2 maps those same codes to sound samples.

## Behaviours Considered

### Option A: Three buttons (left, right, middle)
Simplest. Matches the minimum viable surface. Drops side buttons entirely, including for sound. Users with common 5-button mice lose audio feedback on back/forward, and silent buttons also disappear from the heatmap.

### Option B: Five buttons (left, right, middle, back, forward)
Adds two synthetic codes (`mouse-back`, `mouse-forward`) and two entries in the button-to-key sound map. Side buttons are standard on most modern mice and commonly used for browser navigation, so feedback on them is valuable.

### Option C: Five buttons plus scroll-wheel ticks
Scroll ticks would need throttling rules (distance, rate, volume taper). Out of scope for v1 as a standalone concern.

## Decision

**Option B**. The canonical mouse-button scope across the app — both for recording keystrokes and for playing sounds — is five buttons: left, right, middle, back, forward.

- Stats synthetic codes: `mouse-left`, `mouse-right`, `mouse-middle`, `mouse-back`, `mouse-forward`.
- Sound layer maps those codes to keyboard keys per BDR-0009.
- Mouse movement is not recorded and does not play sound (F2 rule).
- Scroll wheel is not recorded and does not play sound in v1 (see backlog).

## Rejected Alternatives

- **Option A** rejected because 5-button mice are common and silent back/forward would feel like broken feature coverage.
- **Option C** deferred — scroll-tick requires its own throttling spec and is tracked in the backlog for a standalone future feature.
