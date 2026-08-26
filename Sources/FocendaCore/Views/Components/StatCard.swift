import SwiftUI

/// Elegant statistics card component with hover elevation and subtle gradient border for macOS
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
                    .background(color.opacity(isHovered ? 0.18 : 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .scaleEffect(isHovered ? 1.06 : 1.0)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(
                    color: isHovered ? color.opacity(0.12) : Color.black.opacity(0.04),
                    radius: isHovered ? 10 : 6,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(isHovered ? 0.45 : 0.1),
                            color.opacity(isHovered ? 0.2 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
