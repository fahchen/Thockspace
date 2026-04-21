import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var isDropTargeted = false

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

                HStack(spacing: 8) {
                    Button {
                        openWindow(id: "stats")
                    } label: {
                        Label("Stats", systemImage: "chart.bar.doc.horizontal")
                    }
                    .buttonStyle(.glass)

                    Button("Manage Packs…") {
                        openWindow(id: "manage-packs")
                    }
                    .buttonStyle(.glass)

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.glass)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .glassPanel()
        .frame(minWidth: 320)
        .fixedSize(horizontal: true, vertical: true)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: Theme.Metric.panelCorner)
                    .strokeBorder(Theme.Accent.primary, lineWidth: 2)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
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
            HStack {
                Text("Sound Profile")
                    .font(.sectionLabel)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Drop folder to import")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
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

    // MARK: - Drop handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            Task { @MainActor in
                _ = PackImporter.importPack(from: url, library: appState.library)
            }
        }
        return true
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
