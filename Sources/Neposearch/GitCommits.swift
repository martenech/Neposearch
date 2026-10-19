import Foundation
import Observation

struct GitCommit: Hashable, Sendable, Identifiable {
    let hash: String
    let repoPath: String
    let author: String
    let date: Date
    let subject: String
    /// Vetvy a tagy, ktoré na commit ukazujú.
    let refs: String

    var id: String { "\(repoPath):\(hash)" }
    var shortHash: String { String(hash.prefix(7)) }
    var repoName: String { URL(fileURLWithPath: repoPath).lastPathComponent }
    var searchKey: String { IndexedFile.normalize("\(subject) \(repoName) \(author) \(refs) \(hash)") }
    var showCommand: String { "cd \(TerminalLauncher.shellQuoted(repoPath)) && git show \(hash)" }
}

/// Commity z git repozitárov v priečinku s projektmi (predvolene ~/Projects).
@MainActor @Observable
final class GitCommits {
    private(set) var commits: [GitCommit] = []
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    static var projectsFolder: String { NSHomeDirectory() + "/Projects" }

    init() {
        refreshIfNeeded()
    }

    /// Načíta commity na pozadí, najviac raz za 2 minúty.
    func refreshIfNeeded() {
        guard loadTask == nil, loadedAt.map({ Date().timeIntervalSince($0) > 120 }) ?? true else { return }
        let folder = Self.projectsFolder
        loadTask = Task {
            commits = await Task.detached(priority: .utility) { Self.load(from: folder) }.value
            loadedAt = Date()
            loadTask = nil
        }
    }

    func search(_ query: String, limit: Int) -> [GitCommit] {
        let terms = IndexedFile.searchTerms(query)
        guard !terms.isEmpty else { return Array(commits.prefix(limit)) }
        return Array(commits.lazy.filter { commit in terms.allSatisfy { commit.searchKey.contains($0) } }.prefix(limit))
    }

    nonisolated private static func load(from folder: String) -> [GitCommit] {
        let fm = FileManager.default
        // Repozitáre priamo v priečinku a o úroveň nižšie.
        var repos: [String] = []
        for item in (try? fm.contentsOfDirectory(atPath: folder)) ?? [] {
            let path = (folder as NSString).appendingPathComponent(item)
            if fm.fileExists(atPath: path + "/.git") { repos.append(path); continue }
            for inner in (try? fm.contentsOfDirectory(atPath: path)) ?? [] {
                let innerPath = (path as NSString).appendingPathComponent(inner)
                if fm.fileExists(atPath: innerPath + "/.git") { repos.append(innerPath) }
            }
        }
        var result: [GitCommit] = []
        for repo in repos {
            let output = run(["git", "-C", repo, "log", "--all", "--max-count=1000", "--pretty=format:%H%x1f%an%x1f%at%x1f%s%x1f%D%x1e"])
            for record in output.split(separator: "\u{1E}") {
                let fields = record.trimmingCharacters(in: .newlines).split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
                guard fields.count >= 5, let seconds = TimeInterval(fields[2]) else { continue }
                result.append(GitCommit(
                    hash: fields[0], repoPath: repo, author: fields[1],
                    date: Date(timeIntervalSince1970: seconds), subject: fields[3], refs: fields[4]))
            }
        }
        return result.sorted { $0.date > $1.date }
    }

    nonisolated private static func run(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
