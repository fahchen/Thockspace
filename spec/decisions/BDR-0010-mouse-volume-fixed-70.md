---
id: BDR-0010
title: Mouse playback gain is hard-coded at 70% of master volume
status: accepted
date: 2026-04-21
summary: Mouse effective gain = master × 0.70. Hard-coded constant. No UI control, no independent slider.
---

## Scope

**Feature**: sounds/features/mouse-sounds.feature
**Rule**: Mouse playback gain is 70% of the current master volume

## Reason

The user picked a fixed "mouse relative to keyboard" ratio over (a) sharing master flat and (b) exposing a dedicated slider. 70% is the working value: clearly subordinate to keyboard without feeling muted. Hard-coding keeps the popover simple and matches the decision to hide the detail rather than expose a new control. Revisit if tuning complaints appear — upgrading to a user-tunable slider is non-breaking.
