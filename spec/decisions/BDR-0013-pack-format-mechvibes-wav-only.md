---
id: BDR-0013
title: Custom packs use the Mechvibes format; only .wav samples are supported
status: accepted
date: 2026-04-21
summary: Imported packs reuse the existing Mechvibes `config.json` schema (both v1 sprite and v2 multi-file) with `.wav` samples. No Thockspace-proprietary format, no in-app ogg conversion.
---

## Scope

**Feature**: sounds/features/pack-import.feature
**Rule**: Only Mechvibes-format packs with .wav samples are supported

## Reason

`MechvibesLoader` already supports both Mechvibes config modes end-to-end. Reusing the schema means zero new parser code, instant compatibility with hundreds of existing mechvibes.com packs, and the mouse-button-to-key map from BDR-0009 works automatically for any imported pack. Ogg support would require a decoder dependency or bundling ffmpeg — disproportionate for a local-only hobby tool. Users who want ogg packs convert them externally (existing spec.md already documents the ffmpeg conversion command).
