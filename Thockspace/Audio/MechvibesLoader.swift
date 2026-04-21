import AVFoundation
import Foundation

/// Loaded sound profile: maps Mechvibes scancodes to audio buffers
struct SoundProfile {
    /// Per-scancode buffers. Key = Mechvibes scancode. Value = (down buffers, up buffers)
    /// Multiple buffers for random selection (e.g. GENERIC_R{0-4})
    var keyBuffers: [Int: (down: [AVAudioPCMBuffer], up: [AVAudioPCMBuffer])] = [:]
    /// Default buffers for keys not in the map
    var defaultDown: [AVAudioPCMBuffer] = []
    var defaultUp: [AVAudioPCMBuffer] = []

    func randomDown(for scancode: Int) -> AVAudioPCMBuffer? {
        if let entry = keyBuffers[scancode], !entry.down.isEmpty {
            return entry.down.randomElement()
        }
        return defaultDown.randomElement()
    }

    func randomUp(for scancode: Int) -> AVAudioPCMBuffer? {
        if let entry = keyBuffers[scancode], !entry.up.isEmpty {
            return entry.up.randomElement()
        }
        return defaultUp.randomElement()
    }
}

enum MechvibesLoader {
    private static let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!

    /// Load a profile from an arbitrary directory URL (bundled or imported).
    static func loadProfile(at directory: URL) -> SoundProfile? {
        let configURL = directory.appendingPathComponent("config.json")
        guard let configData = try? Data(contentsOf: configURL),
              let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
            print("[Thockspace] config.json not found or invalid at \(directory.path)")
            return nil
        }

        let defineType = config["key_define_type"] as? String ?? "multi"
        let version = config["version"] as? Int ?? 1

        if defineType == "single" {
            return loadSingleProfile(config: config, directory: directory)
        } else {
            return loadMultiProfile(config: config, directory: directory, version: version)
        }
    }

    /// Read the `name` field from a pack's config.json. Used for display name.
    static func readDisplayName(at directory: URL) -> String? {
        let configURL = directory.appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return (json["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
    }

    /// Validate a candidate import directory. Returns .ok on structural success
    /// (config.json present and parseable with a `defines` or `sound` block) or
    /// a specific error case otherwise. Matches BDR-0018.
    enum StructuralError: Error {
        case notADirectory
        case missingConfig
        case unparseableConfig
        case missingRequiredFields
    }

    static func validateStructure(at directory: URL) -> StructuralError? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir),
              isDir.boolValue else {
            return .notADirectory
        }
        let configURL = directory.appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return .missingConfig
        }
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unparseableConfig
        }
        if json["sound"] == nil && json["defines"] == nil {
            return .missingRequiredFields
        }
        return nil
    }

    // MARK: - Multi mode (v2): individual files per key

    private static func loadMultiProfile(config: [String: Any], directory: URL, version: Int) -> SoundProfile {
        var profile = SoundProfile()
        let defines = config["defines"] as? [String: Any] ?? [:]

        // Load default sound(s) — handles {min-max} syntax
        if let defaultSound = config["sound"] as? String {
            profile.defaultDown = expandAndLoad(pattern: defaultSound, directory: directory)
        }
        if let defaultUpSound = config["soundup"] as? String {
            profile.defaultUp = expandAndLoad(pattern: defaultUpSound, directory: directory)
        }

        // Collect down and up defines separately
        var downDefines: [Int: String] = [:]
        var upDefines: [Int: String] = [:]

        for (key, value) in defines {
            guard let fileName = value as? String else { continue }

            if key.hasSuffix("-up") {
                let scancodeStr = String(key.dropLast(3))
                if let scancode = Int(scancodeStr) {
                    upDefines[scancode] = fileName
                }
            } else {
                if let scancode = Int(key) {
                    downDefines[scancode] = fileName
                }
            }
        }

        // Merge into keyBuffers
        let allScancodes = Set(downDefines.keys).union(upDefines.keys)
        for scancode in allScancodes {
            let downBufs = downDefines[scancode].map { expandAndLoad(pattern: $0, directory: directory) } ?? []
            let upBufs = upDefines[scancode].map { expandAndLoad(pattern: $0, directory: directory) } ?? []
            if !downBufs.isEmpty || !upBufs.isEmpty {
                profile.keyBuffers[scancode] = (down: downBufs, up: upBufs)
            }
        }

        return profile
    }

    /// Expand `{min-max}` patterns and load all matching files
    private static func expandAndLoad(pattern: String, directory: URL) -> [AVAudioPCMBuffer] {
        let fileNames = expandPattern(pattern)
        return fileNames.compactMap { name in
            let url = directory.appendingPathComponent(name)
            return loadWavBuffer(url: url)
        }
    }

    /// Expand "GENERIC_R{0-4}.wav" → ["GENERIC_R0.wav", "GENERIC_R1.wav", ...]
    private static func expandPattern(_ pattern: String) -> [String] {
        guard let range = pattern.range(of: #"\{(\d+)-(\d+)\}"#, options: .regularExpression) else {
            return [pattern]
        }

        let match = pattern[range]
        let inner = match.dropFirst().dropLast() // remove { }
        let parts = inner.split(separator: "-")
        guard parts.count == 2, let lo = Int(parts[0]), let hi = Int(parts[1]) else {
            return [pattern]
        }

        return (lo...hi).map { i in
            pattern.replacingCharacters(in: range, with: String(i))
        }
    }

    // MARK: - Single mode (v1): one audio file + sprite defines [startMs, durationMs]

    private static func loadSingleProfile(config: [String: Any], directory: URL) -> SoundProfile {
        var profile = SoundProfile()
        let defines = config["defines"] as? [String: Any] ?? [:]

        guard let soundFile = config["sound"] as? String else {
            print("[Thockspace] Single-mode profile missing 'sound' key")
            return profile
        }

        let soundURL = directory.appendingPathComponent(soundFile)
        guard let fullBuffer = loadWavBuffer(url: soundURL) else {
            print("[Thockspace] Failed to load main sound file: \(soundFile)")
            return profile
        }

        let sampleRate = fullBuffer.format.sampleRate

        for (scancodeStr, value) in defines {
            guard let scancode = Int(scancodeStr) else { continue }

            // Value is [startMs, durationMs]
            if let segment = value as? [Any], let seg = parseTimePair(segment) {
                let startMs = seg.0
                let durationMs = seg.1
                let endMs = startMs + durationMs

                if let buf = extractSegment(from: fullBuffer, startMs: startMs, endMs: endMs, sampleRate: sampleRate) {
                    profile.keyBuffers[scancode] = (down: [buf], up: [])
                }
            }
        }

        return profile
    }

    private static func parseTimePair(_ arr: [Any]) -> (Double, Double)? {
        guard arr.count >= 2 else { return nil }
        let a: Double
        let b: Double

        if let v = arr[0] as? Double { a = v }
        else if let v = arr[0] as? Int { a = Double(v) }
        else { return nil }

        if let v = arr[1] as? Double { b = v }
        else if let v = arr[1] as? Int { b = Double(v) }
        else { return nil }

        return (a, b)
    }

    private static func extractSegment(
        from buffer: AVAudioPCMBuffer,
        startMs: Double,
        endMs: Double,
        sampleRate: Double
    ) -> AVAudioPCMBuffer? {
        let startFrame = AVAudioFramePosition(startMs / 1000.0 * sampleRate)
        let endFrame = AVAudioFramePosition(endMs / 1000.0 * sampleRate)
        let frameCount = AVAudioFrameCount(max(0, endFrame - startFrame))

        guard frameCount > 0,
              startFrame >= 0,
              AVAudioFrameCount(startFrame) + frameCount <= buffer.frameLength else {
            return nil
        }

        guard let segment = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: frameCount) else {
            return nil
        }

        segment.frameLength = frameCount

        if let srcData = buffer.floatChannelData?[0],
           let dstData = segment.floatChannelData?[0] {
            dstData.update(from: srcData.advanced(by: Int(startFrame)), count: Int(frameCount))
        }

        return segment
    }

    // MARK: - WAV loading

    static func loadWavBuffer(url: URL) -> AVAudioPCMBuffer? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let file = try AVAudioFile(forReading: url)
            let frameCount = AVAudioFrameCount(file.length)

            if file.processingFormat.channelCount == monoFormat.channelCount
                && file.processingFormat.sampleRate == monoFormat.sampleRate {
                // Format matches — direct read
                guard let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: frameCount) else { return nil }
                try file.read(into: buffer)
                return buffer
            }

            // Need conversion
            let srcBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount)!
            try file.read(into: srcBuffer)

            guard let converter = AVAudioConverter(from: file.processingFormat, to: monoFormat) else { return nil }
            let outCapacity = AVAudioFrameCount(Double(frameCount) * monoFormat.sampleRate / file.processingFormat.sampleRate) + 100
            guard let outBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: outCapacity) else { return nil }

            var error: NSError?
            converter.convert(to: outBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return srcBuffer
            }

            return error == nil ? outBuffer : nil
        } catch {
            print("[Thockspace] Failed to load \(url.lastPathComponent): \(error)")
            return nil
        }
    }
}
