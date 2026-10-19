import Foundation

/// Skupiny typov súborov, ktoré sa dajú v nastaveniach zapnúť alebo vypnúť.
enum FileCategory: String, CaseIterable, Identifiable, Sendable {
    case documents, data, images, code, web, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .documents: "Dokumenty"
        case .data: "Tabuľky a dáta"
        case .images: "Obrázky s textom (OCR)"
        case .code: "Zdrojový kód"
        case .web: "Web"
        case .other: "Ostatné textové súbory"
        }
    }

    var extensions: [String] {
        switch self {
        case .documents: ["pdf", "docx", "doc", "rtf", "rtfd", "odt", "txt", "md", "markdown"]
        case .data: ["csv", "tsv", "json", "xml", "yaml", "yml"]
        case .images: ["png", "jpg", "jpeg", "heic", "tiff", "tif", "gif", "bmp", "webp"]
        case .code: ["swift", "py", "js", "ts", "tsx", "jsx", "rb", "go", "rs", "java", "kt", "c", "h", "cpp", "hpp", "m", "php"]
        case .web: ["html", "htm", "css"]
        case .other: ["log", "ini", "toml", "tex", "sql", "sh", "zsh", "fish"]
        }
    }

    var enabledByDefault: Bool { self == .documents }
}
