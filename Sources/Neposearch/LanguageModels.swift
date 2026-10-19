import Foundation
import FoundationModels

struct AIError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// Jazykový model, ktorý na systémový prompt a vstup odpovie JSONom podľa schémy.
protocol LanguageModel: Sendable {
    /// Približne koľko znakov vstupu model zvládne.
    var maxInputCharacters: Int { get }
    func generateJSON(system: String, prompt: String, schema: [String: Any]) async throws -> Data
}

// MARK: - Claude (Messages API cez URLSession)

struct ClaudeAPIModel: LanguageModel {
    let apiKey: String
    let model: String

    let maxInputCharacters = 150_000

    func generateJSON(system: String, prompt: String, schema: [String: Any]) async throws -> Data {
        var outputConfig: [String: Any] = ["format": ["type": "json_schema", "schema": schema]]
        // Haiku 4.5 parameter effort nepodporuje.
        if !model.hasPrefix("claude-haiku") { outputConfig["effort"] = "low" }
        var body: [String: Any] = [
            "model": model,
            "max_tokens": 8000,
            "system": system,
            "messages": [["role": "user", "content": prompt]],
            "output_config": outputConfig,
        ]
        let supportsFallbacks = model.hasPrefix("claude-opus") || model.hasPrefix("claude-sonnet")
        if supportsFallbacks { body["fallbacks"] = "default" }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 300
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if supportsFallbacks { request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await send(request)
        struct Response: Decodable {
            struct Block: Decodable {
                let type: String
                let text: String?
            }
            let content: [Block]
            let stop_reason: String?
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        if response.stop_reason == "refusal" { throw AIError("Model odmietol spracovať požiadavku.") }
        guard let json = response.content.last(where: { $0.type == "text" })?.text else {
            throw AIError("Claude API nevrátilo text (stop_reason: \(response.stop_reason ?? "?")).")
        }
        return Data(json.utf8)
    }

    /// Pošle request, pri 429/5xx to skúsi ešte dvakrát s rastúcim čakaním.
    private func send(_ request: URLRequest) async throws -> Data {
        var attempt = 0
        while true {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 200 { return data }
            if (status == 429 || status >= 500) && attempt < 2 {
                attempt += 1
                try await Task.sleep(for: .seconds(5 * attempt))
                continue
            }
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0["error"] as? [String: Any] }?["message"] as? String
            throw AIError("Claude API \(status): \(message ?? String(decoding: data, as: UTF8.self))")
        }
    }
}

// MARK: - Apple Foundation Models (lokálne)

struct AppleModel: LanguageModel {
    /// Kontext modelu je ~4096 tokenov, necháme rezervu na inštrukcie a výstup.
    let maxInputCharacters = 6_000

    static var unavailabilityReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available: nil
        case .unavailable(.appleIntelligenceNotEnabled): "Apple Intelligence je vypnutá (Systémové nastavenia → Apple Intelligence & Siri)."
        case .unavailable(.deviceNotEligible): "Tento Mac nepodporuje Apple Intelligence."
        case .unavailable(.modelNotReady): "Apple model sa ešte sťahuje."
        case .unavailable: "Apple model nie je dostupný."
        }
    }

    func generateJSON(system: String, prompt: String, schema: [String: Any]) async throws -> Data {
        let generationSchema = try GenerationSchema(root: Self.dynamicSchema(schema, name: "Root"), dependencies: [])
        var text = prompt
        while true {
            let session = LanguageModelSession(instructions: system + "\nAlways answer in English.")
            do {
                let content = try await session.respond(to: text, schema: generationSchema).content
                return Data(content.jsonString.utf8)
            } catch LanguageModelSession.GenerationError.exceededContextWindowSize where text.count > 1_000 {
                text = String(text.prefix(text.count / 2))
            }
        }
    }

    /// Prevedie jednoduchú JSON schému (object/array/string/integer) na schému Foundation Models.
    /// Makro @Generable sa nedá použiť bez plného Xcode toolchainu.
    private static func dynamicSchema(_ schema: [String: Any], name: String) -> DynamicGenerationSchema {
        switch schema["type"] as? String {
        case "object":
            let properties = (schema["properties"] as? [String: Any] ?? [:]).sorted { $0.key < $1.key }.map { key, value in
                DynamicGenerationSchema.Property(
                    name: key, description: (value as? [String: Any])?["description"] as? String,
                    schema: dynamicSchema(value as? [String: Any] ?? [:], name: name + "_" + key))
            }
            return DynamicGenerationSchema(name: name, properties: properties)
        case "array":
            return DynamicGenerationSchema(arrayOf: dynamicSchema(schema["items"] as? [String: Any] ?? [:], name: name + "Item"))
        case "integer":
            return DynamicGenerationSchema(type: Int.self)
        default:
            return DynamicGenerationSchema(type: String.self)
        }
    }
}
