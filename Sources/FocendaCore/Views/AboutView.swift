import SwiftUI

/// A dedicated home for Focenda's identity, version information, and updates.
public struct AboutView: View {
    public static let githubURL = URL(string: "https://github.com/OOMestre/Focenda")!

    @Bindable var appState: AppState
    var updateManager: AppUpdateManager

    @State private var isShowingUpdateGuide = false
    @State private var updatePendingConfirmation: AppUpdate?

    public init(
        appState: AppState,
        updateManager: AppUpdateManager = AppUpdateManager()
    ) {
        self.appState = appState
        self.updateManager = updateManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                appIdentitySection
                appUpdateSection
                projectDetailsSection
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(AppTheme.background)
        .navigationTitle("About")
        .sheet(isPresented: $isShowingUpdateGuide) {
            if AppUpdateGuide.isEnabled, let guide = updateManager.lastUpdateGuide {
                AppUpdateGuideView(guide: guide) {
                    isShowingUpdateGuide = false
                }
            } else {
                EmptyView()
            }
        }
        .alert(item: $updatePendingConfirmation) { update in
            Alert(
                title: Text(AppUpdateConfirmation.title),
                message: Text(AppUpdateConfirmation.message(for: update)),
                primaryButton: .default(Text(AppUpdateConfirmation.actionTitle)) {
                    updateManager.installAvailableUpdate()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var appIdentitySection: some View {
        VStack(spacing: 14) {
            OwlMascotView(size: 112)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .accessibilityIdentifier("aboutAppLogo")

            VStack(spacing: 6) {
                Text("Focenda")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .accessibilityIdentifier("aboutAppName")

                Text("A calm workspace for focus, tasks, and time.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    Text("Version \(AppRuntime.currentReleaseIdentifier)")
                        .accessibilityIdentifier("aboutAppVersion")
                    Text("•")
                    Text("100% Free & Open Source")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var appUpdateSection: some View {
        GroupBox(label: Label("Keep Focenda Up to Date", systemImage: "arrow.down.circle").foregroundStyle(AppTheme.textPrimary)) {
            VStack(alignment: .leading, spacing: 14) {
                updateStatusRow

                Divider()

                Toggle(isOn: $appState.automaticUpdateChecksEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Check for updates automatically")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Check GitHub Releases once a day while Focenda is open and notify you when a new version is ready.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(AppTheme.accent)
                .onChange(of: appState.automaticUpdateChecksEnabled) { _, isEnabled in
                    updateManager.setAutomaticChecksEnabled(isEnabled)
                }

                lastUpdateGuideSection

                if let update = updateManager.availableUpdate {
                    availableUpdateCard(update)
                }

                if case .failed(let message) = updateManager.status {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
        }
    }

    private var updateStatusRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: updateStatusIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(updateStatusColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(updateStatusTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                if let lastCheckedAt = updateManager.lastCheckedAt {
                    Text("Last checked \(lastCheckedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Spacer(minLength: 8)

            Button {
                updateManager.checkForUpdates()
            } label: {
                Label(updateManager.status == .checking ? "Checking..." : "Check for Updates", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(updateManager.status.isBusy)
            .accessibilityIdentifier("aboutCheckForUpdatesButton")
        }
    }

    private func availableUpdateCard(_ update: AppUpdate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Version \(update.version.description) is available")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(update.displayName)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack {
                Button("Update Now") {
                    updatePendingConfirmation = update
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.small)
                .disabled(updateManager.status.isBusy)
                .accessibilityIdentifier("aboutUpdateNowButton")

                Button("Later") {
                    updateManager.dismissAvailableUpdate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(updateManager.status.isBusy)

                Spacer()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
        )
    }

    private var lastUpdateGuideSection: some View {
        Group {
            if AppUpdateGuide.isEnabled, let guide = updateManager.lastUpdateGuide {
                Divider()

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Review the latest update")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("See what changed in Focenda \(guide.version) • \(guide.title)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 12)

                    Button {
                        isShowingUpdateGuide = true
                    } label: {
                        Label("Replay Last Update", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("aboutReplayUpdateButton")
                }
            }
        }
    }

    private var projectDetailsSection: some View {
        GroupBox(label: Label("The Focenda Project", systemImage: "info.circle").foregroundStyle(AppTheme.textPrimary)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Built natively with Swift and SwiftUI for a lightweight, distraction-free productivity experience.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Divider()

                HStack(spacing: 12) {
                    Link(destination: Self.githubURL) {
                        Label("GitHub Repository", systemImage: "link")
                    }
                    .foregroundStyle(AppTheme.accent)

                    Spacer()

                    Text("GPL-3.0 License")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Text("Privacy: Tasks, notes, reminders, bookmarks, productivity profiles, and preferences stay on this Mac in encrypted local storage. Focenda contacts only GitHub's public release service for update metadata and the selected app archive. macOS may display reminder content in its notification system. See docs/PRIVACY.md for details.")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
    }

    private var updateStatusTitle: String {
        switch updateManager.status {
        case .idle:
            return "Updates are ready to check"
        case .checking:
            return "Checking GitHub Releases..."
        case .available:
            return "A new version is ready"
        case .upToDate:
            return "Focenda is up to date"
        case .installing:
            return "Installing update..."
        case .failed:
            return updateManager.availableUpdate != nil ? "Update could not be installed" : "Update check could not be completed"
        }
    }

    private var updateStatusIcon: String {
        switch updateManager.status {
        case .idle:
            return "arrow.down.circle"
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .available:
            return "checkmark.seal.fill"
        case .upToDate:
            return "checkmark.circle.fill"
        case .installing:
            return "shippingbox.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var updateStatusColor: Color {
        switch updateManager.status {
        case .failed:
            return .orange
        case .available, .installing:
            return AppTheme.accent
        case .upToDate:
            return AppTheme.success
        case .idle, .checking:
            return AppTheme.textTertiary
        }
    }
}
