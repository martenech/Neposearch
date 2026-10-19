import Carbon.HIToolbox
import Foundation

/// Globálna klávesová skratka cez Carbon (nepotrebuje povolenie Accessibility).
final class HotKey {
    private static var handlers: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private static var isHandlerInstalled = false

    private var ref: EventHotKeyRef?
    private let id: UInt32

    init?(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        Self.installHandler()
        id = Self.nextID
        Self.nextID += 1
        let hotKeyID = EventHotKeyID(signature: OSType(0x4E45_504F), id: id)  // 'NEPO'
        guard RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref) == noErr else {
            return nil
        }
        Self.handlers[id] = handler
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        Self.handlers[id] = nil
    }

    private static func installHandler() {
        guard !isHandlerInstalled else { return }
        isHandlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            DispatchQueue.main.async { HotKey.handlers[hotKeyID.id]?() }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

/// Skratka na históriu schránky.
enum ClipboardHotKeyPreset: String, CaseIterable, Identifiable {
    case none, shiftCommandV, optionCommandV, controlOptionV

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "Žiadna"
        case .shiftCommandV: "⇧⌘V"
        case .optionCommandV: "⌥⌘V"
        case .controlOptionV: "⌃⌥V"
        }
    }

    var modifiers: UInt32? {
        switch self {
        case .none: nil
        case .shiftCommandV: UInt32(cmdKey | shiftKey)
        case .optionCommandV: UInt32(cmdKey | optionKey)
        case .controlOptionV: UInt32(controlKey | optionKey)
        }
    }

    var keyCode: UInt32 { UInt32(kVK_ANSI_V) }
}

/// Skratky na výber v nastaveniach.
enum HotKeyPreset: String, CaseIterable, Identifiable {
    case optionSpace, commandSpace, controlSpace, commandShiftSpace, optionShiftSpace

    var id: String { rawValue }

    var label: String {
        switch self {
        case .optionSpace: "⌥ Space"
        case .commandSpace: "⌘ Space"
        case .controlSpace: "⌃ Space"
        case .commandShiftSpace: "⇧⌘ Space"
        case .optionShiftSpace: "⇧⌥ Space"
        }
    }

    var keyCode: UInt32 { UInt32(kVK_Space) }

    var modifiers: UInt32 {
        switch self {
        case .optionSpace: UInt32(optionKey)
        case .commandSpace: UInt32(cmdKey)
        case .controlSpace: UInt32(controlKey)
        case .commandShiftSpace: UInt32(cmdKey | shiftKey)
        case .optionShiftSpace: UInt32(optionKey | shiftKey)
        }
    }
}

/// Systémová skratka Spotlightu (⌘ Space) – kým je zapnutá, macOS ju zachytí skôr než Neposearch.
enum SpotlightShortcut {
    /// Kľúč „64“ v `com.apple.symbolichotkeys` = „Zobraziť vyhľadávanie Spotlight“.
    /// Chýbajúci záznam znamená predvolený stav, teda zapnutá.
    static var isEnabled: Bool {
        guard
            let hotKeys = CFPreferencesCopyAppValue(
                "AppleSymbolicHotKeys" as CFString, "com.apple.symbolichotkeys" as CFString) as? [String: Any],
            let spotlight = hotKeys["64"] as? [String: Any],
            let enabled = spotlight["enabled"] as? Bool
        else { return true }
        return enabled
    }

    static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!
}
