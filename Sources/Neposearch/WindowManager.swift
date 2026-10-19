import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Príkaz na presun/zmenu veľkosti okna (ako Window Management v Raycaste).
enum WindowCommand: String, CaseIterable, Identifiable, Sendable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case firstThird, centerThird, lastThird, firstTwoThirds, lastTwoThirds
    case maximize, toggleFullscreen, almostMaximize, center, larger, smaller, nextDisplay, restore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leftHalf: "Ľavá polovica"
        case .rightHalf: "Pravá polovica"
        case .topHalf: "Horná polovica"
        case .bottomHalf: "Dolná polovica"
        case .topLeft: "Ľavý horný roh"
        case .topRight: "Pravý horný roh"
        case .bottomLeft: "Ľavý dolný roh"
        case .bottomRight: "Pravý dolný roh"
        case .firstThird: "Prvá tretina"
        case .centerThird: "Stredná tretina"
        case .lastThird: "Posledná tretina"
        case .firstTwoThirds: "Prvé dve tretiny"
        case .lastTwoThirds: "Posledné dve tretiny"
        case .maximize: "Maximalizovať"
        case .toggleFullscreen: "Celá obrazovka"
        case .almostMaximize: "Takmer maximalizovať"
        case .center: "Vycentrovať"
        case .larger: "Zväčšiť"
        case .smaller: "Zmenšiť"
        case .nextDisplay: "Na ďalší monitor"
        case .restore: "Obnoviť pôvodnú veľkosť"
        }
    }

    /// Anglické názvy a ďalšie slová, podľa ktorých sa dá príkaz nájsť.
    private var aliases: [String] {
        switch self {
        case .leftHalf: ["left half", "vlavo"]
        case .rightHalf: ["right half", "vpravo"]
        case .topHalf: ["top half", "hore"]
        case .bottomHalf: ["bottom half", "dole"]
        case .topLeft: ["top left quarter", "stvrtina"]
        case .topRight: ["top right quarter", "stvrtina"]
        case .bottomLeft: ["bottom left quarter", "stvrtina"]
        case .bottomRight: ["bottom right quarter", "stvrtina"]
        case .firstThird: ["first third", "left third"]
        case .centerThird: ["center third", "middle third"]
        case .lastThird: ["last third", "right third"]
        case .firstTwoThirds: ["first two thirds"]
        case .lastTwoThirds: ["last two thirds"]
        case .maximize: ["maximize", "max", "roztiahnut"]
        case .toggleFullscreen: ["fullscreen", "full screen", "toggle fullscreen", "cela obrazovka", "na celu obrazovku"]
        case .almostMaximize: ["almost maximize"]
        case .center: ["center", "stred"]
        case .larger: ["make larger", "bigger", "vacsie"]
        case .smaller: ["make smaller", "mensie"]
        case .nextDisplay: ["next display", "next screen", "monitor", "obrazovka"]
        case .restore: ["restore", "undo", "povodna"]
        }
    }

    var searchNames: [String] {
        ([title] + aliases).map { IndexedFile.normalize($0) } + ["okno", "window"]
    }

    var symbol: String {
        switch self {
        case .leftHalf: "rectangle.lefthalf.filled"
        case .rightHalf: "rectangle.righthalf.filled"
        case .topHalf: "rectangle.tophalf.filled"
        case .bottomHalf: "rectangle.bottomhalf.filled"
        case .topLeft: "rectangle.inset.topleft.filled"
        case .topRight: "rectangle.inset.topright.filled"
        case .bottomLeft: "rectangle.inset.bottomleft.filled"
        case .bottomRight: "rectangle.inset.bottomright.filled"
        case .firstThird: "rectangle.leadingthird.inset.filled"
        case .centerThird: "rectangle.center.inset.filled"
        case .lastThird: "rectangle.trailingthird.inset.filled"
        case .firstTwoThirds: "rectangle.split.2x1.fill"
        case .lastTwoThirds: "rectangle.split.2x1.fill"
        case .maximize: "rectangle.inset.filled"
        case .toggleFullscreen: "arrow.up.left.and.arrow.down.right"
        case .almostMaximize: "rectangle.center.inset.filled"
        case .center: "rectangle.center.inset.filled"
        case .larger: "plus.rectangle"
        case .smaller: "minus.rectangle"
        case .nextDisplay: "display.2"
        case .restore: "arrow.uturn.backward"
        }
    }

    /// Globálne skratky (⌃⌥ + kláves), ak sú zapnuté v nastaveniach.
    var hotKey: (keyCode: Int, label: String)? {
        switch self {
        case .leftHalf: (kVK_LeftArrow, "⌃⌥←")
        case .rightHalf: (kVK_RightArrow, "⌃⌥→")
        case .topHalf: (kVK_UpArrow, "⌃⌥↑")
        case .bottomHalf: (kVK_DownArrow, "⌃⌥↓")
        case .maximize: (kVK_Return, "⌃⌥↩")
        case .toggleFullscreen: (kVK_ANSI_F, "⌃⌥F")
        case .center: (kVK_ANSI_C, "⌃⌥C")
        case .nextDisplay: (kVK_ANSI_N, "⌃⌥N")
        case .restore: (kVK_Delete, "⌃⌥⌫")
        default: nil
        }
    }

    /// Cieľový obdĺžnik v súradniciach AppKit (počiatok vľavo dole) v rámci viditeľnej plochy monitora.
    func frame(for current: CGRect, in area: CGRect) -> CGRect {
        let w = area.width, h = area.height, x = area.minX, y = area.minY
        switch self {
        case .leftHalf: return CGRect(x: x, y: y, width: w / 2, height: h)
        case .rightHalf: return CGRect(x: x + w / 2, y: y, width: w / 2, height: h)
        case .topHalf: return CGRect(x: x, y: y + h / 2, width: w, height: h / 2)
        case .bottomHalf: return CGRect(x: x, y: y, width: w, height: h / 2)
        case .topLeft: return CGRect(x: x, y: y + h / 2, width: w / 2, height: h / 2)
        case .topRight: return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case .bottomLeft: return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case .bottomRight: return CGRect(x: x + w / 2, y: y, width: w / 2, height: h / 2)
        case .firstThird: return CGRect(x: x, y: y, width: w / 3, height: h)
        case .centerThird: return CGRect(x: x + w / 3, y: y, width: w / 3, height: h)
        case .lastThird: return CGRect(x: x + 2 * w / 3, y: y, width: w / 3, height: h)
        case .firstTwoThirds: return CGRect(x: x, y: y, width: 2 * w / 3, height: h)
        case .lastTwoThirds: return CGRect(x: x + w / 3, y: y, width: 2 * w / 3, height: h)
        case .maximize: return area
        case .almostMaximize: return area.insetBy(dx: w * 0.05, dy: h * 0.05)
        case .center:
            let size = CGSize(width: min(current.width, w), height: min(current.height, h))
            return CGRect(x: area.midX - size.width / 2, y: area.midY - size.height / 2, width: size.width, height: size.height)
        case .larger, .smaller:
            let factor: CGFloat = self == .larger ? 1.1 : 0.9
            let size = CGSize(width: min(current.width * factor, w), height: min(current.height * factor, h))
            var rect = CGRect(x: current.midX - size.width / 2, y: current.midY - size.height / 2, width: size.width, height: size.height)
            rect.origin.x = min(max(rect.minX, area.minX), area.maxX - rect.width)
            rect.origin.y = min(max(rect.minY, area.minY), area.maxY - rect.height)
            return rect
        case .nextDisplay, .restore, .toggleFullscreen:
            return current  // riešené v WindowManager
        }
    }
}

/// Presúva okná iných aplikácií cez Accessibility API.
@MainActor
enum WindowManager {
    /// Pôvodné rámy okien pred poslednou zmenou (pre „Obnoviť“).
    private static var previousFrames: [Int: CGRect] = [:]

    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Zobrazí systémovú výzvu na povolenie a otvorí Nastavenia → Súkromie → Accessibility.
    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    enum Failure: LocalizedError {
        case notTrusted, noWindow, couldNotMove
        var errorDescription: String? {
            switch self {
            case .notTrusted: "Povoľ Neposearch v Nastaveniach → Súkromie a bezpečnosť → Accessibility."
            case .noWindow: "Nenašlo sa okno, s ktorým by sa dalo pohnúť."
            case .couldNotMove: "Toto okno sa nedá presunúť."
            }
        }
    }

    /// Vykoná príkaz na aktívnom okne danej aplikácie (predvolene tej v popredí).
    static func perform(_ command: WindowCommand, on app: NSRunningApplication? = nil) throws {
        guard isTrusted else {
            requestAccess()
            throw Failure.notTrusted
        }
        let target = app ?? NSWorkspace.shared.frontmostApplication
        guard let target, target.processIdentifier != ProcessInfo.processInfo.processIdentifier else { throw Failure.noWindow }
        let appElement = AXUIElementCreateApplication(target.processIdentifier)
        guard let window = focusedWindow(of: appElement), let current = frame(of: window) else { throw Failure.noWindow }
        let key = Int(CFHash(window))

        // Skutočný režim celej obrazovky macOS (okno na vlastnej ploche), nie len roztiahnutie.
        if command == .toggleFullscreen {
            let attribute = "AXFullScreen" as CFString
            var value: CFTypeRef?
            let isFullscreen = AXUIElementCopyAttributeValue(window, attribute, &value) == .success && (value as? Bool) == true
            guard AXUIElementSetAttributeValue(window, attribute, (!isFullscreen) as CFBoolean) == .success else {
                throw Failure.couldNotMove
            }
            return
        }

        let newFrame: CGRect
        switch command {
        case .restore:
            guard let previous = previousFrames[key] else { return }
            newFrame = previous
        case .nextDisplay:
            let screens = NSScreen.screens
            guard screens.count > 1, let screen = screen(containing: current),
                let index = screens.firstIndex(of: screen)
            else { return }
            let from = screen.visibleFrame, to = screens[(index + 1) % screens.count].visibleFrame
            // Zachová relatívnu polohu a veľkosť voči ploche monitora.
            let rel = CGRect(
                x: (current.minX - from.minX) / from.width, y: (current.minY - from.minY) / from.height,
                width: current.width / from.width, height: current.height / from.height)
            newFrame = CGRect(
                x: to.minX + rel.minX * to.width, y: to.minY + rel.minY * to.height,
                width: min(rel.width, 1) * to.width, height: min(rel.height, 1) * to.height)
        default:
            guard let area = screen(containing: current)?.visibleFrame else { throw Failure.noWindow }
            newFrame = command.frame(for: current, in: area).integral
        }

        if command != .restore { previousFrames[key] = current }
        withoutEnhancedUI(appElement) {
            setFrame(newFrame, of: window)
        }
    }

    // MARK: - Accessibility

    private static func focusedWindow(of app: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success, let value {
            return (value as! AXUIElement)
        }
        if AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &value) == .success, let value {
            return (value as! AXUIElement)
        }
        return nil
    }

    /// Rám okna v súradniciach AppKit.
    private static func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?, sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success
        else { return nil }
        var position = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return toAppKit(CGRect(origin: position, size: size))
    }

    private static func setFrame(_ rect: CGRect, of window: AXUIElement) {
        let ax = toAccessibility(rect)
        var position = ax.origin, size = ax.size
        guard let positionValue = AXValueCreate(.cgPoint, &position), let sizeValue = AXValueCreate(.cgSize, &size) else { return }
        // Veľkosť → poloha → veľkosť: okno sa tak nezasekne o okraj monitora pri presune medzi plochami.
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }

    /// Niektoré aplikácie (napr. s VoiceOver režimom) animujú zmeny a ignorujú ich; dočasne ho vypneme.
    private static func withoutEnhancedUI(_ app: AXUIElement, _ body: () -> Void) {
        let attribute = "AXEnhancedUserInterface" as CFString
        var value: CFTypeRef?
        let wasEnabled = AXUIElementCopyAttributeValue(app, attribute, &value) == .success && (value as? Bool) == true
        if wasEnabled { AXUIElementSetAttributeValue(app, attribute, kCFBooleanFalse) }
        body()
        if wasEnabled { AXUIElementSetAttributeValue(app, attribute, kCFBooleanTrue) }
    }

    // MARK: - Súradnice

    /// Accessibility má počiatok vľavo hore na hlavnom monitore, AppKit vľavo dole.
    private static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }

    private static func toAppKit(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    private static func toAccessibility(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    /// Monitor, na ktorom je najväčšia časť okna.
    private static func screen(containing rect: CGRect) -> NSScreen? {
        NSScreen.screens.max { a, b in
            let ia = a.frame.intersection(rect), ib = b.frame.intersection(rect)
            return ia.width * ia.height < ib.width * ib.height
        }
    }
}

/// Globálne skratky ⌃⌥ pre okná (zapínajú sa v nastaveniach).
@MainActor
final class WindowHotKeys {
    private var hotKeys: [HotKey] = []

    func update(enabled: Bool) {
        hotKeys = []
        guard enabled else { return }
        for command in WindowCommand.allCases {
            guard let key = command.hotKey else { continue }
            if let hotKey = HotKey(keyCode: UInt32(key.keyCode), modifiers: UInt32(controlKey | optionKey), handler: {
                MainActor.assumeIsolated { try? WindowManager.perform(command) }
            }) {
                hotKeys.append(hotKey)
            }
        }
    }
}
