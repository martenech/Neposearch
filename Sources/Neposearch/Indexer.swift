import Foundation
import ObjectBox
import Observation

/// Stav indexovania pre UI. Samotná práca (sken, extrakcia, AI, zápisy do DB) beží mimo hlavného vlákna.
@MainActor @Observable
final class Indexer {
    /// Pri väčšom počte súborov na zhrnutie sa najprv opýtame (každý súbor = jedno volanie AI).
    static let confirmationThreshold = 200

    let settings: AppSettings
    private let db: Database
    let embedder = Embedder()
    private let processor: FileProcessor

    private(set) var files: [IndexedFile] = []
    private(set) var totalCount = 0
    private(set) var currentFileName: String?
    private(set) var queuedCount = 0
    private(set) var isScanning = false
    private(set) var aiProblem: String?
    /// Priebeh prvého prepočítania vektorov (hotové, spolu).
    private(set) var embeddingProgress: (done: Int, total: Int)?
    private(set) var embeddingProblem: String?
    /// Počet súborov čakajúcich na potvrdenie, že ich naozaj chceme zhrnúť.
    private(set) var pendingConfirmation: Int?
    /// Výsledky, ktoré sa našli len podľa významu (nie podľa zhody slov).
    private(set) var semanticMatches: Set<UInt64> = []
    var isPaused = false {
        didSet { if !isPaused { startWorker() } }
    }
    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            cancelAsk()
            scheduleSearch()
        }
    }

    /// Režim „Opýtať sa Claude“.
    private(set) var isAsking = false
    /// Odpoveď od Claude; nil = bežné vyhľadávanie.
    private(set) var askAnswer: String?
    /// Prečo Claude vybral daný súbor (podľa id).
    private(set) var askReasons: [UInt64: String] = [:]
    private(set) var askError: String?
    var isAskMode: Bool { isAsking || askAnswer != nil }
    private var askTask: Task<Void, Never>?

    private var queue: [String] = []
    private var head = 0
    private var queued: Set<String> = []
    private var forced: Set<String> = []
    private var worker: Task<Void, Never>?
    private var watcher: FileWatcher?
    private var searchTask: Task<Void, Never>?
    private var reloadTask: Task<Void, Never>?

    init(settings: AppSettings, database: Database? = nil) throws {
        self.settings = settings
        self.db = try database ?? Database()
        self.processor = FileProcessor(db: db, embedder: embedder)
        reload()
        start()
        Task { await prepareEmbeddings() }
        startMetadataRefresh()
    }

    // MARK: - Verejné akcie

    /// (Znova) prehľadá priečinok s aktuálnymi nastaveniami a začne sledovať zmeny.
    func start() {
        watcher = nil
        clearQueue()
        pendingConfirmation = nil
        guard let folder = settings.watchedFolder else { return }
        let extensions = settings.enabledExtensions
        watcher = FileWatcher(path: folder) { [weak self] paths in
            MainActor.assumeIsolated {
                for path in paths where FileScanner.shouldIndex(path: path, extensions: extensions) { self?.enqueue(path) }
            }
        }
        Task { await scan(folder: folder, extensions: extensions) }
    }

    func setFolder(_ url: URL) {
        settings.watchedFolder = url.path
        start()
        scheduleReload()
    }

    func confirmLargeFolder() {
        settings.confirmedFolder = settings.watchedFolder
        pendingConfirmation = nil
        startWorker()
    }

    /// Po zmene AI nastavení skúsi znova súbory, ktoré čakali alebo zlyhali.
    func retryPendingAndFailed() {
        let paths = ((try? db.paths(withStatus: .pending)) ?? []) + ((try? db.paths(withStatus: .failed)) ?? [])
        paths.forEach { enqueue($0, force: true) }
        startWorker()
    }

    func resummarize(_ file: IndexedFile) {
        enqueue(file.path, force: true)
    }

    // MARK: - Sken

    private func scan(folder: String, extensions: Set<String>) async {
        isScanning = true
        let db = db
        let plan = await Task.detached(priority: .utility) {
            FileScanner.plan(folder: folder, extensions: extensions, db: db)
        }.value
        isScanning = false
        guard folder == settings.watchedFolder else { return }

        for path in plan.toProcess where queued.insert(path).inserted { queue.append(path) }
        queuedCount = queue.count - head
        if plan.toProcess.count > Self.confirmationThreshold && settings.confirmedFolder != folder {
            pendingConfirmation = plan.toProcess.count
        }
        scheduleReload()
        startWorker()
    }

    // MARK: - Fronta

    private func enqueue(_ path: String, force: Bool = false) {
        if force { forced.insert(path) }
        guard queued.insert(path).inserted else { return }
        queue.append(path)
        queuedCount = queue.count - head
        startWorker()
    }

    private func clearQueue() {
        queue = []
        head = 0
        queued = []
        forced = []
        queuedCount = 0
    }

    private func startWorker() {
        guard worker == nil, !isPaused, pendingConfirmation == nil, head < queue.count else { return }
        worker = Task {
            while !isPaused, pendingConfirmation == nil, head < queue.count {
                let summarizer: FileSummarizer
                switch settings.makeModel() {
                case .success(let model):
                    summarizer = FileSummarizer(model: model, language: settings.summaryLanguage)
                case .failure(let problem):
                    aiProblem = problem.message
                    worker = nil
                    currentFileName = nil
                    return
                }
                aiProblem = nil

                let path = queue[head]
                head += 1
                queued.remove(path)
                if head > 10_000 {
                    queue.removeFirst(head)
                    head = 0
                }
                queuedCount = queue.count - head
                currentFileName = (path as NSString).lastPathComponent
                let force = forced.remove(path) != nil

                let processor = processor
                await Task.detached(priority: .utility) {
                    await processor.process(path: path, summarizer: summarizer, force: force)
                }.value
                scheduleReload()
            }
            currentFileName = nil
            worker = nil
        }
    }

    // MARK: - Opýtať sa Claude

    func askClaude() {
        let question = searchText.trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty else { return }
        cancelAsk()
        searchTask?.cancel()
        let model: any LanguageModel
        switch settings.makeModel() {
        case .success(let m): model = m
        case .failure(let problem):
            askError = problem.message
            return
        }
        let search = ClaudeSearch(model: model, language: settings.summaryLanguage)
        isAsking = true
        askTask = Task {
            let db = db, embedder = embedder
            let candidates = await Self.askCandidates(for: question, db: db, embedder: embedder)
            do {
                guard !candidates.isEmpty else { throw AIError("Zatiaľ nie sú zhrnuté žiadne súbory.") }
                let answer = try await search.ask(question, candidates: candidates)
                guard !Task.isCancelled else { return }
                var found: [IndexedFile] = []
                var reasons: [UInt64: String] = [:]
                for hit in answer.results where hit.id > 0 {
                    guard reasons[UInt64(hit.id)] == nil, let file = try? db.files.get(Id(UInt64(hit.id))) else { continue }
                    found.append(file)
                    reasons[UInt64(hit.id)] = hit.reason
                }
                files = found
                askReasons = reasons
                semanticMatches = []
                askAnswer = answer.answer
            } catch {
                guard !Task.isCancelled else { return }
                askError = error.localizedDescription
            }
            isAsking = false
        }
    }

    /// Ukončí režim „Opýtať sa Claude“ a vráti bežné vyhľadávanie.
    func cancelAsk() {
        let wasActive = isAskMode || askError != nil
        askTask?.cancel()
        askTask = nil
        isAsking = false
        askAnswer = nil
        askReasons = [:]
        askError = nil
        if wasActive { scheduleSearch() }
    }

    /// Súbory, ktoré pošleme Claude. Pri veľkom indexe najprv vyberieme pravdepodobných kandidátov.
    nonisolated private static func askCandidates(for question: String, db: Database, embedder: Embedder) async -> [ClaudeSearch.Candidate] {
        let all = (try? db.summarizedFiles()) ?? []
        var chosen: [IndexedFile]
        if all.count <= 600 {
            chosen = all
        } else {
            var seen = Set<UInt64>()
            chosen = []
            let keyword = (try? db.recent(matching: question, limit: 200)) ?? []
            let vector = try? await embedder.embedQuery(question)
            let semantic = vector.flatMap { try? db.nearest(to: $0, limit: 150).map(\.file) } ?? []
            for file in keyword + semantic + all.prefix(150) where file.indexStatus == .done {
                if seen.insert(file.id.value).inserted { chosen.append(file) }
            }
        }
        let home = NSHomeDirectory()
        return chosen.map { file in
            let folder = (file.path as NSString).deletingLastPathComponent
            return ClaudeSearch.Candidate(
                id: file.id.value, name: file.name,
                folder: folder.hasPrefix(home) ? "~" + folder.dropFirst(home.count) : folder,
                modified: file.modifiedAt, summary: file.summary, tags: file.tags)
        }
    }

    // MARK: - Zoznam a vyhľadávanie

    /// Obnoví zoznam najviac raz za pol sekundy, aj keď sa spracúva veľa súborov.
    private func scheduleReload() {
        guard reloadTask == nil else { return }
        reloadTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            reloadTask = nil
            reload()
        }
    }

    func reload() {
        totalCount = db.count()
        guard !isAskMode else { return }
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            searchTask?.cancel()
            files = (try? db.recent(matching: "", limit: 300)) ?? []
            semanticMatches = []
        } else {
            scheduleSearch()
        }
    }

    /// Spotlight metadáta (posledné otvorenie, tagy, zdroj) obnovíme pri štarte a potom každých 30 minút.
    private func startMetadataRefresh() {
        let processor = processor
        Task {
            while !Task.isCancelled {
                await Task.detached(priority: .background) { processor.refreshMetadata() }.value
                reload()
                try? await Task.sleep(for: .seconds(30 * 60))
            }
        }
    }

    private func prepareEmbeddings() async {
        do {
            try await embedder.prepare()
        } catch {
            print("Embeddingy nie sú dostupné: \(error.localizedDescription)")
            embeddingProblem = "Model na vyhľadávanie podľa významu sa nepodarilo načítať: \(error.localizedDescription)"
            return
        }
        // Dopočíta vektory pre súbory zhrnuté skôr (alebo iným modelom).
        await processor.backfillEmbeddings { done, total in
            Task { @MainActor [weak self] in
                self?.embeddingProgress = done < total ? (done, total) : nil
            }
        }
    }

    /// Hľadanie podľa slov beží hneď (trvá pod milisekundu); podľa významu až po krátkej pauze v písaní
    /// a len vtedy, keď sa podľa slov nenašlo nič.
    private func scheduleSearch() {
        searchTask?.cancel()
        guard !isAskMode else { return }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            reload()
            return
        }
        let keyword = (try? db.recent(matching: query, limit: 100)) ?? []
        files = keyword
        semanticMatches = []
        // Pri málo zhodách podľa slov doplníme súbory podobné významom (po krátkej pauze v písaní).
        guard keyword.count < 5 else { return }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await semanticSearch(query, after: keyword)
        }
    }

    /// Súbory podobné významom (Apple embedding model je málo presný, preto len ako náhradné riešenie).
    private func semanticSearch(_ query: String, after keyword: [IndexedFile]) async {
        guard let vector = try? await embedder.embedQuery(query) else { return }
        let semantic = ((try? db.nearest(to: vector, limit: 30)) ?? []).map { ($0.file, 1 - $0.distance) }
        guard !Task.isCancelled else { return }

        // e5 dáva relevantným súborom ~0,85–0,90 a šumu ~0,80–0,84: berieme pár najlepších nad hranicou.
        // Keď sa niečo našlo podľa slov, pridáme len 2 veľmi blízke výsledky, aby sa nepridával šum.
        let best = semantic.map(\.1).max() ?? 0
        let cutoff = keyword.isEmpty ? max(best - 0.03, 0.83) : max(best - 0.015, 0.85)
        let keywordIDs = Set(keyword.map(\.id.value))
        let hits = semantic.sorted { $0.1 > $1.1 }
            .filter { $0.1 >= cutoff && !keywordIDs.contains($0.0.id.value) }
            .prefix(keyword.isEmpty ? 5 : 2).map(\.0)
        files = keyword + hits
        semanticMatches = Set(hits.map(\.id.value))
    }
}
