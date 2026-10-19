import AppKit
import Observation

/// Prehliadač, z ktorého vieme čítať karty cez AppleScript.
enum Browser: String, CaseIterable, Sendable {
    case safari, chrome, arc, brave, edge

    var bundleID: String {
        switch self {
        case .safari: "com.apple.Safari"
        case .chrome: "com.google.Chrome"
        case .arc: "company.thebrowser.Browser"
        case .brave: "com.brave.Browser"
        case .edge: "com.microsoft.edgemac"
        }
    }

    /// Názov aplikácie pre AppleScript.
    var scriptName: String {
        switch self {
        case .safari: "Safari"
        case .chrome: "Google Chrome"
        case .arc: "Arc"
        case .brave: "Brave Browser"
        case .edge: "Microsoft Edge"
        }
    }

    /// Vypíše karty ako „okno␟karta␟názov␟URL␞“ (oddeľovače ASCII 31 a 30).
    var listScript: String {
        let title = self == .safari ? "name" : "title"
        return """
            tell application "\(scriptName)"
                set out to ""
                repeat with w from 1 to count of windows
                    repeat with t from 1 to count of tabs of window w
                        set out to out & w & (character id 31) & t & (character id 31) & (\(title) of tab t of window w) & (character id 31) & (URL of tab t of window w) & (character id 30)
                    end repeat
                end repeat
                return out
            end tell
            """
    }

    func activateScript(window: Int, tab: Int) -> String {
        switch self {
        case .safari:
            """
            tell application "Safari"
                set current tab of window \(window) to tab \(tab) of window \(window)
                set index of window \(window) to 1
                activate
            end tell
            """
        case .arc:
            """
            tell application "Arc"
                tell tab \(tab) of window \(window) to select
                activate
            end tell
            """
        default:
            """
            tell application "\(scriptName)"
                set active tab index of window \(window) to \(tab)
                set index of window \(window) to 1
                activate
            end tell
            """
        }
    }
}

struct BrowserTab: Hashable, Sendable, Identifiable {
    let browser: Browser
    let appPath: String
    let window: Int
    let tab: Int
    let title: String
    let url: String

    var id: String { "\(browser.rawValue):\(window):\(tab):\(url)" }
    var host: String { URL(string: url)?.host() ?? url }
    var searchKey: String { IndexedFile.normalize("\(title) \(url)") }
}

/// Otvorené karty v bežiacich prehliadačoch. Načítajú sa pri otvorení spúšťača.
@MainActor @Observable
final class BrowserTabsStore {
    private(set) var tabs: [BrowserTab] = []
    private(set) var problem: String?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    func refresh() {
        refreshTask?.cancel()
        let running = Browser.allCases.compactMap { browser -> (Browser, String)? in
            guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: browser.bundleID).first,
                let path = app.bundleURL?.path
            else { return nil }
            return (browser, path)
        }
        guard !running.isEmpty else {
            tabs = []
            return
        }
        refreshTask = Task {
            var all: [BrowserTab] = []
            var denied = false
            for (browser, path) in running {
                let result = await Self.osascript(browser.listScript)
                if result.status != 0 {
                    if result.error.contains("-1743") { denied = true }
                    continue
                }
                for record in result.output.split(separator: "\u{1E}") {
                    let fields = record.split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
                    guard fields.count >= 4, let w = Int(fields[0]), let t = Int(fields[1]) else { continue }
                    all.append(BrowserTab(browser: browser, appPath: path, window: w, tab: t, title: fields[2], url: fields[3]))
                }
            }
            guard !Task.isCancelled else { return }
            tabs = all
            problem = denied ? "Povoľ Neposearch ovládať prehliadač (Nastavenia → Súkromie → Automatizácia)." : nil
        }
    }

    func search(_ query: String, limit: Int) -> [BrowserTab] {
        let terms = IndexedFile.searchTerms(query)
        guard !terms.isEmpty else { return Array(tabs.prefix(limit)) }
        return Array(tabs.filter { tab in terms.allSatisfy { tab.searchKey.contains($0) } }.prefix(limit))
    }

    func activate(_ tab: BrowserTab) {
        let script = tab.browser.activateScript(window: tab.window, tab: tab.tab)
        Task { _ = await Self.osascript(script) }
    }

    /// AppleScript cez `osascript` na pozadí (NSAppleScript by blokoval hlavné vlákno).
    private static func osascript(_ script: String) async -> (output: String, error: String, status: Int32) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                let out = Pipe(), err = Pipe()
                process.standardOutput = out
                process.standardError = err
                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: ("", error.localizedDescription, -1))
                    return
                }
                let output = out.fileHandleForReading.readDataToEndOfFile()
                let error = err.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                continuation.resume(returning: (
                    String(decoding: output, as: UTF8.self).trimmingCharacters(in: .newlines),
                    String(decoding: error, as: UTF8.self), process.terminationStatus))
            }
        }
    }
}
