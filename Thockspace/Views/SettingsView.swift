import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    private let profiles = [
        ("cherry-mx-blue", "Cherry MX Blue"),
        ("holy-panda", "Holy Panda"),
        ("cherry-mx-red", "Cherry MX Red"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .font(.title2)
                Text("Thockspace")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Profile picker
            Picker("Sound Profile", selection: $appState.selectedProfile) {
                ForEach(profiles, id: \.0) { id, name in
                    Text(name).tag(id)
                }
            }
            .pickerStyle(.inline)

            Divider()

            // Volume
            VStack(alignment: .leading, spacing: 4) {
                Text("Volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $appState.masterVolume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Toggles
            Toggle("Spatial Audio", isOn: $appState.spatialAudioEnabled)
            Toggle("Pitch Variation", isOn: $appState.pitchJitterEnabled)

            Divider()

            // Mute
            Button(action: { appState.isMuted.toggle() }) {
                HStack {
                    Image(systemName: appState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    Text(appState.isMuted ? "Unmute" : "Mute")
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(appState.isMuted ? .red : .accentColor)

            Divider()

            // Permission status
            PermissionStatusView()

            Divider()

            // Quit
            Button("Quit Thockspace") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .fixedSize()
    }
}

struct PermissionStatusView: View {
    @State private var hasPermission = PermissionManager.hasInputMonitoringPermission()

    var body: some View {
        HStack {
            Image(systemName: hasPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(hasPermission ? .green : .orange)
            Text(hasPermission ? "Input Monitoring granted" : "Input Monitoring required")
                .font(.caption)
            Spacer()
            if !hasPermission {
                Button("Open Settings") {
                    PermissionManager.openInputMonitoringSettings()
                }
                .font(.caption)
                .controlSize(.small)
            }
        }
    }
}
