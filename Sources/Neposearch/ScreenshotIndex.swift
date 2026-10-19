import AppKit
import ObjectBox
import Observation

/// Index snímok obrazovky: rozpozná text (OCR, lokálne cez Vision) a umožní hľadať podľa neho.
@MainActor @Observable
final class ScreenshotIndex {
    private(set) var count = 0
    private(set) var isIndexing = false

    @ObservationIgnored private let box: Box<ScreenshotItem>
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var rescanTask: Task<Void, Never>?

    init(database: Database, settings: AppSettings) {
        box = database.store.box(for: ScreenshotItem.self)
        self.settings = settings
        count = (try? box.count()) ?? 0
        start()
    }

    /// Priečinok, kam macOS ukladá snímky obrazovky (predvolene Plocha).
    static var folder: URL {
        let configured = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location")
        let path = (configured.map { ($0 as NSString).expandingTildeInPath }) ?? (NSHomeDirectory() + "/Desktop")
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    func start() {
        watcher = nil
        rescanTask?.cancel()
        guard settings.screenshotsEnabled else { return }
        let folder = Self.folder
        watcher = FileWatcher(path: folder.path) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRescan() }
        }
        scheduleRescan(delay: 0)
    }

    private func scheduleRescan(delay: Double = 2) {
        rescanTask?.cancel()
        rescanTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await rescan()
        }
    }

    /// Nové snímky prečíta, zmazané odstráni.
    private func rescan() async {
        isIndexing = true
        defer { isIndexing = false }
        let folder = Self.folder
        let found = await Task.detached(priority: .utility) { Self.screenshots(in: folder) }.value
        let known = Dictionary(((try? box.all()) ?? []).map { ($0.path, $0) }, uniquingKeysWith: { a, _ in a })

        let paths = Set(found.map(\.path))
        let removed = known.values.filter { $0.path.hasPrefix(folder.path) && !paths.contains($0.path) }
        if !removed.isEmpty { _ = try? box.remove(removed.map(\.id)) }

        for file in found.sorted(by: { $0.modified > $1.modified }) {
            guard !Task.isCancelled else { break }
            if let existing = known[file.path], abs(existing.modifiedAt.timeIntervalSince(file.modified)) < 1 { continue }
            let url = URL(fileURLWithPath: file.path)
            let text = await Task.detached(priority: .utility) { (try? TextExtractor.extract(from: url)) ?? "" }.value
            let item = known[file.path] ?? ScreenshotItem()
            item.path = file.path
            item.createdAt = file.created
            item.modifiedAt = file.modified
            item.text = text
            item.searchKey = IndexedFile.normalize("\(url.deletingPathExtension().lastPathComponent) \(text)")
            _ = try? box.put(item)
        }
        count = (try? box.count()) ?? 0
    }

    /// Snímky obsahujúce všetky hľadané slová, najnovšie prvé. Bez dotazu najnovšie snímky.
    func search(_ query: String, limit: Int) -> [ScreenshotItem] {
        _ = count
        let terms = IndexedFile.searchTerms(query)
        let builder: QueryBuilder<ScreenshotItem>
        if let first = terms.first {
            builder = box.query {
                terms.dropFirst().reduce(ScreenshotItem.searchKey.contains(first) as QueryCondition<ScreenshotItem>) {
                    $0 && ScreenshotItem.searchKey.contains($1)
                }
            }
        } else {
            builder = box.query()
        }
        return (try? builder.ordered(by: ScreenshotItem.createdAt, flags: .descending).build().find(offset: 0, limit: limit)) ?? []
    }

    // MARK: - Hľadanie snímok na disku

    private struct Found: Sendable {
        let path: String
        let created: Date
        let modified: Date
    }

    nonisolated private static func screenshots(in folder: URL) -> [Found] {
        let keys: [URLResourceKey] = [.creationDateKey, .contentModificationDateKey, .isRegularFileKey]
        // Snímky priamo v priečinku a v jeho podpriečinku „Screenshots“/„Snímky obrazovky“.
        let folders = [folder, folder.appendingPathComponent("Screenshots"), folder.appendingPathComponent("Snímky obrazovky")]
        var result: [Found] = []
        for dir in folders {
            let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])) ?? []
            for url in items where ["png", "jpg", "jpeg", "heic"].contains(url.pathExtension.lowercased()) {
                guard isScreenshot(url), let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { continue }
                result.append(Found(
                    path: url.path, created: values.creationDate ?? .distantPast, modified: values.contentModificationDate ?? .distantPast))
            }
        }
        return result
    }

    /// Spotlight značka „snímka obrazovky“, alebo typický názov súboru.
    nonisolated private static func isScreenshot(_ url: URL) -> Bool {
        if let item = MDItemCreateWithURL(nil, url as CFURL),
            let value = MDItemCopyAttribute(item, "kMDItemIsScreenCapture" as CFString) as? Bool
        {
            return value
        }
        let name = url.lastPathComponent.lowercased()
        return ["snímka obrazovky", "snimka obrazovky", "screenshot", "snímek obrazovky", "bildschirmfoto"].contains { name.hasPrefix($0) }
    }
}
