---
id: BDR-0005
title: Keystroke recording is decoupled from the audio mute state
status: accepted
date: 2026-04-21
summary: The recorder always runs while the app is up. Mute only silences the audio output; it does not pause, gate, or skip recording.
---

## Scope

**Feature**: stats/features/recording.feature
**Rule**: Recording is independent of the mute state

## Reason

Mute is about audio output, not privacy or consent. The user has already granted Input Monitoring and explicitly wants a stats history. Coupling mute to recording would produce surprising gaps ("why is there a hole at 10:00? I muted so I could join a meeting"). The behaviours are orthogonal: mute affects the ears; recording affects the history. Users who want to pause recording should get an explicit "pause recording" control — that is a separate feature, not a side effect of muting.
