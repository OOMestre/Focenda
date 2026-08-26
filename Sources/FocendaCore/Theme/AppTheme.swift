import Foundation
import SwiftUI
import AppKit

/// Centralized theme definition for Focenda providing a calm, organic, and distraction-free design system.
public enum AppTheme {

    // MARK: - Dynamic Color Helper

    /// Creates a dynamic SwiftUI Color that adapts automatically between Light and Dark mode appearances.
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
    /// Light: Deep Forest Slate (#344E41) / Dark: Calm Sage Forest (#6B8E7D)
    public static let deepFocus = dynamicColor(
        lightRed: 0.204, lightGreen: 0.306, lightBlue: 0.255,
        darkRed: 0.420, darkGreen: 0.557, darkBlue: 0.490
    )

    /// Short Break: Soft Sage / Matcha
    /// Light: Earthy Matcha Sage (#4D6A53) / Dark: Soft Matcha (#7E9F85)
    public static let shortBreak = dynamicColor(
        lightRed: 0.302, lightGreen: 0.416, lightBlue: 0.325,
        darkRed: 0.494, darkGreen: 0.624, darkBlue: 0.522
    )

    /// Long Break: Muted Terracotta / Warm Sand
    /// Light: Warm Terracotta (#9C5B42) / Dark: Muted Warm Terracotta (#C87D65)
    public static let longBreak = dynamicColor(
        lightRed: 0.612, lightGreen: 0.357, lightBlue: 0.259,
        darkRed: 0.784, darkGreen: 0.490, darkBlue: 0.396
    )

    // MARK: - Surfaces & Backgrounds

    /// App Background:
    /// Light: Warm Linen / Cream (#F9F8F5)
    /// Dark: Quiet Obsidian / Matte Charcoal (#18181B)
    public static let background = dynamicColor(
        lightRed: 0.976, lightGreen: 0.973, lightBlue: 0.961,
        darkRed: 0.094, darkGreen: 0.094, darkBlue: 0.106
    )

    /// Card / Surface Background:
    /// Light: Pure Warm Paper White (#FFFFFF)
    /// Dark: Elevated Soft Slate (#222226)
    public static let cardBackground = dynamicColor(
        lightRed: 1.000, lightGreen: 1.000, lightBlue: 1.000,
        darkRed: 0.133, darkGreen: 0.133, darkBlue: 0.149
    )

    /// Secondary / Hover Surface Background:
    /// Light: Soft Warm Linen Tint (#F2EFE9)
    /// Dark: Subdued Dark Slate (#2A2A30)
    public static let cardBackgroundSubtle = dynamicColor(
        lightRed: 0.949, lightGreen: 0.937, lightBlue: 0.914,
        darkRed: 0.165, darkGreen: 0.165, darkBlue: 0.188
    )

    /// Sidebar Background:
    /// Light: Warm Stone Linen (#F4F2EB)
    /// Dark: Quiet Matte Charcoal (#141417)
    public static let sidebarBackground = dynamicColor(
        lightRed: 0.957, lightGreen: 0.949, lightBlue: 0.922,
        darkRed: 0.078, darkGreen: 0.078, darkBlue: 0.090
    )

    // MARK: - Borders & Separators

    /// Primary Crisp Subtle Border:
    /// Light: Subtle Warm Stone Border
    /// Dark: Crisp Subtle Charcoal Border (#2E2E36)
    public static let border = dynamicColor(
        lightRed: 0.863, lightGreen: 0.839, lightBlue: 0.796, lightAlpha: 0.75,
        darkRed: 0.180, darkGreen: 0.180, darkBlue: 0.212, darkAlpha: 0.90
    )

    /// Hairline / Subtle Border:
    public static let subtleBorder = dynamicColor(
        lightRed: 0.880, lightGreen: 0.860, lightBlue: 0.820, lightAlpha: 0.40,
        darkRed: 0.220, darkGreen: 0.220, darkBlue: 0.250, darkAlpha: 0.50
    )

    // MARK: - Typography & Content

    /// Primary Text:
    /// Light: Deep Charcoal (#1C1E21)
    /// Dark: Calm Off-White (#F4F4F6)
    public static let textPrimary = dynamicColor(
        lightRed: 0.110, lightGreen: 0.118, lightBlue: 0.129,
        darkRed: 0.957, darkGreen: 0.957, darkBlue: 0.965
    )

    /// Secondary Text:
    /// Light: Warm Graphite (#5A5D64)
    /// Dark: Muted Zinc Slate (#A1A1AA)
    public static let textSecondary = dynamicColor(
        lightRed: 0.353, lightGreen: 0.365, lightBlue: 0.392,
        darkRed: 0.631, darkGreen: 0.631, darkBlue: 0.667
    )

    /// Tertiary Text:
    /// Light: Soft Stone (#8A8D94)
    /// Dark: Quiet Slate (#71717A)
    public static let textTertiary = dynamicColor(
        lightRed: 0.541, lightGreen: 0.553, lightBlue: 0.580,
        darkRed: 0.443, darkGreen: 0.443, darkBlue: 0.478
    )

    // MARK: - Semantic Accent Palette

    /// Brand Primary Accent: Calm Sage Forest
    public static let accent = dynamicColor(
        lightRed: 0.239, lightGreen: 0.353, lightBlue: 0.298,
        darkRed: 0.490, darkGreen: 0.647, darkBlue: 0.569
    )

    /// Warm Sandstone / Gold (used for focus streaks and warnings):
    public static let sandstone = dynamicColor(
        lightRed: 0.725, lightGreen: 0.522, lightBlue: 0.282,
        darkRed: 0.851, darkGreen: 0.663, darkBlue: 0.435
    )

    /// Organic Moss / Success:
    public static let success = dynamicColor(
        lightRed: 0.278, lightGreen: 0.459, lightBlue: 0.322,
        darkRed: 0.482, darkGreen: 0.667, darkBlue: 0.533
    )

    /// Muted Terracotta / High Priority:
    public static let terracotta = dynamicColor(
        lightRed: 0.690, lightGreen: 0.333, lightBlue: 0.267,
        darkRed: 0.820, darkGreen: 0.471, darkBlue: 0.404
    )

    /// Calm River Slate / Medium Priority:
    public static let riverSlate = dynamicColor(
        lightRed: 0.329, lightGreen: 0.435, lightBlue: 0.490,
        darkRed: 0.518, darkGreen: 0.635, darkBlue: 0.698
    )
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
