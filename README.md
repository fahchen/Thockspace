<p align="center">
  <img src="icon.png" alt="Thockspace" width="200">
</p>

<h1 align="center">Thockspace</h1>

<p align="center">
  macOS menu bar app that plays mechanical keyboard sounds as you type.<br>
  HRTF spatial audio — left keys sound left, right keys sound right.
</p>

---

## Features

### Sound Engine
- **3 built-in profiles**: Cherry MX Blue (clicky), Holy Panda (tactile), Cherry MX Red (linear)
- **Custom pack import**: drag-and-drop Mechvibes `.zip` or folder — auto-validates, handles name collisions
- **Mouse click sounds**: left, right, middle, back, forward — fixed at 50% volume, positioned to the right in spatial field
- **24-voice pool**: round-robin allocation with oldest-steal, handles fast bursts without glitch
- **HRTF spatial audio**: 112+ keys mapped to 3D positions, each keystroke gets random position jitter
- **Pitch jitter**: ±3% random varispeed per keystroke for organic feel

### Stats
- **Keystroke heatmap**: per-minute recording, visualize by hour/day with Today/Yesterday/This Week/This Month ranges
- **5-band quantile color scale**: empty → low → medium → high → peak
- **Hover tooltips**: exact count per cell
- **Recording continues while muted** — stats and sound are independent

### UI
- **Liquid Glass**: native macOS 26 Tahoe design tokens
- **Menu bar popover**: profile picker, volume slider, spatial/pitch toggles, mute, permission status
- **Manage Packs window**: list, preview, delete imported packs
- **Settings persistence**: volume, profile, toggles saved across launches via `@AppStorage`
- **Input Monitoring**: permission status chip with one-click System Settings link

### Build
- **Universal binary**: arm64 + x86_64 via `lipo`
- **Ad-hoc signed**: avoids "damaged" error — right-click → Open on first launch
- **Toolchain**: managed via `mise` (Swift 6.3, xcodegen)

## Requirements

- macOS 26 Tahoe+
- Input Monitoring permission (prompted on first launch)
- Headphones recommended for spatial audio

## Build

```bash
mise install                # swift 6.3, xcodegen
./scripts/bundle.sh         # debug build
./scripts/bundle.sh release # optimized build
```

Output: `build/Thockspace.app`

## Install

```bash
cp -r build/Thockspace.app /Applications/
```

First launch on another Mac: right-click → Open (one time only).

## Project Structure

```
Thockspace/
  ThockspaceApp.swift            # @main, MenuBarExtra, SVG icon loader
  AppState.swift                 # settings, audio engine + event tap wiring
  Views/
    Theme.swift                   # Liquid Glass design tokens
    SettingsView.swift            # menu bar popover
    StatsView.swift               # keystroke heatmap
    ManagePacksView.swift         # pack management window
  Audio/
    AudioEngine.swift             # AVAudioEngine, HRTF, spatial/direct routing
    VoicePool.swift               # 24-voice round-robin with varispeed + steal
    MechvibesLoader.swift         # single (sprite) + multi (per-key) pack formats
    PackImporter.swift            # zip/folder import, 3-tier validation
    PackLibrary.swift             # bundled + custom pack registry
    MouseButtonMap.swift          # 5-button mouse → sample + spatial mapping
    KeycodeMap.swift              # CGKeyCode → PS/2 scancode
    KeyPositionMap.swift          # CGKeyCode → 3D position (112+ keys)
  Stats/
    StatsModel.swift              # minute-bucketed counts, range/unit enums
    StatsRecorder.swift           # event recording (~8 MB/year)
  Input/
    KeyEventTap.swift             # CGEventTap (keys + mouse), dedicated thread
    PermissionManager.swift       # Input Monitoring check/request
  Resources/
    AppIcon.icns                  # app icon
    MenuBarIcon.svg               # keycap T menu bar icon
    sounds/                       # bundled Mechvibes packs (mono WAV 48kHz)
```

## Sound Packs

Bundled samples from [Mechvibes](https://github.com/hainguyents13/mechvibes), converted to mono WAV 48kHz for spatial audio. Supports both `single` (one file + timestamp sprites) and `multi` (per-key files with `{0-4}` random selection) pack formats. Custom packs import to `~/Library/Application Support/Thockspace/packs/`.

## License

Personal use only. Sound samples subject to original Mechvibes pack licenses.
