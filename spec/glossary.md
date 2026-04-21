# Glossary

Shared domain terminology for Thockspace specs.

| Term | Definition |
|------|------------|
| Keystroke | One recorded input event, counted once per OS `keyDown` (including modifier down-transitions and mouse button-down). `keyUp` events and modifier up-transitions do not count. |
| Synthetic code | A reserved identifier used to store non-keyboard input (currently mouse buttons, possibly future sources) in the same event store as real keyboard keycodes. |
| Sample | A single recorded (timestamp, code) pair at the recording layer, before aggregation into buckets. |
| Bucket | A count of keystrokes aggregated over a time window whose size is derived from the selected (range × time unit). |
| Time unit | The bucket size chosen for display. Supported values: `per minute`, `per hour`, `per day`. |
| Range | A preset display window. Supported values: `today`, `yesterday`, `this week`, `this month`. |
| Heatmap | The 2D visualization of keystroke activity: rows are days, columns are time buckets within a day, and color intensity encodes keystroke count. |
| Profile | A named collection of keyboard sound samples (e.g. "Cherry MX Blue"). Selected via the menu-bar popover. The same profile also drives mouse sounds through the button-to-key map. |
| Spatial audio | An audio rendering mode where each input's sound is panned to a 3D position via `AVAudioEnvironmentNode`'s HRTF algorithm. Keyboard uses per-key positions; mouse uses one fixed right-side position. |
| Click event | A mouse button-down or button-up event. For sound purposes, down and up each play a sample with differentiated gain. |
| Button-to-key map | The fixed mapping from a mouse button to a keyboard key whose sample it borrows: left=Space, right=Return, middle=Tab, back=Backspace, forward=Escape. |
| Mouse spatial position | A fixed right-side 3D point (approx x=+0.2, y=-0.05, z=-0.5) shared by all five mouse buttons when Spatial Audio is on. Subject to per-click jitter. |
| Bundled pack | A sound pack shipped inside the app bundle at `Resources/sounds/<id>/`. Currently: Cherry MX Blue, Holy Panda, Cherry MX Red. Not removable, not listed in Manage Packs. |
| Imported pack | A sound pack the user added by dragging a folder onto the menu-bar popover. Stored at `~/Library/Application Support/Thockspace/packs/<folder>/`. Listed in the profile picker (after bundled packs) and in the Manage Packs window. |
| Pack manifest | The `config.json` file inside a pack, describing its name, sample layout, and key defines. Follows the Mechvibes schema (v1 sprite or v2 multi-file). |
| Pack id | The directory name under which a pack lives. For bundled packs, the `Resources/sounds/` subfolder name. For imported packs, the name under `~/Library/Application Support/Thockspace/packs/`. Persisted in `selectedProfile`. |
| Pack display name | The human-readable name shown in the profile picker. Read from `config.json`'s `name` field, falling back to the pack id when absent. |
