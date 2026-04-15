# Thockspace — Execution Plan

Me build step by step. Each step small. Test each step before go next.

## Phase 0 — Setup (30 min)

- [ ] Install Xcode from App Store (if no have).
- [ ] Install `ffmpeg`: `brew install ffmpeg`.
- [ ] Create new Xcode project inside your repo:
  - Template: **macOS → App**
  - Name: `Thockspace`
  - Interface: **SwiftUI**
  - Language: **Swift**

## Phase 1 — Menu Bar Shell (1 hr)

- [ ] Open `Info.plist`. Add key `Application is agent (UIElement)` = `YES`. (Hide Dock.)
- [ ] Delete default `ContentView` window code in `@main` App struct.
- [ ] Add `MenuBarExtra` (SwiftUI, macOS 13+):
  ```swift
  @main
  struct ThockspaceApp: App {
      var body: some Scene {
          MenuBarExtra("Thockspace", systemImage: "keyboard") {
              SettingsView()
          }
          .menuBarExtraStyle(.window)
      }
  }
  ```
- [ ] Make `SettingsView` placeholder with "Hello Thockspace" + Quit button.
- [ ] Run. Icon show in menu bar. Click → popover open.

**Done when**: menu bar icon visible, no Dock icon, popover works.

## Phase 2 — Input Monitoring Permission (1–2 hr)

- [ ] Add to `Info.plist`:
  - Key: `NSInputMonitoringUsageDescription`
  - Value: `Thockspace listens for key presses to play mechanical keyboard sounds. It never reads what you type.`
- [ ] Make `PermissionManager` class:
  - Check `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)` → status.
  - If not granted, call `IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)`.
  - Show current status in `SettingsView`.
- [ ] Add button "Open System Settings" that opens:
  ```swift
  NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
  ```

**Done when**: app show "granted" or "not granted". Button opens right settings pane.

## Phase 3 — CGEventTap (2 hr)

- [ ] Make `KeyEventTap` class.
- [ ] Create tap:
  ```swift
  CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue),
    callback: callback,
    userInfo: selfPointer
  )
  ```
- [ ] Callback: extract keycode via `event.getIntegerValueField(.keyboardEventKeycode)`. Fire closure with `(keycode, isDown: Bool)`.
- [ ] Add tap to run loop, enable.
- [ ] Handle `.tapDisabledByTimeout` — re-enable in callback.
- [ ] Wire up to print `"keyDown: \(keycode)"` / `"keyUp: \(keycode)"` to console.

**Done when**: type in any app, see keycode print in Xcode console.

**Gotcha**: if unsigned build, may need toggle Input Monitoring off/on after rebuild.

## Phase 4 — Single Sound Playback (1 hr)

- [ ] Download ONE `.wav` sample for testing (any mech keyboard click).
- [ ] Drop in Xcode project `Resources/`.
- [ ] Make `AudioEngine` class with `AVAudioEngine`:
  - One `AVAudioPlayerNode`.
  - Load sample as `AVAudioPCMBuffer` at init.
  - `play(keyCode:isDown:)` method — schedule buffer on player node.
- [ ] Start engine at app launch.
- [ ] Wire `KeyEventTap` callback → `audioEngine.play(keyCode:isDown:)`. v1 only require down; up can play same sample quieter if no up sample yet.

**Done when**: press any key, hear the sample.

## Phase 5 — Voice Pool + Polish (2 hr)

- [ ] Make voice pool: 24 per-voice chains. Each chain = `AVAudioPlayerNode → AVAudioUnitVarispeed → AVAudioMixerNode` (per-voice gain for envelope). All voice mixers feed shared `AVAudioEnvironmentNode` → main mixer → output (env node added in phase 7).
- [ ] Round-robin or pick idle node. If all busy, steal oldest (ramp down 10ms, stop).
- [ ] Envelope: automate per-voice mixer gain — ramp in 3ms, ramp out 20ms. Schedule ramps against `lastRenderTime`.
- [ ] Pitch jitter: set voice's `AVAudioUnitVarispeed.rate = 1.0 + Float.random(in: -0.03...0.03)` per keystroke. Gate by `pitchJitterEnabled` setting.
- [ ] Handle `AVAudioEngineConfigurationChange` notify → restart engine, rebuild graph.

**Done when**: rapid typing → no glitch, subtle pitch variation, no click pops.

## Phase 6 — Mechvibes Sample Loader (2–3 hr)

- [ ] Pick 3 Mechvibes pack online:
  - Cherry MX Blue
  - Holy Panda
  - Gateron Red
- [ ] Download. Inspect `config.json`.
- [ ] Convert `.ogg` → `.wav` mono 48kHz:
  ```bash
  cd pack_folder
  for f in *.ogg; do ffmpeg -i "$f" -ac 1 -ar 48000 "${f%.ogg}.wav"; done
  ```
- [ ] Bundle under `Resources/sounds/<profile>/` + keep `config.json`.
- [ ] Write `MechvibesLoader`:
  - Parse `config.json`.
  - If `key_define_type == "single"`: load single file, store `[jsKeycode: (downSegment, upSegment?)]` as (startMs, endMs) pairs. Some packs have down+up in one entry (array of 2 pairs), some only down.
  - If `"multi"`: load each file into buffer, store `[jsKeycode: (downBuffer, upBuffer?)]`.
- [ ] Write `KeycodeMap`: `[CGKeyCode: Int]` (mac VK → JS keycode). Hardcode ~60 main keys (letters, digits, space, return, modifiers).
- [ ] Wire: `play(macKeyCode:isDown:)` → look up JS keycode → pick down or up buffer/segment → play. If no up buffer, skip up event (or play down at lower volume).

**Done when**: switch profile in UI, sound change correctly per key.

**Gotcha**: some Mechvibes packs are `single` (one big file + timestamps). Need schedule with `scheduleSegment` using time offset.

## Phase 7 — Spatial Audio (2 hr)

- [ ] Insert shared `AVAudioEnvironmentNode` between per-voice mixers and main mixer.
- [ ] Set env node `renderingAlgorithm = .HRTFHQ`, listener at origin.
- [ ] Each `AVAudioPlayerNode`: set `renderingAlgorithm = .HRTFHQ` on node.
- [ ] Make `KeyPositionMap`: `[CGKeyCode: AVAudio3DPoint]`. Hardcode rough QWERTY layout:
  - Row 1 (QWERTY): y = +0.03
  - Row 2 (ASDF): y = 0
  - Row 3 (ZXCV): y = −0.03
  - X: spread letters from −0.25 to +0.25 across row.
  - Z: −0.5 constant.
- [ ] Before play: set voice's `position = keyPositionMap[keycode] ?? .init(x: 0, y: 0, z: -0.5)`.
- [ ] Confirm samples are mono (redo ffmpeg with `-ac 1` if stereo).

**Done when**: on headphones, left keys feel left, right keys feel right.

## Phase 8 — UI Polish (1–2 hr)

- [ ] `SettingsView` contents:
  - Picker: Profile (Cherry MX Blue / Holy Panda / Gateron Red).
  - Slider: Master volume (0.0–1.0).
  - Toggle: Spatial audio.
  - Toggle: Pitch jitter.
  - Toggle: Mute.
  - Text: permission status.
  - Button: Open System Settings (if not granted).
  - Button: Quit.
- [ ] Persist all in `UserDefaults` via `@AppStorage`.
- [ ] Wire state → `AudioEngine` live.

**Done when**: change profile/volume in popover, takes effect immediately.

## Phase 9 — Run Local (30 min)

- [ ] In Xcode target → **Signing & Capabilities**: choose "Sign to Run Locally" or select your free Personal Team. (No paid Developer account required.)
- [ ] Build with **Product → Build** (Release config). Locate `.app` under `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Release/Thockspace.app`.
- [ ] Copy `.app` to `/Applications/Thockspace.app`.
- [ ] First launch: **right-click → Open** (bypass Gatekeeper warning).
- [ ] Grant Input Monitoring to `/Applications/Thockspace.app` in System Settings.
- [ ] Add to Login Items manually (System Settings → General → Login Items). Wire `SMAppService` in v2.

**Done when**: Thockspace run on every login, thock thock thock forever.

## Phase 10 — v2 Stretch (if want)

- [ ] Notch visualizer (`NSPanel` overlay, CoreAnimation pulse).
- [ ] 2D tone pad (crossfade between two buffers based on XY).
- [ ] Global mute hotkey via `NSEvent.addGlobalMonitor` or `Carbon` hotkey API.
- [ ] Launch at login via `SMAppService`.
- [ ] Headphone detect → auto disable spatial on speaker.

---

## Time Estimate

- Core (phase 0–9): **~12–16 hour** over weekend.
- v2 stretch: **+4–8 hour**.

## Order of Pain (hardest first)

1. CGEventTap permission dance.
2. Low-latency audio engine tuning (buffer size, voice stealing).
3. Mechvibes config parsing (single vs multi mode).
4. Spatial audio mono requirement (re-export samples).

## Test Matrix

- Single key press → sound fire.
- Fast typing (burst 10+ keys/sec) → no glitch, no crash.
- Switch profile mid-typing → smooth transition.
- Sleep laptop, wake → audio still work.
- Plug headphone, unplug → engine recover.
- Revoke Input Monitoring → app show warning, don't crash.

## Files to Create

```
Thockspace/
  ThockspaceApp.swift         # @main, MenuBarExtra
  Views/
    SettingsView.swift        # popover UI
  Audio/
    AudioEngine.swift         # AVAudioEngine orchestration
    VoicePool.swift           # voice stealing
    MechvibesLoader.swift     # parse config.json
    KeycodeMap.swift          # mac VK ↔ JS keycode
    KeyPositionMap.swift      # keycode → 3D position
  Input/
    KeyEventTap.swift         # CGEventTap wrapper
    PermissionManager.swift   # Input Monitoring check
  Resources/
    sounds/
      cherry-mx-blue/
        config.json
        *.wav
      holy-panda/
        config.json
        *.wav
      gateron-red/
        config.json
        *.wav
  Info.plist                  # LSUIElement, NSInputMonitoringUsageDescription
```

