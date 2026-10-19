import Foundation
import ObjectBox

/// Sedenie Claude Code (`~/.claude/projects/<projekt>/<id>.jsonl`).
// objectbox: entity
class ClaudeSession {
    var id: Id = 0
    // objectbox: unique
    var sessionId: String = ""
    var filePath: String = ""
    /// Priečinok, v ktorom sedenie bežalo (cwd).
    var projectPath: String = ""
    var title: String = ""
    var firstPrompt: String = ""
    /// Všetky tvoje otázky v sedení, oddelené novým riadkom.
    var prompts: String = ""
    /// Úryvky odpovedí Claude (na hľadanie).
    var answers: String = ""
    var gitBranch: String = ""
    var startedAt: Date = Date(timeIntervalSince1970: 0)
    var updatedAt: Date = Date(timeIntervalSince1970: 0)
    var fileSize: Int64 = 0
    var promptCount: Int = 0
    var searchKey: String = ""
    // objectbox:hnswIndex: dimensions=384, distanceType="cosine"
    var vector: [Float]? = nil

    required init() {}
}

extension ClaudeSession {
    var projectName: String { URL(fileURLWithPath: projectPath).lastPathComponent }

    /// Príkaz na pokračovanie v sedení.
    var resumeCommand: String {
        "cd \(TerminalLauncher.shellQuoted(projectPath)) && claude --resume \(sessionId)"
    }

    /// Otázka zo sedenia, ktorá obsahuje hľadané slovo (alebo prvá).
    func matchingPrompt(for terms: [String]) -> String {
        let lines = prompts.split(separator: "\n").map(String.init)
        if let term = terms.first, let line = lines.first(where: { IndexedFile.normalize($0).contains(term) }) {
            return line
        }
        return firstPrompt
    }
}
