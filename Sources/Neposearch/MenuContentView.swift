import AppKit
import SwiftUI

struct MenuContentView: View {
    @Environment(Indexer.self) private var indexer
    @Environment(AppSettings.self) private var settings
    @State private var expandedID: UInt64?

    var body: some View {
        @Bindable var indexer = indexer
        VStack(spacing: 0) {
            header
            Divider()
            if settings.watchedFolder == nil {
                emptyState
            } else if indexer.isAsking {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Claude prechádza zhrnutia súborov…").foregroundStyle(.secondary)
                    Button("Zrušiť") { indexer.cancelAsk() }.controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if indexer.files.isEmpty && (indexer.askAnswer ?? "").isEmpty {
                Text(emptyListText)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if let answer = indexer.askAnswer {
                            askAnswerView(answer)
                        }
                        ForEach(indexer.files, id: \.id) { file in
                            FileRowView(
                                file: file,
                                isExpanded: expandedID == file.id.value,
                                isSemanticMatch: indexer.semanticMatches.contains(file.id.value),
                                reason: indexer.askReasons[file.id.value]
                            ) {
                                expandedID = expandedID == file.id.value ? nil : file.id.value
                            }
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            Divider()
            footer
        }
        .frame(width: 440, height: 560)
    }

    private var header: some View {
        @Bindable var indexer = indexer
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Hľadaj, alebo sa opýtaj a stlač ↩", text: $indexer.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit { indexer.askClaude() }
                if !indexer.searchText.isEmpty {
                    Button {
                        indexer.askClaude()
                    } label: {
                        Label("Opýtať sa Claude", systemImage: "sparkles")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .help("Opýtať sa Claude (↩) – prejde zhrnutia a vyberie súvisiace súbory")
                    .disabled(indexer.isAsking)
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

            if let error = indexer.askError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let count = indexer.pendingConfirmation {
                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        "V priečinku je \(count) súborov na zhrnutie. Každý je jedno volanie AI (\(settings.modelDescription)).",
                        systemImage: "exclamationmark.triangle.fill")
                    HStack {
                        Button("Zhrnúť všetky") { indexer.confirmLargeFolder() }
                        Button("Vybrať menší priečinok…", action: chooseFolder)
                    }
                    .controlSize(.small)
                }
                .font(.caption)
                .foregroundStyle(.orange)
            } else if let problem = indexer.aiProblem {
                Label(
                    indexer.queuedCount > 0 ? "\(problem) Čaká \(indexer.queuedCount) súborov." : problem,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding(12)
    }

    private var emptyListText: String {
        if indexer.askAnswer != nil { return "Claude nenašiel žiadny súvisiaci súbor." }
        if indexer.searchText.isEmpty { return "Zatiaľ nič nezaindexované." }
        return "Nič sa nenašlo.\nStlač ↩ a opýtaj sa Claude."
    }

    private func askAnswerView(_ answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Claude", systemImage: "sparkles").font(.caption.bold()).foregroundStyle(.tint)
                Spacer()
                Button("Späť na vyhľadávanie") { indexer.cancelAsk() }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
            if !answer.isEmpty {
                Text(answer).font(.callout).textSelection(.enabled)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus").font(.system(size: 36)).foregroundStyle(.secondary)
            Text("Vyber priečinok, ktorý má Neposearch indexovať.")
                .multilineTextAlignment(.center)
            Button("Vybrať priečinok…", action: chooseFolder)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        @Bindable var indexer = indexer
        return HStack(spacing: 8) {
            statusText
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button {
                indexer.isPaused.toggle()
            } label: {
                Image(systemName: indexer.isPaused ? "play.fill" : "pause.fill")
            }
            .help(indexer.isPaused ? "Pokračovať v indexovaní" : "Pozastaviť indexovanie")
            Menu {
                Button("Otvoriť vyhľadávanie (\(settings.hotKey.label))") { LauncherController.shared?.show() }
                Divider()
                Button("Zmeniť priečinok…", action: chooseFolder)
                Button("Znova skúsiť neúspešné") { indexer.retryPendingAndFailed() }
                SettingsLink { Text("Nastavenia…") }
                Divider()
                Button("Ukončiť Neposearch") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var statusText: Text {
        if indexer.isPaused { return Text("Pozastavené · \(indexer.queuedCount) v rade") }
        if let name = indexer.currentFileName {
            let queue = indexer.queuedCount > 0 ? " · \(indexer.queuedCount) v rade" : ""
            return Text("Sumarizujem \(name)\(queue)")
        }
        if indexer.isScanning { return Text("Prehľadávam priečinok…") }
        if let progress = indexer.embeddingProgress {
            return Text("Počítam vektory na vyhľadávanie \(progress.done)/\(progress.total)")
        }
        return Text("\(indexer.totalCount) súborov v indexe")
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Indexovať"
        NSApp.activate()
        if panel.runModal() == .OK, let url = panel.url {
            indexer.setFolder(url)
        }
    }
}

struct FileRowView: View {
    @Environment(Indexer.self) private var indexer
    let file: IndexedFile
    let isExpanded: Bool
    let isSemanticMatch: Bool
    var reason: String? = nil
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: file.path))
                .resizable()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(file.name).font(.headline).lineLimit(1).truncationMode(.middle)
                    if isSemanticMatch {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .help("Nájdené podľa významu")
                    }
                    Spacer()
                    Text(file.modifiedAt, format: .relative(presentation: .named))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                if let reason {
                    Label(reason, systemImage: "sparkles")
                        .font(.callout)
                        .foregroundStyle(.tint)
                        .labelStyle(.titleAndIcon)
                }
                description
                if !file.tagList.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(file.tagList.prefix(isExpanded ? 10 : 4), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.tint.opacity(0.15), in: Capsule())
                        }
                    }
                }
                if isExpanded {
                    if !file.sourceDescription.isEmpty {
                        Label("Stiahnuté z: \(file.sourceDescription)", systemImage: "arrow.down.circle")
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                    if let opened = file.lastUsedAt {
                        Label("Naposledy otvorené \(opened.formatted(.relative(presentation: .named))) · \(file.useCount)×", systemImage: "clock")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(file.path).font(.caption2).foregroundStyle(.tertiary).lineLimit(2).textSelection(.enabled)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { NSWorkspace.shared.open(file.url) }
        .onTapGesture(perform: onToggle)
        .background(isExpanded ? Color.accentColor.opacity(0.08) : .clear)
        .contextMenu {
            Button("Otvoriť") { NSWorkspace.shared.open(file.url) }
            Button("Ukázať vo Finderi") { NSWorkspace.shared.activateFileViewerSelecting([file.url]) }
            Button("Kopírovať zhrnutie") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(file.summary, forType: .string)
            }
            .disabled(file.summary.isEmpty)
            Divider()
            Button("Znova zhrnúť") { indexer.resummarize(file) }
        }
    }

    @ViewBuilder private var description: some View {
        switch file.indexStatus {
        case .done:
            Text(file.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 3)
                .textSelection(.enabled)
        case .processing:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("AI práve číta súbor…").font(.callout).foregroundStyle(.secondary)
            }
        case .pending:
            Text("Čaká na zhrnutie").font(.callout).foregroundStyle(.tertiary)
        case .failed:
            Label(file.errorMessage, systemImage: "xmark.octagon")
                .font(.caption).foregroundStyle(.red).lineLimit(isExpanded ? nil : 2)
        case .unsupported:
            Text(file.errorMessage.isEmpty ? "Nepodporovaný typ súboru" : file.errorMessage)
                .font(.callout).foregroundStyle(.tertiary)
        }
    }
}
