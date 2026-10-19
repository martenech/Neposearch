import Foundation
import ObjectBox
import Observation

/// Index sedení Claude Code: hľadanie v otázkach a odpovediach, pokračovanie v sedení.
@MainActor @Observable
final class ClaudeSessionIndex {
    private(set) var count = 0
    /// Mení sa, keď pribudnú výsledky hľadania podľa významu (aby sa obnovil zoznam).
    private(set) var revision = 0

    @ObservationIgnored private let box: Box<ClaudeSession>
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let embedder: Embedder
    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var rescanTask: Task<Void, Never>?
    @ObservationIgnored private var semanticTask: Task<Void, Never>?
    @ObservationIgnored private var semanticQuery = ""
    @ObservationIgnored private var semanticHits: [UInt64] = []

    nonisolated static let projectsFolder = URL(fileURLWithPath: NSHomeDirectory() + "/.claude/projects", isDirectory: true)

    init(database: Database, settings: AppSettings, embedder: Embedder) {
        box = database.store.box(for: ClaudeSession.self)
        self.settings = settings
        self.embedder = embedder
        count = (try? box.count()) ?? 0
        start()
    }

    func start() {
        watcher = nil
        rescanTask?.cancel()
        guard settings.claudeSessionsEnabled else { return }
        // Aktívne sedenie sa zapisuje neustále – obnovujeme najviac raz za minútu.
        watcher = FileWatcher(path: Self.projectsFolder.path) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRescan(delay: 60) }
        }
        scheduleRescan(delay: 0)
    }

    private func scheduleRescan(delay: Double) {
        if delay > 0, rescanTask != nil { return }
        rescanTask?.cancel()
        rescanTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await rescan()
            rescanTask = nil
        }
    }

    // MARK: - Načítanie sedení

    private func rescan() async {
        let files = await Task.detached(priority: .utility) { Self.sessionFiles() }.value
        let known = Dictionary(((try? box.all()) ?? []).map { ($0.filePath, $0) }, uniquingKeysWith: { a, _ in a })

        let paths = Set(files.map(\.path))
        let removed = known.values.filter { !paths.contains($0.filePath) }
        if !removed.isEmpty { _ = try? box.remove(removed.map(\.id)) }

        var changed: [ClaudeSession] = []
        for file in files where known[file.path]?.fileSize != file.size {
            guard let parsed = await Task.detached(priority: .utility, operation: { Self.parse(file.path) }).value else { continue }
            let session = known[file.path] ?? ClaudeSession()
            parsed.apply(to: session)
            session.filePath = file.path
            session.fileSize = file.size
            changed.append(session)
        }
        guard !changed.isEmpty else { return }

        // Vektory z názvu a otázok (na hľadanie podľa významu).
        let texts = changed.map { "\($0.projectName): \($0.title)\n\($0.prompts.prefix(1500))" }
        if let vectors = try? await embedder.embedDocuments(texts) {
            for (session, vector) in zip(changed, vectors) { session.vector = vector }
        }
        _ = try? box.put(changed)
        count = (try? box.count()) ?? 0
        revision += 1
    }

    private struct SessionFile: Sendable {
        let path: String
        let size: Int64
    }

    nonisolated private static func sessionFiles() -> [SessionFile] {
        let fm = FileManager.default
        let projects = (try? fm.contentsOfDirectory(at: projectsFolder, includingPropertiesForKeys: nil)) ?? []
        var result: [SessionFile] = []
        for project in projects {
            let name = project.lastPathComponent
            // Dočasné sedenia (napr. AI hľadanie v Pathfinderi) vynecháme.
            if name.hasPrefix("-private-") || name.hasPrefix("-var-folders") || name.hasPrefix("-tmp") { continue }
            let files = (try? fm.contentsOfDirectory(at: project, includingPropertiesForKeys: [.fileSizeKey])) ?? []
            for file in files where file.pathExtension == "jsonl" {
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { $0 } ?? 0
                result.append(SessionFile(path: file.path, size: Int64(size)))
            }
        }
        return result
    }

    /// Výsledok čítania jedného súboru sedenia.
    private struct Parsed: Sendable {
        var sessionId = ""
        var projectPath = ""
        var title = ""
        var prompts: [String] = []
        var answers = ""
        var gitBranch = ""
        var startedAt: Date?
        var updatedAt: Date?

        func apply(to session: ClaudeSession) {
            session.sessionId = sessionId
            session.projectPath = projectPath
            session.firstPrompt = prompts.first ?? ""
            session.title = title.isEmpty ? String(session.firstPrompt.prefix(80)) : title
            session.prompts = prompts.joined(separator: "\n")
            session.promptCount = prompts.count
            session.answers = answers
            session.gitBranch = gitBranch
            session.startedAt = startedAt ?? .distantPast
            session.updatedAt = updatedAt ?? session.startedAt
            session.searchKey = IndexedFile.normalize(
                "\(session.projectName) \(session.title) \(session.prompts) \(answers) \(gitBranch)")
        }
    }

    nonisolated private static func parse(_ path: String) -> Parsed? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let dates = ISO8601DateFormatter()
        dates.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsed = Parsed()
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            // Rýchly filter: drahé JSON čítanie len pre otázky, odpovede a názov.
            let isUser = line.contains("\"type\":\"user\"")
            let isAssistant = !isUser && line.contains("\"type\":\"assistant\"")
            let isTitle = !isUser && !isAssistant && line.contains("\"type\":\"ai-title\"")
            guard isUser || isAssistant || isTitle,
                let object = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
            else { continue }

            if isTitle {
                parsed.title = object["aiTitle"] as? String ?? parsed.title
                continue
            }
            if let id = object["sessionId"] as? String { parsed.sessionId = id }
            if let cwd = object["cwd"] as? String, parsed.projectPath.isEmpty { parsed.projectPath = cwd }
            if let branch = object["gitBranch"] as? String, branch != "HEAD" { parsed.gitBranch = branch }
            if let stamp = object["timestamp"] as? String, let date = dates.date(from: stamp) {
                if parsed.startedAt == nil { parsed.startedAt = date }
                parsed.updatedAt = date
            }
            guard let message = object["message"] as? [String: Any] else { continue }
            let text = Self.text(of: message["content"])
            if isUser {
                guard object["isMeta"] as? Bool != true else { continue }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                // Systémové vložky, výstupy príkazov a prerušenia nie sú tvoje otázky.
                guard !trimmed.isEmpty, !trimmed.hasPrefix("<"), !trimmed.hasPrefix("[Request interrupted") else { continue }
                parsed.prompts.append(trimmed.replacingOccurrences(of: "\n", with: " "))
            } else if parsed.answers.count < 8000, !text.isEmpty {
                parsed.answers += String(text.prefix(300)).replacingOccurrences(of: "\n", with: " ") + "\n"
            }
        }
        // Dočasné sedenia (cwd v systémových priečinkoch) a sedenia bez otázok vynecháme.
        let temporary = ["/private/var/folders", "/var/folders", "/private/tmp", "/tmp"]
        guard !parsed.sessionId.isEmpty, !parsed.prompts.isEmpty,
            !temporary.contains(where: { parsed.projectPath.hasPrefix($0) })
        else { return nil }
        return parsed
    }

    nonisolated private static func text(of content: Any?) -> String {
        if let text = content as? String { return text }
        guard let blocks = content as? [[String: Any]] else { return "" }
        return blocks.compactMap { $0["type"] as? String == "text" ? $0["text"] as? String : nil }.joined(separator: " ")
    }

    // MARK: - Hľadanie

    /// Podľa slov hneď; k tomu sedenia podobné významom, keď dobehne výpočet (pozri `prefetchSemantic`).
    func search(_ query: String, limit: Int) -> [ClaudeSession] {
        _ = revision
        let terms = IndexedFile.searchTerms(query)
        guard let first = terms.first else {
            return (try? box.query().ordered(by: ClaudeSession.updatedAt, flags: .descending).build().find(offset: 0, limit: limit)) ?? []
        }
        let keyword = (try? box.query {
            terms.dropFirst().reduce(ClaudeSession.searchKey.contains(first) as QueryCondition<ClaudeSession>) {
                $0 && ClaudeSession.searchKey.contains($1)
            }
        }.ordered(by: ClaudeSession.updatedAt, flags: .descending).build().find(offset: 0, limit: limit)) ?? []

        prefetchSemantic(query)
        guard semanticQuery == query, keyword.count < limit else { return keyword }
        let keywordIDs = Set(keyword.map(\.id.value))
        let extra = semanticHits.filter { !keywordIDs.contains($0) }.compactMap { try? box.get(Id($0)) }
        return Array((keyword + extra).prefix(limit))
    }

    /// Vypočíta vektor dotazu po krátkej pauze v písaní a nájde podobné sedenia.
    private func prefetchSemantic(_ query: String) {
        guard query != semanticQuery else { return }
        semanticQuery = query
        semanticHits = []
        semanticTask?.cancel()
        let embedder = embedder
        semanticTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let vector = try? await embedder.embedQuery(query) else { return }
            let results = (try? box.query { ClaudeSession.vector.nearestNeighbors(queryVector: vector, maxCount: 10) }
                .build().findWithScores()) ?? []
            guard !Task.isCancelled, query == semanticQuery else { return }
            let similarities = results.map { (id: $0.object.id.value, similarity: 1 - $0.score) }
            let best = similarities.map(\.similarity).max() ?? 0
            semanticHits = similarities.filter { $0.similarity >= max(best - 0.03, 0.82) }.prefix(3).map(\.id)
            revision += 1
        }
    }
}
