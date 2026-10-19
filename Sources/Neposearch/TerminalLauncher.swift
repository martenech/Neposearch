import AppKit

/// Terminál, v ktorom spúšťame príkazy (pokračovanie v sedení Claude Code a pod.).
enum TerminalApp: String, CaseIterable, Identifiable {
    case iTerm, terminal

    var id: String { rawValue }
    var label: String { self == .iTerm ? "iTerm" : "Terminál" }
    var path: String { self == .iTerm ? "/Applications/iTerm.app" : "/System/Applications/Utilities/Terminal.app" }
    var isInstalled: Bool { FileManager.default.fileExists(atPath: path) }

    static var preferred: TerminalApp { TerminalApp.iTerm.isInstalled ? .iTerm : .terminal }
}

enum TerminalLauncher {
    /// Otvorí nové okno terminálu a spustí v ňom príkaz (cez AppleScript; prvýkrát sa macOS opýta na povolenie).
    static func run(_ command: String, in app: TerminalApp) {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script: String
        switch app {
        case .iTerm:
            script = """
                tell application "iTerm"
                    activate
                    set newWindow to (create window with default profile)
                    tell current session of newWindow to write text "\(escaped)"
                end tell
                """
        case .terminal:
            script = """
                tell application "Terminal"
                    activate
                    do script "\(escaped)"
                end tell
                """
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try? process.run()
        }
    }

    /// Cesta v jednoduchých úvodzovkách pre shell.
    static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
