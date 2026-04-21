import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    private let profiles = [
        ("cherry-mx-blue", "Cherry MX Blue"),
        ("holy-panda", "Holy Panda"),
        ("cherry-mx-red", "Cherry MX Red"),
    ]

    var body: some View {
        GlassEffectContainer(spacing: Theme.Metric.sectionSpacing) {
            VStack(alignment: .leading, spacing: Theme.Metric.sectionSpacing) {
                header

                profilePicker
                    .glassSection()

                volumeRow
                    .glassSection()

                togglesRow
                    .glassSection()

                muteButton

                PermissionStatusView()
                    .glassChip()

                Button("Quit Thockspace") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.glass)
                .frame(maxWidth: .infinity)
            }
        }
        .glassPanel()
        .frame(minWidth: 300)
        .fixedSize(horizontal: true, vertical: true)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard")
                .font(.title3)
                .foregroundStyle(Theme.Accent.primary)
            Text("Thockspace")
                .font(.panelTitle)
            Spacer()
        }
    }

    private var profilePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.rowSpacing) {
            Text("Sound Profile")
                .font(.sectionLabel)
                .foregroundStyle(.secondary)
            ForEach(profiles, id: \.0) { id, name in
                ProfileRow(
                    id: id,
                    name: name,
                    isSelected: appState.selectedProfile == id
                ) {
                    appState.selectedProfile = id
                }
            }
        }
    }

    private var volumeRow: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.rowSpacing) {
            Text("Volume")
                .font(.sectionLabel)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $appState.masterVolume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var togglesRow: some View {
        VStack(spacing: Theme.Metric.rowSpacing) {
            Toggle("Spatial Audio", isOn: $appState.spatialAudioEnabled)
            Toggle("Pitch Variation", isOn: $appState.pitchJitterEnabled)
        }
        .font(.panelBody)
        .toggleStyle(.switch)
    }

    private var muteButton: some View {
        Button(action: { appState.isMuted.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: appState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                Text(appState.isMuted ? "Unmute" : "Mute")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(appState.isMuted ? Theme.Accent.muteActive : Theme.Accent.primary)
        .controlSize(.large)
    }
}

// MARK: - Profile row

private struct ProfileRow: View {
    let id: String
    let name: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.Accent.primary : .secondary)
                Text(name)
                    .font(.panelBody)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }
}

// MARK: - Permission status

struct PermissionStatusView: View {
    @State private var hasPermission = PermissionManager.hasInputMonitoringPermission()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: hasPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(hasPermission ? .green : .orange)
            Text(hasPermission ? "Input Monitoring granted" : "Input Monitoring required")
                .font(.caption)
            Spacer()
            if !hasPermission {
                Button("Open Settings") {
                    PermissionManager.openInputMonitoringSettings()
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
        }
    }
}
