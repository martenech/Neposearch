import AppKit
import Foundation
import Observation

/// Nainštalovaná aplikácia, ktorú vie spúšťač otvoriť.
struct AppEntry: Sendable, Hashable {
    let name: String
    let path: String
    /// Lokalizovaný aj anglický názov, malými písmenami bez diakritiky.
    let searchNames: [String]

    var url: URL { URL(fileURLWithPath: path) }
}

/// Zoznam aplikácií na Macu a ich hľadanie podľa názvu.
@MainActor @Observable
final class AppCatalog {
    private(set) var apps: [AppEntry] = []
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var isLoading = false
    @ObservationIgnored private let defaults = UserDefaults.standard

    /// Načíta aplikácie na pozadí, ak ešte nie sú, alebo ak sú staršie ako 5 minút.
    func refreshIfNeeded() {
        guard !isLoading, loadedAt.map({ Date().timeIntervalSince($0) > 300 }) ?? true else { return }
        isLoading = true
        Task {
            let apps = await Task.detached(priority: .utility) { Self.scan() }.value
            self.apps = apps
            loadedAt = Date()
            isLoading = false
        }
    }

    /// Najlepšie zhody pre dotaz; často spúšťané aplikácie sú vyššie.
    func search(_ query: String, limit: Int = 5) -> [AppEntry] {
        let q = IndexedFile.normalize(query.trimmingCharacters(in: .whitespaces))
        guard !q.isEmpty else { return [] }
        let launches = defaults.dictionary(forKey: "appLaunches") as? [String: Int] ?? [:]
        var scored: [(app: AppEntry, score: Int)] = []
        for app in apps {
            guard let match = app.searchNames.compactMap({ Self.score(name: $0, query: q) }).max() else { continue }
            scored.append((app, match + min(launches[app.path] ?? 0, 20)))
        }
        return scored
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.app.name.count < $1.app.name.count }
            .prefix(limit)
            .map(\.app)
    }

    func recordLaunch(_ app: AppEntry) {
        var launches = defaults.dictionary(forKey: "appLaunches") as? [String: Int] ?? [:]
        launches[app.path, default: 0] += 1
        defaults.set(launches, forKey: "appLaunches")
    }

    /// Celý názov > začiatok názvu > začiatok slova > skratka z počiatočných písmen > kdekoľvek v názve.
    static func score(name: String, query: String) -> Int? {
        if name == query { return 100 }
        if name.hasPrefix(query) { return 90 }
        let words = name.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(query) }) { return 80 }
        if query.count >= 2, String(words.compactMap(\.first)).hasPrefix(query) { return 70 }
        if query.count >= 3, name.contains(query) { return 50 }
        return nil
    }

    nonisolated private static func scan() -> [AppEntry] {
        let home = NSHomeDirectory()
        let folders = [
            "/Applications", "/Applications/Utilities", "\(home)/Applications",
            "/System/Applications", "/System/Applications/Utilities",
        ]
        var paths: [String] = ["/System/Library/CoreServices/Finder.app"]
        let fm = FileManager.default
        for folder in folders {
            guard let items = try? fm.contentsOfDirectory(atPath: folder) else { continue }
            for item in items where !item.hasPrefix(".") {
                let path = (folder as NSString).appendingPathComponent(item)
                if item.hasSuffix(".app") {
                    paths.append(path)
                } else if folder == "/Applications" || folder == "\(home)/Applications",
                    let inner = try? fm.contentsOfDirectory(atPath: path)
                {
                    // Aplikácie v podpriečinkoch (napr. /Applications/Setapp).
                    paths += inner.filter { $0.hasSuffix(".app") }.map { (path as NSString).appendingPathComponent($0) }
                }
            }
        }

        var seen = Set<String>()
        var result: [AppEntry] = []
        for path in paths where fm.fileExists(atPath: path) {
            let bundle = Bundle(path: path)
            let id = bundle?.bundleIdentifier ?? path
            guard seen.insert(id).inserted else { continue }
            let displayName = fm.displayName(atPath: path).replacingOccurrences(of: ".app", with: "")
            let info = bundle?.infoDictionary
            let names = [displayName, info?["CFBundleDisplayName"] as? String, info?["CFBundleName"] as? String,
                         ((path as NSString).lastPathComponent as NSString).deletingPathExtension]
                .compactMap { $0 }
                .map(IndexedFile.normalize)
            result.append(AppEntry(name: displayName, path: path, searchNames: Array(Set(names))))
        }
        return result
    }
}
