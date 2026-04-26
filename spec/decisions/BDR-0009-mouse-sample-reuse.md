---
id: BDR-0009
title: Mouse reuses keyboard samples via a fixed button-to-key map; profile-bound
status: accepted
date: 2026-04-21
summary: Mouse buttons borrow existing keyboard samples from the active profile through a fixed mapping (left=Space, right=Return, middle=Tab, back=Backspace, forward=Escape). No separate mouse profile or mouse asset pack.
---

**Feature**: sounds/features/mouse-sounds.feature
**Rule**: Mouse samples come from the active keyboard profile through a fixed button-to-key map

## Context

F2 adds mouse button sounds. Every Mechvibes profile currently ships keyboard-only samples; none include dedicated mouse sounds. A decision is needed on where mouse samples come from and whether mouse has its own profile selector.

## Behaviours Considered

### Option A: Reuse keyboard samples, fixed button-to-key map, profile-bound
Zero new assets. Mouse feel is tied to the active keyboard profile. Mapping is:

| Button   | Keyboard key | macOS keycode |
|----------|--------------|---------------|
| left     | Space        | 49            |
| right    | Return       | 36            |
| middle   | Tab          | 48            |
| back     | Backspace    | 51            |
| forward  | Escape       | 53            |

All five keys are distinct, universally present, and unambiguous on macOS (no aliasing with numpad variants). They were chosen for their substantial, "thocky" character on most profiles — Space in particular is usually the largest keycap and sounds closest to a real mouse click. An earlier draft used "Enter" and "Return" as two distinct mappings; that was rejected because on macOS the main Return key (keycode 36) is often labeled "Enter" and most Mechvibes packs define only one sample for it, so the two mouse buttons would have collapsed onto the same sample.

### Option B: Ship dedicated mouse samples per profile
Requires sourcing or recording five mouse samples × down/up × three profiles = up to 30 new assets before v1 ships. Most Mechvibes packs do not include these.

### Option C: Hybrid — use dedicated mouse samples when a profile ships them, else fall back to Option A
Nice in theory but meaningless in v1 because no profile ships mouse samples. Adds branching in the loader without activating.

### Option D: Independent "Mouse profile" picker in the popover
Lets users mix-and-match (e.g. keyboard Holy Panda + mouse MX Red). Adds a UI control and mental overhead for a "reverse mullet" use case that was not requested.

## Decision

**Option A**. Mouse reuses keyboard samples through a fixed button-to-key map from the active profile. Switching the keyboard profile also switches the mouse sound. Option C is a compatible future upgrade — if a profile later adds dedicated mouse samples, the loader can prefer them without breaking existing behaviour.

## Rejected Alternatives

- **Option B** was rejected because asset collection is substantial and blocks shipping. If future profiles add mouse samples, upgrading via C is non-breaking.
- **Option C** was rejected for v1 only — it will become the natural default once B's assets exist. Implementing it today means adding unused branching.
- **Option D** was rejected because the user did not ask for decoupled audio identities and popover real estate is scarce.
