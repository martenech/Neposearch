import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(Indexer.self) private var indexer
    @State private var claudeCodeStatus: ClaudeCodeModel.Status?

    private func aliasField(_ title: String, id: String) -> some View {
        LabeledContent(title) {
            TextField("", text: Binding(
                get: { settings.aliases[id] ?? "" },
                set: { settings.setAlias($0, for: id) }
            ), prompt: Text("alias"))
            .frame(width: 90)
            .multilineTextAlignment(.trailing)
        }
    }

    var body: some View {
        TabView {
            Tab("Všeobecné", systemImage: "gearshape") { general }
            Tab("Vzhľad", systemImage: "paintpalette") { AppearanceSettings() }
            Tab("AI", systemImage: "sparkles") { ai }
            Tab("Klávesnica", systemImage: "keyboard") { keyboard }
            Tab("Snippety", systemImage: "text.quote") { SnippetSettings() }
            Tab("Schránka", systemImage: "doc.on.clipboard") { clipboard }
        }
        .frame(width: 560, height: 600)
        .onAppear { NSApp.activate() }
        .task { claudeCodeStatus = await ClaudeCodeModel.status() }
    }

    private func page(@ViewBuilder _ content: () -> some View) -> some View {
        Form { content() }.formStyle(.grouped)
    }

    private var general: some View {
        @Bindable var settings = settings
        return page {
            Section("Priečinok") {
                LabeledContent("Indexovaný priečinok") {
                    Text(settings.watchedFolder ?? "nevybraný").foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            }
            Section("Spúšťanie") {
                LoginItemToggle()
            }
            Section("Vyhľadávanie") {
                Picker("Klávesová skratka", selection: $settings.hotKey) {
                    ForEach(HotKeyPreset.allCases) { Text($0.label).tag($0) }
                }
                .onChange(of: settings.hotKey) { LauncherController.shared?.registerHotKey() }
                if settings.hotKey == .commandSpace && SpotlightShortcut.isEnabled {
                    HStack {
                        Text("⌘ Space zatiaľ zachytáva Spotlight. Vypni ho v Nastaveniach systému → Klávesnica → Klávesové skratky → Spotlight.")
                            .font(.caption).foregroundStyle(.orange)
                        Button("Otvoriť") { NSWorkspace.shared.open(SpotlightShortcut.settingsURL) }
                            .controlSize(.small)
                    }
                } else if LauncherController.shared?.isHotKeyRegistered == false {
                    Text("Túto skratku už používa iná aplikácia, vyber inú.").font(.caption).foregroundStyle(.orange)
                }
            }
            Section("Mail a Safari") {
                Toggle(isOn: $settings.mailEnabled) {
                    Text("Hľadať v e-mailoch (Mail)")
                    Text("Predmet, odosielateľ a úryvok správy. ↩ otvorí e-mail v Maile.")
                }
                .onChange(of: settings.mailEnabled) { LauncherController.shared?.mail.refreshIfNeeded() }
                Toggle(isOn: $settings.safariEnabled) {
                    Text("Hľadať v histórii a záložkách Safari")
                }
                .onChange(of: settings.safariEnabled) { LauncherController.shared?.safari.refreshIfNeeded() }
                if let controller = LauncherController.shared {
                    if let problem = controller.mail.problem ?? controller.safari.problem {
                        Text(problem).font(.caption).foregroundStyle(.orange)
                        Button("Otvoriť Úplný prístup k disku…") { FullDiskAccess.openSettings() }
                    }
                    LabeledContent("V indexe") {
                        Text("\(controller.mail.messages.count) e-mailov · \(controller.safari.pages.count) stránok").foregroundStyle(.secondary)
                    }
                }
                Text("Čítajú sa len lokálne, nič sa neposiela von. Potrebujú Úplný prístup k disku.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Kontakty a kalendár") {
                Toggle(isOn: $settings.contactsEnabled) {
                    Text("Osoby a firmy z Kontaktov")
                    Text("Prepoja sa so súbormi, v ktorých zhrnutí sa spomínajú, a so stretnutiami.")
                }
                .onChange(of: settings.contactsEnabled) { LauncherController.shared?.people.start() }
                Toggle(isOn: $settings.calendarEnabled) {
                    Text("Kalendár a Pripomienky")
                    Text("Stretnutia 90 dní dozadu a 60 dopredu, nesplnené pripomienky.")
                }
                .onChange(of: settings.calendarEnabled) { LauncherController.shared?.people.start() }
                Toggle(isOn: $settings.entitiesEnabled) {
                    Text("Osoby, firmy a projekty zo súborov")
                    Text("Claude roztriedi mená z kľúčových slov súborov (po dávkach, len nové názvy).")
                }
                .onChange(of: settings.entitiesEnabled) { LauncherController.shared?.people.start() }
                if let people = LauncherController.shared?.people {
                    if let progress = people.extractionProgress {
                        Text("Claude triedi názvy zo súborov: \(progress.done)/\(progress.total)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let problem = people.contactsProblem ?? people.calendarProblem ?? people.extractionProblem {
                        Text(problem).font(.caption).foregroundStyle(.orange)
                    }
                    LabeledContent("V indexe") {
                        Text("\(people.personCount) osôb · \(people.organizationCount) firiem · \(people.eventCount) udalostí · \(people.reminderCount) pripomienok")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Prepojené súbory") { Text("\(people.linkedFileCount)").foregroundStyle(.secondary) }
                }
            }
            Section("Claude Code") {
                Toggle(isOn: $settings.claudeSessionsEnabled) {
                    Text("Hľadať v sedeniach Claude Code")
                    Text("Tvoje otázky a odpovede z ~/.claude/projects. ↩ pokračuje v sedení v termináli.")
                }
                .onChange(of: settings.claudeSessionsEnabled) { LauncherController.shared?.claudeSessions.start() }
                Picker("Terminál", selection: $settings.terminalApp) {
                    ForEach(TerminalApp.allCases.filter(\.isInstalled)) { Text($0.label).tag($0) }
                }
                if let index = LauncherController.shared?.claudeSessions {
                    LabeledContent("V indexe") { Text("\(index.count) sedení").foregroundStyle(.secondary) }
                }
            }
            Section("Terminál") {
                Toggle(isOn: $settings.shellHistoryEnabled) {
                    Text("Hľadať v histórii terminálu")
                    Text("Príkazy z fish, zsh a bash. Ostávajú len na tvojom Macu.")
                }
                .onChange(of: settings.shellHistoryEnabled) { LauncherController.shared?.shellHistory.start() }
                if let history = LauncherController.shared?.shellHistory {
                    LabeledContent("V histórii") { Text("\(history.commands.count) príkazov").foregroundStyle(.secondary) }
                }
            }
            Section("Screenshoty") {
                Toggle(isOn: $settings.screenshotsEnabled) {
                    Text("Hľadať v screenshotoch")
                    Text("Text na snímkach obrazovky sa rozpozná lokálne (OCR), bez AI a bez nákladov.")
                }
                .onChange(of: settings.screenshotsEnabled) { LauncherController.shared?.screenshots.start() }
                LabeledContent("Priečinok") {
                    Text(ScreenshotIndex.folder.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .foregroundStyle(.secondary)
                }
                if let index = LauncherController.shared?.screenshots {
                    LabeledContent("V indexe") {
                        Text(index.isIndexing ? "\(index.count) · čítam nové…" : "\(index.count) snímok").foregroundStyle(.secondary)
                    }
                }
            }
            Section("Typy súborov") {
                ForEach(FileCategory.allCases) { category in
                    Toggle(isOn: Binding(
                        get: { settings.enabledCategories.contains(category) },
                        set: { isOn in
                            if isOn { settings.enabledCategories.insert(category) } else { settings.enabledCategories.remove(category) }
                        }
                    )) {
                        Text(category.label)
                        Text(category.extensions.joined(separator: ", "))
                    }
                }
                TextField("Vlastné prípony", text: $settings.customExtensions, prompt: Text("napr. eml, srt, vtt"))
                Text("Vlastné prípony sa čítajú ako obyčajný text. Súbory vypnutých typov sa z indexu odstránia.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Použiť a prehľadať priečinok znova") { indexer.start() }
                    .disabled(settings.watchedFolder == nil)
            }
        }
    }

    private var ai: some View {
        @Bindable var settings = settings
        return page {
            Section("AI súhrny") {
                Picker("Model", selection: $settings.backend) {
                    ForEach(AIBackend.allCases) { Text($0.label).tag($0) }
                }
                if settings.backend == .claudeCode {
                    Picker("Model", selection: $settings.claudeCodeModel) {
                        ForEach(ClaudeCodeModel.models, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Jazyk súhrnov", text: $settings.summaryLanguage)
                    LabeledContent("Stav") {
                        switch claudeCodeStatus {
                        case nil: ProgressView().controlSize(.small)
                        case let s? where !s.installed: Text("Nenainštalovaný: brew install --cask claude-code").foregroundStyle(.orange)
                        case let s? where !s.signedIn: Text("Neprihlásený: v termináli spusti claude auth login").foregroundStyle(.orange)
                        default: Label("Prihlásený", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                    Text("Používa tvoje Claude Pro/Max predplatné, bez API kľúča. Zhrnutia sa počítajú do limitov predplatného, Haiku ich míňa najmenej.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if settings.backend == .claude {
                    SecureField("Anthropic API kľúč", text: $settings.apiKey)
                    Picker("Claude model", selection: $settings.claudeModel) {
                        ForEach(AppSettings.claudeModels, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Jazyk súhrnov", text: $settings.summaryLanguage)
                    Text("Obsah súborov sa posiela na Anthropic API.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if let reason = AppleModel.unavailabilityReason {
                    Label(reason, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                } else {
                    Text("Beží lokálne na tvojom Macu. Apple model zatiaľ nepodporuje slovenčinu, súhrny budú po anglicky.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Použiť a znova skúsiť čakajúce súbory") { indexer.retryPendingAndFailed() }
            }
            Section("Vyhľadávanie podľa významu") {
                LabeledContent("Model") { Text("multilingual-e5-small (lokálne)").foregroundStyle(.secondary) }
                LabeledContent("Stav") {
                    if let problem = indexer.embeddingProblem {
                        Text(problem).foregroundStyle(.orange)
                    } else if let progress = indexer.embeddingProgress {
                        Text("Počítam vektory \(progress.done)/\(progress.total)").foregroundStyle(.secondary)
                    } else {
                        Label("Pripravený", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
                Text("Beží na tvojom Macu, nič sa neposiela von. Model (~490 MB) je v ~/Library/Application Support/Neposearch/models.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var keyboard: some View {
        @Bindable var settings = settings
        return page {
            Section("Okná") {
                LabeledContent("Accessibility") {
                    if WindowManager.isTrusted {
                        Label("Povolené", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button("Povoliť…") { WindowManager.requestAccess() }
                    }
                }
                Toggle(isOn: $settings.windowHotKeys) {
                    Text("Klávesové skratky pre okná")
                    Text("⌃⌥← → ↑ ↓ polovice, ⌃⌥↩ maximalizovať, ⌃⌥F celá obrazovka, ⌃⌥C vycentrovať, ⌃⌥N ďalší monitor, ⌃⌥⌫ obnoviť")
                }
                .onChange(of: settings.windowHotKeys) { LauncherController.shared?.updateWindowHotKeys() }
                Text("Príkazy na okná nájdeš aj v spúšťači, napr. „ľavá“, „max“, „monitor“.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Aliasy") {
                Text("Napíš alias do spúšťača a ↩ príkaz hneď spustí (napr. wsl = ľavá polovica). Aplikáciám nastavíš alias v spúšťači cez ⌘K → Nastaviť alias.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(LauncherCommand.allCases) { command in
                    aliasField(command.title, id: "command:\(command.rawValue)")
                }
                ForEach(WindowCommand.allCases) { command in
                    aliasField(command.title, id: "window:\(command.rawValue)")
                }
                ForEach(settings.aliases.keys.filter { $0.hasPrefix("app:") }.sorted(), id: \.self) { id in
                    aliasField(((id.dropFirst(4) as Substring).split(separator: "/").last.map(String.init) ?? id)
                        .replacingOccurrences(of: ".app", with: ""), id: id)
                }
            }
        }
    }

    private var clipboard: some View {
        @Bindable var settings = settings
        return page {
            Section("Schránka") {
                Toggle("Ukladať históriu schránky", isOn: $settings.clipboardEnabled)
                    .onChange(of: settings.clipboardEnabled) {
                        LauncherController.shared?.clipboard.updateMonitoring()
                        LauncherController.shared?.registerClipboardHotKey()
                    }
                Picker("Klávesová skratka", selection: $settings.clipboardHotKey) {
                    ForEach(ClipboardHotKeyPreset.allCases) { Text($0.label).tag($0) }
                }
                .disabled(!settings.clipboardEnabled)
                .onChange(of: settings.clipboardHotKey) { LauncherController.shared?.registerClipboardHotKey() }
                if LauncherController.shared?.isClipboardHotKeyRegistered == false {
                    Text("Túto skratku už používa iná aplikácia, vyber inú.").font(.caption).foregroundStyle(.orange)
                }
                Text("Ukladá sa posledných 1000 položiek za 90 dní, pripnuté navždy. Heslá zo správcov hesiel sa neukladajú. ↩ vloží položku do aktívnej aplikácie (potrebuje Accessibility).")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Vymazať históriu (okrem pripnutých)", role: .destructive) {
                    LauncherController.shared?.clipboard.clearHistory()
                }
            }
        }
    }
}

// MARK: - Vzhľad

private struct AppearanceSettings: View {
    @Bindable private var theme = ThemeStore.shared

    var body: some View {
        Form {
            ForEach([("Téma", nil), ("Tmavé témy", AppearanceMode.dark), ("Svetlé témy", AppearanceMode.light)], id: \.0) { title, mode in
                Section(title) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                        ForEach(ThemePreset.all.filter { $0.appearance == mode }) { preset in
                            ThemeSwatch(preset: preset, isSelected: preset.id == theme.presetID)
                                .onTapGesture { theme.presetID = preset.id }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            Section {
                Picker("Vzhľad", selection: $theme.appearance) {
                    ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(theme.preset.appearance != nil)
                if let forced = theme.preset.appearance {
                    Text(forced == .dark ? "\(theme.preset.name) je tmavá téma." : "\(theme.preset.name) je svetlá téma.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                LabeledContent("Farba zvýraznenia") {
                    HStack {
                        ColorPicker("", selection: Binding(
                            get: { theme.accent },
                            set: { theme.customAccent = $0 }
                        ), supportsOpacity: false)
                        .labelsHidden()
                        Button("Farba témy") { theme.customAccent = nil }
                            .disabled(theme.customAccent == nil)
                    }
                }
            }
            Section("Obrázok na pozadí") {
                LabeledContent("Obrázok") {
                    HStack {
                        Text(theme.backgroundImage?.lastPathComponent ?? "Žiadny")
                            .lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                        Button("Vybrať…") { chooseImage() }
                        if theme.backgroundImage != nil {
                            Button("Odstrániť") { theme.backgroundImage = nil }
                        }
                    }
                }
                if theme.backgroundImage != nil {
                    LabeledContent("Priehľadnosť") {
                        Slider(value: $theme.backgroundOpacity, in: 0.05...1)
                            .frame(width: 200)
                    }
                }
            }
            Section {
                Button("Ukázať spúšťač") { LauncherController.shared?.show() }
            }
        }
        .formStyle(.grouped)
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { theme.backgroundImage = url }
    }
}

/// Náhľad témy: zmenšený pruh spúšťača s riadkom výsledku.
private struct ThemeSwatch: View {
    let preset: ThemePreset
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Circle().strokeBorder(foreground.opacity(0.5), lineWidth: 1.5).frame(width: 8, height: 8)
                        RoundedRectangle(cornerRadius: 2).fill(foreground.opacity(0.35)).frame(width: 46, height: 5)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                    .background(preset.chrome ?? .clear)
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(preset.accent ?? .accentColor).frame(width: 10, height: 10)
                        RoundedRectangle(cornerRadius: 2).fill(foreground.opacity(0.5)).frame(width: 40, height: 5)
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((preset.accent ?? Color.primary).opacity(preset.accent == nil ? 0.08 : 0.22), in: RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal, 4)
                    Spacer(minLength: 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(height: 60)
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.themeAccent : Color.primary.opacity(0.15), lineWidth: isSelected ? 2.5 : 1))
            Text(preset.name).font(.callout).lineLimit(1)
        }
        .contentShape(Rectangle())
    }

    private var background: AnyShapeStyle {
        if let content = preset.content { return AnyShapeStyle(content) }
        if preset.frosted { return AnyShapeStyle(.regularMaterial) }
        return AnyShapeStyle(LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var foreground: Color {
        switch preset.appearance {
        case .dark?: .white
        case .light?: .black
        default: .primary
        }
    }
}

// MARK: - Snippety

private struct SnippetSettings: View {
    @Environment(AppSettings.self) private var settings
    @State private var selection: Snippet.ID?

    private var store: SnippetStore? { LauncherController.shared?.snippets }

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.snippetExpansion) {
                    Text("Rozbaľovať pri písaní")
                    Text("Napíš kľúčové slovo (napr. ;dnes) v ľubovoľnej aplikácii a nahradí sa textom. Potrebuje povolenie Accessibility.")
                }
                .onChange(of: settings.snippetExpansion) { LauncherController.shared?.updateSnippetExpansion() }
                if settings.snippetExpansion && !WindowManager.isTrusted {
                    Button("Povoliť Accessibility…") { WindowManager.requestAccess() }
                }
                Text("Zástupné symboly: {date} dátum, {time} čas, {datetime}, {clipboard} obsah schránky, {cursor} kam sa postaví kurzor.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let store {
                Section("Snippety") {
                    ForEach(Bindable(store).snippets) { $snippet in
                        DisclosureGroup(isExpanded: Binding(
                            get: { selection == snippet.id },
                            set: { selection = $0 ? snippet.id : nil }
                        )) {
                            TextField("Názov", text: $snippet.name)
                            TextField("Kľúčové slovo", text: $snippet.keyword, prompt: Text(";skratka"))
                            TextEditor(text: $snippet.text)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 70)
                            Button("Vymazať snippet", role: .destructive) {
                                store.snippets.removeAll { $0.id == snippet.id }
                            }
                        } label: {
                            HStack {
                                Text(snippet.name.isEmpty ? "Bez názvu" : snippet.name)
                                Spacer()
                                Text(snippet.keyword).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Pridať snippet") {
                        let snippet = Snippet(name: "Nový snippet", keyword: ";", text: "")
                        store.snippets.append(snippet)
                        selection = snippet.id
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Spustenie pri prihlásení


private struct LoginItemToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    @State private var problem: String?

    var body: some View {
        Toggle(isOn: Binding(get: { isEnabled }, set: { setEnabled($0) })) {
            Text("Spustiť pri prihlásení")
            Text("Neposearch beží na pozadí, aby fungovali ⌥Space, schránka a snippety hneď po zapnutí Macu.")
        }
        if let problem {
            Text(problem).font(.caption).foregroundStyle(.orange)
        }
        if !Bundle.main.bundlePath.hasPrefix("/Applications/") {
            Text("Aplikácia nebeží z /Applications – po presunutí (scripts/bundle.sh --install) zapni znova.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            problem = nil
        } catch {
            problem = error.localizedDescription
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
