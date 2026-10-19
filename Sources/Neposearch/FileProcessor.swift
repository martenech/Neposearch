import Foundation

/// Spracuje jeden súbor: extrakcia textu → AI zhrnutie → embedding → zápis do DB. Volá sa mimo hlavného vlákna.
struct FileProcessor: Sendable {
    /// Väčšie súbory preskočíme (typicky videá, archívy, obrovské PDF).
    static let maxFileSize: Int64 = 50 * 1024 * 1024

    let db: Database
    let embedder: Embedder

    func process(path: String, summarizer: FileSummarizer, force: Bool) async {
        let url = URL(fileURLWithPath: path)

        // Zmazaný súbor odstránime z indexu.
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else {
            try? db.remove(path: path)
            return
        }
        guard (attrs[.type] as? FileAttributeType) == .typeRegular else { return }
        let modified = attrs[.modificationDate] as? Date ?? .distantPast
        let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0

        let file = (try? db.file(atPath: path)) ?? IndexedFile()
        let finished: Set<IndexStatus> = [.done, .failed, .unsupported]
        let unchanged = file.id != 0 && Database.Snapshot.sameDate(file.modifiedAt, modified) && file.size == size
        if unchanged && !force && finished.contains(file.indexStatus) && !file.needsResummary { return }

        file.path = path
        file.name = url.lastPathComponent
        file.fileExtension = url.pathExtension.lowercased()
        file.modifiedAt = modified
        file.size = size
        file.errorMessage = ""

        guard size <= Self.maxFileSize else {
            file.status = IndexStatus.unsupported.rawValue
            file.errorMessage = "Súbor je väčší ako \(Self.maxFileSize / 1024 / 1024) MB."
            save(file)
            return
        }

        file.status = IndexStatus.processing.rawValue
        save(file)

        do {
            let text = try TextExtractor.extract(from: url)
            if text.isEmpty {
                file.summary = "Súbor neobsahuje žiadny čitateľný text."
                file.tags = ""
                file.keywords = ""
            } else {
                let result = try await summarizer.summarize(fileName: file.name, text: text)
                file.summary = result.summary
                file.tags = result.tags.joined(separator: ", ")
                file.keywords = result.keywords.joined(separator: ", ")
            }
            file.status = IndexStatus.done.rawValue
            file.summaryVersion = FileSummarizer.version
            file.indexedAt = Date()
            await embed(file)
        } catch {
            file.status = IndexStatus.failed.rawValue
            file.errorMessage = error.localizedDescription
        }
        save(file)
    }

    /// Dopočíta vektory pre zhrnuté súbory, ktoré ich nemajú (alebo ich má iný model). Po dávkach, s priebehom.
    func backfillEmbeddings(progress: @escaping @Sendable (Int, Int) -> Void) async {
        let missing = (try? db.filesNeedingEmbedding(model: embedder.modelIdentifier)) ?? []
        guard !missing.isEmpty else { return }
        progress(0, missing.count)
        var done = 0
        for start in stride(from: 0, to: missing.count, by: 64) {
            let chunk = Array(missing[start..<min(start + 64, missing.count)])
            guard let vectors = try? await embedder.embedDocuments(chunk.map(Embedder.text(for:))) else { return }
            for (file, vector) in zip(chunk, vectors) {
                file.vector = vector
                file.embeddingModel = embedder.modelIdentifier
            }
            _ = try? db.files.put(chunk)
            done += chunk.count
            progress(done, missing.count)
        }
    }

    private func embed(_ file: IndexedFile) async {
        guard let vector = try? await embedder.embedDocuments([Embedder.text(for: file)]).first else { return }
        file.vector = vector
        file.embeddingModel = embedder.modelIdentifier
    }

    /// Obnoví Spotlight metadáta (posledné otvorenie, tagy…) všetkých súborov; zmeny uloží naraz.
    func refreshMetadata() {
        let all = (try? db.files.all()) ?? []
        var changed: [IndexedFile] = []
        for file in all where file.apply(FileMetadata.read(file.url)) { changed.append(file) }
        if !changed.isEmpty { _ = try? db.files.put(changed) }
    }

    private func save(_ file: IndexedFile) {
        file.apply(FileMetadata.read(file.url))
        file.updateSearchKey()
        do { try db.files.put(file) } catch { print("Zápis do DB zlyhal: \(error)") }
    }
}
