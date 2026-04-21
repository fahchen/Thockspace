---
id: BDR-0008
title: Mouse buttons trigger both down and up sounds, mirroring the keyboard
status: accepted
date: 2026-04-21
summary: Each mouse button press plays a down-sample; each release plays an up-sample (quieter). This matches the existing keyboard down/up playback model.
---

## Scope

**Feature**: sounds/features/mouse-sounds.feature
**Rule**: Both mouse button-down and button-up trigger a sound, mirroring the keyboard

## Reason

The existing `AudioEngine.play(macKeyCode:isDown:)` interface and spec.md already define down/up as two separate sample classes with differentiated gain (down louder, up softer). Mouse clicks reuse keyboard samples (BDR-0009), so reusing the same down/up pathway is the path of least mechanism. Real mechanical mice also produce audible down-snap and up-snap events, so the symmetric model matches user intuition. A down-only alternative was considered but rejected because it leaves the release feel hollow.
