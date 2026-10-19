import AppKit
import Carbon.HIToolbox

/// Systémové príkazy v spúšťači (zamknúť, uspať, vysypať kôš…).
enum SystemCommand: String, CaseIterable, Identifiable {
    case lockScreen, sleep, displaySleep, screenSaver
    case emptyTrash, toggleDarkMode, toggleMute
    case quitApp, forceQuitApp, hideOthers, ejectAll
    case restart, shutDown, logOut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lockScreen: "Zamknúť obrazovku"
        case .sleep: "Uspať Mac"
        case .displaySleep: "Vypnúť obrazovku"
        case .screenSaver: "Spustiť šetrič obrazovky"
        case .emptyTrash: "Vysypať kôš"
        case .toggleDarkMode: "Prepnúť tmavý režim"
        case .toggleMute: "Stlmiť / zapnúť zvuk"
        case .quitApp: "Ukončiť aplikáciu"
        case .forceQuitApp: "Vynútiť ukončenie aplikácie"
        case .hideOthers: "Skryť ostatné aplikácie"
        case .ejectAll: "Vysunúť všetky disky"
        case .restart: "Reštartovať"
        case .shutDown: "Vypnúť Mac"
        case .logOut: "Odhlásiť sa"
        }
    }

    private var aliases: [String] {
        switch self {
        case .lockScreen: ["lock screen", "zamknut", "zamok"]
        case .sleep: ["sleep", "uspat", "spanok"]
        case .displaySleep: ["display sleep", "turn off display", "vypnut monitor"]
        case .screenSaver: ["screen saver", "setric"]
        case .emptyTrash: ["empty trash", "kos", "vysypat"]
        case .toggleDarkMode: ["dark mode", "tmavy", "svetly rezim", "toggle appearance"]
        case .toggleMute: ["mute", "unmute", "zvuk", "hlasitost", "stlmit"]
        case .quitApp: ["quit", "ukoncit", "zavriet aplikaciu"]
        case .forceQuitApp: ["force quit", "kill", "zabit"]
        case .hideOthers: ["hide others", "hide all", "skryt"]
        case .ejectAll: ["eject", "vysunut", "disky", "unmount"]
        case .restart: ["restart", "reboot", "restartovat"]
        case .shutDown: ["shut down", "power off", "vypnut"]
        case .logOut: ["log out", "odhlasit"]
        }
    }

    var searchNames: [String] {
        ([title] + aliases).map { IndexedFile.normalize($0) } + ["system", "systemove"]
    }

    var symbol: String {
        switch self {
        case .lockScreen: "lock"
        case .sleep: "moon.zzz"
        case .displaySleep: "display"
        case .screenSaver: "sparkles.tv"
        case .emptyTrash: "trash"
        case .toggleDarkMode: "circle.lefthalf.filled"
        case .toggleMute: "speaker.slash"
        case .quitApp: "xmark.app"
        case .forceQuitApp: "bolt.trianglebadge.exclamationmark"
        case .hideOthers: "eye.slash"
        case .ejectAll: "eject"
        case .restart: "arrow.clockwise.circle"
        case .shutDown: "power"
        case .logOut: "rectangle.portrait.and.arrow.right"
        }
    }

    /// Nevratné príkazy treba potvrdiť druhým ↩.
    var needsConfirmation: Bool {
        [.emptyTrash, .forceQuitApp, .restart, .shutDown, .logOut].contains(self)
    }

    /// Popis pod názvom; pri príkazoch na aplikáciu jej názov.
    func subtitle(targetApp: NSRunningApplication?) -> String {
        switch self {
        case .quitApp, .forceQuitApp: targetApp?.localizedName.map { "Aplikácia \($0)" } ?? "Aktívna aplikácia"
        case .hideOthers: targetApp?.localizedName.map { "Okrem \($0)" } ?? "Okrem aktívnej aplikácie"
        default: needsConfirmation ? "Systém · vyžaduje potvrdenie" : "Systém"
        }
    }

    /// Vykoná príkaz. Chyba sa vráti ako text na zobrazenie.
    @MainActor
    func run(targetApp: NSRunningApplication?) -> String? {
        switch self {
        case .lockScreen:
            return Self.lockScreen() ? nil : "Obrazovku sa nepodarilo zamknúť."
        case .sleep:
            return Self.shell("/usr/bin/pmset", ["sleepnow"])
        case .displaySleep:
            return Self.shell("/usr/bin/pmset", ["displaysleepnow"])
        case .screenSaver:
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app"),
                configuration: NSWorkspace.OpenConfiguration())
            return nil
        case .emptyTrash:
            return Self.appleScript(#"tell application "Finder" to empty trash"#)
        case .toggleDarkMode:
            return Self.appleScript(
                #"tell application "System Events" to tell appearance preferences to set dark mode to not dark mode"#)
        case .toggleMute:
            return Self.appleScript("set volume output muted (not (output muted of (get volume settings)))")
        case .quitApp:
            guard let targetApp else { return "Žiadna aktívna aplikácia." }
            targetApp.terminate()
            return nil
        case .forceQuitApp:
            guard let targetApp else { return "Žiadna aktívna aplikácia." }
            targetApp.forceTerminate()
            return nil
        case .hideOthers:
            for app in NSWorkspace.shared.runningApplications
            where app.activationPolicy == .regular && app.processIdentifier != targetApp?.processIdentifier {
                app.hide()
            }
            targetApp?.activate()
            return nil
        case .ejectAll:
            let volumes = FileManager.default.mountedVolumeURLs(
                includingResourceValuesForKeys: [.volumeIsEjectableKey, .volumeIsRemovableKey], options: [.skipHiddenVolumes]) ?? []
            var failed: [String] = []
            for url in volumes where url.path.hasPrefix("/Volumes/") {
                let values = try? url.resourceValues(forKeys: [.volumeIsEjectableKey, .volumeIsRemovableKey])
                guard values?.volumeIsEjectable == true || values?.volumeIsRemovable == true else { continue }
                do { try NSWorkspace.shared.unmountAndEjectDevice(at: url) } catch { failed.append(url.lastPathComponent) }
            }
            return failed.isEmpty ? nil : "Nepodarilo sa vysunúť: \(failed.joined(separator: ", "))"
        case .restart:
            return Self.appleScript(#"tell application "System Events" to restart"#)
        case .shutDown:
            return Self.appleScript(#"tell application "System Events" to shut down"#)
        case .logOut:
            return Self.appleScript(#"tell application "System Events" to log out"#)
        }
    }

    // MARK: - Pomocné

    /// Zamknutie cez súkromnú funkciu login.framework (ako ⌃⌘Q); záložne cez skratku ⌃⌘Q.
    private static func lockScreen() -> Bool {
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        if let handle = dlopen(path, RTLD_LAZY), let symbol = dlsym(handle, "SACLockScreenImmediate") {
            typealias LockFunction = @convention(c) () -> Int32
            _ = unsafeBitCast(symbol, to: LockFunction.self)()
            return true
        }
        guard AXIsProcessTrusted() else { return false }
        let source = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_Q), keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_Q), keyDown: false)
        down?.flags = [.maskCommand, .maskControl]
        up?.flags = [.maskCommand, .maskControl]
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        return true
    }

    private static func shell(_ path: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        do { try process.run() } catch { return error.localizedDescription }
        return nil
    }

    /// AppleScript (pri prvom použití sa macOS opýta na povolenie ovládať Finder / System Events).
    private static func appleScript(_ source: String) -> String? {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        guard let error else { return nil }
        if (error[NSAppleScript.errorNumber] as? Int) == -1743 {
            return "Povoľ Neposearch v Nastaveniach → Súkromie → Automatizácia."
        }
        return error[NSAppleScript.errorMessage] as? String ?? "Príkaz zlyhal."
    }
}
