import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Plávajúci panel, ktorý vie byť aktívny bez aktivovania celej aplikácie (ako Spotlight).
final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Spravuje okno spúšťača: globálnu skratku, zobrazenie/skrytie a klávesnicu.
@MainActor
final class LauncherController {
    static private(set) var shared: LauncherController?

    static let width: CGFloat = 680
    /// Horný okraj pruhu je vo výške 22 % od vrchu obrazovky.
    private static let topOffset: CGFloat = 0.22

    let model: LauncherModel
    private let settings: AppSettings
    private let panel: LauncherPanel
    private var hotKey: HotKey?
    private let windowHotKeys = WindowHotKeys()
    private var keyMonitor: Any?

    let clipboard: ClipboardStore
    private var clipboardHotKey: HotKey?

    let snippets: SnippetStore
    let snippetExpander: SnippetExpander
    let screenshots: ScreenshotIndex
    let claudeSessions: ClaudeSessionIndex
    let shellHistory: ShellHistory
    let people: PeopleIndex
    let mail: MailIndex
    let safari: SafariIndex

    static func setUp(indexer: Indexer, settings: AppSettings, clipboard: ClipboardStore, database: Database) {
        shared = LauncherController(indexer: indexer, settings: settings, clipboard: clipboard, database: database)
    }

    private init(indexer: Indexer, settings: AppSettings, clipboard: ClipboardStore, database: Database) {
        self.settings = settings
        self.clipboard = clipboard
        snippets = SnippetStore()
        snippetExpander = SnippetExpander(store: snippets)
        screenshots = ScreenshotIndex(database: database, settings: settings)
        claudeSessions = ClaudeSessionIndex(database: database, settings: settings, embedder: indexer.embedder)
        shellHistory = ShellHistory(settings: settings)
        people = PeopleIndex(database: database, settings: settings)
        mail = MailIndex(settings: settings)
        safari = SafariIndex(settings: settings)
        model = LauncherModel(
            indexer: indexer, clipboard: clipboard, settings: settings, snippets: snippets, screenshots: screenshots,
            claudeSessions: claudeSessions, shellHistory: shellHistory, people: people, mail: mail, safari: safari)
        panel = LauncherPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: LauncherView.barHeight),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        let root = LauncherView()
            .environment(model)
            .environment(indexer)
            .environment(settings)
        let hosting = NSHostingView(rootView: root)
        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = NSRect(x: 0, y: 0, width: Self.width, height: LauncherView.barHeight)
        panel.contentView = hosting

        model.onClose = { [weak self] in self?.hide() }
        model.onResize = { [weak self] height in self?.resize(to: height) }
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.hide() }
        }
        registerHotKey()
        registerClipboardHotKey()
        updateWindowHotKeys()
        updateSnippetExpansion()
    }

    func updateSnippetExpansion() {
        snippetExpander.update(enabled: settings.snippetExpansion)
    }

    func updateWindowHotKeys() {
        windowHotKeys.update(enabled: settings.windowHotKeys)
    }

    func registerClipboardHotKey() {
        clipboardHotKey = nil
        let preset = settings.clipboardHotKey
        guard settings.clipboardEnabled, let modifiers = preset.modifiers else { return }
        clipboardHotKey = HotKey(keyCode: preset.keyCode, modifiers: modifiers) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.panel.isVisible && self.model.mode == .clipboard { self.hide() } else { self.show(mode: .clipboard) }
            }
        }
    }

    var isClipboardHotKeyRegistered: Bool { clipboardHotKey != nil || settings.clipboardHotKey == .none }

    func registerHotKey() {
        hotKey = nil
        let preset = settings.hotKey
        hotKey = HotKey(keyCode: preset.keyCode, modifiers: preset.modifiers) { [weak self] in
            MainActor.assumeIsolated { self?.toggle() }
        }
    }

    var isHotKeyRegistered: Bool { hotKey != nil }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show(mode: LauncherModel.Mode = .search) {
        model.prepareForShow(mode: mode)
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            let height = panel.frame.height
            let top = visible.maxY - visible.height * Self.topOffset
            panel.setFrame(NSRect(x: visible.midX - Self.width / 2, y: top - height, width: Self.width, height: height), display: false)
        }
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }
        installKeyMonitor()
    }

    /// Zmení výšku okna podľa obsahu; horný okraj ostáva na mieste.
    private func resize(to height: CGFloat) {
        let frame = panel.frame
        guard abs(frame.height - height) > 0.5 else { return }
        panel.setFrame(NSRect(x: frame.minX, y: frame.maxY - height, width: Self.width, height: height), display: true)
        panel.invalidateShadow()
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// Šípky, Enter, Tab a Esc spracujeme skôr, ako ich dostane textové pole.
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let command = flags.contains(.command)
            let shift = flags.contains(.shift)
            let key = Int(event.keyCode)

            if model.isShowingActions {
                switch key {
                case kVK_DownArrow: model.moveAction(1)
                case kVK_UpArrow: model.moveAction(-1)
                case kVK_Return, kVK_ANSI_KeypadEnter: model.performSelectedAction()
                case kVK_Escape: model.escape()
                case kVK_ANSI_K where command: model.toggleActions()
                default: return event
                }
                return nil
            }

            if case .alias = model.mode {
                switch key {
                case kVK_Return, kVK_ANSI_KeypadEnter: model.saveAlias()
                case kVK_Escape: model.escape()
                default: return event
                }
                return nil
            }

            if model.mode == .clipboard {
                switch key {
                case kVK_ANSI_P where command:
                    model.perform(.pin)
                    return nil
                case kVK_Delete where command:
                    model.perform(.deleteClip)
                    return nil
                default: break
                }
            }
            if model.isListMode, key == kVK_Delete, !command, model.modeQuery.isEmpty {
                model.exitMode()
                return nil
            }

            switch key {
            case kVK_DownArrow: model.move(1)
            case kVK_UpArrow: model.move(-1)
            case kVK_Return, kVK_ANSI_KeypadEnter: model.activate(reveal: command)
            case kVK_Tab: model.ask()
            case kVK_Escape: model.escape()
            case kVK_ANSI_K where command: model.toggleActions()
            case kVK_ANSI_C where command && shift: model.perform(.copyPath)
            case kVK_ANSI_R where command: model.perform(.resummarize)
            default: return event
            }
            return nil
        }
    }
}
