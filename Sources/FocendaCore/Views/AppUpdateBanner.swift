import SwiftUI

public struct AppUpdateBanner: View {
    public let update: AppUpdate
    public let isInstalling: Bool
    public let onInstall: () -> Void
    public let onDismiss: () -> Void

    public init(
        update: AppUpdate,
        isInstalling: Bool,
        onInstall: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.update = update
        self.isInstalling = isInstalling
        self.onInstall = onInstall
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.textOnAccent)
                .frame(width: 34, height: 34)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Focenda update available")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Version \(update.version.description) is ready to install.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Button {
                onInstall()
            } label: {
                Group {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                            .tint(AppTheme.textOnAccent)
                            .frame(minWidth: 86)
                    } else {
                        Text("Update Now")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(minWidth: 86)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .foregroundStyle(AppTheme.textOnAccent)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isInstalling)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(isInstalling)
            .help("Remind me later")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 4)
    }
}
