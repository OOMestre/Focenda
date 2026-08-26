import Foundation
import SwiftUI
import AppKit

/// Selectable application themes providing a calm, organic, and distraction-free design system.
public enum AppThemeOption: String, CaseIterable, Identifiable, Codable {
    case zenCalm = "Zen Calm (Light)"
    case obsidianMinimal = "Obsidian Minimal (Dark)"
    case warmSandstone = "Warm Sandstone"
    case nordicFrost = "Nordic Frost"
    case forestMatcha = "Forest Matcha"

    public var id: String { rawValue }
    public var displayName: String { rawValue }

    public var subtitle: String {
        switch self {
        case .zenCalm:
            return "Warm linen / cream paper with charcoal typography."
        case .obsidianMinimal:
            return "Quiet matte obsidian charcoal (#18181B) with warm subtle borders."
        case .warmSandstone:
            return "Earthy warm neutral palette with sunlit accents."
        case .nordicFrost:
            return "Clean cool slate and arctic muted blue."
        case .forestMatcha:
            return "Deep tranquil organic evergreen and sage."
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .zenCalm:
            return .light
        case .obsidianMinimal:
            return .dark
        case .warmSandstone, .nordicFrost, .forestMatcha:
            return nil
        }
    }

    /// Color swatches for live preview in Settings
    public var previewSwatches: [Color] {
        switch self {
        case .zenCalm:
            return [
                Color(red: 0.976, green: 0.973, blue: 0.961), // linen bg
                Color(red: 1.000, green: 1.000, blue: 1.000), // paper card
                Color(red: 0.204, green: 0.306, blue: 0.255), // deep forest accent
                Color(red: 0.110, green: 0.118, blue: 0.129), // charcoal text
                Color(red: 0.725, green: 0.522, blue: 0.282)  // sandstone
            ]
        case .obsidianMinimal:
            return [
                Color(red: 0.094, green: 0.094, blue: 0.106), // #18181B obsidian
                Color(red: 0.133, green: 0.133, blue: 0.149), // card
                Color(red: 0.420, green: 0.557, blue: 0.490), // sage accent
                Color(red: 0.957, green: 0.957, blue: 0.965), // light text
                Color(red: 0.180, green: 0.180, blue: 0.212)  // border
            ]
        case .warmSandstone:
            return [
                Color(red: 0.969, green: 0.957, blue: 0.933), // sandstone bg
                Color(red: 1.000, green: 1.000, blue: 1.000), // card
                Color(red: 0.722, green: 0.451, blue: 0.200), // terracotta/sandstone accent
                Color(red: 0.157, green: 0.137, blue: 0.114), // warm charcoal text
                Color(red: 0.875, green: 0.843, blue: 0.784)  // border
            ]
        case .nordicFrost:
            return [
                Color(red: 0.949, green: 0.961, blue: 0.973), // cool slate bg
                Color(red: 1.000, green: 1.000, blue: 1.000), // card
                Color(red: 0.231, green: 0.431, blue: 0.549), // arctic muted blue accent
                Color(red: 0.094, green: 0.133, blue: 0.176), // slate text
                Color(red: 0.816, green: 0.867, blue: 0.906)  // ice border
            ]
        case .forestMatcha:
            return [
                Color(red: 0.953, green: 0.965, blue: 0.953), // matcha bg
                Color(red: 1.000, green: 1.000, blue: 1.000), // card
                Color(red: 0.180, green: 0.357, blue: 0.239), // evergreen accent
                Color(red: 0.078, green: 0.133, blue: 0.094), // forest text
                Color(red: 0.812, green: 0.875, blue: 0.812)  // sage border
            ]
        }
    }

    public static func from(storedValue: String?) -> AppThemeOption {
        guard let stored = storedValue, !stored.isEmpty else { return .zenCalm }
        if let match = AppThemeOption(rawValue: stored) {
            return match
        }
        switch stored.lowercased() {
        case "zencalm", "zen calm (light)", "zen calm", "zen", "light":
            return .zenCalm
        case "obsidianminimal", "obsidian minimal (dark)", "obsidian minimal", "obsidian", "dark":
            return .obsidianMinimal
        case "warmsandstone", "warm sandstone", "sandstone":
            return .warmSandstone
        case "nordicfrost", "nordic frost", "frost", "nordic":
            return .nordicFrost
        case "forestmatcha", "forest matcha", "matcha", "forest":
            return .forestMatcha
        default:
            return .zenCalm
        }
    }
}

/// Centralized theme definition for Focenda providing a calm, organic, and distraction-free design system.
public enum AppTheme {

    /// Storage key used in UserDefaults
    public static let storageKey = "focenda_selected_theme"

    private static var _cachedTheme: AppThemeOption? = nil

    /// Currently active theme option
    public static var current: AppThemeOption {
        get {
            if let cached = _cachedTheme {
                return cached
            }
            let stored = UserDefaults.standard.string(forKey: storageKey)
            let resolved = AppThemeOption.from(storedValue: stored)
            _cachedTheme = resolved
            return resolved
        }
        set {
            _cachedTheme = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }

    // MARK: - Dynamic Color Helper

    /// Creates a dynamic SwiftUI Color that adapts automatically based on the active theme and system appearance.
    public static func dynamicThemeColor(
        zenLight: (r: Double, g: Double, b: Double, a: Double),
        obsidianDark: (r: Double, g: Double, b: Double, a: Double),
        sandstoneLight: (r: Double, g: Double, b: Double, a: Double),
        sandstoneDark: (r: Double, g: Double, b: Double, a: Double),
        nordicLight: (r: Double, g: Double, b: Double, a: Double),
        nordicDark: (r: Double, g: Double, b: Double, a: Double),
        matchaLight: (r: Double, g: Double, b: Double, a: Double),
        matchaDark: (r: Double, g: Double, b: Double, a: Double)
    ) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            let isDark = match == .darkAqua

            switch AppTheme.current {
            case .zenCalm:
                return NSColor(srgbRed: zenLight.r, green: zenLight.g, blue: zenLight.b, alpha: zenLight.a)
            case .obsidianMinimal:
                return NSColor(srgbRed: obsidianDark.r, green: obsidianDark.g, blue: obsidianDark.b, alpha: obsidianDark.a)
            case .warmSandstone:
                let c = isDark ? sandstoneDark : sandstoneLight
                return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
            case .nordicFrost:
                let c = isDark ? nordicDark : nordicLight
                return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
            case .forestMatcha:
                let c = isDark ? matchaDark : matchaLight
                return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
            }
        }))
    }

    /// Backwards compatible helper for simple Light/Dark dynamic color pairs
    public static func dynamicColor(
        lightRed: Double, lightGreen: Double, lightBlue: Double, lightAlpha: Double = 1.0,
        darkRed: Double, darkGreen: Double, darkBlue: Double, darkAlpha: Double = 1.0
    ) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            if match == .darkAqua {
                return NSColor(srgbRed: darkRed, green: darkGreen, blue: darkBlue, alpha: darkAlpha)
            } else {
                return NSColor(srgbRed: lightRed, green: lightGreen, blue: lightBlue, alpha: lightAlpha)
            }
        }))
    }

    // MARK: - Focus Mode Colors (Calm, Sophisticated & Organic)

    /// Deep Focus: Calm Forest Slate / Deep Warm Slate
    public static var deepFocus: Color {
        dynamicThemeColor(
            zenLight: (0.204, 0.306, 0.255, 1.0),
            obsidianDark: (0.420, 0.557, 0.490, 1.0),
            sandstoneLight: (0.612, 0.388, 0.188, 1.0),
            sandstoneDark: (0.780, 0.533, 0.314, 1.0),
            nordicLight: (0.231, 0.431, 0.549, 1.0),
            nordicDark: (0.365, 0.588, 0.722, 1.0),
            matchaLight: (0.180, 0.357, 0.239, 1.0),
            matchaDark: (0.322, 0.600, 0.431, 1.0)
        )
    }

    /// Short Break: Soft Sage / Matcha
    public static var shortBreak: Color {
        dynamicThemeColor(
            zenLight: (0.302, 0.416, 0.325, 1.0),
            obsidianDark: (0.494, 0.624, 0.522, 1.0),
            sandstoneLight: (0.478, 0.522, 0.314, 1.0),
            sandstoneDark: (0.620, 0.659, 0.447, 1.0),
            nordicLight: (0.294, 0.518, 0.467, 1.0),
            nordicDark: (0.427, 0.667, 0.627, 1.0),
            matchaLight: (0.302, 0.478, 0.345, 1.0),
            matchaDark: (0.455, 0.643, 0.502, 1.0)
        )
    }

    /// Long Break: Muted Terracotta / Warm Sand
    public static var longBreak: Color {
        dynamicThemeColor(
            zenLight: (0.612, 0.357, 0.259, 1.0),
            obsidianDark: (0.784, 0.490, 0.396, 1.0),
            sandstoneLight: (0.690, 0.361, 0.231, 1.0),
            sandstoneDark: (0.831, 0.478, 0.341, 1.0),
            nordicLight: (0.459, 0.392, 0.541, 1.0),
            nordicDark: (0.616, 0.549, 0.690, 1.0),
            matchaLight: (0.561, 0.396, 0.275, 1.0),
            matchaDark: (0.722, 0.545, 0.416, 1.0)
        )
    }

    // MARK: - Surfaces & Backgrounds

    /// App Background
    public static var background: Color {
        dynamicThemeColor(
            zenLight: (0.976, 0.973, 0.961, 1.0), // Warm Linen / Cream (#F9F8F5)
            obsidianDark: (0.094, 0.094, 0.106, 1.0), // Matte Charcoal (#18181B)
            sandstoneLight: (0.969, 0.957, 0.933, 1.0), // Sandstone (#F7F4EE)
            sandstoneDark: (0.118, 0.106, 0.094, 1.0),
            nordicLight: (0.949, 0.961, 0.973, 1.0), // Slate (#F2F5F8)
            nordicDark: (0.078, 0.094, 0.114, 1.0),
            matchaLight: (0.953, 0.965, 0.953, 1.0), // Matcha (#F3F6F3)
            matchaDark: (0.075, 0.102, 0.082, 1.0)
        )
    }

    /// Card / Surface Background
    public static var cardBackground: Color {
        dynamicThemeColor(
            zenLight: (1.000, 1.000, 1.000, 1.0), // Warm Paper White
            obsidianDark: (0.133, 0.133, 0.149, 1.0), // Soft Slate (#222226)
            sandstoneLight: (1.000, 1.000, 1.000, 1.0),
            sandstoneDark: (0.157, 0.141, 0.125, 1.0),
            nordicLight: (1.000, 1.000, 1.000, 1.0),
            nordicDark: (0.110, 0.133, 0.165, 1.0),
            matchaLight: (1.000, 1.000, 1.000, 1.0),
            matchaDark: (0.106, 0.141, 0.118, 1.0)
        )
    }

    /// Secondary / Hover Surface Background
    public static var cardBackgroundSubtle: Color {
        dynamicThemeColor(
            zenLight: (0.949, 0.937, 0.914, 1.0),
            obsidianDark: (0.165, 0.165, 0.188, 1.0),
            sandstoneLight: (0.937, 0.918, 0.878, 1.0),
            sandstoneDark: (0.196, 0.176, 0.157, 1.0),
            nordicLight: (0.898, 0.925, 0.949, 1.0),
            nordicDark: (0.141, 0.173, 0.212, 1.0),
            matchaLight: (0.902, 0.933, 0.902, 1.0),
            matchaDark: (0.137, 0.180, 0.153, 1.0)
        )
    }

    /// Sidebar Background
    public static var sidebarBackground: Color {
        dynamicThemeColor(
            zenLight: (0.957, 0.949, 0.922, 1.0),
            obsidianDark: (0.078, 0.078, 0.090, 1.0),
            sandstoneLight: (0.949, 0.929, 0.894, 1.0),
            sandstoneDark: (0.094, 0.082, 0.075, 1.0),
            nordicLight: (0.918, 0.941, 0.965, 1.0),
            nordicDark: (0.063, 0.078, 0.094, 1.0),
            matchaLight: (0.925, 0.949, 0.925, 1.0),
            matchaDark: (0.055, 0.078, 0.063, 1.0)
        )
    }

    // MARK: - Borders & Separators

    /// Primary Crisp Subtle Border
    public static var border: Color {
        dynamicThemeColor(
            zenLight: (0.863, 0.839, 0.796, 0.75),
            obsidianDark: (0.180, 0.180, 0.212, 0.90),
            sandstoneLight: (0.875, 0.843, 0.784, 0.75),
            sandstoneDark: (0.239, 0.212, 0.184, 0.90),
            nordicLight: (0.816, 0.867, 0.906, 0.75),
            nordicDark: (0.169, 0.212, 0.259, 0.90),
            matchaLight: (0.812, 0.875, 0.812, 0.75),
            matchaDark: (0.153, 0.212, 0.173, 0.90)
        )
    }

    /// Hairline / Subtle Border
    public static var subtleBorder: Color {
        dynamicThemeColor(
            zenLight: (0.880, 0.860, 0.820, 0.40),
            obsidianDark: (0.220, 0.220, 0.250, 0.50),
            sandstoneLight: (0.906, 0.878, 0.827, 0.45),
            sandstoneDark: (0.290, 0.259, 0.227, 0.50),
            nordicLight: (0.859, 0.898, 0.929, 0.45),
            nordicDark: (0.208, 0.259, 0.322, 0.50),
            matchaLight: (0.859, 0.906, 0.859, 0.45),
            matchaDark: (0.196, 0.271, 0.220, 0.50)
        )
    }

    // MARK: - Typography & Content

    /// Primary Text
    public static var textPrimary: Color {
        dynamicThemeColor(
            zenLight: (0.110, 0.118, 0.129, 1.0), // Deep Charcoal (#1C1E21)
            obsidianDark: (0.957, 0.957, 0.965, 1.0), // Calm Off-White (#F4F4F6)
            sandstoneLight: (0.157, 0.137, 0.114, 1.0),
            sandstoneDark: (0.961, 0.937, 0.922, 1.0),
            nordicLight: (0.094, 0.133, 0.176, 1.0),
            nordicDark: (0.933, 0.953, 0.973, 1.0),
            matchaLight: (0.078, 0.133, 0.094, 1.0),
            matchaDark: (0.937, 0.961, 0.937, 1.0)
        )
    }

    /// Secondary Text
    public static var textSecondary: Color {
        dynamicThemeColor(
            zenLight: (0.353, 0.365, 0.392, 1.0),
            obsidianDark: (0.631, 0.631, 0.667, 1.0),
            sandstoneLight: (0.431, 0.384, 0.333, 1.0),
            sandstoneDark: (0.722, 0.675, 0.627, 1.0),
            nordicLight: (0.306, 0.380, 0.451, 1.0),
            nordicDark: (0.592, 0.667, 0.749, 1.0),
            matchaLight: (0.275, 0.380, 0.302, 1.0),
            matchaDark: (0.584, 0.690, 0.608, 1.0)
        )
    }

    /// Tertiary Text
    public static var textTertiary: Color {
        dynamicThemeColor(
            zenLight: (0.541, 0.553, 0.580, 1.0),
            obsidianDark: (0.443, 0.443, 0.478, 1.0),
            sandstoneLight: (0.612, 0.557, 0.502, 1.0),
            sandstoneDark: (0.522, 0.478, 0.439, 1.0),
            nordicLight: (0.490, 0.565, 0.639, 1.0),
            nordicDark: (0.420, 0.494, 0.569, 1.0),
            matchaLight: (0.455, 0.561, 0.482, 1.0),
            matchaDark: (0.392, 0.494, 0.416, 1.0)
        )
    }

    // MARK: - Semantic Accent Palette

    /// Brand Primary Accent
    public static var accent: Color {
        dynamicThemeColor(
            zenLight: (0.204, 0.306, 0.255, 1.0), // Calm Sage Forest (#344E41)
            obsidianDark: (0.420, 0.557, 0.490, 1.0), // Calm Sage (#6B8E7D)
            sandstoneLight: (0.722, 0.451, 0.200, 1.0), // Warm Sandstone Amber
            sandstoneDark: (0.851, 0.580, 0.333, 1.0),
            nordicLight: (0.231, 0.431, 0.549, 1.0), // Arctic Muted Blue
            nordicDark: (0.365, 0.588, 0.722, 1.0),
            matchaLight: (0.180, 0.357, 0.239, 1.0), // Evergreen
            matchaDark: (0.322, 0.600, 0.431, 1.0)
        )
    }

    /// Warm Sandstone / Gold
    public static var sandstone: Color {
        dynamicThemeColor(
            zenLight: (0.725, 0.522, 0.282, 1.0),
            obsidianDark: (0.851, 0.663, 0.435, 1.0),
            sandstoneLight: (0.788, 0.525, 0.259, 1.0),
            sandstoneDark: (0.878, 0.643, 0.392, 1.0),
            nordicLight: (0.690, 0.545, 0.349, 1.0),
            nordicDark: (0.831, 0.690, 0.494, 1.0),
            matchaLight: (0.667, 0.529, 0.298, 1.0),
            matchaDark: (0.808, 0.675, 0.443, 1.0)
        )
    }

    /// Organic Moss / Success
    public static var success: Color {
        dynamicThemeColor(
            zenLight: (0.278, 0.459, 0.322, 1.0),
            obsidianDark: (0.482, 0.667, 0.533, 1.0),
            sandstoneLight: (0.361, 0.541, 0.404, 1.0),
            sandstoneDark: (0.494, 0.678, 0.537, 1.0),
            nordicLight: (0.239, 0.478, 0.408, 1.0),
            nordicDark: (0.384, 0.639, 0.565, 1.0),
            matchaLight: (0.180, 0.357, 0.239, 1.0),
            matchaDark: (0.322, 0.600, 0.431, 1.0)
        )
    }

    /// Muted Terracotta / High Priority
    public static var terracotta: Color {
        dynamicThemeColor(
            zenLight: (0.690, 0.333, 0.267, 1.0),
            obsidianDark: (0.820, 0.471, 0.404, 1.0),
            sandstoneLight: (0.769, 0.357, 0.263, 1.0),
            sandstoneDark: (0.871, 0.490, 0.400, 1.0),
            nordicLight: (0.659, 0.322, 0.314, 1.0),
            nordicDark: (0.800, 0.455, 0.447, 1.0),
            matchaLight: (0.639, 0.325, 0.263, 1.0),
            matchaDark: (0.780, 0.459, 0.396, 1.0)
        )
    }

    /// Calm River Slate / Medium Priority
    public static var riverSlate: Color {
        dynamicThemeColor(
            zenLight: (0.329, 0.435, 0.490, 1.0),
            obsidianDark: (0.518, 0.635, 0.698, 1.0),
            sandstoneLight: (0.345, 0.459, 0.522, 1.0),
            sandstoneDark: (0.490, 0.608, 0.667, 1.0),
            nordicLight: (0.231, 0.431, 0.549, 1.0),
            nordicDark: (0.365, 0.588, 0.722, 1.0),
            matchaLight: (0.282, 0.431, 0.396, 1.0),
            matchaDark: (0.431, 0.592, 0.553, 1.0)
        )
    }
}

// MARK: - View Modifiers for Calm Natural Styling

public struct CalmCardModifier: ViewModifier {
    public var isHovered: Bool
    public var cornerRadius: CGFloat

    public init(isHovered: Bool = false, cornerRadius: CGFloat = 12) {
        self.isHovered = isHovered
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.cardBackground)
                    .shadow(
                        color: Color.black.opacity(isHovered ? 0.08 : 0.035),
                        radius: isHovered ? 8 : 4,
                        x: 0,
                        y: isHovered ? 3 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isHovered ? AppTheme.border : AppTheme.subtleBorder, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies a calm, organic card background, subtle border, and soft natural shadow.
    public func calmCard(isHovered: Bool = false, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(CalmCardModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }
}
