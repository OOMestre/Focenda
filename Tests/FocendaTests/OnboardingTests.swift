import XCTest
import CryptoKit
import SwiftUI
@testable import FocendaCore

final class OnboardingTests: XCTestCase {

    func testOnboardingIncludesEverySidebarSectionAndMenuBarControlCenter() {
        let coveredTabs = Set(
            OnboardingStep.featureSteps.compactMap { $0.appTab?.rawValue }
        )
        let appTabs = Set(AppTab.availableCases.map(\.rawValue))

        XCTAssertEqual(coveredTabs, appTabs)
        XCTAssertFalse(OnboardingStep.availableCases.contains(.profiles))
        XCTAssertTrue(OnboardingStep.featureSteps.contains(.menuBar))
        XCTAssertEqual(OnboardingStep.allCases.first, .welcome)
        XCTAssertEqual(OnboardingStep.allCases.last, .support)
    }

    func testEveryOnboardingStepHasCompleteContent() {
        XCTAssertEqual(OnboardingStep.allCases.count, 12)

        for step in OnboardingStep.allCases {
            XCTAssertFalse(step.eyebrow.isEmpty, "Missing eyebrow for \(step)")
            XCTAssertFalse(step.title.isEmpty, "Missing title for \(step)")
            XCTAssertFalse(step.summary.isEmpty, "Missing summary for \(step)")
            XCTAssertEqual(step.tips.count, 3, "Expected three tips for \(step)")
            XCTAssertTrue(step.tips.allSatisfy { !$0.isEmpty }, "Missing tip for \(step)")
            XCTAssertFalse(step.systemImage.isEmpty, "Missing icon for \(step)")
        }
    }

    func testOnboardingViewRendersEveryStep() throws {
        let (store, suiteName) = try makeStore()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let appState = AppState(secureStore: store)

        for step in OnboardingStep.allCases {
            let view = OnboardingView(appState: appState, initialStep: step)
            XCTAssertNotNil(view.body, "Onboarding view failed to render \(step)")
        }
    }

    func testOnboardingCompletionPersistsAndCanBeReset() throws {
        let suiteName = "Focenda.OnboardingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(data: Data(repeating: 0x5A, count: 32))
        )
        let appState = AppState(secureStore: store)

        XCTAssertFalse(appState.hasCompletedOnboarding)
        XCTAssertNil(store.bool(forKey: AppState.onboardingCompletionKey))

        appState.completeOnboarding()

        XCTAssertTrue(appState.hasCompletedOnboarding)
        XCTAssertTrue(store.bool(forKey: AppState.onboardingCompletionKey) ?? false)
        XCTAssertTrue(AppState(secureStore: store).hasCompletedOnboarding)

        appState.resetOnboarding()

        XCTAssertFalse(appState.hasCompletedOnboarding)
        XCTAssertFalse(store.bool(forKey: AppState.onboardingCompletionKey) ?? true)
        XCTAssertFalse(AppState(secureStore: store).hasCompletedOnboarding)
    }

    func testOnboardingCompletionIsIdempotent() throws {
        let (store, suiteName) = try makeStore()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let appState = AppState(secureStore: store)

        appState.completeOnboarding()
        appState.completeOnboarding()

        XCTAssertTrue(appState.hasCompletedOnboarding)
        XCTAssertTrue(store.bool(forKey: AppState.onboardingCompletionKey) ?? false)
    }

    private func makeStore() throws -> (SecureStore, String) {
        let suiteName = "Focenda.OnboardingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let store = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(data: Data(repeating: 0x4C, count: 32))
        )
        return (store, suiteName)
    }
}
