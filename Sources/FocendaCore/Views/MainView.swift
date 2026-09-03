import SwiftUI

public struct MainView: View {
    /// Enforced minimum dimensions for the macOS window to guarantee all views, controls,
    /// and text remain 100% visible, fully functional, and visually balanced without breaking.
    public static let minimumWindowWidth: CGFloat = 800
    public static let minimumWindowHeight: CGFloat = 560
    /// Comfortable first-launch size that keeps the sidebar and primary workspace visible
    /// without opening the app in full screen. Users can still resize down to the minimum.
    public static let defaultWindowWidth: CGFloat = 1360
    public static let defaultWindowHeight: CGFloat = 900
    private static let initialSizePreferenceKey = "focenda_applied_comfortable_window_size_v1"

    @Bindable var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    private var customTaskVM: TaskListViewModel?
    private var customScratchpadVM: ScratchpadViewModel?
    private var customBookmarkVM: BookmarkViewModel?
    private var customRecurringReminderVM: RecurringReminderViewModel?

    private var taskVM: TaskListViewModel? {
        guard appState.isModuleInstalled(.kanban) else { return nil }
        return customTaskVM ?? appState.moduleManager.taskVM
    }
    private var scratchpadVM: ScratchpadViewModel? {
        guard appState.isModuleInstalled(.scratchpad) else { return nil }
        return customScratchpadVM ?? appState.moduleManager.scratchpadVM
    }
    private var bookmarkVM: BookmarkViewModel? {
        guard appState.isModuleInstalled(.bookmarks) else { return nil }
        return customBookmarkVM ?? appState.moduleManager.bookmarkVM
    }
    private var recurringReminderVM: RecurringReminderViewModel? {
        guard appState.isModuleInstalled(.reminders) else { return nil }
        return customRecurringReminderVM ?? appState.moduleManager.recurringReminderVM
    }

    @State private var productivityProfileVM: ProductivityProfileViewModel
    var updateManager: AppUpdateManager
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var activeInAppReminder: (title: String, subtitle: String, time: String)?
    @State private var isShowingUpdateGuide = false
    @State private var isShowingOnboarding = false
    @State private var isPresentingInitialOnboarding = false

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel? = nil,
        scratchpadVM: ScratchpadViewModel? = nil,
        bookmarkVM: BookmarkViewModel? = nil,
        recurringReminderVM: RecurringReminderViewModel? = nil,
        productivityProfileVM: ProductivityProfileViewModel = ProductivityProfileViewModel(),
        updateManager: AppUpdateManager = AppUpdateManager()
    ) {
        self.appState = appState
        self.updateManager = updateManager
        self.customTaskVM = taskVM
        self.customScratchpadVM = scratchpadVM
        self.customBookmarkVM = bookmarkVM
        self.customRecurringReminderVM = recurringReminderVM
        _timerVM = State(initialValue: timerVM)
        _productivityProfileVM = State(initialValue: productivityProfileVM)
    }

    public var body: some View {
        let activeThemeID = appState.selectedTheme.rawValue

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                bookmarkVM: bookmarkVM,
                recurringReminderVM: recurringReminderVM
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            .background(AppTheme.sidebarBackground)
            // AppTheme colors are resolved from a shared theme cache. Rebuild
            // the column when that cache changes while keeping the split view
            // itself stable so its geometry and selection are preserved.
            .id(activeThemeID)
        } detail: {
            VStack(spacing: 0) {
                // Keep update notices in the layout so they never cover page content.
                if let update = updateManager.availableUpdate {
                    HStack {
                        Spacer(minLength: 0)
                        AppUpdateBanner(
                            update: update,
                            isInstalling: updateManager.status == .installing,
                            onInstall: updateManager.installAvailableUpdate,
                            onDismiss: updateManager.dismissAvailableUpdate
                        )
                        .frame(maxWidth: 760)
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                ZStack(alignment: .top) {
                    Group {
                        switch appState.selectedTab {
                        case .dashboard:
                            DashboardView(
                                appState: appState,
                                timerVM: timerVM,
                                taskVM: taskVM
                            )
                        case .timer:
                            FocusTimerView(timerVM: timerVM)
                        case .kanban:
                            if let taskVM {
                                KanbanBoardView(taskVM: taskVM)
                            } else {
                                DashboardView(
                                    appState: appState,
                                    timerVM: timerVM,
                                    taskVM: nil
                                )
                            }
                        case .calendar:
                            if appState.isModuleInstalled(.calendar) {
                                CalendarView(
                                    timerVM: timerVM,
                                    taskVM: taskVM,
                                    recurringReminderVM: recurringReminderVM
                                )
                            } else {
                                DashboardView(
                                    appState: appState,
                                    timerVM: timerVM,
                                    taskVM: taskVM
                                )
                            }
                        case .reminders:
                            if let recurringReminderVM {
                                RemindersView(
                                    recurringReminderVM: recurringReminderVM,
                                    taskVM: taskVM
                                )
                            } else {
                                DashboardView(
                                    appState: appState,
                                    timerVM: timerVM,
                                    taskVM: taskVM
                                )
                            }
                        case .scratchpad:
                            if let scratchpadVM {
                                ScratchpadView(viewModel: scratchpadVM)
                            } else {
                                DashboardView(
                                    appState: appState,
                                    timerVM: timerVM,
                                    taskVM: taskVM
                                )
                            }
                        case .bookmarks:
                            if let bookmarkVM {
                                BookmarksView(viewModel: bookmarkVM)
                            } else {
                                DashboardView(
                                    appState: appState,
                                    timerVM: timerVM,
                                    taskVM: taskVM
                                )
                            }
                        case .profiles:
                            if ProductivityProfilesFeature.isEnabled {
                                ProductivityProfilesView(viewModel: productivityProfileVM)
                            } else {
                                DashboardView(
                                    appState: appState,
                                    timerVM: timerVM,
                                    taskVM: taskVM
                                )
                            }
                        case .settings:
                            SettingsView(
                                appState: appState,
                                timerVM: timerVM,
                                updateManager: updateManager
                            )
                        case .support:
                            SupportView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background)

                    // Floating In-App Reminder Toast Banner
                    if let reminderAlert = activeInAppReminder {
                        HStack(spacing: 12) {
                            HStack(spacing: 5) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Reminder")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent.opacity(0.15))
                            .clipShape(Capsule())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminderAlert.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text("\(reminderAlert.subtitle) • \(reminderAlert.time)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                NotificationManager.shared.snoozeReminder(
                                    title: reminderAlert.title,
                                    subtitle: reminderAlert.subtitle,
                                    notes: "",
                                    minutes: 5
                                )
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    activeInAppReminder = nil
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 10))
                                    Text("Snooze 5m")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.cardBackgroundSubtle)
                                .foregroundStyle(AppTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                NotificationManager.shared.stopActiveSound()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    activeInAppReminder = nil
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Done")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.accent)
                                .foregroundStyle(AppTheme.textOnAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

                            Button {
                                NotificationManager.shared.stopActiveSound()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    activeInAppReminder = nil
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1.0)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppTheme.background)
            // Recreate the detail subtree so every page, including Settings,
            // resolves the newly selected palette in the same render pass.
            .id(activeThemeID)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: Self.minimumWindowWidth,
            minHeight: Self.minimumWindowHeight
        )
        .enforceMinimumWindowSize(
            width: Self.minimumWindowWidth,
            height: Self.minimumWindowHeight,
            initialWidth: Self.defaultWindowWidth,
            initialHeight: Self.defaultWindowHeight,
            initialSizePreferenceKey: Self.initialSizePreferenceKey
        )
        .background(AppTheme.background)
        .preferredColorScheme(appState.selectedTheme.colorScheme)
        .onAppear {
            if !appState.hasCompletedOnboarding {
                isPresentingInitialOnboarding = true
                isShowingOnboarding = true
            } else if AppUpdateGuide.isEnabled, updateManager.completedUpdateGuide != nil {
                isShowingUpdateGuide = true
            }
        }
        .sheet(isPresented: $isShowingOnboarding, onDismiss: {
            guard isPresentingInitialOnboarding else { return }
            isPresentingInitialOnboarding = false

            // If an update guide is waiting, show it after the first-launch
            // tour has been dismissed instead of competing for the same sheet.
            guard AppUpdateGuide.isEnabled,
                  appState.hasCompletedOnboarding,
                  updateManager.completedUpdateGuide != nil else { return }
            DispatchQueue.main.async {
                isShowingUpdateGuide = true
            }
        }) {
            OnboardingView(appState: appState)
        }
        .sheet(isPresented: $isShowingUpdateGuide, onDismiss: {
            updateManager.dismissCompletedUpdateGuide()
        }) {
            if AppUpdateGuide.isEnabled, let guide = updateManager.completedUpdateGuide {
                AppUpdateGuideView(guide: guide) {
                    isShowingUpdateGuide = false
                }
            } else {
                EmptyView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationManager.reminderAlertBannerNotification)) { notif in
            let title = notif.userInfo?["title"] as? String ?? "Reminder"
            let subtitle = notif.userInfo?["subtitle"] as? String ?? "Focenda Alert"
            let time = notif.userInfo?["time"] as? String ?? ""
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                activeInAppReminder = (title: title, subtitle: subtitle, time: time)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    activeInAppReminder = nil
                }
            }
        }
    }
}
