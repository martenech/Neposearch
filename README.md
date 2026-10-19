# Neposearch

A native macOS launcher and semantic index of personal data, inspired by KDE's [Nepomuk](https://en.wikipedia.org/wiki/NEPOMUK_(software)) semantic desktop. Neposearch indexes files, e-mail, contacts, calendar, browser history, screenshots and shell history on your Mac, links them to the **people, organisations, projects and places** they mention, and lets you search everything from a Spotlight-style bar (⌥Space) – in Slovak, Czech or English.

The index and the embedding model live on your Mac. Only file text for AI summaries and short keyword lists for entity classification are sent to the language model you choose (see [Privacy](#privacy)).

> The user interface and code comments are in Slovak.

## Research motivation

Desktop search tools find files by name or exact words. Personal information, however, is organised around *context*: who a document is from, which project it belongs to, which meeting it was prepared for. Neposearch explores how far a combination of

- **local multilingual sentence embeddings** for semantic retrieval,
- **LLM-generated summaries and keywords** as a compact, searchable representation of each document, and
- **LLM-based entity typing** that turns free-form keywords into a small knowledge graph (person / organisation / project / place)

can bring the original semantic-desktop idea to a single user's machine, for a morphologically rich language like Slovak, without a cloud index.

## Features

**Semantic index**
- Files: watched with FSEvents; text extracted from documents; each file gets a 2–4 sentence summary, 3–6 tags and 10–20 keywords.
- Vector search: [`intfloat/multilingual-e5-small`](https://huggingface.co/intfloat/multilingual-e5-small) (384-d) run locally via [swift-embeddings](https://github.com/jkrukowski/swift-embeddings) – documents in batches on the GPU, queries on the Neural Engine, with the e5 `passage:` / `query:` prefixes.
- Storage: [ObjectBox](https://objectbox.io) with an HNSW vector index (cosine distance) and to-many relations between entities and files.
- Entity extraction: proper names from keywords are classified as person, organisation, project or place and linked to files, contacts and meetings. Inflected and variant forms are normalised (e.g. *Bratislave* → *Bratislava*).
- "Ask Claude": a natural-language question plus the stored file summaries → the relevant files with a reason for each.

**Data sources** (each can be switched off in Settings)

| Source | Module | Notes |
|---|---|---|
| Files | `Indexer`, `FileScanner`, `FileProcessor` | FSEvents; skips Library, `node_modules`, media folders |
| Spotlight metadata | `FileMetadata` | download source (URL / e-mail), last opened, Finder tags |
| Screenshots | `ScreenshotIndex` | OCR with Apple Vision |
| Clipboard | `ClipboardStore` | ignores concealed / transient items (passwords) |
| Contacts, Calendar, Reminders | `PeopleIndex` | entities and links to files |
| Mail, Safari | `MailIndex`, `SafariIndex` | read-only SQLite, requires Full Disk Access |
| Shell history | `ShellHistory` | fish, zsh, bash |
| Git commits | `GitCommits` | repositories in `~/Projects` |
| Claude Code sessions | `ClaudeSessionIndex` | resume a session in the terminal |
| Browser tabs | `BrowserTabs` | AppleScript |

**Launcher (⌥Space)** – files, apps, window management, system commands, calculator and currency conversion (ECB rates), unit conversion, clipboard history, text snippets with expansion, aliases, ⌘K actions and an "everything related" view for a person or organisation.

## Architecture

```
FSEvents / EventKit / Contacts / SQLite (Mail, Safari) / Vision OCR
        │
        ▼
 TextExtractor ──► Summarizer (LLM: summary, tags, keywords) ──► EntityExtractor (LLM: entity types)
        │                                                              │
        ▼                                                              ▼
 Embedder (multilingual-e5-small, local) ──► ObjectBox: IndexedFile + HNSW vectors ◄── Person / Organization links
                                                     │
                                                     ▼
                                    LauncherModel ──► LauncherView (SwiftUI)
```

Language models are pluggable (`LanguageModels.swift`):

| Provider | Notes |
|---|---|
| Claude via Claude Code CLI | default; structured output with `--json-schema`, no API key |
| Claude API | your own API key |
| Apple Foundation Models | fully on-device; English only |

## Requirements

- macOS 26 or later, Apple Silicon
- Swift 6 toolchain (Xcode or the Command Line Tools)
- ~500 MB disk space for the embedding model (downloaded on first start)
- for AI summaries: [Claude Code](https://claude.com/claude-code) signed in, or a Claude API key

## Build and run

```bash
swift build                          # quick check
./scripts/create_signing_cert.sh     # once: local code-signing identity, so macOS keeps granted permissions across builds
./scripts/bundle.sh --install        # release build → /Applications/Neposearch.app, signed, launched
```

`./scripts/bundle.sh` without `--install` only builds `build/Neposearch.app`; `--debug` builds a debug version.

After the first start, grant the permissions you want to use: Accessibility (snippets, window management), Contacts, Calendar, Reminders, and Full Disk Access (Mail, Safari).

**ObjectBox code generation.** After changing an entity (classes marked `// objectbox: entity`), regenerate the bindings and commit the output:

```bash
swift package plugin --allow-writing-to-package-directory --allow-network-connections all \
  objectbox-generator --target Neposearch --no-statistics
```

## Privacy

- The database, vectors, clipboard history and screenshots are stored in `~/Library/Application Support/Neposearch/` and never leave the Mac.
- Embeddings are computed locally.
- For summaries, the beginning of each file's text is sent to the selected language model; for entity typing, only lists of keywords are sent. With the Apple Foundation Models provider nothing leaves the device.
- Mail and Safari are read-only and optional; sensitive sources each have their own switch.

## Status and limitations

Personal research prototype, used daily by its author. See [`TODO.md`](TODO.md) for the roadmap (in Slovak).

- No automated test suite yet.
- Distributing the app to other Macs requires bundling `swift-transformers_Hub.bundle`, which is currently resolved from the build directory.
- Apple Foundation Models do not support Slovak, so Slovak summaries need a Claude provider.

## References

- Groza T. et al. (2007) *The NEPOMUK Project – On the way to the Social Semantic Desktop.* I-SEMANTICS '07.
- Wang L. et al. (2024) *Multilingual E5 Text Embeddings: A Technical Report.* arXiv:2402.05672.
- Malkov Yu.A., Yashunin D.A. (2020) *Efficient and robust approximate nearest neighbor search using Hierarchical Navigable Small World graphs.* IEEE TPAMI 42(4):824–836.

## Author

Developed by **Martin Pohorelský** ([martenech](https://github.com/martenech)).

## License

MIT, see [`LICENSE`](LICENSE). Dependencies: ObjectBox Swift (Apache-2.0), swift-embeddings (MIT); the multilingual-e5-small model is MIT-licensed.
