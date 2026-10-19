import AppKit
import Observation

struct MailMessage: Hashable, Sendable, Identifiable {
    let id: Int
    let subject: String
    let senderEmail: String
    let senderName: String
    let summary: String
    let date: Date
    let mailbox: String
    let messageIdHeader: String
    let isRead: Bool
    let isFlagged: Bool
    let searchKey: String

    var sender: String { senderName.isEmpty ? senderEmail : senderName }

    /// Odkaz, ktorý otvorí správu v Maile.
    var url: URL? {
        guard !messageIdHeader.isEmpty,
            let encoded = messageIdHeader.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "@.-_")))
        else { return nil }
        return URL(string: "message://\(encoded)")
    }
}

/// E-maily z aplikácie Mail (Envelope Index). Číta sa priamo, len na čítanie, a drží v pamäti.
/// Potrebuje Full Disk Access.
@MainActor @Observable
final class MailIndex {
    private(set) var messages: [MailMessage] = []
    private(set) var problem: String?

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadedSignature = ""

    nonisolated static let databasePath = NSHomeDirectory() + "/Library/Mail/V10/MailData/Envelope Index"

    init(settings: AppSettings) {
        self.settings = settings
        refreshIfNeeded()
    }

    /// Načíta znova, ak sa databáza Mailu zmenila (kontrola pri otvorení spúšťača).
    func refreshIfNeeded() {
        guard settings.mailEnabled, loadTask == nil else {
            if !settings.mailEnabled { messages = [] }
            return
        }
        let signature = Self.signature()
        guard signature != loadedSignature else { return }
        loadTask = Task {
            let result = await Task.detached(priority: .utility) { () -> Result<[MailMessage], Error> in
                Result { try Self.load() }
            }.value
            switch result {
            case .success(let loaded):
                messages = loaded
                problem = nil
                loadedSignature = signature
            case .failure:
                problem = "Povoľ Neposearch v Nastaveniach → Súkromie a bezpečnosť → Úplný prístup k disku."
            }
            loadTask = nil
        }
    }

    nonisolated private static func signature() -> String {
        [databasePath, databasePath + "-wal"].map { path in
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            return "\((attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0)"
        }.joined(separator: "|")
    }

    nonisolated private static func load() throws -> [MailMessage] {
        // Jedna správa môže byť vo viacerých priečinkoch (Gmail: Doručené + Všetky správy) – zlúčime podľa globálneho ID.
        let sql = """
            SELECT m.ROWID, s.subject, a.address, a.comment, su.summary, m.date_received, mb.url,
                   g.message_id_header, m.read, m.flagged
            FROM messages m
            JOIN subjects s ON s.ROWID = m.subject
            LEFT JOIN addresses a ON a.ROWID = m.sender
            LEFT JOIN summaries su ON su.ROWID = m.summary
            LEFT JOIN mailboxes mb ON mb.ROWID = m.mailbox
            LEFT JOIN message_global_data g ON g.ROWID = m.global_message_id
            WHERE m.deleted = 0
            GROUP BY m.global_message_id
            ORDER BY m.date_received DESC
            """
        var result: [MailMessage] = []
        try SQLiteReader.query(databasePath, sql) { row in
            let subject = row.string(1), email = row.string(2).lowercased(), name = row.string(3)
            let summary = String(row.string(4).prefix(300))
            let mailboxURL = row.string(6)
            let mailbox = (mailboxURL.removingPercentEncoding ?? mailboxURL).split(separator: "/").last.map(String.init) ?? ""
            result.append(MailMessage(
                id: row.int(0), subject: subject, senderEmail: email, senderName: name, summary: summary,
                date: Date(timeIntervalSince1970: row.double(5)), mailbox: mailbox, messageIdHeader: row.string(7),
                isRead: row.int(8) != 0, isFlagged: row.int(9) != 0,
                searchKey: IndexedFile.normalize("\(subject) \(name) \(email) \(summary)")))
        }
        return result
    }

    func search(_ query: String, limit: Int) -> [MailMessage] {
        let terms = IndexedFile.searchTerms(query)
        guard !terms.isEmpty else { return Array(messages.prefix(limit)) }
        return Array(messages.lazy.filter { message in terms.allSatisfy { message.searchKey.contains($0) } }.prefix(limit))
    }

    /// E-maily od osoby (podľa jej e-mailových adries).
    func messages(from emails: Set<String>, limit: Int) -> [MailMessage] {
        guard !emails.isEmpty else { return [] }
        return Array(messages.lazy.filter { emails.contains($0.senderEmail) }.prefix(limit))
    }
}
