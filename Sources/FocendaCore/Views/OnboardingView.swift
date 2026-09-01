import SwiftUI

/// A first-launch guided tour of Focenda's workspace and quick actions.
public struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState

    @State private var currentStepIndex: Int

    private static let heroDiameter: CGFloat = 126

    public static let minimumWidth: CGFloat = 760
    public static let idealWidth: CGFloat = 860
    public static let minimumHeight: CGFloat = 560
    public static let idealHeight: CGFloat = 680

    public init(appState: AppState, initialStep: OnboardingStep = .welcome) {
        self.appState = appState
        let availableSteps = OnboardingStep.availableCases
        _currentStepIndex = State(initialValue: availableSteps.firstIndex(of: initialStep) ?? 0)
    }

    public var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                progressIndicator
                Divider()
                    .overlay(AppTheme.subtleBorder)

                ScrollView {
                    stepContent
                        .id(currentStep.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .scrollIndicators(.visible)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .overlay(AppTheme.subtleBorder)
                footer
            }
        }
        .frame(
            minWidth: Self.minimumWidth,
            idealWidth: Self.idealWidth,
            minHeight: Self.minimumHeight,
            idealHeight: Self.idealHeight
        )
        .background(AppTheme.background)
        .preferredColorScheme(appState.selectedTheme.colorScheme)
        .accessibilityIdentifier("onboardingView")
    }

    private var currentStep: OnboardingStep {
        guard OnboardingStep.availableCases.indices.contains(currentStepIndex) else {
            return .welcome
        }
        return OnboardingStep.availableCases[currentStepIndex]
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                OwlFaceView(size: 34)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Focenda")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("A quick tour of your workspace")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer(minLength: 16)

            Text(currentStep.progressLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityIdentifier("onboardingProgress")

            Button("Skip tour") {
                finishOnboarding()
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.textSecondary)
            .accessibilityIdentifier("onboardingSkipButton")
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
    }

    private var progressIndicator: some View {
        HStack(spacing: 5) {
            ForEach(Array(OnboardingStep.availableCases.enumerated()), id: \.element.id) { index, step in
                Capsule(style: .continuous)
                    .fill(index <= currentStepIndex ? AppTheme.accent : AppTheme.border)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.2), value: currentStepIndex)
            }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress, \(currentStep.progressLabel)")
    }

    private var stepContent: some View {
        VStack(spacing: 22) {
            stepHero

            VStack(spacing: 8) {
                Text(currentStep.eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(AppTheme.accent)

                Text(currentStep.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("onboardingStepTitle")

                Text(currentStep.summary)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 650)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if currentStep == .welcome {
                welcomeFeatureGrid
            }

            tipsCard
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 34)
        .padding(.vertical, 28)
    }

    private var stepHero: some View {
        ZStack {
            if currentStep == .welcome {
                OwlMascotView(size: Self.heroDiameter, isCircular: true)
            } else {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: Self.heroDiameter, height: Self.heroDiameter)

                Image(systemName: currentStep.systemImage)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .symbolRenderingMode(.hierarchical)
            }

            Circle()
                .stroke(AppTheme.accent.opacity(0.22), lineWidth: 1)
                .frame(width: Self.heroDiameter, height: Self.heroDiameter)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(currentStep.title)
    }

    private var welcomeFeatureGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Everything you can do here")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 185, maximum: .infinity), spacing: 10)],
                spacing: 10
            ) {
                ForEach(OnboardingStep.featureSteps) { step in
                    OnboardingFeatureChip(step: step)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackgroundSubtle.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(currentStep == .welcome ? "A few things to know" : "How it works")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)
            }

            ForEach(Array(currentStep.tips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.success)
                        .padding(.top, 1)

                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let locationHint = currentStep.locationHint {
                Divider()

                Label(locationHint, systemImage: "location.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                moveToPreviousStep()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.textSecondary)
            .disabled(currentStepIndex == 0)
            .accessibilityIdentifier("onboardingBackButton")

            Spacer()

            Button {
                moveToNextStep()
            } label: {
                Label(
                    currentStep.isLast ? "Start using Focenda" : "Continue",
                    systemImage: currentStep.isLast ? "checkmark" : "chevron.right"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
            .accessibilityIdentifier(currentStep.isLast ? "onboardingFinishButton" : "onboardingNextButton")
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
    }

    private func moveToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            currentStepIndex -= 1
        }
    }

    private func moveToNextStep() {
        guard !currentStep.isLast else {
            finishOnboarding()
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            currentStepIndex += 1
        }
    }

    private func finishOnboarding() {
        appState.completeOnboarding()
        dismiss()
    }
}

private struct OnboardingFeatureChip: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: step.systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18)

            Text(step.appTab?.rawValue ?? step.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
}
