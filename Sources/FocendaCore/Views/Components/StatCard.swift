import SwiftUI

/// Elegant statistics card component with hover elevation and subtle borders for macOS
public struct StatCard: View {
    public let title: String
    public let value: String
    public let subtitle: String?
    public let icon: String
    public let color: Color

    @State private var isHovered: Bool = false

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 38, height: 38)
                    .background(color.opacity(isHovered ? 0.16 : 0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .scaleEffect(isHovered ? 1.04 : 1.0)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .calmCard(isHovered: isHovered, cornerRadius: 14)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
