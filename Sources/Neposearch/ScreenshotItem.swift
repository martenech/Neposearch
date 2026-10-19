import Foundation
import ObjectBox

// objectbox: entity
class ScreenshotItem {
    var id: Id = 0
    // objectbox: unique
    var path: String = ""
    var createdAt: Date = Date()
    var modifiedAt: Date = Date(timeIntervalSince1970: 0)
    /// Text rozpoznaný na obrázku (OCR).
    var text: String = ""
    /// Text malými písmenami bez diakritiky – na vyhľadávanie.
    var searchKey: String = ""

    required init() {}
}

extension ScreenshotItem {
    var url: URL { URL(fileURLWithPath: path) }

    /// Riadok OCR textu, ktorý obsahuje hľadané slovo (alebo prvý riadok).
    func matchingLine(for terms: [String]) -> String {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        if let term = terms.first,
            let line = lines.first(where: { IndexedFile.normalize($0).contains(term) })
        {
            return line
        }
        return lines.first ?? "Bez textu"
    }
}
