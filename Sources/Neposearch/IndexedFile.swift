import Foundation
import ObjectBox

// objectbox: entity
class IndexedFile {
    var id: Id = 0
    // objectbox: unique
    var path: String = ""
    var name: String = ""
    var fileExtension: String = ""
    var size: Int64 = 0
    var modifiedAt: Date = Date(timeIntervalSince1970: 0)
    var indexedAt: Date? = nil
    var summary: String = ""
    /// Tagy oddelené čiarkou.
    var tags: String = ""
    /// Odkiaľ bol súbor stiahnutý (Spotlight kMDItemWhereFroms).
    var sourceURL: String = ""
    /// Kedy bol súbor naposledy otvorený a koľkokrát (Spotlight).
    var lastUsedAt: Date? = nil
    var useCount: Int = 0
    /// Finder tagy, oddelené čiarkou.
    var finderTags: String = ""
    /// Vyhľadávacie slová od AI, oddelené čiarkou.
    var keywords: String = ""
    /// Verzia zhrnutia (`FileSummarizer.version`), staršie sa prepočítajú.
    var summaryVersion: Int = 0
    /// Osoby a firmy, ktoré sa v súbore spomínajú.
    var people: ToMany<Person> = nil
    var organizations: ToMany<Organization> = nil
    /// Hodnota z `IndexStatus`.
    var status: String = IndexStatus.pending.rawValue
    var errorMessage: String = ""
    /// Názov, zhrnutie a tagy malými písmenami bez diakritiky – na vyhľadávanie slov.
    var searchKey: String = ""
    /// Vektor zo zhrnutia, tagov a názvu – na vyhľadávanie podľa významu (multilingual-e5-small).
    // objectbox:hnswIndex: dimensions=384, distanceType="cosine"
    var vector: [Float]? = nil
    /// Identifikátor modelu, ktorý vektor vytvoril (pri zmene modelu treba prepočítať).
    var embeddingModel: String = ""

    required init() {}
}

enum IndexStatus: String {
    case pending, processing, done, failed, unsupported
}

extension IndexedFile {
    var indexStatus: IndexStatus { IndexStatus(rawValue: status) ?? .pending }
    var url: URL { URL(fileURLWithPath: path) }

    /// Prepočíta `searchKey` z aktuálneho názvu, zhrnutia a tagov.
    func updateSearchKey() {
        searchKey = Self.normalize("\(name) \(summary) \(tags) \(keywords) \(finderTags) \(sourceDescription) \(sourceURL)")
    }

    /// Malé písmená bez diakritiky („Štvrť“ → „stvrt“).
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "sk"))
    }

    /// Slová dotazu pripravené na hľadanie: bez diakritiky, bez krátkych spojok a s odrezanou koncovkou,
    /// aby „prenájme“ našlo aj „prenájom“ a „bytu“ aj „byt“.
    static func searchTerms(_ query: String) -> [String] {
        let words = normalize(query).split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let meaningful = words.filter { $0.count > 2 }
        return (meaningful.isEmpty ? words : meaningful).map { word in
            guard word.allSatisfy(\.isLetter) else { return word }
            switch word.count {
            case ...3: return word
            case 4...5: return String(word.dropLast())
            default: return String(word.dropLast(2))
            }
        }
    }

    /// „príloha z Gmailu“, „example.edu“…
    var sourceDescription: String { FileMetadata.describeSource(sourceURL) }

    /// Posledná aktivita: otvorenie alebo zmena.
    var lastActivity: Date { max(lastUsedAt ?? .distantPast, modifiedAt) }

    /// Prevezme metadáta zo Spotlightu; vráti true, ak sa niečo zmenilo.
    @discardableResult
    func apply(_ metadata: FileMetadata) -> Bool {
        let tags = metadata.finderTags.joined(separator: ", ")
        guard sourceURL != metadata.source || lastUsedAt != metadata.lastUsedAt
            || useCount != metadata.useCount || finderTags != tags
        else { return false }
        sourceURL = metadata.source
        lastUsedAt = metadata.lastUsedAt
        useCount = metadata.useCount
        finderTags = tags
        updateSearchKey()
        return true
    }

    /// Je zhrnutie aktuálne (podľa verzie a stavu)?
    var needsResummary: Bool { indexStatus == .done && summaryVersion < FileSummarizer.version }
    var tagList: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
