import Foundation

/// Roztriedi vlastné mená z kľúčových slov súborov (osoba / firma / projekt / miesto) pomocou Claude.
/// Výsledok sa ukladá, takže sa ďalej triedia len nové názvy.
struct EntityExtractor: Sendable {
    struct Classified: Codable, Sendable {
        var type: String
        var canonical: String
    }

    static var cacheURL: URL {
        Database.defaultDirectory.deletingLastPathComponent().appendingPathComponent("keyword-types.json")
    }

    static func loadCache() -> [String: Classified] {
        guard let data = try? Data(contentsOf: cacheURL) else { return [:] }
        return (try? JSONDecoder().decode([String: Classified].self, from: data)) ?? [:]
    }

    static func saveCache(_ cache: [String: Classified]) {
        if let data = try? JSONEncoder().encode(cache) { try? data.write(to: cacheURL, options: .atomic) }
    }

    /// Kandidáti: kľúčové slová a tagy začínajúce veľkým písmenom (vlastné mená), nie čísla.
    static func candidates(in files: [IndexedFile]) -> Set<String> {
        var result = Set<String>()
        for file in files {
            for word in (file.keywords + "," + file.tags).split(separator: ",") {
                let keyword = word.trimmingCharacters(in: .whitespaces)
                guard (3...60).contains(keyword.count), keyword.first?.isUppercase == true,
                    !keyword.allSatisfy({ $0.isNumber || $0 == "." || $0 == " " })
                else { continue }
                result.insert(keyword)
            }
        }
        return result
    }

    let model: any LanguageModel

    private static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "items": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "keyword": ["type": "string"],
                        "type": ["type": "string", "enum": ["person", "organization", "project", "place", "other"]],
                        "canonical": ["type": "string"],
                    ],
                    "required": ["keyword", "type", "canonical"],
                    "additionalProperties": false,
                ],
            ]
        ],
        "required": ["items"],
        "additionalProperties": false,
    ]

    /// Roztriedi dávku názvov (najviac ~250 naraz).
    func classify(_ keywords: [String]) async throws -> [String: Classified] {
        let system = """
            Dostaneš zoznam názvov z kľúčových slov dokumentov používateľa (Slovensko). Pre každý urči typ:
            - person: konkrétna osoba (meno a priezvisko alebo známa osoba),
            - organization: firma, inštitúcia, obchod, značka alebo produktová značka,
            - project: projekt, aplikácia alebo produkt, na ktorom používateľ pracuje, hra, softvér,
            - place: mesto, krajina, adresa, miesto,
            - other: všetko ostatné (skratky, technológie, všeobecné pojmy, formáty súborov).
            canonical je jednotný názov – rovnaké varianty (iný pravopis, s/bez právnej formy, preklad) zjednoť
            na ten istý tvar (napr. „Bratislave“ a „Bratislava“ → „Bratislava“, „Acme s. r. o.“ → „Acme s. r. o.“).
            Vráť každý názov zo vstupu presne raz, v poli keyword nezmenený.
            """
        let data = try await model.generateJSON(
            system: system, prompt: keywords.joined(separator: "\n"), schema: Self.schema)
        struct Response: Decodable {
            struct Item: Decodable {
                let keyword: String
                let type: String
                let canonical: String
            }
            let items: [Item]
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        var result: [String: Classified] = [:]
        for item in response.items {
            result[item.keyword] = Classified(type: item.type, canonical: item.canonical.isEmpty ? item.keyword : item.canonical)
        }
        return result
    }
}
