import AppKit
import PDFKit
import Vision

/// Vytiahne čitateľný text zo súboru podľa jeho typu. Neznáme prípony číta ako obyčajný text.
enum TextExtractor {
    static let richText: [String: NSAttributedString.DocumentType] = [
        "rtf": .rtf, "rtfd": .rtfd, "doc": .docFormat, "docx": .officeOpenXML, "odt": .openDocument,
    ]
    static let images = Set(FileCategory.images.extensions)

    enum ExtractionError: LocalizedError {
        case unreadable
        var errorDescription: String? { "Súbor sa nepodarilo prečítať." }
    }

    static func extract(from url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()
        let text: String
        if ext == "pdf" {
            guard let doc = PDFDocument(url: url) else { throw ExtractionError.unreadable }
            text = doc.string ?? ""
        } else if let type = richText[ext] {
            let attributed = try NSAttributedString(url: url, options: [.documentType: type], documentAttributes: nil)
            text = attributed.string
        } else if images.contains(ext) {
            text = try recognizeText(in: url)
        } else {
            text = try String(contentsOf: url, encoding: .utf8)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// OCR cez Vision (funguje aj na skeny a screenshoty).
    private static func recognizeText(in url: URL) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(url: url).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}
