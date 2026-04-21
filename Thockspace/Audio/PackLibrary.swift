import Foundation
import SwiftUI

/// A single sound pack the user can select in the profile picker.
struct PackEntry: Identifiable, Hashable {
    /// Directory name; also used as `AppStorage selectedProfile` value.
    let id: String
    let displayName: String
    let directory: URL
    let isBundled: Bool
}

/// Catalog of sound packs currently visible to the app.
/// Bundled packs ship inside the app bundle at `Resources/sounds/<id>/`.
/// Imported packs live in `~/Library/Application Support/Thockspace/packs/<id>/`.
@MainActor
final class PackLibrary: ObservableObject {
    @Published private(set) var bundled: [PackEntry] = []
    @Published private(set) var imported: [PackEntry] = []

    /// Fixed order for the three bundled packs — matches the order in spec.md
    /// and the prior hard-coded list in SettingsView.
    private static let bundledIDs: [(id: String, fallbackName: String)] = [
        ("cherry-mx-blue", "Cherry MX Blue"),
        ("holy-panda", "Holy Panda"),
        ("cherry-mx-red", "Cherry MX Red"),
    ]

    init() {
        refresh()
    }

    /// All packs in display order: bundled (fixed order) then imported (alphabetical).
    var all: [PackEntry] {
        bundled + imported
    }

    func entry(forID id: String) -> PackEntry? {
        all.first { $0.id == id }
    }

    /// Full path to the packs root in Application Support. Creates it if missing.
    static var importedPacksDirectory: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = appSupport
            .appendingPathComponent("Thockspace", isDirectory: true)
            .appendingPathComponent("packs", isDirectory: true)
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// Re-scan both sources. Call after import/delete.
    func refresh() {
        bundled = Self.bundledIDs.compactMap { pair in
            guard let url = Bundle.main.url(
                forResource: pair.id,
                withExtension: nil,
                subdirectory: "sounds"
            ) else {
                return nil
            }
            let name = MechvibesLoader.readDisplayName(at: url) ?? pair.fallbackName
            return PackEntry(id: pair.id, displayName: name, directory: url, isBundled: true)
        }
        imported = Self.scanImported()
    }

    private static func scanImported() -> [PackEntry] {
        let root = importedPacksDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        let entries: [PackEntry] = contents.compactMap { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            guard isDir.boolValue else { return nil }
            let id = url.lastPathComponent
            let name = MechvibesLoader.readDisplayName(at: url) ?? id
            return PackEntry(id: id, displayName: name, directory: url, isBundled: false)
        }
        return entries.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
