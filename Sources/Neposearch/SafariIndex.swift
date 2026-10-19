import AppKit
import Observation

struct WebPage: Hashable, Sendable, Identifiable {
    enum Kind: String, Sendable {
        case history, bookmark, readingList
    }

    let url: String
    let title: String
    let lastVisit: Date?
    let visitCount: Int
    let kind: Kind
    let searchKey: String

    var id: String { "\(kind.rawValue):\(url)" }
    var host: String { URL(string: url)?.host() ?? url }
}

/// História, záložky a Zoznam na čítanie zo Safari. Potrebuje Full Disk Access.
@MainActor @Observable
final class SafariIndex {
    private(set) var pages: [WebPage] = []
    private(set) var problem: String?

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadedAt: Date?

    nonisolated static let historyPath = NSHomeDirectory() + "/Library/Safari/History.db"
    nonisolated static let bookmarksPath = NSHomeDirectory() + "/Library/Safari/Bookmarks.plist"

    init(settings: AppSettings) {
        self.settings = settings
        refreshIfNeeded()
    }

    /// Načíta históriu najviac raz za 2 minúty (pri otvorení spúšťača).
    func refreshIfNeeded() {
        guard settings.safariEnabled else {
            pages = []
            return
        }
        guard loadTask == nil, loadedAt.map({ Date().timeIntervalSince($0) > 120 }) ?? true else { return }
        loadTask = Task {
            let result = await Task.detached(priority: .utility) { () -> Result<[WebPage], Error> in Result { try Self.load() } }.value
            switch result {
            case .success(let loaded):
                pages = loaded
                problem = nil
                loadedAt = Date()
            case .failure:
                problem = "Povoľ Neposearch v Nastaveniach → Súkromie a bezpečnosť → Úplný prístup k disku."
            }
            loadTask = nil
        }
    }

    nonisolated private static func load() throws -> [WebPage] {
        var result: [WebPage] = []
        // Záložky a Zoznam na čítanie prvé.
        if let data = FileManager.default.contents(atPath: bookmarksPath),
            let root = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        {
            func walk(_ node: [String: Any], readingList: Bool) {
                if node["WebBookmarkType"] as? String == "WebBookmarkTypeLeaf", let url = node["URLString"] as? String {
                    let title = (node["URIDictionary"] as? [String: Any])?["title"] as? String ?? url
                    result.append(WebPage(
                        url: url, title: title, lastVisit: nil, visitCount: 0, kind: readingList ? .readingList : .bookmark,
                        searchKey: IndexedFile.normalize("\(title) \(url)")))
                }
                for child in node["Children"] as? [[String: Any]] ?? [] {
                    walk(child, readingList: readingList || node["Title"] as? String == "com.apple.ReadingList")
                }
            }
            walk(root, readingList: false)
        }
        // História: posledná návšteva a názov každej adresy.
        let sql = """
            SELECT i.url, v.title, MAX(v.visit_time), i.visit_count
            FROM history_items i JOIN history_visits v ON v.history_item = i.id
            GROUP BY i.id ORDER BY MAX(v.visit_time) DESC LIMIT 20000
            """
        try SQLiteReader.query(historyPath, sql) { row in
            let url = row.string(0), title = row.string(1)
            result.append(WebPage(
                url: url, title: title.isEmpty ? url : title, lastVisit: Date(timeIntervalSinceReferenceDate: row.double(2)),
                visitCount: row.int(3), kind: .history, searchKey: IndexedFile.normalize("\(title) \(url)")))
        }
        return result
    }

    /// Stránky obsahujúce všetky slová; záložky a často navštevované vyššie.
    func search(_ query: String, limit: Int) -> [WebPage] {
        let terms = IndexedFile.searchTerms(query)
        guard !terms.isEmpty else { return Array(pages.prefix(limit)) }
        var seenHosts: [String: Int] = [:]
        var result: [WebPage] = []
        for page in pages where terms.allSatisfy({ page.searchKey.contains($0) }) {
            // Z jednej domény najviac 2 (inak by zaplavila výsledky, napr. mail.google.com/...).
            let count = seenHosts[page.host, default: 0]
            guard count < 2 || page.kind != .history else { continue }
            seenHosts[page.host] = count + 1
            result.append(page)
            if result.count >= limit * 3 { break }
        }
        return Array(result.sorted { score($0) > score($1) }.prefix(limit))
    }

    private func score(_ page: WebPage) -> Double {
        switch page.kind {
        case .bookmark, .readingList: return 1_000_000
        case .history:
            let age = Date().timeIntervalSince(page.lastVisit ?? .distantPast) / 86400
            return Double(page.visitCount) * 10 - age
        }
    }
}
