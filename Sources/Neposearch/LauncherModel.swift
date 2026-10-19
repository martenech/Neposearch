import AppKit
import ObjectBox
import Observation

/// Príkazy spúšťača (otvárajú vlastný režim alebo niečo vykonajú).
enum LauncherCommand: String, CaseIterable, Identifiable {
    case clipboardHistory, snippets, screenshots, browserTabs, claudeSessions, shellHistory, gitCommits
    case calendar, reminders, people, mail, webHistory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clipboardHistory: "História schránky"
        case .snippets: "Snippety"
        case .screenshots: "Hľadať v screenshotoch"
        case .browserTabs: "Karty prehliadača"
        case .claudeSessions: "Sedenia Claude Code"
        case .shellHistory: "História terminálu"
        case .gitCommits: "Git commity"
        case .calendar: "Kalendár"
        case .reminders: "Pripomienky"
        case .people: "Ľudia a firmy"
        case .mail: "Mail"
        case .webHistory: "Safari – história a záložky"
        }
    }

    var subtitle: String {
        switch self {
        case .clipboardHistory: "Všetko, čo si skopíroval"
        case .snippets: "Uložené texty na vloženie"
        case .screenshots: "Podľa textu na snímke"
        case .browserTabs: "Otvorené karty v prehliadačoch"
        case .claudeSessions: "Hľadať a pokračovať v minulých sedeniach"
        case .shellHistory: "Príkazy, ktoré si spustil (fish, zsh)"
        case .gitCommits: "Commity v projektoch v ~/Projects"
        case .calendar: "Najbližšie stretnutia (14 dní)"
        case .reminders: "Nesplnené pripomienky"
        case .people: "Kontakty, firmy a všetko, čo s nimi súvisí"
        case .mail: "Hľadať v e-mailoch"
        case .webHistory: "Navštívené stránky, záložky, Zoznam na čítanie"
        }
    }

    var symbol: String {
        switch self {
        case .clipboardHistory: "doc.on.clipboard"
        case .snippets: "text.quote"
        case .screenshots: "camera.viewfinder"
        case .browserTabs: "safari"
        case .claudeSessions: "terminal"
        case .shellHistory: "chevron.left.forwardslash.chevron.right"
        case .gitCommits: "point.topleft.down.to.point.bottomright.curvepath"
        case .calendar: "calendar"
        case .reminders: "checklist"
        case .people: "person.2"
        case .mail: "envelope"
        case .webHistory: "clock.arrow.circlepath"
        }
    }

    var searchNames: [String] {
        switch self {
        case .clipboardHistory:
            ["historia schranky", "schranka", "clipboard history", "clipboard", "kopirovane", "vlozit"]
        case .snippets: ["snippety", "snippets", "texty", "sablony"]
        case .screenshots: ["screenshoty", "screenshots", "snimky obrazovky", "screeny"]
        case .browserTabs: ["karty", "tabs", "prehliadac", "browser", "safari", "chrome"]
        case .claudeSessions: ["claude code", "sedenia", "sessions", "historia claude", "konverzacie"]
        case .shellHistory: ["historia terminalu", "terminal history", "shell history", "prikazy", "commands", "fish", "zsh"]
        case .gitCommits: ["git commity", "commits", "git log", "zmeny v projektoch"]
        case .calendar: ["kalendar", "calendar", "stretnutia", "meetings", "dnes", "zajtra", "agenda"]
        case .reminders: ["pripomienky", "reminders", "ulohy", "todo", "tasks"]
        case .people: ["ludia", "people", "kontakty", "contacts", "firmy", "osoby"]
        case .mail: ["mail", "e-maily", "emaily", "posta", "spravy"]
        case .webHistory: ["safari", "historia", "history", "zalozky", "bookmarks", "web"]
        }
    }
}

/// Výber a akcie v spúšťači. Výsledky hľadania súborov berie z `Indexer`.
@MainActor @Observable
final class LauncherModel {
    enum Mode: Equatable {
        case search, clipboard, snippets, screenshots, tabs, claudeSessions, shell, commits
        case calendar, reminders, people, mail, web
        /// Všetko, čo súvisí s osobou alebo firmou.
        case person(id: UInt64, name: String)
        case organization(id: UInt64, name: String)
        /// Zadávanie aliasu pre riadok (id, názov).
        case alias(id: String, title: String)
    }

    enum Row: Identifiable {
        case calculation(CalculationResult)
        case app(AppEntry)
        case command(LauncherCommand)
        case window(WindowCommand)
        case system(SystemCommand)
        case snippet(Snippet)
        case tab(BrowserTab)
        case screenshot(ScreenshotItem)
        case claudeSession(ClaudeSession)
        case shellCommand(ShellCommand)
        case commit(GitCommit)
        case person(Person)
        case organization(Organization)
        case event(CalendarEvent)
        case reminder(ReminderItem)
        case mail(MailMessage)
        case web(WebPage)
        case file(IndexedFile)
        case clip(ClipboardItem)
        case ask

        var id: String {
            switch self {
            case .calculation: "calc"
            case .app(let app): "app:\(app.path)"
            case .command(let command): "command:\(command.rawValue)"
            case .window(let command): "window:\(command.rawValue)"
            case .system(let command): "system:\(command.rawValue)"
            case .snippet(let snippet): "snippet:\(snippet.id)"
            case .tab(let tab): "tab:\(tab.id)"
            case .screenshot(let item): "screenshot:\(item.id.value)"
            case .claudeSession(let session): "session:\(session.id.value)"
            case .shellCommand(let command): "shell:\(command.command)"
            case .commit(let commit): "commit:\(commit.id)"
            case .person(let person): "person:\(person.id.value)"
            case .organization(let organization): "org:\(organization.id.value)"
            case .event(let event): "event:\(event.id.value)"
            case .reminder(let reminder): "reminder:\(reminder.id.value)"
            case .mail(let message): "mail:\(message.id)"
            case .web(let page): "web:\(page.id)"
            case .file(let file): "file:\(file.id.value)"
            case .clip(let item): "clip:\(item.id.value)"
            case .ask: "ask"
            }
        }

        /// Riadky rovnakého druhu patria do jednej sekcie.
        var section: String {
            switch self {
            case .calculation: "Kalkulačka"
            case .app: "Aplikácie"
            case .command: "Príkazy"
            case .window: "Okná"
            case .system: "Systém"
            case .snippet: "Snippety"
            case .tab: "Karty"
            case .screenshot: "Screenshoty"
            case .claudeSession: "Claude Code"
            case .shellCommand: "Terminál"
            case .commit: "Git"
            case .person: "Ľudia"
            case .organization: "Firmy a projekty"
            case .event: "Kalendár"
            case .reminder: "Pripomienky"
            case .mail: "Mail"
            case .web: "Safari"
            case .file: "Súbory"
            case .clip(let item): item.isPinned ? "Pripnuté" : "História"
            case .ask: "Claude"
            }
        }
    }

    /// Akcie pre vybraný riadok (menu ⌘K).
    enum Action: String, CaseIterable, Identifiable {
        case open, reveal, copyPath, copySummary, resummarize, ask
        case paste, copyClip, pin, deleteClip, clearClipboard, copyResult, setAlias
        case copyText, copyImage, copyURL, copyCommand, runInTerminal, copyHash
        case email, call, copyEmail, openInContacts, joinMeeting, completeReminder

        var id: String { rawValue }

        var title: String {
            switch self {
            case .open: "Otvoriť"
            case .reveal: "Ukázať vo Finderi"
            case .copyPath: "Kopírovať cestu"
            case .copySummary: "Kopírovať zhrnutie"
            case .resummarize: "Znova zhrnúť"
            case .ask: "Opýtať sa Claude"
            case .paste: "Vložiť do aplikácie"
            case .copyClip: "Kopírovať"
            case .pin: "Pripnúť / odopnúť"
            case .deleteClip: "Vymazať"
            case .clearClipboard: "Vymazať celú históriu"
            case .copyResult: "Kopírovať výsledok"
            case .setAlias: "Nastaviť alias"
            case .copyText: "Kopírovať text zo snímky"
            case .copyImage: "Kopírovať obrázok"
            case .copyURL: "Kopírovať URL"
            case .copyCommand: "Kopírovať príkaz"
            case .runInTerminal: "Spustiť v novom okne terminálu"
            case .copyHash: "Kopírovať hash"
            case .email: "Napísať e-mail"
            case .call: "Zavolať"
            case .copyEmail: "Kopírovať e-mail"
            case .openInContacts: "Otvoriť v Kontaktoch"
            case .joinMeeting: "Pripojiť sa k stretnutiu"
            case .completeReminder: "Označiť ako hotové"
            }
        }

        var symbol: String {
            switch self {
            case .open: "arrow.up.forward.app"
            case .reveal: "folder"
            case .copyPath: "doc.on.doc"
            case .copySummary: "text.quote"
            case .resummarize: "arrow.clockwise"
            case .ask: "sparkles"
            case .paste: "doc.on.clipboard"
            case .copyClip, .copyResult: "doc.on.doc"
            case .pin: "pin"
            case .deleteClip: "trash"
            case .clearClipboard: "trash.slash"
            case .setAlias: "character.cursor.ibeam"
            case .copyText: "text.viewfinder"
            case .copyImage: "photo.on.rectangle"
            case .copyURL: "link"
            case .copyCommand: "terminal"
            case .runInTerminal: "play.rectangle"
            case .copyHash: "number"
            case .email: "envelope"
            case .call: "phone"
            case .copyEmail: "at"
            case .openInContacts: "person.crop.circle"
            case .joinMeeting: "video"
            case .completeReminder: "checkmark.circle"
            }
        }

        var shortcut: String {
            switch self {
            case .open, .paste, .copyResult: "↩"
            case .reveal, .copyClip: "⌘↩"
            case .copyPath: "⇧⌘C"
            case .resummarize: "⌘R"
            case .ask: "Tab"
            case .pin: "⌘P"
            case .deleteClip: "⌘⌫"
            case .copySummary, .clearClipboard, .setAlias, .copyText, .copyImage, .copyURL, .copyCommand, .runInTerminal, .copyHash, .email, .call, .copyEmail, .openInContacts, .joinMeeting, .completeReminder: ""
            }
        }
    }

    let indexer: Indexer
    let clipboard: ClipboardStore
    let settings: AppSettings
    let snippets: SnippetStore
    let screenshots: ScreenshotIndex
    let browserTabs = BrowserTabsStore()
    let claudeSessions: ClaudeSessionIndex
    let shellHistory: ShellHistory
    let gitCommits = GitCommits()
    let people: PeopleIndex
    let mail: MailIndex
    let safari: SafariIndex
    /// Príkaz čakajúci na potvrdenie druhým ↩.
    private(set) var pendingConfirmation: SystemCommand?
    let apps = AppCatalog()
    let calculator = Calculator()

    private(set) var mode: Mode = .search
    /// Rozpísaný alias v režime `.alias`.
    var aliasDraft = ""
    /// Text hľadania v režime schránky (v bežnom režime sa hľadá cez `indexer.searchText`).
    var modeQuery = "" {
        didSet { selection = 0 }
    }
    /// Aplikácia, ktorá bola v popredí pri otvorení spúšťača (do nej sa vkladá a jej okno sa posúva).
    private(set) var targetApp: NSRunningApplication?
    var selection = 0
    var isShowingActions = false
    var actionSelection = 0
    /// Krátke potvrdenie akcie („Cesta skopírovaná“).
    private(set) var toast: String?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    /// Zvýši sa pri každom otvorení, aby si pole na hľadanie vzalo fokus.
    private(set) var focusToken = 0
    @ObservationIgnored var onClose: () -> Void = {}
    /// Volá sa, keď sa zmení výška obsahu (pruh sa rozbalí/zbalí).
    @ObservationIgnored var onResize: (CGFloat) -> Void = { _ in }

    init(
        indexer: Indexer, clipboard: ClipboardStore, settings: AppSettings, snippets: SnippetStore, screenshots: ScreenshotIndex,
        claudeSessions: ClaudeSessionIndex, shellHistory: ShellHistory, people: PeopleIndex,
        mail: MailIndex, safari: SafariIndex
    ) {
        self.mail = mail
        self.safari = safari
        self.people = people
        self.claudeSessions = claudeSessions
        self.shellHistory = shellHistory
        self.indexer = indexer
        self.clipboard = clipboard
        self.settings = settings
        self.snippets = snippets
        self.screenshots = screenshots
        apps.refreshIfNeeded()
    }

    private var query: String { indexer.searchText.trimmingCharacters(in: .whitespaces) }

    // MARK: - Riadky

    @ObservationIgnored private var cachedAppKey = ""
    @ObservationIgnored private var cachedApps: [AppEntry] = []

    /// Aplikácie, ktoré zodpovedajú dotazu (výsledok sa pamätá, kým sa nezmení dotaz alebo zoznam aplikácií).
    private var matchingApps: [AppEntry] {
        let key = "\(apps.apps.count)|\(query)"
        if key != cachedAppKey {
            cachedAppKey = key
            cachedApps = apps.search(query)
        }
        return cachedApps
    }

    /// Príkazy (napr. na okná), ktoré zodpovedajú dotazu.
    private func matching<C: CaseIterable>(_ type: C.Type, names: (C) -> [String], limit: Int) -> [C] {
        // Bez koncoviek, aby „ľavá“ našlo aj „Ľavý horný roh“.
        let q = IndexedFile.searchTerms(query).joined(separator: " ")
        guard !q.isEmpty else { return [] }
        return type.allCases
            .compactMap { item in names(item).compactMap { AppCatalog.score(name: $0, query: q) }.max().map { (item, $0) } }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    /// Riadok podľa id (pre aliasy).
    private func row(forID id: String) -> Row? {
        let parts = id.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "window": return WindowCommand(rawValue: parts[1]).map(Row.window)
        case "command": return LauncherCommand(rawValue: parts[1]).map(Row.command)
        case "system": return SystemCommand(rawValue: parts[1]).map(Row.system)
        case "app": return apps.apps.first { $0.path == parts[1] }.map(Row.app)
        default: return nil
        }
    }

    /// Príkazy, ktorých alias začína napísaným textom (presná zhoda prvá).
    private var aliasRows: [Row] {
        let q = query.lowercased()
        guard !q.contains(" ") else { return [] }
        return settings.aliases
            .filter { $0.value.hasPrefix(q) }
            .sorted { ($0.value == q ? 0 : 1, $0.value.count) < ($1.value == q ? 0 : 1, $1.value.count) }
            .compactMap { row(forID: $0.key) }
    }

    func alias(for row: Row) -> String? {
        settings.aliases[row.id]
    }

    var rows: [Row] {
        switch mode {
        case .clipboard: return clipboard.items(matching: modeQuery).map(Row.clip)
        case .snippets:
            return (modeQuery.isEmpty ? snippets.snippets : snippets.search(modeQuery, limit: 50)).map(Row.snippet)
        case .screenshots: return screenshots.search(modeQuery, limit: 50).map(Row.screenshot)
        case .tabs: return browserTabs.search(modeQuery, limit: 100).map(Row.tab)
        case .claudeSessions: return claudeSessions.search(modeQuery, limit: 50).map(Row.claudeSession)
        case .shell: return shellHistory.search(modeQuery, limit: 100).map(Row.shellCommand)
        case .commits: return gitCommits.search(modeQuery, limit: 100).map(Row.commit)
        case .calendar:
            return (modeQuery.isEmpty ? people.upcomingEvents(days: 14, limit: 100) : people.searchEvents(modeQuery, limit: 100))
                .map(Row.event)
        case .reminders: return people.searchReminders(modeQuery, limit: 100).map(Row.reminder)
        case .mail: return mail.search(modeQuery, limit: 100).map(Row.mail)
        case .web: return safari.search(modeQuery, limit: 100).map(Row.web)
        case .people:
            return people.searchOrganizations(modeQuery, limit: 30).map(Row.organization)
                + people.searchPeople(modeQuery, limit: 100).map(Row.person)
        case .person(let id, _): return filtered(relatedRows(personID: id))
        case .organization(let id, _): return filtered(relatedRows(organizationID: id))
        case .alias: return []
        case .search: break
        }
        // Medzi nedávnymi ukážeme len zhrnuté súbory; spúšťač ukáže najviac 20 súborov.
        let files = (query.isEmpty && !indexer.isAskMode
            ? indexer.files.filter { $0.indexStatus == .done || $0.indexStatus == .processing }
            : indexer.files).prefix(20)
        guard !query.isEmpty, !indexer.isAskMode else { return files.map(Row.file) }

        // Aliasy navrchu, potom kalkulačka, aplikácie, príkazy, okná, súbory a Claude.
        var rows = aliasRows
        var seen = Set(rows.map(\.id))
        func add(_ new: [Row]) {
            for row in new where seen.insert(row.id).inserted { rows.append(row) }
        }
        if let result = calculator.evaluate(query) { add([.calculation(result)]) }
        add(matchingApps.map(Row.app))
        add(matching(LauncherCommand.self, names: \.searchNames, limit: 3).map(Row.command))
        add(matching(SystemCommand.self, names: \.searchNames, limit: 4).map(Row.system))
        add(matching(WindowCommand.self, names: \.searchNames, limit: 6).map(Row.window))
        if settings.contactsEnabled {
            add(people.searchPeople(query, limit: 3).map(Row.person))
            add(people.searchOrganizations(query, limit: 2).map(Row.organization))
        }
        if settings.calendarEnabled {
            add(people.searchEvents(query, limit: 3).map(Row.event))
            add(people.searchReminders(query, limit: 2).map(Row.reminder))
        }
        if settings.mailEnabled && query.count >= 3 { add(mail.search(query, limit: 3).map(Row.mail)) }
        if settings.safariEnabled && query.count >= 3 { add(safari.search(query, limit: 3).map(Row.web)) }
        add(snippets.search(query, limit: 3).map(Row.snippet))
        add(browserTabs.search(query, limit: 4).map(Row.tab))
        if settings.screenshotsEnabled { add(screenshots.search(query, limit: 3).map(Row.screenshot)) }
        if settings.claudeSessionsEnabled { add(claudeSessions.search(query, limit: 3).map(Row.claudeSession)) }
        if settings.shellHistoryEnabled && query.count >= 2 { add(shellHistory.search(query, limit: 3).map(Row.shellCommand)) }
        if query.count >= 3 { add(gitCommits.search(query, limit: 3).map(Row.commit)) }
        add(files.map(Row.file))
        add([.ask])
        return rows
    }

    var selectedRow: Row? {
        let rows = rows
        return rows.indices.contains(selection) ? rows[selection] : nil
    }

    var selectedFile: IndexedFile? {
        if case .file(let file)? = selectedRow { return file }
        return nil
    }

    var selectedApp: AppEntry? {
        if case .app(let app)? = selectedRow { return app }
        return nil
    }

    var selectedClip: ClipboardItem? {
        if case .clip(let item)? = selectedRow { return item }
        return nil
    }

    // MARK: - Akcie

    var availableActions: [Action] {
        switch selectedRow {
        case .clip?: return [.paste, .copyClip, .pin, .deleteClip, .clearClipboard]
        case .calculation?: return [.copyResult]
        case .app?: return [.open, .reveal, .copyPath, .setAlias]
        case .file?: return [.open, .reveal, .copyPath, .copySummary, .resummarize] + (query.isEmpty ? [] : [.ask])
        case .ask?: return [.ask]
        case .command?, .window?, .system?: return [.open, .setAlias]
        case .snippet?: return [.paste, .copyClip]
        case .tab?: return [.open, .copyURL]
        case .screenshot?: return [.open, .reveal, .copyText, .copyImage]
        case .claudeSession?: return [.open, .reveal, .copyCommand]
        case .shellCommand?: return [.paste, .copyClip, .runInTerminal]
        case .commit?: return [.open, .reveal, .copyHash]
        case .person(let person)?:
            var actions: [Action] = [.open]
            if !person.emails.isEmpty { actions += [.email, .copyEmail] }
            if !person.phones.isEmpty { actions.append(.call) }
            if !person.contactIdentifier.isEmpty { actions.append(.openInContacts) }
            return actions
        case .organization?: return [.open]
        case .event(let event)?: return event.meetingURL.isEmpty ? [.open] : [.open, .joinMeeting]
        case .reminder?: return [.open, .completeReminder]
        case .mail?: return [.open, .copyText]
        case .web?: return [.open, .copyURL]
        case nil: return []
        }
    }

    func perform(_ action: Action) {
        isShowingActions = false
        switch action {
        case .ask: ask()
        case .open, .paste, .copyResult: activate(reveal: false)
        case .reveal, .copyClip: activate(reveal: true)
        case .copyPath:
            if let path = selectedApp?.path ?? selectedFile?.path { copy(path, toast: "Cesta skopírovaná") }
        case .copySummary:
            if let file = selectedFile { copy(file.summary, toast: "Zhrnutie skopírované") }
        case .resummarize:
            if let file = selectedFile {
                indexer.resummarize(file)
                showToast("Súbor sa znova zhrnie")
            }
        case .pin:
            if let item = selectedClip {
                clipboard.togglePin(item)
                showToast(item.isPinned ? "Pripnuté" : "Odopnuté")
            }
        case .deleteClip:
            if let item = selectedClip {
                clipboard.delete(item)
                selection = min(selection, max(rows.count - 1, 0))
            }
        case .clearClipboard:
            clipboard.clearHistory()
            selection = 0
            showToast("História vymazaná")
        case .setAlias:
            if let row = selectedRow { beginAlias(for: row) }
        case .copyText:
            if case .screenshot(let item)? = selectedRow { copy(item.text, toast: "Text skopírovaný") }
            if case .mail(let message)? = selectedRow { copy("\(message.subject)\n\(message.summary)", toast: "Skopírované") }
        case .copyImage:
            if case .screenshot(let item)? = selectedRow, let image = NSImage(contentsOf: item.url) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([image])
                showToast("Obrázok skopírovaný")
            }
        case .copyURL:
            if case .tab(let tab)? = selectedRow { copy(tab.url, toast: "URL skopírovaná") }
            if case .web(let page)? = selectedRow { copy(page.url, toast: "URL skopírovaná") }
        case .copyCommand:
            if case .claudeSession(let session)? = selectedRow { copy(session.resumeCommand, toast: "Príkaz skopírovaný") }
        case .copyHash:
            if case .commit(let commit)? = selectedRow { copy(commit.hash, toast: "Hash skopírovaný") }
        case .email:
            if case .person(let person)? = selectedRow, let email = person.firstEmail,
                let url = URL(string: "mailto:\(email)")
            {
                onClose()
                NSWorkspace.shared.open(url)
            }
        case .call:
            if case .person(let person)? = selectedRow, let phone = person.phones.split(separator: ",").first,
                let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })")
            {
                onClose()
                NSWorkspace.shared.open(url)
            }
        case .copyEmail:
            if case .person(let person)? = selectedRow, let email = person.firstEmail { copy(email, toast: "E-mail skopírovaný") }
        case .openInContacts:
            if case .person(let person)? = selectedRow, let url = URL(string: "addressbook://\(person.contactIdentifier)") {
                onClose()
                NSWorkspace.shared.open(url)
            }
        case .joinMeeting:
            if case .event(let event)? = selectedRow, let url = URL(string: event.meetingURL) {
                onClose()
                NSWorkspace.shared.open(url)
            }
        case .completeReminder:
            if case .reminder(let item)? = selectedRow {
                people.complete(item)
                showToast("Hotovo ✓")
            }
        case .runInTerminal:
            if case .shellCommand(let command)? = selectedRow {
                onClose()
                TerminalLauncher.run(command.command, in: settings.terminalApp)
            }
        }
    }

    func toggleActions() {
        isShowingActions.toggle()
        actionSelection = 0
    }

    func moveAction(_ delta: Int) {
        let count = availableActions.count
        guard count > 0 else { return }
        actionSelection = (actionSelection + delta + count) % count
    }

    func performSelectedAction() {
        let actions = availableActions
        guard actions.indices.contains(actionSelection) else { return }
        perform(actions[actionSelection])
    }

    private func copy(_ text: String, toast: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        showToast(toast)
    }

    private func showToast(_ text: String) {
        toastTask?.cancel()
        toast = text
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    // MARK: - Otvorenie, pohyb, potvrdenie

    func prepareForShow(mode: Mode = .search) {
        let frontmost = NSWorkspace.shared.frontmostApplication
        targetApp = frontmost?.processIdentifier == ProcessInfo.processInfo.processIdentifier ? nil : frontmost
        isShowingActions = false
        if indexer.isAskMode { indexer.cancelAsk() }
        indexer.searchText = ""
        modeQuery = ""
        self.mode = mode
        selection = 0
        focusToken += 1
        apps.refreshIfNeeded()
        calculator.refreshRatesIfNeeded()
        browserTabs.refresh()
        gitCommits.refreshIfNeeded()
        mail.refreshIfNeeded()
        safari.refreshIfNeeded()
        pendingConfirmation = nil
    }

    func move(_ delta: Int) {
        pendingConfirmation = nil
        let count = rows.count
        guard count > 0 else { return }
        selection = min(max(selection + delta, 0), count - 1)
    }

    /// ↩ (alebo ⌘↩ = `reveal`): otvorí/spustí/vloží podľa druhu riadku.
    func activate(reveal: Bool) {
        switch selectedRow {
        case .calculation(let result)?:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.copyValue, forType: .string)
            onClose()
        case .app(let app)?:
            if reveal {
                NSWorkspace.shared.activateFileViewerSelecting([app.url])
            } else {
                apps.recordLaunch(app)
                NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration())
            }
            onClose()
        case .command(let command)?:
            run(command)
        case .window(let command)?:
            onClose()
            let target = targetApp
            // Až po skrytí spúšťača, aby sa okno aplikácie znova stalo aktívnym.
            DispatchQueue.main.async {
                target?.activate()
                do {
                    try WindowManager.perform(command, on: target)
                } catch {
                    NSSound.beep()
                }
            }
        case .file(let file)?:
            if reveal {
                NSWorkspace.shared.activateFileViewerSelecting([file.url])
            } else {
                NSWorkspace.shared.open(file.url)
            }
            onClose()
        case .system(let command)?:
            if command.needsConfirmation && pendingConfirmation != command {
                pendingConfirmation = command
                showToast("Stlač ↩ ešte raz na potvrdenie")
                return
            }
            pendingConfirmation = nil
            onClose()
            let target = targetApp
            DispatchQueue.main.async {
                if command.run(targetApp: target) != nil { NSSound.beep() }
            }
        case .snippet(let snippet)?:
            let expansion = snippet.expanded()
            if reveal {
                copy(expansion.text, toast: "Skopírované")
                return
            }
            onClose()
            let target = targetApp
            DispatchQueue.main.async {
                PasteHelper.paste(expansion.text, into: target, cursorOffset: expansion.cursorOffset)
            }
        case .tab(let tab)?:
            onClose()
            browserTabs.activate(tab)
        case .person(let person)?:
            if reveal, !person.contactIdentifier.isEmpty {
                perform(.openInContacts)
            } else {
                enter(.person(id: person.id.value, name: person.name))
            }
        case .organization(let organization)?:
            enter(.organization(id: organization.id.value, name: organization.name))
        case .event(let event)?:
            onClose()
            if reveal, let url = URL(string: event.meetingURL), !event.meetingURL.isEmpty {
                NSWorkspace.shared.open(url)
            } else {
                Self.openInCalendar(event)
            }
        case .mail(let message)?:
            onClose()
            if let url = message.url { NSWorkspace.shared.open(url) }
        case .web(let page)?:
            onClose()
            if let url = URL(string: page.url) { NSWorkspace.shared.open(url) }
        case .reminder:
            onClose()
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: "/System/Applications/Reminders.app"), configuration: NSWorkspace.OpenConfiguration())
        case .commit(let commit)?:
            onClose()
            if reveal {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: commit.repoPath)])
            } else {
                TerminalLauncher.run(commit.showCommand, in: settings.terminalApp)
            }
        case .shellCommand(let command)?:
            if reveal {
                copy(command.command, toast: "Príkaz skopírovaný")
                return
            }
            onClose()
            let target = targetApp
            DispatchQueue.main.async { PasteHelper.paste(command.command, into: target) }
        case .claudeSession(let session)?:
            onClose()
            if reveal {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: session.projectPath)])
            } else {
                TerminalLauncher.run(session.resumeCommand, in: settings.terminalApp)
            }
        case .screenshot(let item)?:
            if reveal {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } else {
                NSWorkspace.shared.open(item.url)
            }
            onClose()
        case .clip(let item)?:
            onClose()
            if reveal {
                clipboard.copyToPasteboard(item)
            } else {
                let target = targetApp
                DispatchQueue.main.async { [clipboard] in clipboard.paste(item, into: target) }
            }
        case .ask?:
            ask()
        case nil:
            break
        }
    }

    private func run(_ command: LauncherCommand) {
        switch command {
        case .clipboardHistory: enter(.clipboard)
        case .snippets: enter(.snippets)
        case .screenshots: enter(.screenshots)
        case .browserTabs: enter(.tabs)
        case .claudeSessions: enter(.claudeSessions)
        case .shellHistory: enter(.shell)
        case .gitCommits: enter(.commits)
        case .calendar: enter(.calendar)
        case .reminders: enter(.reminders)
        case .people: enter(.people)
        case .mail: enter(.mail)
        case .webHistory: enter(.web)
        }
    }

    // MARK: - Všetko súvisiace s osobou / firmou

    private func relatedRows(personID: UInt64) -> [Row] {
        guard let person = try? people.persons.get(Id(personID)) else { return [] }
        var rows: [Row] = [.person(person)]
        if let organization = people.searchOrganizations(person.organizationName, limit: 1).first, !person.organizationName.isEmpty {
            rows.append(.organization(organization))
        }
        rows += people.events(with: person).prefix(10).map(Row.event)
        let emails = Set(person.emails.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        if settings.mailEnabled { rows += mail.messages(from: emails, limit: 10).map(Row.mail) }
        rows += person.files.sorted { $0.lastActivity > $1.lastActivity }.prefix(30).map(Row.file)
        rows += relatedByText(person.name)
        return rows
    }

    private func relatedRows(organizationID: UInt64) -> [Row] {
        guard let organization = try? people.organizations.get(Id(organizationID)) else { return [] }
        var rows: [Row] = [.organization(organization)]
        let colleagues = ((try? people.persons.all()) ?? []).filter { IndexedFile.normalize($0.organizationName) == organization.nameKey }
        rows += colleagues.map(Row.person)
        rows += people.searchEvents(organization.name, limit: 10).map(Row.event)
        rows += organization.files.sorted { $0.lastActivity > $1.lastActivity }.prefix(30).map(Row.file)
        rows += relatedByText(organization.name)
        return rows
    }

    /// Screenshoty, schránka a sedenia Claude Code, kde sa meno spomína.
    private func relatedByText(_ name: String) -> [Row] {
        var rows: [Row] = []
        if settings.screenshotsEnabled { rows += screenshots.search(name, limit: 5).map(Row.screenshot) }
        rows += clipboard.items(matching: name, limit: 5).map(Row.clip)
        if settings.claudeSessionsEnabled { rows += claudeSessions.search(name, limit: 3).map(Row.claudeSession) }
        return rows
    }

    /// Zúženie zoznamu „všetko súvisiace“ podľa napísaného textu.
    private func filtered(_ rows: [Row]) -> [Row] {
        let terms = IndexedFile.searchTerms(modeQuery)
        guard !terms.isEmpty else { return rows }
        return rows.filter { row in
            let text: String
            switch row {
            case .file(let file): text = file.searchKey
            case .event(let event): text = event.searchKey
            case .person(let person): text = person.searchKey
            case .organization(let organization): text = organization.searchKey
            case .screenshot(let item): text = item.searchKey
            case .clip(let item): text = item.searchKey
            case .claudeSession(let session): text = session.searchKey
            default: text = ""
            }
            return terms.allSatisfy { text.contains($0) }
        }
    }

    /// Otvorí udalosť v Kalendári.
    static func openInCalendar(_ event: CalendarEvent) {
        let identifier = event.eventIdentifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? event.eventIdentifier
        if let url = URL(string: "ical://ekevent/\(identifier)?method=show&options=more"), NSWorkspace.shared.open(url) { return }
        if let url = URL(string: "calshow:\(event.start.timeIntervalSinceReferenceDate)") { NSWorkspace.shared.open(url) }
    }

    /// Režim so zoznamom (schránka, snippety, screenshoty, karty) má vlastné pole na hľadanie.
    var isListMode: Bool {
        switch mode {
        case .search, .alias: false
        default: true
        }
    }

    var modeTitle: String {
        switch mode {
        case .clipboard: "Schránka"
        case .snippets: "Snippety"
        case .screenshots: "Screenshoty"
        case .tabs: "Karty"
        case .claudeSessions: "Claude Code"
        case .shell: "Terminál"
        case .commits: "Git"
        case .calendar: "Kalendár"
        case .reminders: "Pripomienky"
        case .people: "Ľudia"
        case .mail: "Mail"
        case .web: "Safari"
        case .person(_, let name), .organization(_, let name): name
        default: ""
        }
    }

    var modeSymbol: String {
        switch mode {
        case .clipboard: "doc.on.clipboard"
        case .snippets: "text.quote"
        case .screenshots: "camera.viewfinder"
        case .tabs: "safari"
        case .claudeSessions: "terminal"
        case .shell: "chevron.left.forwardslash.chevron.right"
        case .commits: "point.topleft.down.to.point.bottomright.curvepath"
        case .calendar: "calendar"
        case .reminders: "checklist"
        case .people: "person.2"
        case .mail: "envelope"
        case .web: "clock.arrow.circlepath"
        case .person: "person.crop.circle"
        case .organization: "building.2"
        default: "magnifyingglass"
        }
    }

    var modeEmptyText: String {
        if !modeQuery.isEmpty { return "Nič sa nenašlo." }
        switch mode {
        case .clipboard: return "História schránky je prázdna. Skopíruj niečo (⌘C)."
        case .snippets: return "Zatiaľ nemáš žiadne snippety. Pridáš ich v Nastaveniach → Snippety."
        case .screenshots: return settings.screenshotsEnabled ? "V priečinku so snímkami obrazovky zatiaľ nič nie je." : "Hľadanie v screenshotoch je vypnuté v Nastaveniach."
        case .tabs: return browserTabs.problem ?? "Žiadne otvorené karty (Safari, Chrome, Arc, Brave, Edge)."
        case .claudeSessions:
            return settings.claudeSessionsEnabled ? "Zatiaľ žiadne sedenia Claude Code." : "Hľadanie v sedeniach je vypnuté v Nastaveniach."
        case .shell:
            return settings.shellHistoryEnabled ? "História terminálu je prázdna." : "História terminálu je vypnutá v Nastaveniach."
        case .commits: return "V ~/Projects sa nenašli žiadne git repozitáre."
        case .calendar: return people.calendarProblem ?? "Žiadne stretnutia v najbližších 14 dňoch."
        case .reminders: return people.calendarProblem ?? "Žiadne nesplnené pripomienky."
        case .people: return people.contactsProblem ?? "Žiadne kontakty."
        case .mail: return mail.problem ?? (settings.mailEnabled ? "Žiadne e-maily." : "Mail je vypnutý v Nastaveniach.")
        case .web: return safari.problem ?? (settings.safariEnabled ? "Žiadna história." : "Safari je vypnuté v Nastaveniach.")
        case .person, .organization: return "Zatiaľ sa s tým nič nespája."
        default: return ""
        }
    }

    func enter(_ newMode: Mode) {
        isShowingActions = false
        modeQuery = ""
        if newMode == .tabs { browserTabs.refresh() }
        mode = newMode
        selection = 0
        focusToken += 1
    }

    private func title(of row: Row) -> String {
        switch row {
        case .app(let app): app.name
        case .command(let command): command.title
        case .window(let command): command.title
        case .system(let command): command.title
        default: ""
        }
    }

    func beginAlias(for row: Row) {
        isShowingActions = false
        aliasDraft = alias(for: row) ?? ""
        mode = .alias(id: row.id, title: title(of: row))
        focusToken += 1
    }

    /// ↩ v režime aliasu: uloží alias a vráti sa do hľadania s týmto aliasom.
    func saveAlias() {
        guard case .alias(let id, _) = mode else { return }
        let alias = aliasDraft.trimmingCharacters(in: .whitespaces).lowercased()
        settings.setAlias(alias, for: id)
        exitMode()
        indexer.searchText = alias
        showToast(alias.isEmpty ? "Alias zmazaný" : "Alias „\(alias)“ uložený")
    }

    func exitMode() {
        isShowingActions = false
        mode = .search
        selection = 0
        focusToken += 1
    }

    func ask() {
        guard mode == .search, !query.isEmpty, !indexer.isAsking else { return }
        indexer.askClaude()
        selection = 0
    }

    /// Esc: zavrie menu akcií / odpoveď Claude / režim schránky, potom vymaže text, potom zavrie okno.
    func escape() {
        if isShowingActions {
            isShowingActions = false
        } else if case .alias = mode {
            exitMode()
        } else if isListMode {
            if modeQuery.isEmpty { exitMode() } else { modeQuery = "" }
        } else if indexer.isAskMode {
            indexer.cancelAsk()
        } else if !indexer.searchText.isEmpty {
            indexer.searchText = ""
        } else {
            onClose()
        }
    }
}
