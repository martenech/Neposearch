import CoreML
import Embeddings
import Foundation
import Observation

/// Lokálny viacjazyčný embedding model (intfloat/multilingual-e5-small, 384 rozmerov).
/// Model (~490 MB) sa pri prvom spustení stiahne do Application Support a potom beží offline.
actor Embedder {
    static let modelID = "intfloat/multilingual-e5-small"
    static let dimension = 384
    /// Uložené pri každom vektore; pri zmene modelu sa vektory prepočítajú.
    nonisolated let modelIdentifier = "e5-small-v1"

    enum State: Equatable, Sendable {
        case notLoaded, loading, ready
        case failed(String)
    }

    private var bundle: XLMRoberta.ModelBundle?
    private var loadTask: Task<XLMRoberta.ModelBundle, Error>?
    private(set) var state: State = .notLoaded

    static var modelsDirectory: URL {
        Database.defaultDirectory.deletingLastPathComponent().appendingPathComponent("models", isDirectory: true)
    }

    /// Načíta model (pri prvom spustení ho stiahne).
    func prepare() async throws {
        _ = try await loadedBundle()
    }

    private func loadedBundle() async throws -> XLMRoberta.ModelBundle {
        if let bundle { return bundle }
        if let loadTask { return try await loadTask.value }
        state = .loading
        let task = Task {
            try FileManager.default.createDirectory(at: Self.modelsDirectory, withIntermediateDirectories: true)
            return try await XLMRoberta.loadModelBundle(from: Self.modelID, downloadBase: Self.modelsDirectory)
        }
        loadTask = task
        do {
            let loaded = try await task.value
            bundle = loaded
            state = .ready
            return loaded
        } catch {
            loadTask = nil
            state = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Vektory dokumentov (e5 vyžaduje predponu „passage: “). Po dávkach cez GPU – ~35 ms na text.
    func embedDocuments(_ texts: [String]) async throws -> [[Float]] {
        let bundle = try await loadedBundle()
        var options = bundle.defaultEncodeOptions
        options.maxLength = 192
        options.computePolicy = .cpuAndGPU
        var result: [[Float]] = []
        for start in stride(from: 0, to: texts.count, by: 16) {
            let batch = texts[start..<min(start + 16, texts.count)].map { "passage: " + $0 }
            let matrix = try await bundle.batchEncode(Array(batch), options: options)
                .cast(to: Float.self).shapedArray(of: Float.self)
            let dim = matrix.shape[1]
            for row in 0..<matrix.shape[0] { result.append(Array(matrix.scalars[row * dim..<(row + 1) * dim])) }
        }
        return result
    }

    /// Vektor hľadaného textu (predpona „query: “). Jednotlivo je najrýchlejší Neural Engine.
    func embedQuery(_ text: String) async throws -> [Float] {
        let bundle = try await loadedBundle()
        var options = bundle.defaultEncodeOptions
        options.maxLength = 64
        options.computePolicy = MLComputePolicy(.cpuAndNeuralEngine)
        return try await bundle.encode("query: " + text, options: options).cast(to: Float.self).shapedArray(of: Float.self).scalars
    }

    /// Text, z ktorého robíme vektor súboru.
    static func text(for file: IndexedFile) -> String {
        "\(file.name)\n\(file.summary)\n\(file.tags)\n\(file.keywords)"
    }
}
