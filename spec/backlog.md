# Backlog

Deferred features and open decisions that don't warrant a full BDR.

## Deferred Features

- **Ogg sample support** — rejected for v1 (see BDR-0013). Users convert with ffmpeg externally. Revisit if an ogg decoder becomes a lightweight option (discovered: 2026-04-21)
- **Live Finder-level directory watching** — external changes to the packs directory require an app relaunch. Could upgrade to `DispatchSourceFileSystemObject` or `NSFilePresenter` if users complain (discovered: 2026-04-21)
- **Pack rename UI** — currently the pack id (folder name) is changed by renaming the directory via Finder + restart; no in-app rename control. Revisit if demand appears (discovered: 2026-04-21)
- **Picker section headers** — picker is flat; could add "Bundled" / "Imported" headers if the list grows long (discovered: 2026-04-21)
- **Scroll-wheel sound** — rejected for v1 (see BDR-0007). Revisit when throttling rules (distance/rate/volume taper) are designed as a standalone feature (discovered: 2026-04-21)
- **Mouse-move sound** — rejected for v1. Would need event-rate throttling; belongs to a dedicated motion-audio feature if ever wanted (discovered: 2026-04-21)
- **Left-handed mouse spatial placement** — rejected for v1. A "Mouse side" toggle is straightforward if demand appears (discovered: 2026-04-21)
- **User-tunable mouse volume** — currently hard-coded at 50% of master (BDR-0010). Revisit if tuning complaints emerge (discovered: 2026-04-21)
- **Independent Mouse Sounds toggle** — rejected for v1. Global Mute covers both. Revisit if a "keyboard on / mouse off" use case appears (discovered: 2026-04-21)
- **Dedicated mouse sample packs** — currently mouse borrows keyboard samples (BDR-0009). Upgrade to a hybrid loader is non-breaking once assets exist (discovered: 2026-04-21)
- **Pause recording while muted or on demand** — explicit pause control is a separate feature, not a mute side effect (see BDR-0005) (discovered: 2026-04-21)

## Open Decisions

- **Stats export or screenshot sharing** — currently rejected for v1 privacy posture, but revisit if a user-initiated share flow becomes interesting
- **Yearly / multi-month heatmap** — rejected from the preset-range list for v1; revisit once the v1 heatmap lands
- **Pack metadata in Manage Packs** — v1 shows at minimum display name + delete. Revisit whether to show source path, size, number of defined keys, or imported date
