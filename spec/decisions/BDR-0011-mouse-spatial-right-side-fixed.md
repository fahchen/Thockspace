---
id: BDR-0011
title: Mouse uses a fixed right-side spatial position; left-handed placement not supported in v1
status: accepted
date: 2026-04-21
summary: When Spatial Audio is on, all five mouse buttons render from one fixed right-side 3D position (x approx +0.2, y approx -0.05, z approx -0.5) with per-click jitter. When Spatial Audio is off, mouse inherits stereo. No left/right-hand switch in v1.
---

**Feature**: sounds/features/mouse-sounds.feature
**Rule**: Mouse spatial placement is a fixed right-side position; stereo fallback when Spatial Audio is off

## Context

Keyboard already renders per-key 3D positions via `KeyPositionMap` when Spatial Audio is enabled. Mouse has no intrinsic physical position relative to the listener, so a placement policy is needed. The Global Spatial Audio toggle is expected to control both keyboard and mouse uniformly.

## Behaviours Considered

### Option A: Mouse always at center (0, 0, -0.5)
Safe default, indistinguishable from listener-front. Loses spatial flavor entirely for mouse.

### Option B: Mouse at fixed right-side offset
Right-handed bias. Simple. All buttons share one point. Adds audible "mouse-ness" without extra logic.

### Option C: Follow the mapped keyboard key's position
Mouse-left plays at Space position, mouse-right at Return, etc. Gives spatial diversity across buttons for free.

### Option D: Mouse bypasses the environment node entirely
Keyboard remains spatial, mouse stays stereo regardless of global toggle. Inconsistent behaviour of the single toggle.

## Decision

**Option B** with these concrete values:

- `x = +0.2`, `y = -0.05`, `z = -0.5` (approximate; tune by ear)
- All five mouse buttons share this position
- Per-click jitter matches the keyboard jitter amplitudes so repeated clicks do not sound identical
- Global Spatial Audio off → mouse falls back to stereo (matches keyboard)
- No left-hand support in v1 — the right-side position is hard-coded; left-handed users can file a feature request

## Rejected Alternatives

- **Option A** rejected because a center-pan mouse loses the spatial "they're on my right" cue that right-handed users unconsciously expect.
- **Option C** rejected even though it would give free button-level diversity — it conflates two concerns (sample source vs spatial source) that may need to decouple later, and middle-click on Tab (left side of the keyboard) and forward-click on Escape (top-left corner) would end up in off-hand spatial positions that contradict the right-handed mouse assumption.
- **Option D** rejected because it makes the single Spatial Audio toggle behave inconsistently across input sources.
- **Left-handed support** deferred — adding a "Mouse side" toggle is simple but the user explicitly declined for v1.
