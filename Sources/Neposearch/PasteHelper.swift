import AppKit
import Carbon.HIToolbox

/// Vloží text do aktívnej aplikácie (cez schránku a ⌘V) a potom vráti pôvodný obsah schránky.
@MainActor
enum PasteHelper {
    /// Typ, ktorým správcovia schránky (aj náš) označujú dočasný obsah – neukladá sa do histórie.
    static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    /// - Parameters:
    ///   - cursorOffset: o koľko znakov posunúť kurzor doľava po vložení (pre `{cursor}` v snippetoch).
    ///   - deleteBefore: koľko znakov najprv zmazať (kľúčové slovo snippetu).
    /// - Returns: `false`, ak chýba povolenie Accessibility (text ostane len v schránke).
    @discardableResult
    static func paste(_ text: String, into app: NSRunningApplication? = nil, deleteBefore: Int = 0, cursorOffset: Int = 0) -> Bool {
        let pasteboard = NSPasteboard.general
        let saved = snapshot(pasteboard)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        pasteboard.setData(Data(), forType: transientType)
        guard AXIsProcessTrusted() else { return false }

        app?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + (app == nil ? 0.02 : 0.15)) {
            for _ in 0..<deleteBefore { press(kVK_Delete) }
            press(kVK_ANSI_V, flags: .maskCommand)
            for _ in 0..<cursorOffset { press(kVK_LeftArrow) }
            // Pôvodný obsah schránky vrátime, až keď si aplikácia vložený text prečíta.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { restore(saved, to: pasteboard) }
        }
        return true
    }

    static func press(_ key: Int, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: false)
        down?.flags = flags
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    private static func snapshot(_ pasteboard: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        (pasteboard.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } })
        }
    }

    private static func restore(_ items: [[NSPasteboard.PasteboardType: Data]], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let restored = items.map { values -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in values { item.setData(data, forType: type) }
            // Obnovený obsah nie je nová položka histórie.
            item.setData(Data(), forType: transientType)
            return item
        }
        if !restored.isEmpty { pasteboard.writeObjects(restored) }
    }
}
