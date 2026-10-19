import AppKit
import Carbon.HIToolbox
import Observation

/// Uložený text, ktorý sa dá vložiť zo spúšťača alebo rozbaliť napísaním kľúčového slova.
struct Snippet: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    /// Napr. „;iban“ – po napísaní kdekoľvek sa nahradí textom.
    var keyword: String
    var text: String

    var searchNames: [String] {
        [name, keyword].map { IndexedFile.normalize($0) }
    }

    /// Text s doplnenými zástupnými symbolmi a pozícia kurzora (počet znakov od konca).
    func expanded() -> (text: String, cursorOffset: Int) {
        let now = Date()
        var result = text
            .replacingOccurrences(of: "{date}", with: now.formatted(date: .numeric, time: .omitted))
            .replacingOccurrences(of: "{time}", with: now.formatted(date: .omitted, time: .shortened))
            .replacingOccurrences(of: "{datetime}", with: now.formatted(date: .numeric, time: .shortened))
            .replacingOccurrences(of: "{clipboard}", with: NSPasteboard.general.string(forType: .string) ?? "")
        var offset = 0
        if let range = result.range(of: "{cursor}") {
            offset = result[range.upperBound...].count
            result.removeSubrange(range)
        }
        return (result, offset)
    }
}

@MainActor @Observable
final class SnippetStore {
    var snippets: [Snippet] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "snippets"),
            let saved = try? JSONDecoder().decode([Snippet].self, from: data)
        {
            snippets = saved
        } else {
            snippets = [
                Snippet(name: "Dnešný dátum", keyword: ";dnes", text: "{date}"),
                Snippet(name: "Aktuálny čas", keyword: ";cas", text: "{time}"),
            ]
        }
    }

    func search(_ query: String, limit: Int = 5) -> [Snippet] {
        let q = IndexedFile.normalize(query.trimmingCharacters(in: .whitespaces))
        guard !q.isEmpty else { return [] }
        return snippets
            .compactMap { snippet in
                let byName = snippet.searchNames.compactMap { AppCatalog.score(name: $0, query: q) }.max()
                let byText = IndexedFile.normalize(snippet.text).contains(q) && q.count >= 3 ? 40 : nil
                return [byName, byText].compactMap { $0 }.max().map { (snippet, $0) }
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snippets) { UserDefaults.standard.set(data, forKey: "snippets") }
    }
}

/// Rozbaľuje snippety počas písania v ľubovoľnej aplikácii (potrebuje povolenie Accessibility).
@MainActor
final class SnippetExpander {
    private let store: SnippetStore
    private var monitor: Any?
    private var buffer = ""

    init(store: SnippetStore) {
        self.store = store
    }

    var isRunning: Bool { monitor != nil }

    func update(enabled: Bool) {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        buffer = ""
        guard enabled, AXIsProcessTrusted() else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }
    }

    private func handle(_ event: NSEvent) {
        guard event.type == .keyDown else {
            buffer = ""
            return
        }
        let flags = event.modifierFlags.intersection([.command, .control])
        guard flags.isEmpty else {
            buffer = ""
            return
        }
        switch Int(event.keyCode) {
        case kVK_Delete:
            if !buffer.isEmpty { buffer.removeLast() }
            return
        case kVK_Return, kVK_Tab, kVK_Escape, kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow, kVK_ANSI_KeypadEnter:
            buffer = ""
            return
        default:
            break
        }
        guard let characters = event.characters, !characters.isEmpty else { return }
        buffer = String((buffer + characters).suffix(64))

        guard let snippet = store.snippets.first(where: { !$0.keyword.isEmpty && buffer.hasSuffix($0.keyword) }) else { return }
        buffer = ""
        let expansion = snippet.expanded()
        // Kľúčové slovo sa zmaže a nahradí textom snippetu.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            PasteHelper.paste(expansion.text, deleteBefore: snippet.keyword.count, cursorOffset: expansion.cursorOffset)
        }
    }
}
