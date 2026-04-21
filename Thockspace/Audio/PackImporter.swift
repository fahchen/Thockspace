import AppKit
import Foundation

/// Handles drag-and-drop imports of sound packs into the managed Application
/// Support directory. Enforces BDR-0018 (tiered validation) and BDR-0015
/// (folder-name id with `-2`, `-3` suffix on collision).
enum PackImporter {
    struct ImportResult {
        let entry: PackEntry
        /// Non-fatal warnings. Currently emitted for .ogg-only / missing samples
        /// cases — import proceeds but some keys will be silent.
        let warnings: [String]
    }

    enum ImportError: Error {
        case notADirectory
        case missingConfig
        case unparseableConfig
        case missingRequiredFields
        case copyFailed(String)
    }

    /// Import a dropped folder. Performs structural validation first;
    /// on failure, presents an NSAlert and returns nil. On success, copies
    /// the folder to the managed directory with a collision-safe name,
    /// refreshes the library, and returns the new entry plus any partial-error
    /// warnings (see validatePartial).
    @MainActor
    static func importPack(from source: URL, library: PackLibrary) -> ImportResult? {
        // Structural validation — reject wholesale on any failure
        if let err = MechvibesLoader.validateStructure(at: source) {
            presentAlert(for: err, source: source)
            return nil
        }

        // Resolve a unique destination id
        let baseID = source.lastPathComponent
        let destID = uniqueID(baseID: baseID, in: PackLibrary.importedPacksDirectory)
        let destURL = PackLibrary.importedPacksDirectory.appendingPathComponent(destID, isDirectory: true)

        do {
            try FileManager.default.copyItem(at: source, to: destURL)
        } catch {
            presentAlert(title: "Could not import pack",
                         message: "Failed to copy the folder: \(error.localizedDescription)")
            return nil
        }

        let warnings = validatePartial(at: destURL)
        let name = MechvibesLoader.readDisplayName(at: destURL) ?? destID
        let entry = PackEntry(id: destID, displayName: name, directory: destURL, isBundled: false)

        library.refresh()

        if !warnings.isEmpty {
            presentAlert(
                title: "Imported '\(name)' with warnings",
                message: warnings.joined(separator: "\n"),
                style: .warning
            )
        }

        return ImportResult(entry: entry, warnings: warnings)
    }

    /// Remove an imported pack. Returns true on success.
    @MainActor
    static func delete(_ entry: PackEntry, library: PackLibrary) -> Bool {
        guard !entry.isBundled else { return false }
        do {
            try FileManager.default.removeItem(at: entry.directory)
            library.refresh()
            return true
        } catch {
            presentAlert(title: "Could not delete pack",
                         message: "\(entry.displayName): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Internals

    private static func uniqueID(baseID: String, in root: URL) -> String {
        let fm = FileManager.default
        if !fm.fileExists(atPath: root.appendingPathComponent(baseID).path) {
            return baseID
        }
        var suffix = 2
        while fm.fileExists(atPath: root.appendingPathComponent("\(baseID)-\(suffix)").path) {
            suffix += 1
        }
        return "\(baseID)-\(suffix)"
    }

    /// Scan the copied pack for referenced samples that did not load. Returns
    /// a list of human-readable warning strings (empty on a clean pack).
    private static func validatePartial(at directory: URL) -> [String] {
        let configURL = directory.appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        var missing = Set<String>()
        // Check `defines` file references (multi mode)
        if let defines = json["defines"] as? [String: Any] {
            for (_, value) in defines {
                guard let fileName = value as? String else { continue }
                for expanded in expandPattern(fileName) {
                    let path = directory.appendingPathComponent(expanded).path
                    if !FileManager.default.fileExists(atPath: path) {
                        missing.insert(expanded)
                    }
                }
            }
        }
        // Default sound (single mode and multi fallback)
        if let sound = json["sound"] as? String {
            for expanded in expandPattern(sound) {
                let path = directory.appendingPathComponent(expanded).path
                if !FileManager.default.fileExists(atPath: path) {
                    missing.insert(expanded)
                }
            }
        }

        var warnings: [String] = []
        if !missing.isEmpty {
            let lower = missing.sorted().prefix(3).joined(separator: ", ")
            let more = missing.count > 3 ? " (+\(missing.count - 3) more)" : ""
            warnings.append("\(missing.count) referenced sample files are missing: \(lower)\(more)")
        }
        return warnings
    }

    private static func expandPattern(_ pattern: String) -> [String] {
        guard let range = pattern.range(of: #"\{(\d+)-(\d+)\}"#, options: .regularExpression) else {
            return [pattern]
        }
        let match = pattern[range]
        let inner = match.dropFirst().dropLast()
        let parts = inner.split(separator: "-")
        guard parts.count == 2, let lo = Int(parts[0]), let hi = Int(parts[1]) else {
            return [pattern]
        }
        return (lo...hi).map { pattern.replacingCharacters(in: range, with: String($0)) }
    }

    // MARK: - Alerts

    @MainActor
    private static func presentAlert(
        for err: MechvibesLoader.StructuralError,
        source: URL
    ) {
        let name = source.lastPathComponent
        switch err {
        case .notADirectory:
            presentAlert(title: "Not a pack folder",
                         message: "\(name) is not a folder. Drop a folder that contains a config.json and sample files.")
        case .missingConfig:
            presentAlert(title: "Missing config.json",
                         message: "\(name) has no config.json at its top level.")
        case .unparseableConfig:
            presentAlert(title: "Invalid config.json",
                         message: "The config.json in \(name) could not be parsed as JSON.")
        case .missingRequiredFields:
            presentAlert(title: "Incomplete config.json",
                         message: "The config.json in \(name) has neither `sound` nor `defines` — nothing to load.")
        }
    }

    @MainActor
    private static func presentAlert(
        title: String,
        message: String,
        style: NSAlert.Style = .warning
    ) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }
}

extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
