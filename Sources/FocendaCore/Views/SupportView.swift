import SwiftUI

/// A friendly, distraction-free way to support Focenda's independent development.
public struct SupportView: View {
    public static let supportURL = URL(string: "https://buymeacoffee.com/omestre")!
    public static let githubURL = GitHubFeedbackURLBuilder.repositoryURL

    @State private var selectedFeedbackKind: GitHubFeedbackKind?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                feedbackCard
                supportCard
            }
            .frame(maxWidth: 760, minHeight: 360)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(AppTheme.background)
        .navigationTitle("Support")
        .sheet(item: $selectedFeedbackKind) { kind in
            GitHubFeedbackFormView(kind: kind)
        }
    }

    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Report a problem or share an idea")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Your message will open as a pre-filled GitHub issue. Choose a category, review the details, and submit it when you are ready.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 10) {
                feedbackButton(for: .bug)
                feedbackButton(for: .suggestion)
            }

            Label("GitHub may ask you to sign in before you submit.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Label("Do not include passwords or other private information.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 640, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feedbackSection")
    }

    private func feedbackButton(for kind: GitHubFeedbackKind) -> some View {
        Button {
            selectedFeedbackKind = kind
        } label: {
            HStack(spacing: 12) {
                Image(systemName: kind.systemImageName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.buttonTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(kind.buttonSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(AppTheme.cardBackgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind.accessibilityLabel)
        .accessibilityHint("Opens a short form before opening GitHub.")
        .accessibilityIdentifier(kind.accessibilityIdentifier)
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

/// A short form that prepares a categorized, pre-filled issue for GitHub.
public struct GitHubFeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public let kind: GitHubFeedbackKind

    @State private var title = ""
    @State private var details = ""

    public init(kind: GitHubFeedbackKind) {
        self.kind = kind
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        TextField(kind.titlePrompt, text: $title)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Issue title")
                            .accessibilityIdentifier("feedbackTitleField")
                            .onChange(of: title) { _, newValue in
                                guard newValue.count > GitHubFeedbackURLBuilder.maxTitleLength else { return }
                                title = String(newValue.prefix(GitHubFeedbackURLBuilder.maxTitleLength))
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(kind.detailsPrompt)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $details)
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .frame(minHeight: 160)
                                .background(AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                                )
                                .accessibilityLabel(kind.detailsPrompt)
                                .accessibilityHint(kind.detailsPlaceholder)
                                .accessibilityIdentifier("feedbackDetailsField")
                                .onChange(of: details) { _, newValue in
                                    guard newValue.count > GitHubFeedbackURLBuilder.maxDetailsLength else { return }
                                    details = String(newValue.prefix(GitHubFeedbackURLBuilder.maxDetailsLength))
                                }

                            if details.isEmpty {
                                Text(kind.detailsPlaceholder)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 14)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }

                        Text("Up to \(GitHubFeedbackURLBuilder.maxDetailsLength.formatted()) characters")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                            .accessibilityLabel("Maximum \(GitHubFeedbackURLBuilder.maxDetailsLength.formatted()) characters")
                    }

                    Label("Focenda adds the app version, macOS version, and hardware architecture to help us understand your report.", systemImage: "wand.and.stars")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Label("When you continue, the browser sends the pre-filled text to GitHub to show the form. Review it there; the issue is not public until you click Submit.", systemImage: "safari")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    Label("Do not include passwords or other private information.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }

            Divider()

            HStack(spacing: 10) {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button {
                    submitToGitHub()
                } label: {
                    Label("Continue to GitHub", systemImage: "arrow.up.right")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit)
                .accessibilityIdentifier("feedbackContinueToGitHubButton")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 460, idealHeight: 540)
        .background(AppTheme.background)
        .preferredColorScheme(AppTheme.current.colorScheme)
        .accessibilityIdentifier("githubFeedbackForm")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.systemImageName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 42, height: 42)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.formTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(kind.formDescription)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close feedback form")
            .accessibilityIdentifier("closeFeedbackFormButton")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitToGitHub() {
        let issueURL = GitHubFeedbackURLBuilder.makeIssueURL(
            for: kind,
            title: title,
            details: details
        )
        openURL(issueURL)
        dismiss()
    }
}
