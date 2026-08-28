import SwiftUI

/// A friendly, distraction-free way to support Focenda's independent development.
public struct SupportView: View {
    public static let supportURL = URL(string: "https://buymeacoffee.com/omestre")!
    public static let githubURL = URL(string: "https://github.com/OOMestre/Focenda")!

    public init() {}

    public var body: some View {
        ScrollView {
            VStack {
                supportCard
            }
            .frame(maxWidth: .infinity, minHeight: 360)
            .padding(24)
        }
        .background(AppTheme.background)
        .navigationTitle("Support")
    }

    private var supportCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)
            }
            .frame(width: 48, height: 48)
            .background(AppTheme.accent.opacity(0.12))
            .clipShape(Circle())

            VStack(spacing: 6) {
                Text("Help Focenda keep growing")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Focenda is free, independent, and built in my spare time. If you enjoy using it, a contribution helps keep development moving forward.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 540)
            }

            HStack(spacing: 10) {
                supportLink(
                    title: "Buy Me a Coffee",
                    systemImage: "cup.and.saucer.fill",
                    destination: Self.supportURL,
                    identifier: "supportOnBuyMeACoffeeButton",
                    isPrimary: true
                )

                supportLink(
                    title: "Star on GitHub",
                    systemImage: "star.fill",
                    destination: Self.githubURL,
                    identifier: "starOnGitHubButton",
                    isPrimary: false
                )
            }
        }
        .frame(maxWidth: 640)
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private func supportLink(
        title: String,
        systemImage: String,
        destination: URL,
        identifier: String,
        isPrimary: Bool
    ) -> some View {
        Link(destination: destination) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isPrimary ? AppTheme.textOnAccent : AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isPrimary ? AppTheme.accent : AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isPrimary ? Color.clear : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
