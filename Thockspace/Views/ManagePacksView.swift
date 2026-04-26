import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Dedicated window for listing and removing imported sound packs.
/// Bundled packs are not shown — they are not removable.
/// This window is also the drop target for importing new packs.
struct ManagePacksView: View {
    @EnvironmentObject var appState: AppState
    @State private var pendingDelete: PackEntry?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.sectionSpacing) {
            header

            if appState.library.imported.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                list
            }

            Spacer(minLength: 0)

            Text("Drag a pack folder anywhere in this window to import.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 460, minHeight: 320)
        .padding(.top, 28)
        .padding(.horizontal, Theme.Metric.panelPadding)
        .padding(.bottom, Theme.Metric.panelPadding)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: Theme.Metric.panelCorner)
                    .strokeBorder(Theme.Accent.primary, lineWidth: 3)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
        .confirmationDialog(
            confirmTitle,
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { entry in
            Button("Remove", role: .destructive) { confirmDelete(entry) }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { entry in
            Text(confirmMessage(for: entry))
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "tray.full")
                .font(.title3)
                .foregroundStyle(Theme.Accent.primary)
            Text("Manage Packs")
                .font(.panelTitle)
            Spacer()
            Text(countLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .glassChip()
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(appState.library.imported) { entry in
                    PackRow(entry: entry, isActive: entry.id == appState.selectedProfile) {
                        pendingDelete = entry
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            Text("No imported packs yet")
                .font(.panelBody)
                .foregroundStyle(.secondary)
        }
    }

    private var countLabel: String {
        let n = appState.library.imported.count
        return n == 1 ? "1 pack" : "\(n) packs"
    }

    private var confirmTitle: String {
        guard let entry = pendingDelete else { return "Remove pack" }
        return "Remove '\(entry.displayName)'?"
    }

    private func confirmMessage(for entry: PackEntry) -> String {
        if entry.id == appState.selectedProfile {
            return "This is your current pack. Thockspace will switch to Cherry MX Blue after removal."
        }
        return "This will delete the pack folder from your Library."
    }

    private func confirmDelete(_ entry: PackEntry) {
        let wasActive = (entry.id == appState.selectedProfile)
        if PackImporter.delete(entry, library: appState.library), wasActive {
            appState.selectedProfile = "cherry-mx-blue"
        }
        pendingDelete = nil
    }

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

private struct PackRow: View {
    let entry: PackEntry
    let isActive: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? Theme.Accent.primary : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.panelBody)
                Text(entry.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.glass)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .glassSection()
    }
}
