import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    private func showWindow(id: String) {
        openWindow(id: id)
        // Popover buttons look "inactive" when a new key window takes focus.
        // Activating the whole app keeps both popover and new window vibrant;
        // promoting the named window to key makes it jump to front reliably.
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            if let win = NSApp.windows.first(where: { $0.identifier?.rawValue == id }) {
                win.makeKeyAndOrderFront(nil)
                win.orderFrontRegardless()
            }
        }
    }

    var body: some View {
        GlassEffectContainer(spacing: Theme.Metric.sectionSpacing) {
            VStack(alignment: .leading, spacing: Theme.Metric.sectionSpacing) {
                header

                profilePicker
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassSection()

                volumeRow
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassSection()

                togglesRow
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassSection()

                PermissionStatusView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassChip()

                HStack(spacing: 8) {
                    Button("Manage Packs…") {
                        showWindow(id: "manage-packs")
                    }
                    .buttonStyle(.glass)

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.glass)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: 272)
        }
        .glassPanel()
        .fixedSize(horizontal: false, vertical: true)
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
            Button {
                showWindow(id: "stats")
            } label: {
                Image(systemName: "square.grid.3x3.fill")
            }
            .buttonStyle(.glass)
            .controlSize(.small)
            .help("Open Keystroke Stats")
        }
    }

    private var profilePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.rowSpacing) {
            Text("Sound Profile")
                .font(.sectionLabel)
                .foregroundStyle(.secondary)
            ForEach(appState.library.all) { entry in
                ProfileRow(
                    entry: entry,
                    isSelected: appState.selectedProfile == entry.id
                ) {
                    appState.selectedProfile = entry.id
                }
            }
        }
    }

    private var volumeRow: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.rowSpacing) {
            HStack {
                Text("Volume")
                    .font(.sectionLabel)
                    .foregroundStyle(.secondary)
                Spacer()
                if appState.isMuted {
                    Text("MUTED")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.Accent.muteActive)
                }
            }
            HStack(spacing: 10) {
                Button {
                    appState.isMuted.toggle()
                } label: {
                    Image(systemName: appState.isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .font(.body)
                        .foregroundStyle(appState.isMuted ? Theme.Accent.muteActive : .secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help(appState.isMuted ? "Unmute" : "Mute")

                Slider(value: $appState.masterVolume, in: 0...1)
                    .disabled(appState.isMuted)
                    .opacity(appState.isMuted ? 0.5 : 1)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var togglesRow: some View {
        VStack(spacing: Theme.Metric.rowSpacing) {
            toggleRow("Spatial Audio", isOn: $appState.spatialAudioEnabled)
            toggleRow("Pitch Variation", isOn: $appState.pitchJitterEnabled)
        }
        .font(.panelBody)
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

}

// MARK: - Profile row

private struct ProfileRow: View {
    let entry: PackEntry
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.Accent.primary : .secondary)
                Text(entry.displayName)
                    .font(.panelBody)
                    .foregroundStyle(.primary)
                if !entry.isBundled {
                    Text("custom")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(.secondary.opacity(0.12))
                        )
                }
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
