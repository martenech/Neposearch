import Foundation
import ObjectBox

/// Obal nad ObjectBox store-om. ObjectBox je thread-safe, takže ho môžeme zdieľať.
final class Database: @unchecked Sendable {
    let store: Store
    let files: Box<IndexedFile>

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Neposearch/db", isDirectory: true)
    }

    init(directory: URL = Database.defaultDirectory) throws {
        let dir = directory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        store = try Store(directoryPath: dir.path)
        files = store.box(for: IndexedFile.self)
        try fillMissingSearchKeys()
    }

    /// Záznamy z verzie bez `searchKey` doplní jednorazovo.
    private func fillMissingSearchKeys() throws {
        // Pole pridané neskôr je v starých záznamoch nil, nie "", preto filtrujeme v pamäti.
        let missing = try files.all().filter { $0.searchKey.isEmpty }
        guard !missing.isEmpty else { return }
        missing.forEach { $0.updateSearchKey() }
        try files.put(missing)
    }

    func file(atPath path: String) throws -> IndexedFile? {
        try files.query { IndexedFile.path == path }.build().findUnique()
    }

    /// Najnovšie súbory, alebo pri zadanom texte súbory zoradené podľa počtu nájdených slov.
    /// Pri viacslovnom dotaze stačí, keď sa nájde väčšina slov.
    func recent(matching text: String, limit: Int) throws -> [IndexedFile] {
        let terms = IndexedFile.searchTerms(text)
        guard let first = terms.first else {
            // Nedávne: podľa poslednej zmeny alebo otvorenia (Spotlight kMDItemLastUsedDate).
            let modified = try files.query().ordered(by: IndexedFile.modifiedAt, flags: .descending).build().find(offset: 0, limit: limit)
            let opened = try files.query { IndexedFile.lastUsedAt.isNotNil() }
                .ordered(by: IndexedFile.lastUsedAt, flags: .descending).build().find(offset: 0, limit: 100)
            var seen = Set<UInt64>()
            return (opened + modified)
                .filter { seen.insert($0.id.value).inserted }
                .sorted { $0.lastActivity > $1.lastActivity }
                .prefix(limit).map { $0 }
        }
        let candidates = try files.query {
            terms.dropFirst().reduce(IndexedFile.searchKey.contains(first) as QueryCondition<IndexedFile>) {
                $0 || IndexedFile.searchKey.contains($1)
            }
        }.build().find()
        let required = terms.count <= 2 ? terms.count : Int((Double(terms.count) * 0.6).rounded(.up))
        var scored: [(file: IndexedFile, matches: Int)] = []
        for file in candidates {
            let matches = terms.filter { file.searchKey.contains($0) }.count
            if matches >= required { scored.append((file, matches)) }
        }
        scored.sort { a, b in
            a.matches != b.matches ? a.matches > b.matches : a.file.modifiedAt > b.file.modifiedAt
        }
        return scored.prefix(limit).map(\.file)
    }

    /// Zhrnuté súbory pre „Opýtať sa Claude“, najnovšie ako prvé.
    func summarizedFiles() throws -> [IndexedFile] {
        try files.query { IndexedFile.status == IndexStatus.done.rawValue }
            .ordered(by: IndexedFile.modifiedAt, flags: .descending).build().find()
    }

    /// Najbližší susedia podľa vektora. Skóre je kosínusová vzdialenosť (0 = zhodné).
    func nearest(to vector: [Float], limit: Int) throws -> [(file: IndexedFile, distance: Double)] {
        try files.query { IndexedFile.vector.nearestNeighbors(queryVector: vector, maxCount: limit) }
            .build().findWithScores().map { ($0.object, $0.score) }
    }

    func filesNeedingEmbedding(model: String) throws -> [IndexedFile] {
        try files.query {
            IndexedFile.status == IndexStatus.done.rawValue && IndexedFile.embeddingModel.isNotEqual(to: model)
        }.build().find()
    }

    /// Ľahký záznam o súbore na porovnanie s diskom.
    struct Snapshot: Sendable {
        let id: Id
        let modifiedAt: Date
        let size: Int64
        let status: IndexStatus
        let summaryVersion: Int

        /// Súbor treba spracovať, ak sa zmenil, nie je dokončený, alebo má staré zhrnutie.
        func needsProcessing(modified: Date, size: Int64) -> Bool {
            let finished: Set<IndexStatus> = [.done, .failed, .unsupported]
            guard matches(modified: modified, size: size), finished.contains(status) else { return true }
            return status == .done && summaryVersion < FileSummarizer.version
        }

        func matches(modified: Date, size: Int64) -> Bool {
            Self.sameDate(modifiedAt, modified) && self.size == size
        }

        /// ObjectBox ukladá dátum s presnosťou na milisekundy, preto porovnávame s toleranciou.
        static func sameDate(_ a: Date, _ b: Date) -> Bool {
            abs(a.timeIntervalSince(b)) < 0.01
        }
    }

    func snapshot(under folder: String) throws -> [String: Snapshot] {
        let prefix = folder.hasSuffix("/") ? folder : folder + "/"
        let found = try files.query { IndexedFile.path.startsWith(prefix) }.build().find()
        var result: [String: Snapshot] = [:]
        for f in found {
            result[f.path] = Snapshot(id: f.id, modifiedAt: f.modifiedAt, size: f.size, status: f.indexStatus, summaryVersion: f.summaryVersion)
        }
        return result
    }

    func remove(ids: [Id]) throws {
        try files.remove(ids)
    }

    func count() -> Int { (try? files.count()) ?? 0 }

    func paths(withStatus status: IndexStatus) throws -> [String] {
        try files.query { IndexedFile.status == status.rawValue }.build().find().map(\.path)
    }

    func remove(path: String) throws {
        if let f = try file(atPath: path) { try files.remove(f.id) }
    }
}
