import Foundation

struct FileSummary: Codable, Sendable {
    var summary: String
    var tags: [String]
    /// Slová, ktoré by niekto mohol hľadať (synonymá, súvisiace pojmy, tvary slov).
    var keywords: [String] = []
}

/// Zhrnie obsah súboru jazykovým modelom.
struct FileSummarizer: Sendable {
    /// Zvýšiť pri zmene výstupu, aby sa staršie zhrnutia prepočítali.
    static let version = 2

    let model: any LanguageModel
    let language: String

    private static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "summary": ["type": "string", "description": "2-4 sentence summary of the file."],
            "tags": ["type": "array", "items": ["type": "string"], "description": "3-6 short topic tags."],
            "keywords": ["type": "array", "items": ["type": "string"], "description": "10-20 search keywords."],
        ],
        "required": ["summary", "tags", "keywords"],
        "additionalProperties": false,
    ]

    func summarize(fileName: String, text: String) async throws -> FileSummary {
        let limit = model.maxInputCharacters
        var prompt = "Súbor: \(fileName)\n"
        if text.count > limit {
            prompt += "Pozor: nižšie je len začiatok súboru (\(limit) z \(text.count) znakov). Zhrň ho a uveď, že ide o začiatok.\n"
        }
        prompt += "\n<obsah>\n\(text.prefix(limit))\n</obsah>"

        let system = """
            Si indexer súborov na Macu. Pre daný súbor vráť:
            - summary: stručné zhrnutie (2–4 vety) toho, čo súbor obsahuje a na čo slúži,
            - tags: 3–6 krátkych tém (podstatné mená, malými písmenami),
            - keywords: 10–20 slov a krátkych fráz, ktoré by niekto mohol napísať do vyhľadávania, keď hľadá tento \
            súbor: synonymá, nadradené a súvisiace pojmy, typ dokumentu, mená, miesta, dátumy a anglické ekvivalenty \
            (napr. pri nájomnej zmluve: nájom, prenájom, podnájom, dohoda, byt, nájomca, prenajímateľ, lease).
            Zhrnutie, tagy aj kľúčové slová píš v jazyku: \(language). Ak súbor nemá zmysluplný obsah, povedz to v zhrnutí.
            """
        let data = try await model.generateJSON(system: system, prompt: prompt, schema: Self.schema)
        do {
            return try JSONDecoder().decode(FileSummary.self, from: data)
        } catch {
            throw AIError("Model vrátil zhrnutie v neočakávanom formáte.")
        }
    }
}
