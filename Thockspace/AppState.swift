import SwiftUI
import Combine

final class AppState: ObservableObject {
    @AppStorage("selectedProfile") var selectedProfile: String = "cherry-mx-blue"
    @AppStorage("masterVolume") var masterVolume: Double = 0.8
    @AppStorage("spatialAudioEnabled") var spatialAudioEnabled: Bool = true
    @AppStorage("pitchJitterEnabled") var pitchJitterEnabled: Bool = true
    @AppStorage("isMuted") var isMuted: Bool = false

    private var audioEngine: AudioEngine?
    private var keyEventTap: KeyEventTap?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAudioEngine()
        setupKeyEventTap()
        observeSettings()
    }

    private func setupAudioEngine() {
        audioEngine = AudioEngine()
        audioEngine?.masterVolume = Float(masterVolume)
        audioEngine?.spatialAudioEnabled = spatialAudioEnabled
        audioEngine?.pitchJitterEnabled = pitchJitterEnabled
        audioEngine?.isMuted = isMuted
        audioEngine?.loadProfile(named: selectedProfile)
        audioEngine?.start()
    }

    private func setupKeyEventTap() {
        keyEventTap = KeyEventTap { [weak self] keyCode, isDown in
            self?.audioEngine?.play(macKeyCode: keyCode, isDown: isDown)
        }
        keyEventTap?.start()
    }

    private func observeSettings() {
        // Watch for changes via objectWillChange and re-sync
        // Using a timer-based approach since @AppStorage doesn't publish through Combine
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncSettings()
            }
            .store(in: &cancellables)
    }

    private var lastSyncedProfile: String = ""
    private var lastSyncedVolume: Double = -1
    private var lastSyncedSpatial: Bool?
    private var lastSyncedJitter: Bool?
    private var lastSyncedMute: Bool?

    private func syncSettings() {
        guard let engine = audioEngine else { return }

        if selectedProfile != lastSyncedProfile {
            lastSyncedProfile = selectedProfile
            engine.loadProfile(named: selectedProfile)
        }
        if masterVolume != lastSyncedVolume {
            lastSyncedVolume = masterVolume
            engine.masterVolume = Float(masterVolume)
        }
        if spatialAudioEnabled != lastSyncedSpatial {
            lastSyncedSpatial = spatialAudioEnabled
            engine.spatialAudioEnabled = spatialAudioEnabled
        }
        if pitchJitterEnabled != lastSyncedJitter {
            lastSyncedJitter = pitchJitterEnabled
            engine.pitchJitterEnabled = pitchJitterEnabled
        }
        if isMuted != lastSyncedMute {
            lastSyncedMute = isMuted
            engine.isMuted = isMuted
        }
    }
}
