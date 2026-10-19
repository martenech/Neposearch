import Foundation

/// Prehľadanie priečinka a rozhodnutie, ktoré súbory treba (znova) spracovať. Beží na pozadí.
enum FileScanner {
    /// Priečinky, ktoré nemá zmysel indexovať (systémové dáta, závislosti, buildy).
    static let excludedDirectories: Set<String> = [
        "Library", "Applications", "node_modules", "DerivedData", "Pods", "Carthage",
        "venv", "__pycache__", "site-packages", "Caches", "build", "dist", "target", "vendor",
        // Médiá: dokumenty v nich nie sú a macOS by pýtal prístup k hudobnej knižnici.
        "Music", "Movies",
    ]

    struct Plan: Sendable {
        /// Cesty na spracovanie, najnovšie ako prvé.
        var toProcess: [String]
    }

    /// Rýchly filter pre cesty z FSEvents.
    static func shouldIndex(path: String, extensions: Set<String>) -> Bool {
        let components = path.split(separator: "/")
        if components.contains(where: { $0.hasPrefix(".") || excludedDirectories.contains(String($0)) }) { return false }
        return extensions.contains((path as NSString).pathExtension.lowercased())
    }

    /// Porovná súbory na disku s indexom: nové a zmenené vráti na spracovanie, zmazané odstráni z DB.
    /// Súbory s vypnutými typmi sa z indexu tiež odstránia.
    static func plan(folder: String, extensions: Set<String>, db: Database) -> Plan {
        let onDisk = listFiles(in: folder, extensions: extensions)
        let known = (try? db.snapshot(under: folder)) ?? [:]
        var toProcess: [(path: String, modified: Date)] = []
        var seen = Set<String>()
        for file in onDisk {
            seen.insert(file.path)
            if let entry = known[file.path], !entry.needsProcessing(modified: file.modified, size: file.size) {
                continue
            }
            toProcess.append((file.path, file.modified))
        }
        let removed = known.filter { !seen.contains($0.key) }.map(\.value.id)
        if !removed.isEmpty { try? db.remove(ids: removed) }

        return Plan(toProcess: toProcess.sorted { $0.modified > $1.modified }.map(\.path))
    }

    private static func listFiles(in folder: String, extensions: Set<String>) -> [(path: String, modified: Date, size: Int64)] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .contentModificationDateKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: folder), includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants])
        else { return [] }
        var result: [(String, Date, Int64)] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isDirectory == true {
                if excludedDirectories.contains(url.lastPathComponent) { enumerator.skipDescendants() }
                continue
            }
            guard values.isRegularFile == true, extensions.contains(url.pathExtension.lowercased()) else { continue }
            result.append((url.path, values.contentModificationDate ?? .distantPast, Int64(values.fileSize ?? 0)))
        }
        return result
    }
}
