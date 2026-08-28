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
    @State private var taskVM: TaskListViewModel
    @State private var scratchpadVM: ScratchpadViewModel
    @State private var bookmarkVM: BookmarkViewModel
    @State private var recurringReminderVM: RecurringReminderViewModel
    @State private var productivityProfileVM: ProductivityProfileViewModel
    var updateManager: AppUpdateManager
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var activeInAppReminder: (title: String, subtitle: String, time: String)?
    @State private var isShowingUpdateGuide = false

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        bookmarkVM: BookmarkViewModel = BookmarkViewModel(),
        recurringReminderVM: RecurringReminderViewModel = RecurringReminderViewModel(),
        productivityProfileVM: ProductivityProfileViewModel = ProductivityProfileViewModel(),
        updateManager: AppUpdateManager = AppUpdateManager()
    ) {
        self.appState = appState
        self.updateManager = updateManager
        _timerVM = State(initialValue: timerVM)
        _taskVM = State(initialValue: taskVM)
        _scratchpadVM = State(initialValue: scratchpadVM)
        _bookmarkVM = State(initialValue: bookmarkVM)
        _recurringReminderVM = State(initialValue: recurringReminderVM)
        _productivityProfileVM = State(initialValue: productivityProfileVM)
    }

    public var body: some View {
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
                            KanbanBoardView(taskVM: taskVM)
                        case .calendar:
                            CalendarView(
                                timerVM: timerVM,
                                taskVM: taskVM,
                                recurringReminderVM: recurringReminderVM
                            )
                        case .reminders:
                            RemindersView(
                                recurringReminderVM: recurringReminderVM,
                                taskVM: taskVM
                            )
                        case .scratchpad:
                            ScratchpadView(viewModel: scratchpadVM)
                        case .bookmarks:
                            BookmarksView(viewModel: bookmarkVM)
                        case .profiles:
                            ProductivityProfilesView(viewModel: productivityProfileVM)
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
            if updateManager.completedUpdateGuide != nil {
                isShowingUpdateGuide = true
            }
        }
        .sheet(isPresented: $isShowingUpdateGuide, onDismiss: {
            updateManager.dismissCompletedUpdateGuide()
        }) {
            if let guide = updateManager.completedUpdateGuide {
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
