# Thockspace

macOS menu bar app. Press key, hear mechanical keyboard thock. HRTF spatial audio on headphones.

## Features

- **3 sound profiles**: Cherry MX Blue (clicky), Holy Panda (tactile), Cherry MX Red (linear)
- **Spatial audio**: HRTF — left keys sound left, right keys sound right
- **24-voice pool**: handles fast typing without glitch
- **Pitch jitter**: subtle random variation per keystroke
- **Position jitter**: per-keystroke 3D offset for organic feel
- **Menu bar only**: no Dock icon, lives in menu bar

## Requirements

- macOS 26 Tahoe+ (uses native Liquid Glass UI)
- Input Monitoring permission (prompted on first launch)
- Headphones recommended for spatial audio

## Build

```bash
mise install           # swift 6.3, xcodegen
./scripts/bundle.sh    # debug build
./scripts/bundle.sh release
```

Output: `build/Thockspace.app` (universal binary, arm64 + x86_64, ad-hoc signed)

## Install

```bash
cp -r build/Thockspace.app /Applications/
```

First launch: right-click → Open (Gatekeeper bypass, one time only).

## Project Structure

```
Thockspace/
  ThockspaceApp.swift           # @main, MenuBarExtra
  AppState.swift                # settings + wiring
  Views/
    Theme.swift                  # Liquid Glass design tokens (panel/section/chip)
    SettingsView.swift           # popover UI
  Audio/
    AudioEngine.swift            # AVAudioEngine + HRTF spatial
    VoicePool.swift              # 24-voice round-robin with steal
    MechvibesLoader.swift        # parse Mechvibes config.json
    KeycodeMap.swift             # CGKeyCode → PS/2 scancode
    KeyPositionMap.swift         # CGKeyCode → 3D position
  Input/
    KeyEventTap.swift            # CGEventTap on dedicated thread
    PermissionManager.swift      # Input Monitoring check/request
  Resources/sounds/
    cherry-mx-blue/              # single-file sprite mode
    holy-panda/                  # multi-file per-key mode
    cherry-mx-red/               # single-file sprite mode
```

## Sound Packs

Samples from [Mechvibes](https://github.com/hainguyents13/mechvibes), converted to mono WAV 48kHz for spatial audio. Supports both `single` (one file + timestamp sprites) and `multi` (per-key files) pack formats.

## License

Personal use only. Sound samples subject to original Mechvibes pack licenses.
