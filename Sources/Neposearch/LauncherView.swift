import AppKit
import SwiftUI

/// Úzky vyhľadávací pruh (ako Spotlight). Výsledky sa rozbalia pod ním až pri písaní.
struct LauncherView: View {
    @Environment(LauncherModel.self) private var model
    @Environment(Indexer.self) private var indexer
    @Environment(AppSettings.self) private var settings
    @FocusState private var isSearchFocused: Bool
    @State private var listHeight: CGFloat = 0

    static let barHeight: CGFloat = 56
    static let maxListHeight: CGFloat = 380
    private static let corner: CGFloat = 22

    private var isExpanded: Bool {
        if case .alias = model.mode { return false }
        return model.isListMode || model.isShowingActions || indexer.isAskMode || indexer.askError != nil
            || !indexer.searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if isExpanded {
                Rectangle().fill(.primary.opacity(0.08)).frame(height: 1)
                expandedContent
            }
        }
        .frame(width: LauncherController.width)
        .themedLauncherBackground(cornerRadius: Self.corner)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { model.onResize($0) }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear { isSearchFocused = true }
        .onChange(of: model.focusToken) { isSearchFocused = true }
        .onChange(of: indexer.files.map(\.id.value)) { model.selection = 0 }
        .onChange(of: indexer.searchText) { model.selection = 0 }
    }

    // MARK: - Pruh

    private var searchBar: some View {
        @Bindable var indexer = indexer
        @Bindable var model = model
        let isListMode = model.isListMode
        return HStack(spacing: 12) {
            Image(systemName: isListMode ? model.modeSymbol : indexer.isAskMode ? "sparkles" : "magnifyingglass")
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(indexer.isAskMode ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24)
            if case .alias(_, let title) = model.mode {
                Text("Alias pre \(title)")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .fixedSize()
                TextField("napr. wsl (prázdne = zmazať)", text: $model.aliasDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .regular))
                    .focused($isSearchFocused)
                KeyCap("↩ uložiť")
            } else if isListMode {
                Text(model.modeTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .onTapGesture { model.exitMode() }
                    .help("Späť (esc)")
                TextField("Hľadaj…", text: $model.modeQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .regular))
                    .focused($isSearchFocused)
            } else {
                TextField("Hľadaj súbory, aplikácie, počítaj…", text: $indexer.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .regular))
                    .focused($isSearchFocused)
            }
            if let toast = model.toast {
                StatusChip(symbol: "checkmark.circle.fill", text: toast, showsProgress: false, animates: false)
                    .foregroundStyle(.green)
            } else if indexer.isAsking {
                StatusChip(symbol: nil, text: "Claude premýšľa", showsProgress: true)
            } else if indexer.currentFileName != nil {
                StatusChip(
                    symbol: "arrow.triangle.2.circlepath",
                    text: indexer.queuedCount > 0 ? "\(indexer.queuedCount)" : "",
                    showsProgress: false)
                    .help("Indexujem \(indexer.currentFileName ?? "")")
            }
        }
        .padding(.horizontal, 18)
        .frame(height: Self.barHeight)
        .background(ThemeStore.shared.preset.chrome ?? .clear)
    }

    // MARK: - Rozbalená časť

    @ViewBuilder private var expandedContent: some View {
        if model.isShowingActions {
            ActionsList()
        } else if indexer.isAsking {
            AskingRow()
        } else {
            resultList
        }
    }

    private var resultList: some View {
        let rows = model.rows
        let terms = model.isListMode
            ? IndexedFile.searchTerms(model.modeQuery)
            : indexer.isAskMode ? [] : IndexedFile.searchTerms(indexer.searchText)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    if let answer = indexer.askAnswer {
                        AnswerCard(answer: answer).padding(.bottom, 4)
                    }
                    if let error = indexer.askError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12)).foregroundStyle(.orange).padding(10)
                    }
                    if rows.isEmpty, model.isListMode {
                        Text(model.modeEmptyText)
                            .font(.system(size: 12.5)).foregroundStyle(.secondary).padding(10)
                    }
                    if rows.isEmpty, indexer.askAnswer != nil {
                        Text("Claude nenašiel žiadny súvisiaci súbor.")
                            .font(.system(size: 12.5)).foregroundStyle(.secondary).padding(10)
                    }
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        if let title = sectionTitle(at: index, rows: rows) {
                            SectionHeader(title: title)
                        }
                        ResultRow(
                            row: row,
                            query: indexer.searchText,
                            terms: terms,
                            reason: reason(for: row),
                            isSemantic: isSemantic(row),
                            isSelected: index == model.selection,
                            alias: model.alias(for: row),
                            targetAppName: model.targetApp?.localizedName,
                            targetApp: model.targetApp,
                            pendingConfirmation: isPending(row),
                            windowHotKeys: settings.windowHotKeys
                        )
                        .id(row.id)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            model.selection = index
                            model.activate(reveal: false)
                        }
                        .onTapGesture { model.selection = index }
                    }
                }
                .padding(6)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
            }
            .scrollIndicators(.never)
            .frame(height: min(listHeight, Self.maxListHeight))
            .onChange(of: model.selection) {
                if let row = model.selectedRow { proxy.scrollTo(row.id) }
            }
        }
    }

    /// Nadpis sekcie nad prvým riadkom každého druhu (aplikácie, súbory, Claude).
    private func sectionTitle(at index: Int, rows: [LauncherModel.Row]) -> String? {
        let section = rows[index].section
        if index > 0 && rows[index - 1].section == section { return nil }
        if case .ask = rows[index], index == 0 { return nil }
        if case .file = rows[index], indexer.isAskMode { return "Odporúčania od Claude" }
        return section
    }

    private func isPending(_ row: LauncherModel.Row) -> Bool {
        if case .system(let command) = row { return model.pendingConfirmation == command }
        return false
    }

    private func reason(for row: LauncherModel.Row) -> String? {
        if case .file(let file) = row { return indexer.askReasons[file.id.value] }
        return nil
    }

    private func isSemantic(_ row: LauncherModel.Row) -> Bool {
        if case .file(let file) = row { return indexer.semanticMatches.contains(file.id.value) }
        return false
    }
}

// MARK: - Riadky

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 3)
    }
}

private struct ResultRow: View {
    let row: LauncherModel.Row
    let query: String
    let terms: [String]
    let reason: String?
    let isSemantic: Bool
    let isSelected: Bool
    var alias: String?
    var targetAppName: String?
    var targetApp: NSRunningApplication?
    var pendingConfirmation = false
    var windowHotKeys = false

    /// „↓ example.edu · otvorené pred 2 dňami · tagy: …“ (zo Spotlight metadát).
    private func fileDetails(_ file: IndexedFile) -> String? {
        var parts: [String] = []
        if !file.sourceDescription.isEmpty { parts.append("↓ \(file.sourceDescription)") }
        if let opened = file.lastUsedAt {
            parts.append("otvorené \(opened.formatted(.relative(presentation: .named)))")
        }
        if !file.finderTags.isEmpty { parts.append("🏷 \(file.finderTags)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func clipSubtitle(_ item: ClipboardItem) -> String {
        let source = item.sourceAppName.isEmpty ? "" : "\(item.sourceAppName) · "
        switch item.clipKind {
        case .image: return source + "Obrázok \(item.text)"
        case .files: return source + item.fileURLs.map(\.path).joined(separator: ", ")
        case .text: return source + "\(item.text.count) znakov"
        }
    }

    private var windowSubtitle: String {
        targetAppName.map { "Okno aplikácie \($0)" } ?? "Aktívne okno"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            icon.frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    title
                    if let alias {
                        Text(alias)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(.primary.opacity(0.2)))
                            .fixedSize()
                    }
                }
                subtitle
            }
            Spacer(minLength: 6)
            accessory
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.themeSelection)
            }
        }
    }

    @ViewBuilder private var icon: some View {
        switch row {
        case .mail(let message):
            Image(systemName: message.isRead ? "envelope" : "envelope.badge")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .web(let page):
            Image(systemName: page.kind == .history ? "clock.arrow.circlepath" : page.kind == .readingList ? "eyeglasses" : "bookmark.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.cyan.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .person(let person):
            Text(person.initials.isEmpty ? "?" : person.initials)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.teal.gradient, in: Circle())
        case .organization:
            Image(systemName: "building.2.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .event(let event):
            VStack(spacing: 0) {
                Text(event.start.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 1).background(Color.red)
                Text(event.start.formatted(.dateTime.day()))
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 28, height: 28)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        case .reminder:
            Image(systemName: "circle")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
        case .commit:
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(hex: "F05032").gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .shellCommand:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(white: 0.2).gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .claudeSession:
            Image(systemName: "terminal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(hex: "D97757").gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .system(let command):
            Image(systemName: command.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.gray.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .snippet:
            Image(systemName: "text.quote")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.yellow.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .tab(let tab):
            Image(nsImage: IconCache.icon(forFile: tab.appPath)).resizable()
        case .screenshot(let item):
            if let image = IconCache.thumbnail(forImageAt: item.path) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: "camera.viewfinder").frame(width: 28, height: 28)
            }
        case .calculation:
            Image(systemName: "equal")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .command(let command):
            Image(systemName: command.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.purple.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .clip(let item):
            ClipIcon(item: item)
        case .app(let app):
            Image(nsImage: IconCache.icon(forFile: app.path)).resizable()
        case .window(let command):
            Image(systemName: command.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        case .file(let file):
            Image(nsImage: IconCache.icon(forFile: file.path)).resizable()
        case .ask:
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
    }

    @ViewBuilder private var title: some View {
        switch row {
        case .mail(let message):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Highlighter.highlight(message.subject.isEmpty ? "(bez predmetu)" : message.subject, terms: terms))
                    .font(.system(size: 13.5, weight: message.isRead ? .medium : .semibold)).lineLimit(1)
                if message.isFlagged { Image(systemName: "flag.fill").font(.system(size: 9)).foregroundStyle(.orange) }
            }
        case .web(let page):
            Text(Highlighter.highlight(page.title, terms: terms)).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .person(let person):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Highlighter.highlight(person.name, terms: terms)).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
                if !person.organizationName.isEmpty, person.organizationName != person.name {
                    Text(person.organizationName).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(1).layoutPriority(-1)
                }
            }
        case .organization(let organization):
            Text(Highlighter.highlight(organization.name, terms: terms)).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .event(let event):
            Text(Highlighter.highlight(event.title, terms: terms)).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .reminder(let item):
            Text(Highlighter.highlight(item.title, terms: terms)).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .commit(let commit):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Highlighter.highlight(commit.subject, terms: terms))
                    .font(.system(size: 13.5, weight: .medium)).lineLimit(isSelected ? 2 : 1)
                Text(commit.repoName).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(1).layoutPriority(-1)
            }
        case .shellCommand(let command):
            Text(command.command.replacingOccurrences(of: "\n", with: " ⏎ "))
                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                .lineLimit(isSelected ? 3 : 1)
                .truncationMode(.middle)
        case .claudeSession(let session):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Highlighter.highlight(session.title, terms: terms))
                    .font(.system(size: 13.5, weight: .medium)).lineLimit(1)
                Text(session.projectName).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(1).layoutPriority(-1)
            }
        case .system(let command):
            Text(command.title).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .snippet(let snippet):
            HStack(spacing: 6) {
                Text(snippet.name).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
                if !snippet.keyword.isEmpty {
                    Text(snippet.keyword)
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(.primary.opacity(0.2)))
                        .fixedSize()
                }
            }
        case .tab(let tab):
            Text(Highlighter.highlight(tab.title.isEmpty ? tab.url : tab.title, terms: terms))
                .font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .screenshot(let item):
            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .calculation(let result):
            Text(result.display)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .textSelection(.enabled)
        case .command(let command):
            Text(command.title).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .clip(let item):
            Text(item.title).font(.system(size: 13.5, weight: .medium)).lineLimit(1).truncationMode(.tail)
        case .app(let app):
            Text(app.name).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .window(let command):
            Text(command.title).font(.system(size: 13.5, weight: .medium)).lineLimit(1)
        case .file(let file):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Highlighter.highlight(file.name, terms: terms))
                    .font(.system(size: 13.5, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(file.url.deletingLastPathComponent().lastPathComponent)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .layoutPriority(-1)
            }
        case .ask:
            Text("Opýtať sa Claude: „\(query.trimmingCharacters(in: .whitespaces))“")
                .font(.system(size: 13.5, weight: .medium))
                .lineLimit(1)
        }
    }

    @ViewBuilder private var subtitle: some View {
        switch row {
        case .mail(let message):
            Text(Highlighter.highlight("\(message.sender) · \(message.summary)", terms: terms))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(isSelected ? 3 : 1)
        case .web(let page):
            Text([page.kind == .readingList ? "Zoznam na čítanie" : page.kind == .bookmark ? "Záložka" : nil, page.host,
                  page.visitCount > 1 ? "\(page.visitCount)×" : nil].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .person(let person):
            Text([person.source == "ai" ? "Zo súborov" : nil, person.jobTitle, person.emails,
                  person.files.isEmpty ? nil : "\(person.files.count) súborov"]
                .compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .organization(let organization):
            Text([organization.kind == "project" ? "Projekt" : "Firma",
                  organization.files.isEmpty ? nil : "\(organization.files.count) súborov"].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .event(let event):
            Text([event.isAllDay ? event.start.formatted(date: .abbreviated, time: .omitted)
                    : "\(event.start.formatted(date: .abbreviated, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))",
                  event.location.isEmpty ? nil : event.location,
                  event.attendeesText.isEmpty ? nil : event.attendeesText].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(isSelected ? 2 : 1)
        case .reminder(let item):
            Text([item.listName, item.due.map { "do \($0.formatted(date: .abbreviated, time: .omitted))" }, item.notes.isEmpty ? nil : item.notes]
                .compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .commit(let commit):
            Text([commit.shortHash, commit.author, commit.date.formatted(.relative(presentation: .named)),
                  commit.refs.isEmpty ? nil : commit.refs].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 11.5, design: .monospaced)).foregroundStyle(.secondary).lineLimit(1)
        case .shellCommand(let command):
            Text([command.shell,
                  command.lastRun.map { $0.formatted(.relative(presentation: .named)) },
                  command.count > 1 ? "\(command.count)×" : nil].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .claudeSession(let session):
            Text(Highlighter.highlight(
                isSelected ? session.matchingPrompt(for: terms) : "\(session.promptCount) otázok · \(session.matchingPrompt(for: terms))",
                terms: terms))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(isSelected ? 2 : 1)
        case .system(let command):
            Text(pendingConfirmation ? "Stlač ↩ ešte raz na potvrdenie" : command.subtitle(targetApp: targetApp))
                .font(.system(size: 11.5))
                .foregroundStyle(pendingConfirmation ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                .lineLimit(1)
        case .snippet(let snippet):
            Text(snippet.text.replacingOccurrences(of: "\n", with: " ⏎ "))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(isSelected ? 3 : 1)
        case .tab(let tab):
            Text("\(tab.browser.scriptName) · \(tab.host)").font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .screenshot(let item):
            Text(Highlighter.highlight(item.matchingLine(for: terms), terms: terms))
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .calculation(let result):
            Text(result.detail).font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .command(let command):
            Text(command.subtitle).font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .clip(let item):
            if isSelected && item.clipKind == .text && item.text.contains(where: \.isNewline) || isSelected && item.text.count > 80 {
                Text(item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 11.5, design: item.text.contains("{") || item.text.contains(";") ? .monospaced : .default))
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            } else {
                Text(clipSubtitle(item)).font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
            }
        case .app(let app):
            Text(app.url.deletingLastPathComponent().path)
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .window:
            Text(windowSubtitle)
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        case .file(let file):
            VStack(alignment: .leading, spacing: 2) {
                if let reason {
                    Text(reason)
                        .font(.system(size: 11.5)).foregroundStyle(.tint)
                        .lineLimit(isSelected ? 2 : 1)
                } else {
                    Text(Highlighter.highlight(subtitleText(file), terms: terms))
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(isSelected ? 2 : 1)
                }
                if isSelected, let details = fileDetails(file) {
                    Text(details).font(.system(size: 10.5)).foregroundStyle(.tertiary).lineLimit(1)
                }
            }
        case .ask:
            Text("Prejde zhrnutia a vyberie súvisiace súbory")
                .font(.system(size: 11.5)).foregroundStyle(.secondary).lineLimit(1)
        }
    }

    @ViewBuilder private var accessory: some View {
        switch row {
        case .mail(let message):
            if isSelected { KeyCap("↩ otvoriť") } else {
                Text(message.date.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
                    .font(.system(size: 11)).foregroundStyle(.tertiary).monospacedDigit()
            }
        case .web(let page):
            if isSelected { KeyCap("↩ otvoriť") } else if let visit = page.lastVisit {
                Text(visit.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
                    .font(.system(size: 11)).foregroundStyle(.tertiary).monospacedDigit()
            }
        case .person, .organization:
            if isSelected { KeyCap("↩ všetko súvisiace") } else { Text("Kontakt").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .event(let event):
            if isSelected {
                KeyCap(event.meetingURL.isEmpty ? "↩" : "⌘↩ pripojiť")
            } else {
                Text(event.start.formatted(.relative(presentation: .named)))
                    .font(.system(size: 11)).foregroundStyle(event.end >= Date() ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            }
        case .reminder(let item):
            if isSelected { KeyCap("⌘K hotovo") } else if let due = item.due {
                Text(due.formatted(.relative(presentation: .named)))
                    .font(.system(size: 11)).foregroundStyle(due < Date() ? AnyShapeStyle(.red) : AnyShapeStyle(.tertiary))
            }
        case .commit:
            if isSelected { KeyCap("↩ git show") } else { Text("Commit").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .shellCommand:
            if isSelected { KeyCap("↩ vložiť") } else { Text("Príkaz").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .claudeSession(let session):
            if isSelected {
                KeyCap("↩ pokračovať")
            } else {
                Text(session.updatedAt.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
                    .font(.system(size: 11)).foregroundStyle(.tertiary).monospacedDigit()
            }
        case .system:
            if isSelected { KeyCap("↩") } else { Text("Systém").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .snippet:
            if isSelected { KeyCap("↩ vložiť") } else { Text("Snippet").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .tab:
            if isSelected { KeyCap("↩ prepnúť") } else { Text("Karta").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .screenshot:
            if isSelected { KeyCap("↩") } else { Text("Screenshot").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .calculation:
            if isSelected { KeyCap("↩ kopírovať") }
        case .command:
            if isSelected { KeyCap("↩") } else { Text("Príkaz").font(.system(size: 11)).foregroundStyle(.tertiary) }
        case .clip(let item):
            HStack(spacing: 6) {
                if item.isPinned {
                    Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(.orange)
                }
                if isSelected {
                    KeyCap("↩ vložiť")
                } else {
                    Text(item.createdAt.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
                        .font(.system(size: 11)).foregroundStyle(.tertiary).monospacedDigit()
                }
            }
        case .app:
            if isSelected {
                KeyCap("↩")
            } else {
                Text("Aplikácia").font(.system(size: 11)).foregroundStyle(.tertiary)
            }
        case .window(let command):
            if isSelected {
                KeyCap("↩")
            } else if windowHotKeys, let key = command.hotKey {
                KeyCap(key.label)
            } else {
                Text("Okno").font(.system(size: 11)).foregroundStyle(.tertiary)
            }
        case .file(let file):
            HStack(spacing: 6) {
                if isSemantic {
                    Image(systemName: "sparkles").font(.system(size: 10)).foregroundStyle(.tint)
                        .help("Nájdené podľa významu")
                }
                if file.indexStatus == .processing {
                    ProgressView().controlSize(.mini)
                } else if isSelected {
                    KeyCap("↩")
                } else {
                    Text(file.modifiedAt.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
        case .ask:
            KeyCap(isSelected ? "↩" : "Tab")
        }
    }

    private func subtitleText(_ file: IndexedFile) -> String {
        switch file.indexStatus {
        case .done: file.summary
        case .processing: "AI práve číta súbor…"
        case .pending: "Čaká na zhrnutie"
        case .failed: file.errorMessage
        case .unsupported: file.errorMessage.isEmpty ? "Nepodporovaný typ" : file.errorMessage
        }
    }
}

// MARK: - Claude

private struct AnswerCard: View {
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(
                        LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle())
                Text("Claude").font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("esc späť").font(.system(size: 11)).foregroundStyle(.tertiary)
            }
            if !answer.isEmpty {
                Text(answer)
                    .font(.system(size: 12.5))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [.orange.opacity(0.12), .pink.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)))
    }
}

private struct AskingRow: View {
    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .symbolEffect(.pulse, options: .repeating)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("Claude prechádza tvoje súbory…").font(.system(size: 13.5, weight: .medium))
                Text("Zvyčajne 10–30 sekúnd").font(.system(size: 11.5)).foregroundStyle(.secondary)
            }
            Spacer()
            Text("esc zruší").font(.system(size: 11)).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Akcie (⌘K)

private struct ActionsList: View {
    @Environment(LauncherModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text("Akcie").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                if let file = model.selectedFile {
                    Text(file.name).font(.system(size: 11)).foregroundStyle(.tertiary).lineLimit(1).truncationMode(.middle)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 3)
            ForEach(Array(model.availableActions.enumerated()), id: \.element) { index, action in
                HStack(spacing: 10) {
                    Image(systemName: action.symbol)
                        .font(.system(size: 13))
                        .frame(width: 28)
                        .foregroundStyle(action == .ask ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    Text(action.title).font(.system(size: 13.5))
                    Spacer(minLength: 16)
                    if !action.shortcut.isEmpty { KeyCap(action.shortcut) }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    if index == model.actionSelection {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.themeSelection)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { model.perform(action) }
            }
        }
        .padding(6)
    }
}

// MARK: - Drobné prvky

private struct StatusChip: View {
    let symbol: String?
    let text: String
    let showsProgress: Bool
    var animates = true

    var body: some View {
        HStack(spacing: 5) {
            if showsProgress {
                ProgressView().controlSize(.mini)
            } else if let symbol {
                if animates {
                    Image(systemName: symbol).symbolEffect(.rotate, options: .repeating)
                } else {
                    Image(systemName: symbol)
                }
            }
            if !text.isEmpty { Text(text).monospacedDigit() }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(.primary.opacity(0.06), in: Capsule())
    }
}

private struct KeyCap: View {
    let keys: String
    init(_ keys: String) { self.keys = keys }

    var body: some View {
        Text(keys)
            .font(.system(size: 10.5, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .frame(minWidth: 20, minHeight: 18)
            .background(Color.themeSurface, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

/// Ikona položky schránky: náhľad obrázka, ikona súboru alebo zdrojovej aplikácie.
private struct ClipIcon: View {
    let item: ClipboardItem

    var body: some View {
        switch item.clipKind {
        case .image:
            if let image = IconCache.thumbnail(forImageAt: item.imagePath) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: "photo").frame(width: 28, height: 28)
            }
        case .files:
            Image(nsImage: IconCache.icon(forFile: item.fileURLs.first?.path ?? "/")).resizable()
        case .text:
            if !item.sourceAppPath.isEmpty {
                Image(nsImage: IconCache.icon(forFile: item.sourceAppPath)).resizable()
            } else {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
        }
    }
}

/// Ikony súborov a aplikácií si pamätáme, aby sa pri každom písmene nenačítavali znova.
@MainActor
enum IconCache {
    private static let cache = NSCache<NSString, NSImage>()

    private static let thumbnails = NSCache<NSString, NSImage>()

    static func thumbnail(forImageAt path: String) -> NSImage? {
        if let image = thumbnails.object(forKey: path as NSString) { return image }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        let size = NSSize(width: 56, height: 56)
        let thumb = NSImage(size: size, flipped: false) { rect in
            image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
            return true
        }
        thumbnails.setObject(thumb, forKey: path as NSString)
        return thumb
    }

    static func icon(forFile path: String) -> NSImage {
        if let icon = cache.object(forKey: path as NSString) { return icon }
        let icon = NSWorkspace.shared.icon(forFile: path)
        cache.setObject(icon, forKey: path as NSString)
        return icon
    }
}

/// Zvýrazní hľadané slová (bez ohľadu na diakritiku a veľkosť písmen).
enum Highlighter {
    static func highlight(_ text: String, terms: [String]) -> AttributedString {
        var result = AttributedString(text)
        for term in terms where !term.isEmpty {
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: term, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
                if let lower = AttributedString.Index(range.lowerBound, within: result),
                    let upper = AttributedString.Index(range.upperBound, within: result)
                {
                    result[lower..<upper].inlinePresentationIntent = .stronglyEmphasized
                    result[lower..<upper].foregroundColor = .primary
                }
                searchRange = range.upperBound..<text.endIndex
            }
        }
        return result
    }
}
