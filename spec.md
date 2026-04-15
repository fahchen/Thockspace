# Thockspace — Spec

Me build mac app. Play keyboard thock. Local only. No sell.

## Big Rock Goal

Press key → hear real mechanical switch sound. Feel like fancy keyboard. Live in menu bar. No Dock.

## Must Have

### App Shape

- macOS menu bar app. No Dock icon.
- `LSUIElement = YES` in Info.plist.
- macOS 13+.
- Swift + SwiftUI + AppKit bridge.

### Permission

- Need **Input Monitoring**.
- Info.plist key: `NSInputMonitoringUsageDescription` = "Thockspace listen key press to make thock sound. Never read what you type."
- First launch: show onboarding. Open System Settings → Privacy & Security → Input Monitoring.
- If no permission: show warning in menu bar popover.

### Key Capture

- Use **CGEventTap** at `kCGHIDEventTap`.
- Listen `keyDown` + `keyUp` only.
- Tap type `.listenOnly`. Don't eat event.
- Run tap on own `CFRunLoop` thread.
- Re-enable tap when macOS kill on timeout (listen for `.tapDisabledByTimeout`).
- Never read keycode for log. Only trigger sound.

### Audio Engine

- **AVAudioEngine**. Low buffer (128 or 256 frame).
- Per-voice chain (one per `AVAudioPlayerNode` in pool):

  ```
  AVAudioPlayerNode
    → AVAudioUnitVarispeed (pitch jitter, per voice)
    → AVAudioMixerNode (per-voice gain for envelope)
    → AVAudioEnvironmentNode (HRTF spatial, shared)
    → main mixer
    → output
  ```

- Pre-load all sample as `AVAudioPCMBuffer` at launch. No disk read per keystroke.
- Voice pool cap: 24 concurrent voice. Steal oldest when full (ramp down 10ms, stop).
- Pitch jitter: random ±3% per key (togglable). Stop "two click same" feel.
- Envelope per voice: 3ms ramp in, 20ms ramp out via per-voice mixer gain. No click pop.
- Separate **down** and **up** sample per profile. Different volume. Trigger down on `keyDown`, up on `keyUp`.

### Spatial Audio

- `AVAudioEnvironmentNode` with `.HRTFHQ` render algorithm.
- Listener at origin `(0, 0, 0)`.
- Each key map to 3D position:
  - X: left key negative, right key positive. Range ~−0.3 to +0.3 meter.
  - Y: top row slight up, bottom row slight down. Range ~±0.05.
  - Z: constant −0.5 (half meter in front).
- Hardcode `[CGKeyCode: AVAudio3DPoint]` dict.
- Sample **must be mono**. Environment node no spatialize stereo.
- Toggle in UI: spatial on/off. Off = bypass env node, straight stereo.
- Headphone detect: auto fallback to stereo on speaker → **v2**.

### Sound Source

- Download real sample from **Mechvibes** pack.
- Ship with 3 profile first:
  - Cherry MX Blue (clicky)
  - Holy Panda (tactile)
  - Gateron Red (linear)
- Convert `.ogg` → `.wav` with `ffmpeg`:

  ```
  for f in *.ogg; do ffmpeg -i "$f" -ac 1 -ar 48000 "${f%.ogg}.wav"; done
  ```

  (`-ac 1` = mono, required for spatial.)
- Parse Mechvibes `config.json`. Map JS keycode → mac virtual keycode.
- Bundle all sample in Xcode `Resources/sounds/<profile>/`.

### UI (menu bar popover) — v1

- Profile picker (list, 3 row).
- Master volume slider.
- Spatial audio toggle.
- Pitch jitter toggle.
- Mute toggle (big button).
- Permission status text + "Open System Settings" button.
- Quit button.
- Persist all setting in `UserDefaults`.

## Nice Have (v2)

- **Notch visualizer**: transparent `NSPanel` over notch. Pulse on keystroke. `.nonactivating`, `.statusBar` level, `ignoresMouseEvents = true`.
- **2D tone pad**: draggable XY control. Crossfade between two sample bank (thock ↔ clack).
- **Global hotkey** to mute quick.
- **Launch at login**: `SMAppService` (macOS 13+).

## Skip For Now

- Code sign + notarize. Run local only.
- License key / paywall. Me not sell.
- Mac App Store.
- Marketing site.
- Analytic / telemetry.

## Non-Goal

- No key logging, ever. Never read content.
- No network call. All local.
- No iOS / Vision Pro port.

## Tech Risk

1. **CGEventTap flaky**. Need re-enable on timeout. Test under heavy CPU load.
2. **Input Monitoring reset on rebuild**. Unsigned binary change hash each build. Keep `.app` in `/Applications` and rebuild less, or live with re-grant.
3. **Latency spike**. Watch for audio engine config change (device switch, sleep/wake). Listen `AVAudioEngineConfigurationChange` notify.
4. **Mechvibes pack license**. Most free for personal use. Check per pack if redistribute.
5. **Ogg decode**. macOS `AVAudioFile` no read Ogg. Must convert up front.

## Done Look Like

- Press key anywhere in macOS. Hear real MX Blue click within ~10ms perceived.
- Switch profile in menu bar. Sound change.
- Toggle spatial. Sound pan follow key position on headphone.
- Close laptop, wake, still work.
- Zero network call (check with Little Snitch).
