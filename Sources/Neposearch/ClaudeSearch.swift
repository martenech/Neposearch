import Foundation

/// „Opýtať sa Claude“: model dostane otázku a zhrnutia súborov a vyberie tie, ktoré naozaj súvisia.
struct ClaudeSearch: Sendable {
    struct Candidate: Sendable {
        let id: UInt64
        let name: String
        let folder: String
        let modified: Date
        let summary: String
        let tags: String
    }

    struct Hit: Decodable, Sendable {
        let id: Int
        let reason: String
    }

    struct Answer: Decodable, Sendable {
        let answer: String
        let results: [Hit]
    }

    let model: any LanguageModel
    let language: String

    private static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "answer": ["type": "string", "description": "Short direct answer to the question, or empty."],
            "results": [
                "type": "array",
                "description": "Up to 10 relevant files, most relevant first.",
                "items": [
                    "type": "object",
                    "properties": [
                        "id": ["type": "integer", "description": "File id from the list."],
                        "reason": ["type": "string", "description": "One sentence why the file is relevant."],
                    ],
                    "required": ["id", "reason"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["answer", "results"],
        "additionalProperties": false,
    ]

    func ask(_ question: String, candidates: [Candidate]) async throws -> Answer {
        let dateFormat = Date.FormatStyle(date: .numeric, time: .omitted)
        var list = ""
        for c in candidates {
            let entry = "[\(c.id)] \(c.name) — \(c.folder) — \(c.modified.formatted(dateFormat))\n\(c.summary)\ntagy: \(c.tags)\n\n"
            if list.count + entry.count > model.maxInputCharacters { break }
            list += entry
        }
        let system = """
            Pomáhaš používateľovi nájsť súbory na jeho Macu. Dostaneš otázku a zoznam súborov s ich zhrnutiami \
            (formát: [id] názov — priečinok — dátum zmeny, potom zhrnutie a tagy). Vyber najviac 10 súborov, ktoré \
            naozaj súvisia s otázkou, zoraď ich od najrelevantnejšieho a ku každému napíš jednu vetu, prečo. \
            Ak sa dá na otázku odpovedať priamo zo zhrnutí, napíš do answer krátku odpoveď (1–3 vety), inak nechaj \
            answer prázdne. Ak nič nesúvisí, vráť prázdny zoznam. Používaj len id zo zoznamu. Píš v jazyku: \(language).
            """
        let prompt = "Otázka: \(question)\n\n<súbory>\n\(list)</súbory>"
        let data = try await model.generateJSON(system: system, prompt: prompt, schema: Self.schema)
        do {
            return try JSONDecoder().decode(Answer.self, from: data)
        } catch {
            throw AIError("Model vrátil odpoveď v neočakávanom formáte.")
        }
    }
}
