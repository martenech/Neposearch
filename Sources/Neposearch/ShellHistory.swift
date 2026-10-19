import Foundation
import Observation

/// Príkaz z histórie terminálu (rovnaké príkazy zlúčené).
struct ShellCommand: Hashable, Sendable, Identifiable {
    let command: String
    let shell: String
    let lastRun: Date?
    let count: Int

    var id: String { command }
    var searchKey: String { command.lowercased() }
}

/// História príkazov z fish a zsh. Je malá, preto ju držíme v pamäti a pri zmene súboru načítame znova.
@MainActor @Observable
final class ShellHistory {
    private(set) var commands: [ShellCommand] = []

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var watchers: [FileWatcher] = []
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

    nonisolated static let fishHistory = NSHomeDirectory() + "/.local/share/fish/fish_history"
    nonisolated static let zshHistory = NSHomeDirectory() + "/.zsh_history"
    nonisolated static let bashHistory = NSHomeDirectory() + "/.bash_history"

    init(settings: AppSettings) {
        self.settings = settings
        start()
    }

    func start() {
        watchers = []
        guard settings.shellHistoryEnabled else {
            commands = []
            return
        }
        let folders = Set([Self.fishHistory, Self.zshHistory].map { ($0 as NSString).deletingLastPathComponent })
        watchers = folders.map { folder in
            FileWatcher(path: folder) { [weak self] paths in
                MainActor.assumeIsolated {
                    if paths.contains(where: { $0.hasSuffix("history") }) { self?.scheduleReload() }
                }
            }
        }
        scheduleReload(delay: 0)
    }

    private func scheduleReload(delay: Double = 2) {
        reloadTask?.cancel()
        reloadTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            commands = await Task.detached(priority: .utility) { Self.load() }.value
        }
    }

    /// Príkazy obsahujúce všetky slová dotazu, najnovšie prvé.
    func search(_ query: String, limit: Int) -> [ShellCommand] {
        let words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return Array(commands.prefix(limit)) }
        return Array(commands.lazy.filter { command in words.allSatisfy { command.searchKey.contains($0) } }.prefix(limit))
    }

    // MARK: - Čítanie histórie

    nonisolated private static func load() -> [ShellCommand] {
        var entries: [(command: String, date: Date?, shell: String)] = []
        entries += parseFish(Self.fishHistory)
        entries += parseZsh(Self.zshHistory)
        if let bash = try? String(contentsOfFile: Self.bashHistory, encoding: .utf8) {
            entries += bash.split(separator: "\n").map { (String($0), nil, "bash") }
        }

        // Zlúčime rovnaké príkazy: počet spustení a posledný čas.
        var merged: [String: (date: Date?, shell: String, count: Int, order: Int)] = [:]
        for (index, entry) in entries.enumerated() {
            let command = entry.command.trimmingCharacters(in: .whitespacesAndNewlines)
            guard command.count > 1 else { continue }
            let previous = merged[command]
            let date = [previous?.date, entry.date].compactMap { $0 }.max()
            merged[command] = (date, entry.shell, (previous?.count ?? 0) + 1, index)
        }
        return merged
            .map { ShellCommand(command: $0.key, shell: $0.value.shell, lastRun: $0.value.date, count: $0.value.count) }
            .sorted { a, b in
                switch (a.lastRun, b.lastRun) {
                case let (x?, y?): return x > y
                case (_?, nil): return true
                case (nil, _?): return false
                default: return (merged[a.command]?.order ?? 0) > (merged[b.command]?.order ?? 0)
                }
            }
    }

    /// fish: „- cmd: príkaz\n  when: 1791745459“ (\\n a \\\\ sú escapované).
    nonisolated private static func parseFish(_ path: String) -> [(String, Date?, String)] {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
        var result: [(String, Date?, String)] = []
        var command: String?
        var date: Date?
        func flush() {
            if let command { result.append((command, date, "fish")) }
            command = nil
            date = nil
        }
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("- cmd: ") {
                flush()
                command = String(line.dropFirst(7))
                    .replacingOccurrences(of: "\\n", with: "\n")
                    .replacingOccurrences(of: "\\\\", with: "\\")
            } else if line.hasPrefix("  when: "), let seconds = TimeInterval(line.dropFirst(8)) {
                date = Date(timeIntervalSince1970: seconds)
            }
        }
        flush()
        return result
    }

    /// zsh: „: 1700000000:0;príkaz“ (rozšírený formát) alebo len príkaz; ne-ASCII znaky sú „metafikované“.
    nonisolated private static func parseZsh(_ path: String) -> [(String, Date?, String)] {
        guard let data = FileManager.default.contents(atPath: path) else { return [] }
        // zsh ukladá bajty 0x80+ ako 0x83 nasledované bajtom XOR 0x20.
        var bytes: [UInt8] = []
        bytes.reserveCapacity(data.count)
        var meta = false
        for byte in data {
            if meta {
                bytes.append(byte ^ 0x20)
                meta = false
            } else if byte == 0x83 {
                meta = true
            } else {
                bytes.append(byte)
            }
        }
        let text = String(decoding: bytes, as: UTF8.self)
        var result: [(String, Date?, String)] = []
        var pending = ""
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            // Viacriadkový príkaz končí spätným lomítkom.
            if line.hasSuffix("\\") {
                pending += line.dropLast() + "\n"
                continue
            }
            let full = pending + line
            pending = ""
            if full.hasPrefix(": "), let semicolon = full.firstIndex(of: ";") {
                let stamp = full.dropFirst(2).prefix { $0.isNumber }
                result.append((String(full[full.index(after: semicolon)...]), TimeInterval(stamp).map(Date.init(timeIntervalSince1970:)), "zsh"))
            } else if !full.isEmpty {
                result.append((full, nil, "zsh"))
            }
        }
        return result
    }
}
