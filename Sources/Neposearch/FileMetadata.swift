import Foundation

/// Metadáta, ktoré si macOS (Spotlight) pamätá k súboru: odkiaľ bol stiahnutý, kedy otvorený, tagy.
struct FileMetadata: Sendable {
    /// Odkiaľ súbor pochádza (URL stiahnutia, príloha e-mailu…), prvá položka kMDItemWhereFroms.
    var source = ""
    var lastUsedAt: Date?
    var useCount = 0
    var finderTags: [String] = []

    static func read(_ url: URL) -> FileMetadata {
        guard let item = MDItemCreateWithURL(nil, url as CFURL) else { return FileMetadata() }
        func value(_ key: String) -> CFTypeRef? { MDItemCopyAttribute(item, key as CFString) }
        var metadata = FileMetadata()
        metadata.source = (value("kMDItemWhereFroms") as? [String])?.first ?? ""
        metadata.lastUsedAt = value("kMDItemLastUsedDate") as? Date
        metadata.useCount = (value("kMDItemUseCount") as? NSNumber)?.intValue ?? 0
        metadata.finderTags = (value("kMDItemUserTags") as? [String]) ?? []
        return metadata
    }

    /// Čitateľný zdroj: „príloha z Gmailu“, „example.edu“, alebo text (napr. odosielateľ z Mailu).
    static func describeSource(_ source: String) -> String {
        guard !source.isEmpty else { return "" }
        guard let host = URL(string: source)?.host() else { return source }
        if host.contains("mail-attachment.googleusercontent") || host.hasSuffix("mail.google.com") { return "príloha z Gmailu" }
        if host.contains("outlook") { return "príloha z Outlooku" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
