import AVFoundation

/// A single voice in the pool: player → varispeed → per-voice mixer
final class Voice {
    let playerNode: AVAudioPlayerNode
    let varispeedNode: AVAudioUnitVarispeed
    let mixerNode: AVAudioMixerNode
    var startTime: UInt64 = 0  // mach_absolute_time when started
    var isActive: Bool = false

    init() {
        playerNode = AVAudioPlayerNode()
        varispeedNode = AVAudioUnitVarispeed()
        mixerNode = AVAudioMixerNode()
    }

    /// Attach all nodes to the engine and connect: player → varispeed → mixer
    func attach(to engine: AVAudioEngine, format: AVAudioFormat) {
        engine.attach(playerNode)
        engine.attach(varispeedNode)
        engine.attach(mixerNode)
        engine.connect(playerNode, to: varispeedNode, format: format)
        engine.connect(varispeedNode, to: mixerNode, format: format)
    }

    /// Connect this voice's mixer to a destination node
    func connect(to destination: AVAudioNode, engine: AVAudioEngine, format: AVAudioFormat) {
        engine.connect(mixerNode, to: destination, format: format)
    }

    func play(buffer: AVAudioPCMBuffer, gain: Float, pitch: Float) {
        playerNode.stop()
        varispeedNode.rate = pitch
        mixerNode.outputVolume = gain
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        playerNode.play()
        startTime = mach_absolute_time()
        isActive = true

        // Auto-mark inactive after buffer duration + margin
        let duration = Double(buffer.frameLength) / buffer.format.sampleRate
        let rampOut = 0.02  // 20ms ramp out
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + duration + rampOut) { [weak self] in
            self?.isActive = false
        }
    }

    func steal() {
        // Quick ramp down then stop
        mixerNode.outputVolume = 0
        playerNode.stop()
        isActive = false
    }
}

/// Pool of voices with round-robin allocation and oldest-steal
final class VoicePool {
    let voices: [Voice]
    private var nextIndex: Int = 0
    private let lock = NSLock()

    init(size: Int) {
        voices = (0..<size).map { _ in Voice() }
    }

    func attachAll(to engine: AVAudioEngine, format: AVAudioFormat) {
        for voice in voices {
            voice.attach(to: engine, format: format)
        }
    }

    func connectAll(to destination: AVAudioNode, engine: AVAudioEngine, format: AVAudioFormat) {
        for voice in voices {
            voice.connect(to: destination, engine: engine, format: format)
        }
    }

    /// Get next available voice, stealing oldest if all busy
    func acquire() -> Voice {
        lock.lock()
        defer { lock.unlock() }

        // Try to find idle voice starting from nextIndex
        for offset in 0..<voices.count {
            let idx = (nextIndex + offset) % voices.count
            if !voices[idx].isActive {
                nextIndex = (idx + 1) % voices.count
                return voices[idx]
            }
        }

        // All busy — steal oldest
        var oldestIdx = 0
        var oldestTime: UInt64 = .max
        for (i, voice) in voices.enumerated() {
            if voice.startTime < oldestTime {
                oldestTime = voice.startTime
                oldestIdx = i
            }
        }

        let stolen = voices[oldestIdx]
        stolen.steal()
        nextIndex = (oldestIdx + 1) % voices.count
        return stolen
    }
}
