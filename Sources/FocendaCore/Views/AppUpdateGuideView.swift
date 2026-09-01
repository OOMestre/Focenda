import SwiftUI

/// A compact, paginated introduction to the release that was just installed.
public struct AppUpdateGuideView: View {
    public let guide: AppUpdateGuide
    public let onFinish: () -> Void

    @State private var pageIndex = 0

    public init(guide: AppUpdateGuide, onFinish: @escaping () -> Void) {
        self.guide = guide
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Button {
                    onFinish()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Close update guide")
            }
            .padding(.top, 14)
            .padding(.horizontal, 18)

            Group {
                if pageIndex == 0 || guide.sections.isEmpty {
                    welcomePage
                } else if let section = guide.sections[safe: pageIndex - 1] {
                    sectionPage(section)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 30)
            .padding(.vertical, 18)

            pageIndicator

            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                Button("Skip") {
                    onFinish()
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Button(pageIndex == pageCount - 1 ? "Finish" : "Next") {
                    advance()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(18)
        }
        .frame(width: 520)
        .frame(minHeight: 390, maxHeight: 620)
        .background(AppTheme.background)
    }

    private var pageCount: Int {
        max(1, guide.sections.count + 1)
    }

    private var welcomePage: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.14))
                    .frame(width: 82, height: 82)

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Text("New update")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 5) {
                Text("Focenda " + guide.version)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)

                Text(guide.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Text("Here’s a quick tour of what’s new. Use Next to see each improvement.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .frame(maxWidth: 380)
    }

    private func sectionPage(_ section: AppUpdateGuideSection) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: section.title))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("What’s new")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .textCase(.uppercase)

                    Text(section.title)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(item)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
            }
            .frame(maxHeight: 245)
        }
        .frame(maxWidth: 430, alignment: .leading)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? AppTheme.accent : AppTheme.border)
                    .frame(width: index == pageIndex ? 20 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: pageIndex)
            }
        }
        .padding(.bottom, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Guide page " + String(pageIndex + 1) + " of " + String(pageCount))
    }

    private func advance() {
        guard pageIndex < pageCount - 1 else {
            onFinish()
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            pageIndex += 1
        }
    }

    private func iconName(for title: String) -> String {
        let normalized = title.lowercased()
        if normalized.contains("bug") || normalized.contains("stability") {
            return "checkmark.shield.fill"
        }
        if normalized.contains("ui") || normalized.contains("interface") || normalized.contains("refinement") {
            return "rectangle.3.group"
        }
        if normalized.contains("shortcut") || normalized.contains("keyboard") {
            return "command"
        }
        if normalized.contains("document") || normalized.contains("guide") {
            return "book.pages"
        }
        return "sparkles"
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
