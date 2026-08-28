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
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

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
                if isInstalling {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 70)
                } else {
                    Text("Update Now")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 70)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(isInstalling)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(isInstalling)
            .help("Remind me later")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
    }
}
