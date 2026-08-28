import SwiftUI

/// A friendly, distraction-free way to support Focenda's independent development.
public struct SupportView: View {
    public static let supportURL = URL(string: "https://buymeacoffee.com/omestre")!

    public init() {}

    public var body: some View {
        ScrollView {
            VStack {
                supportCard
            }
            .frame(maxWidth: .infinity, minHeight: 500)
            .padding(28)
        }
        .background(AppTheme.background)
        .navigationTitle("Support")
    }

    private var supportCard: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.textPrimary)
                    .frame(width: 156, height: 156)

                Image(systemName: "heart.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 10) {
                Text("Help Focenda keep growing")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Focenda is free, independent, and built in my spare time. If you enjoy using it, a contribution helps keep development moving forward.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 720)
            }

            Link(destination: Self.supportURL) {
                Label("Support on Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textOnAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.accent.opacity(0.24), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("supportOnBuyMeACoffeeButton")
        }
        .frame(maxWidth: 860)
        .padding(.horizontal, 36)
        .padding(.vertical, 48)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 5)
    }
}
