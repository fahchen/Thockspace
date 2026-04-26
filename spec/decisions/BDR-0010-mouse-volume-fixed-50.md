---
id: BDR-0010
title: Mouse playback gain is hard-coded at 50% of master volume
status: accepted
date: 2026-04-21
summary: Mouse effective gain = master × 0.50. Hard-coded constant. No UI control, no independent slider.
---

## Scope

**Feature**: sounds/features/mouse-sounds.feature
**Rule**: Mouse playback gain is half the current master volume

## Reason

The user picked a fixed "mouse relative to keyboard" ratio over (a) sharing master flat and (b) exposing a dedicated slider. 50% is the working value: mouse clicks are frequent enough that keyboard-equal intensity becomes fatiguing, and half-gain sits clearly in the background without disappearing. Hard-coding keeps the popover simple and matches the decision to hide the detail rather than expose a new control. Revisit if tuning complaints appear — upgrading to a user-tunable slider is non-breaking.
