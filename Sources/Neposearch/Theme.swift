import AppKit
import Observation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Systém"
        case .light: "Svetlý"
        case .dark: "Tmavý"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

/// Téma spúšťača (rovnaké palety ako v Pathfinderi).
struct ThemePreset: Identifiable, Hashable {
    let id: String
    let name: String
    /// Tmavé/svetlé palety vynútia vzhľad, aby systémové farby textu ostali čitateľné.
    var appearance: AppearanceMode? = nil
    var accent: Color? = nil
    /// Pozadie pruhu; nil = Liquid Glass.
    var content: Color? = nil
    /// Pozadie vyhľadávacieho riadku (ak sa líši od zvyšku).
    var chrome: Color? = nil
    /// Karty a štítky (odpoveď Claude, klávesy); nil = systémová farba.
    var surface: Color? = nil
    /// Matné sklo namiesto Liquid Glass.
    var frosted = false

    static let all: [ThemePreset] = [
        ThemePreset(id: "default", name: "Liquid Glass"),
        ThemePreset(id: "frosted", name: "Matné sklo", frosted: true),
        ThemePreset(id: "nord", name: "Nord", appearance: .dark, accent: Color(hex: "88C0D0"),
                    content: Color(hex: "2E3440"), chrome: Color(hex: "3B4252")),
        ThemePreset(id: "dracula", name: "Dracula", appearance: .dark, accent: Color(hex: "BD93F9"),
                    content: Color(hex: "282A36"), chrome: Color(hex: "21222C")),
        ThemePreset(id: "midnight", name: "Midnight", appearance: .dark, accent: Color(hex: "4F8CFF"),
                    content: Color(hex: "0D1117"), chrome: Color(hex: "161B22")),
        ThemePreset(id: "navy", name: "Navy", appearance: .dark, accent: Color(hex: "2F7BFF"),
                    content: Color(hex: "121729"), chrome: Color(hex: "0E1222"), surface: Color(hex: "1A2038")),
        ThemePreset(id: "catppuccin-mocha", name: "Catppuccin Mocha", appearance: .dark, accent: Color(hex: "CBA6F7"),
                    content: Color(hex: "1E1E2E"), chrome: Color(hex: "181825"), surface: Color(hex: "313244")),
        ThemePreset(id: "tokyo-night", name: "Tokyo Night", appearance: .dark, accent: Color(hex: "7AA2F7"),
                    content: Color(hex: "1A1B26"), chrome: Color(hex: "16161E"), surface: Color(hex: "24283B")),
        ThemePreset(id: "gruvbox-dark", name: "Gruvbox Dark", appearance: .dark, accent: Color(hex: "FABD2F"),
                    content: Color(hex: "282828"), chrome: Color(hex: "1D2021"), surface: Color(hex: "3C3836")),
        ThemePreset(id: "one-dark", name: "One Dark", appearance: .dark, accent: Color(hex: "61AFEF"),
                    content: Color(hex: "282C34"), chrome: Color(hex: "21252B"), surface: Color(hex: "2C313A")),
        ThemePreset(id: "rose-pine", name: "Rosé Pine", appearance: .dark, accent: Color(hex: "C4A7E7"),
                    content: Color(hex: "191724"), chrome: Color(hex: "1F1D2E"), surface: Color(hex: "26233A")),
        ThemePreset(id: "monokai", name: "Monokai", appearance: .dark, accent: Color(hex: "A6E22E"),
                    content: Color(hex: "272822"), chrome: Color(hex: "1E1F1C"), surface: Color(hex: "3E3D32")),
        ThemePreset(id: "everforest", name: "Everforest", appearance: .dark, accent: Color(hex: "A7C080"),
                    content: Color(hex: "2D353B"), chrome: Color(hex: "232A2E"), surface: Color(hex: "343F44")),
        ThemePreset(id: "kanagawa", name: "Kanagawa", appearance: .dark, accent: Color(hex: "7E9CD8"),
                    content: Color(hex: "1F1F28"), chrome: Color(hex: "16161D"), surface: Color(hex: "2A2A37")),
        ThemePreset(id: "solarized-dark", name: "Solarized Dark", appearance: .dark, accent: Color(hex: "268BD2"),
                    content: Color(hex: "002B36"), chrome: Color(hex: "073642"), surface: Color(hex: "073642")),
        ThemePreset(id: "solarized", name: "Solarized Light", appearance: .light, accent: Color(hex: "268BD2"),
                    content: Color(hex: "FDF6E3"), chrome: Color(hex: "EEE8D5")),
        ThemePreset(id: "catppuccin-latte", name: "Catppuccin Latte", appearance: .light, accent: Color(hex: "8839EF"),
                    content: Color(hex: "EFF1F5"), chrome: Color(hex: "E6E9EF"), surface: Color(hex: "E6E9EF")),
        ThemePreset(id: "rose-pine-dawn", name: "Rosé Pine Dawn", appearance: .light, accent: Color(hex: "907AA9"),
                    content: Color(hex: "FAF4ED"), chrome: Color(hex: "F2E9E1"), surface: Color(hex: "FFFAF3")),
        ThemePreset(id: "gruvbox-light", name: "Gruvbox Light", appearance: .light, accent: Color(hex: "076678"),
                    content: Color(hex: "FBF1C7"), chrome: Color(hex: "F2E5BC"), surface: Color(hex: "EBDBB2")),
        ThemePreset(id: "github-light", name: "GitHub Light", appearance: .light, accent: Color(hex: "0969DA"),
                    content: Color(hex: "FFFFFF"), chrome: Color(hex: "F6F8FA"), surface: Color(hex: "F6F8FA")),
        ThemePreset(id: "one-light", name: "One Light", appearance: .light, accent: Color(hex: "4078F2"),
                    content: Color(hex: "FAFAFA"), chrome: Color(hex: "F0F0F1"), surface: Color(hex: "E5E5E6")),
        ThemePreset(id: "tokyo-night-day", name: "Tokyo Night Day", appearance: .light, accent: Color(hex: "2E7DE9"),
                    content: Color(hex: "E1E2E7"), chrome: Color(hex: "D0D5E3"), surface: Color(hex: "C4C8DA")),
        ThemePreset(id: "nord-light", name: "Nord Light", appearance: .light, accent: Color(hex: "5E81AC"),
                    content: Color(hex: "ECEFF4"), chrome: Color(hex: "E5E9F0"), surface: Color(hex: "D8DEE9")),
        ThemePreset(id: "everforest-light", name: "Everforest Light", appearance: .light, accent: Color(hex: "8DA101"),
                    content: Color(hex: "FDF6E3"), chrome: Color(hex: "EFEBD4"), surface: Color(hex: "F4F0D9")),
        ThemePreset(id: "kanagawa-lotus", name: "Kanagawa Lotus", appearance: .light, accent: Color(hex: "4D699B"),
                    content: Color(hex: "F2ECBC"), chrome: Color(hex: "E5DDB0"), surface: Color(hex: "E4D794")),
        ThemePreset(id: "ayu-light", name: "Ayu Light", appearance: .light, accent: Color(hex: "FF9940"),
                    content: Color(hex: "FCFCFC"), chrome: Color(hex: "F3F4F5"), surface: Color(hex: "E7EAED")),
        ThemePreset(id: "flexoki-light", name: "Flexoki Light", appearance: .light, accent: Color(hex: "205EA6"),
                    content: Color(hex: "FFFCF0"), chrome: Color(hex: "F2F0E5"), surface: Color(hex: "E6E4D9")),
        ThemePreset(id: "quiet-light", name: "Quiet Light", appearance: .light, accent: Color(hex: "705697"),
                    content: Color(hex: "F5F5F5"), chrome: Color(hex: "EDEDF5"), surface: Color(hex: "E4E6F1")),
        ThemePreset(id: "papercolor-light", name: "PaperColor Light", appearance: .light, accent: Color(hex: "005F87"),
                    content: Color(hex: "EEEEEE"), chrome: Color(hex: "E4E4E4"), surface: Color(hex: "D0D0D0")),
    ]
}

@MainActor @Observable
final class ThemeStore {
    static let shared = ThemeStore()

    var appearance: AppearanceMode {
        didSet { save("theme.appearance", appearance.rawValue); applyAppearance() }
    }
    var presetID: String {
        didSet { save("theme.preset", presetID); applyAppearance() }
    }
    var customAccent: Color? {
        didSet { save("theme.accent", customAccent?.hex) }
    }
    var backgroundImage: URL? {
        didSet { save("theme.backgroundImage", backgroundImage?.path); loadImage() }
    }
    var backgroundOpacity: Double {
        didSet { save("theme.backgroundOpacity", backgroundOpacity) }
    }

    private(set) var image: NSImage?

    private init() {
        let defaults = UserDefaults.standard
        appearance = defaults.string(forKey: "theme.appearance").flatMap(AppearanceMode.init(rawValue:)) ?? .system
        presetID = defaults.string(forKey: "theme.preset") ?? "default"
        customAccent = defaults.string(forKey: "theme.accent").map(Color.init(hex:))
        backgroundImage = defaults.string(forKey: "theme.backgroundImage").map { URL(fileURLWithPath: $0) }
        backgroundOpacity = defaults.object(forKey: "theme.backgroundOpacity") as? Double ?? 0.25
        loadImage()
    }

    var preset: ThemePreset { ThemePreset.all.first { $0.id == presetID } ?? ThemePreset.all[0] }

    var accent: Color { customAccent ?? preset.accent ?? .accentColor }

    /// Má téma vlastnú farbu zvýraznenia? (inak je výber neutrálny ako v Spotlighte)
    var hasAccent: Bool { customAccent != nil || preset.accent != nil }

    var effectiveAppearance: AppearanceMode { preset.appearance ?? appearance }

    /// Volať pri štarte a pri každej zmene témy.
    func applyAppearance() {
        NSApp?.appearance = effectiveAppearance.nsAppearance
    }

    private func loadImage() {
        image = backgroundImage.flatMap { NSImage(contentsOf: $0) }
    }

    private func save(_ key: String, _ value: Any?) {
        if let value { UserDefaults.standard.set(value, forKey: key) } else { UserDefaults.standard.removeObject(forKey: key) }
    }
}

extension Color {
    /// Farba zvýraznenia témy; používať namiesto `Color.accentColor`.
    @MainActor static var themeAccent: Color { ThemeStore.shared.accent }

    /// Pozadie vybraného riadku: farba témy, alebo neutrálne sivé ako v Spotlighte.
    @MainActor static var themeSelection: Color {
        ThemeStore.shared.hasAccent ? ThemeStore.shared.accent.opacity(0.22) : Color.primary.opacity(0.09)
    }

    /// Karty a štítky: farba témy, alebo jemná systémová.
    @MainActor static var themeSurface: Color { ThemeStore.shared.preset.surface ?? Color.primary.opacity(0.08) }

    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }

    var hex: String? {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        return String(
            format: "%02X%02X%02X",
            Int((rgb.redComponent * 255).rounded()),
            Int((rgb.greenComponent * 255).rounded()),
            Int((rgb.blueComponent * 255).rounded()))
    }
}

/// Pozadie pruhu spúšťača podľa témy: Liquid Glass, matné sklo alebo plná farba, prípadne s obrázkom.
struct ThemedLauncherBackground: ViewModifier {
    let cornerRadius: CGFloat
    private var theme: ThemeStore { .shared }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let base = content
            .background {
                if let image = theme.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(theme.backgroundOpacity)
                        .allowsHitTesting(false)
                        .clipShape(shape)
                }
            }
            .tint(theme.accent)
        if let color = theme.preset.content {
            base
                .background(color, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.08)))
                .clipShape(shape)
        } else if theme.preset.frosted {
            base
                .background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.12)))
                .clipShape(shape)
        } else {
            base.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }
}

extension View {
    func themedLauncherBackground(cornerRadius: CGFloat) -> some View {
        modifier(ThemedLauncherBackground(cornerRadius: cornerRadius))
    }
}
