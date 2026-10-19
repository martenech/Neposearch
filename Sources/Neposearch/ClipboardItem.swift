import Foundation
import ObjectBox

// objectbox: entity
class ClipboardItem {
    var id: Id = 0
    /// Hodnota z `ClipboardKind`.
    var kind: String = ClipboardKind.text.rawValue
    /// Text, alebo pri súboroch cesty oddelené novým riadkom.
    var text: String = ""
    /// Cesta k uloženému obrázku (pri obrázkoch).
    var imagePath: String = ""
    var sourceAppName: String = ""
    var sourceAppPath: String = ""
    var createdAt: Date = Date()
    var isPinned: Bool = false
    /// Text malými písmenami bez diakritiky – na vyhľadávanie.
    var searchKey: String = ""

    required init() {}
}

enum ClipboardKind: String {
    case text, image, files
}

extension ClipboardItem {
    var clipKind: ClipboardKind { ClipboardKind(rawValue: kind) ?? .text }

    var fileURLs: [URL] {
        clipKind == .files ? text.split(separator: "\n").map { URL(fileURLWithPath: String($0)) } : []
    }

    /// Prvý neprázdny riadok na zobrazenie v zozname.
    var title: String {
        switch clipKind {
        case .image: return "Obrázok"
        case .files:
            let urls = fileURLs
            return urls.count == 1 ? urls[0].lastPathComponent : "\(urls.count) súbory"
        case .text:
            let line = text.split(whereSeparator: \.isNewline).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            return line.map { $0.trimmingCharacters(in: .whitespaces) } ?? text
        }
    }
}
