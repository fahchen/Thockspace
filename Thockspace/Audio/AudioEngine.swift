import AVFoundation
import Foundation

final class AudioEngine {
    private let engine = AVAudioEngine()
    private let environmentNode = AVAudioEnvironmentNode()
    private let voicePool: VoicePool
    private let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!

    private var currentProfile: SoundProfile?
    private let poolSize = 24

    // Settings (set from AppState)
    var masterVolume: Float = 0.8 {
        didSet { engine.mainMixerNode.outputVolume = isMuted ? 0 : masterVolume }
    }

    var spatialAudioEnabled: Bool = true {
        didSet { rebuildGraph() }
    }

    var pitchJitterEnabled: Bool = true
    var isMuted: Bool = false {
        didSet { engine.mainMixerNode.outputVolume = isMuted ? 0 : masterVolume }
    }

    private var isRunning = false

    init() {
        voicePool = VoicePool(size: poolSize)
        buildGraph()
        observeConfigChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        engine.stop()
    }

    // MARK: - Graph

    private func buildGraph() {
        // Attach environment node
        engine.attach(environmentNode)

        // Configure environment
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.renderingAlgorithm = .HRTFHQ

        // Attach voice pool
        voicePool.attachAll(to: engine, format: monoFormat)

        if spatialAudioEnabled {
            // voices → environment → main mixer
            voicePool.connectAll(to: environmentNode, engine: engine, format: monoFormat)
            engine.connect(environmentNode, to: engine.mainMixerNode, format: monoFormat)
        } else {
            // voices → main mixer directly
            voicePool.connectAll(to: engine.mainMixerNode, engine: engine, format: monoFormat)
        }

        engine.mainMixerNode.outputVolume = isMuted ? 0 : masterVolume

        // Low latency buffer
        engine.prepare()
    }

    private func rebuildGraph() {
        let wasRunning = isRunning
        if wasRunning {
            engine.stop()
            isRunning = false
        }

        // Reset all connections
        engine.disconnectNodeOutput(environmentNode)
        for voice in voicePool.voices {
            engine.disconnectNodeOutput(voice.mixerNode)
        }

        if spatialAudioEnabled {
            voicePool.connectAll(to: environmentNode, engine: engine, format: monoFormat)
            engine.connect(environmentNode, to: engine.mainMixerNode, format: monoFormat)
        } else {
            voicePool.connectAll(to: engine.mainMixerNode, engine: engine, format: monoFormat)
        }

        if wasRunning {
            start()
        }
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("[Thockspace] Audio engine start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    // MARK: - Profile

    func loadProfile(named name: String) {
        currentProfile = MechvibesLoader.loadProfile(named: name)
        if currentProfile == nil {
            print("[Thockspace] Warning: no profile loaded for '\(name)'")
        }
    }

    // MARK: - Playback

    func play(macKeyCode: CGKeyCode, isDown: Bool) {
        guard !isMuted, let profile = currentProfile else { return }

        let isMouse = MouseButtonMap.isMouseCode(macKeyCode)
        let sampleCode = isMouse
            ? MouseButtonMap.keyboardSampleCode(forMouseCode: macKeyCode)
            : macKeyCode

        // Map mac keycode → Mechvibes scancode
        guard let scancode = KeycodeMap.scancode(for: sampleCode) else { return }

        // Look up buffer (random selection from available variants)
        let buffer: AVAudioPCMBuffer?
        if isDown {
            buffer = profile.randomDown(for: scancode)
        } else {
            buffer = profile.randomUp(for: scancode)
        }

        guard let buf = buffer else { return }
        playBuffer(buf, macKeyCode: macKeyCode, isDown: isDown, isMouse: isMouse)
    }

    private func playBuffer(
        _ buffer: AVAudioPCMBuffer,
        macKeyCode: CGKeyCode,
        isDown: Bool,
        isMouse: Bool
    ) {
        let voice = voicePool.acquire()

        // Set spatial position with per-keystroke jitter
        if spatialAudioEnabled {
            let basePos = isMouse
                ? MouseButtonMap.spatialPosition
                : KeyPositionMap.position(for: macKeyCode)
            let jitteredPoint = AVAudio3DPoint(
                x: basePos.x + Float.random(in: -0.05...0.05),
                y: basePos.y + Float.random(in: -0.03...0.03),
                z: basePos.z + Float.random(in: -0.02...0.02)
            )
            voice.playerNode.position = jitteredPoint
        }

        // Pitch jitter
        let pitch: Float = pitchJitterEnabled
            ? 1.0 + Float.random(in: -0.03...0.03)
            : 1.0

        // Gain: key-up quieter; mouse runs at a fixed fraction of keyboard gain.
        let baseGain: Float = isDown ? 1.0 : 0.6
        let gain: Float = isMouse ? baseGain * MouseButtonMap.relativeGain : baseGain

        voice.play(buffer: buffer, gain: gain, pitch: pitch)
    }

    // MARK: - Config change handling

    private func observeConfigChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigChange),
            name: .AVAudioEngineConfigurationChange,
            object: engine
        )
    }

    @objc private func handleConfigChange(_ notification: Notification) {
        print("[Thockspace] Audio config changed, restarting engine...")
        isRunning = false
        rebuildGraph()
        start()
    }
}
