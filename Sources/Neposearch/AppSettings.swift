import Foundation
import Observation

enum AIBackend: String, CaseIterable, Identifiable {
    case claudeCode, claude, apple
    var id: String { rawValue }
    var label: String {
        switch self {
        case .claudeCode: "Claude predplatné (cez Claude Code)"
        case .claude: "Claude API (vlastný API kľúč)"
        case .apple: "Apple Intelligence (lokálne, len angličtina)"
        }
    }
}

@MainActor @Observable
final class AppSettings {
    static let claudeModels = ["claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-4-5"]

    private let defaults = UserDefaults.standard

    var watchedFolder: String? { didSet { defaults.set(watchedFolder, forKey: "watchedFolder") } }
    /// Priečinok, pri ktorom používateľ potvrdil zhrnutie veľkého množstva súborov.
    var confirmedFolder: String? { didSet { defaults.set(confirmedFolder, forKey: "confirmedFolder") } }
    var hotKey: HotKeyPreset { didSet { defaults.set(hotKey.rawValue, forKey: "hotKey") } }
    /// E-maily z aplikácie Mail (Full Disk Access).
    var mailEnabled: Bool { didSet { defaults.set(mailEnabled, forKey: "mailEnabled") } }
    /// História, záložky a Zoznam na čítanie zo Safari (Full Disk Access).
    var safariEnabled: Bool { didSet { defaults.set(safariEnabled, forKey: "safariEnabled") } }
    /// Osoby a firmy z Kontaktov.
    var contactsEnabled: Bool { didSet { defaults.set(contactsEnabled, forKey: "contactsEnabled") } }
    /// Osoby, firmy a projekty nájdené v súboroch (Claude roztriedi kľúčové slová).
    var entitiesEnabled: Bool { didSet { defaults.set(entitiesEnabled, forKey: "entitiesEnabled") } }
    /// Udalosti z Kalendára a pripomienky.
    var calendarEnabled: Bool { didSet { defaults.set(calendarEnabled, forKey: "calendarEnabled") } }
    /// Hľadať v histórii terminálu (fish, zsh, bash).
    var shellHistoryEnabled: Bool { didSet { defaults.set(shellHistoryEnabled, forKey: "shellHistoryEnabled") } }
    /// Indexovať sedenia Claude Code.
    var claudeSessionsEnabled: Bool { didSet { defaults.set(claudeSessionsEnabled, forKey: "claudeSessionsEnabled") } }
    /// Terminál na pokračovanie v sedení.
    var terminalApp: TerminalApp { didSet { defaults.set(terminalApp.rawValue, forKey: "terminalApp") } }
    /// Indexovať snímky obrazovky (OCR).
    var screenshotsEnabled: Bool { didSet { defaults.set(screenshotsEnabled, forKey: "screenshotsEnabled") } }
    /// Rozbaľovať snippety pri písaní v iných aplikáciách.
    var snippetExpansion: Bool { didSet { defaults.set(snippetExpansion, forKey: "snippetExpansion") } }
    /// Ukladať históriu schránky.
    var clipboardEnabled: Bool { didSet { defaults.set(clipboardEnabled, forKey: "clipboardEnabled") } }
    var clipboardHotKey: ClipboardHotKeyPreset { didSet { defaults.set(clipboardHotKey.rawValue, forKey: "clipboardHotKey") } }
    /// Aliasy príkazov: id riadku („window:leftHalf“, „app:/Applications/Safari.app“) → alias („wsl“).
    var aliases: [String: String] { didSet { defaults.set(aliases, forKey: "aliases") } }
    /// Globálne skratky ⌃⌥ + šípky na presun okien.
    var windowHotKeys: Bool { didSet { defaults.set(windowHotKeys, forKey: "windowHotKeys") } }
    var backend: AIBackend { didSet { defaults.set(backend.rawValue, forKey: "backend") } }
    var claudeCodeModel: String { didSet { defaults.set(claudeCodeModel, forKey: "claudeCodeModel") } }
    var claudeModel: String { didSet { defaults.set(claudeModel, forKey: "claudeModel") } }
    var summaryLanguage: String { didSet { defaults.set(summaryLanguage, forKey: "summaryLanguage") } }
    var enabledCategories: Set<FileCategory> {
        didSet { defaults.set(enabledCategories.map(\.rawValue), forKey: "enabledCategories") }
    }
    /// Ďalšie prípony oddelené čiarkou, čítajú sa ako obyčajný text.
    var customExtensions: String { didSet { defaults.set(customExtensions, forKey: "customExtensions") } }
    var apiKey: String { didSet { Keychain.set(apiKey, for: "anthropic-api-key") } }

    init() {
        watchedFolder = defaults.string(forKey: "watchedFolder")
        confirmedFolder = defaults.string(forKey: "confirmedFolder")
        hotKey = HotKeyPreset(rawValue: defaults.string(forKey: "hotKey") ?? "") ?? .optionSpace
        windowHotKeys = defaults.bool(forKey: "windowHotKeys")
        aliases = defaults.dictionary(forKey: "aliases") as? [String: String] ?? [
            "window:leftHalf": "wsl", "window:rightHalf": "wsr", "window:maximize": "wf", "window:toggleFullscreen": "wff",
        ]
        clipboardEnabled = defaults.object(forKey: "clipboardEnabled") as? Bool ?? true
        screenshotsEnabled = defaults.object(forKey: "screenshotsEnabled") as? Bool ?? true
        claudeSessionsEnabled = defaults.object(forKey: "claudeSessionsEnabled") as? Bool ?? true
        shellHistoryEnabled = defaults.object(forKey: "shellHistoryEnabled") as? Bool ?? true
        contactsEnabled = defaults.object(forKey: "contactsEnabled") as? Bool ?? true
        mailEnabled = defaults.object(forKey: "mailEnabled") as? Bool ?? true
        safariEnabled = defaults.object(forKey: "safariEnabled") as? Bool ?? true
        calendarEnabled = defaults.object(forKey: "calendarEnabled") as? Bool ?? true
        entitiesEnabled = defaults.object(forKey: "entitiesEnabled") as? Bool ?? true
        terminalApp = TerminalApp(rawValue: defaults.string(forKey: "terminalApp") ?? "") ?? .preferred
        snippetExpansion = defaults.object(forKey: "snippetExpansion") as? Bool ?? true
        clipboardHotKey = ClipboardHotKeyPreset(rawValue: defaults.string(forKey: "clipboardHotKey") ?? "") ?? .shiftCommandV
        backend = AIBackend(rawValue: defaults.string(forKey: "backend") ?? "") ?? .claudeCode
        claudeCodeModel = defaults.string(forKey: "claudeCodeModel") ?? "haiku"
        claudeModel = defaults.string(forKey: "claudeModel") ?? "claude-opus-5-5"
        summaryLanguage = defaults.string(forKey: "summaryLanguage") ?? "slovenčina"
        if let saved = defaults.stringArray(forKey: "enabledCategories") {
            enabledCategories = Set(saved.compactMap(FileCategory.init(rawValue:)))
        } else {
            enabledCategories = Set(FileCategory.allCases.filter(\.enabledByDefault))
        }
        customExtensions = defaults.string(forKey: "customExtensions") ?? ""
        apiKey = Keychain.get("anthropic-api-key") ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    }

    /// Nastaví alias pre príkaz; rovnaký alias sa z iného príkazu odoberie. Prázdny alias ho zmaže.
    func setAlias(_ alias: String, for id: String) {
        let cleaned = alias.trimmingCharacters(in: .whitespaces).lowercased()
        var updated = aliases.filter { $0.value != cleaned || $0.key == id }
        updated[id] = cleaned.isEmpty ? nil : cleaned
        aliases = updated
    }

    /// Krátky popis modelu pre UI.
    var modelDescription: String {
        switch backend {
        case .claudeCode: "Claude \(claudeCodeModel) cez predplatné"
        case .claude: claudeModel
        case .apple: "lokálny Apple model"
        }
    }

    /// Všetky prípony, ktoré sa majú indexovať (malými písmenami, bez bodky).
    var enabledExtensions: Set<String> {
        let custom = customExtensions
            .split(whereSeparator: { $0 == "," || $0 == " " })
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased() }
            .filter { !$0.isEmpty }
        return Set(enabledCategories.flatMap(\.extensions)).union(custom)
    }

    /// Vráti nakonfigurovaný jazykový model, alebo dôvod, prečo AI nie je dostupná.
    func makeModel() -> Result<any LanguageModel, AIError> {
        switch backend {
        case .claudeCode:
            guard ClaudeCodeModel.executable != nil else {
                return .failure(AIError("Claude Code nie je nainštalovaný (brew install --cask claude-code)."))
            }
            return .success(ClaudeCodeModel(model: claudeCodeModel))
        case .claude:
            guard !apiKey.isEmpty else { return .failure(AIError("Chýba Anthropic API kľúč (Nastavenia).")) }
            return .success(ClaudeAPIModel(apiKey: apiKey, model: claudeModel))
        case .apple:
            if let reason = AppleModel.unavailabilityReason { return .failure(AIError(reason)) }
            return .success(AppleModel())
        }
    }
}
