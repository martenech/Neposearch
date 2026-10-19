import AppKit
import ServiceManagement
import SwiftUI

@main
struct NeposearchApp: App {
    @State private var settings: AppSettings
    @State private var indexer: Indexer

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        ThemeStore.shared.applyAppearance()
        Self.enableLoginItemOnce()
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        let indexer: Indexer
        let database: Database
        do {
            database = try Database()
            indexer = try Indexer(settings: settings, database: database)
        } catch {
            fatalError("Nepodarilo sa otvoriť databázu: \(error)")
        }
        _indexer = State(initialValue: indexer)
        let clipboard = ClipboardStore(database: database, settings: settings)
        LauncherController.setUp(indexer: indexer, settings: settings, clipboard: clipboard, database: database)
        // Na vývoj: `Neposearch --show-launcher [dotaz]` otvorí spúšťač hneď po štarte.
        let args = CommandLine.arguments
        if args.contains("--show-clipboard") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { LauncherController.shared?.show(mode: .clipboard) }
        }
        if let flag = args.firstIndex(of: "--show-launcher") {
            let query = args.indices.contains(flag + 1) ? args[flag + 1] : nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                LauncherController.shared?.show()
                if let query { indexer.searchText = query }
            }
        }
    }

    /// Pri prvom spustení z /Applications zapne spustenie pri prihlásení (dá sa vypnúť v Nastaveniach).
    private static func enableLoginItemOnce() {
        let key = "loginItemConfigured"
        guard Bundle.main.bundlePath.hasPrefix("/Applications/"), !UserDefaults.standard.bool(forKey: key) else { return }
        try? SMAppService.mainApp.register()
        UserDefaults.standard.set(true, forKey: key)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(indexer)
                .environment(settings)
                .tint(ThemeStore.shared.accent)
        } label: {
            Image(systemName: indexer.currentFileName == nil ? "doc.text.magnifyingglass" : "sparkles")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(indexer)
                .environment(settings)
        }
    }
}
