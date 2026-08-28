import SwiftUI

public struct MainView: View {
    /// Enforced minimum dimensions for the macOS window to guarantee all views, controls,
    /// and text remain 100% visible, fully functional, and visually balanced without breaking.
    public static let minimumWindowWidth: CGFloat = 800
    public static let minimumWindowHeight: CGFloat = 560
    public static let defaultWindowWidth: CGFloat = 1060
    public static let defaultWindowHeight: CGFloat = 720

    @Bindable var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    @State private var taskVM: TaskListViewModel
    @State private var scratchpadVM: ScratchpadViewModel
    @State private var bookmarkVM: BookmarkViewModel
    @State private var recurringReminderVM: RecurringReminderViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var activeInAppReminder: (title: String, subtitle: String, time: String)?

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        bookmarkVM: BookmarkViewModel = BookmarkViewModel(),
        recurringReminderVM: RecurringReminderViewModel = RecurringReminderViewModel()
    ) {
        self.appState = appState
        _timerVM = State(initialValue: timerVM)
        _taskVM = State(initialValue: taskVM)
        _scratchpadVM = State(initialValue: scratchpadVM)
        _bookmarkVM = State(initialValue: bookmarkVM)
        _recurringReminderVM = State(initialValue: recurringReminderVM)
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
                    case .stats:
                        StatsView(
                            timerVM: timerVM,
                            taskVM: taskVM
                        )
                    case .settings:
                        SettingsView(
                            appState: appState,
                            timerVM: timerVM
                        )
                    }
                }
                .background(AppTheme.background)

                // Floating In-App Reminder Toast Banner
                if let reminderAlert = activeInAppReminder {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Opa, deu a hora!")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
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
                                Text("Adiar 5m")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.cardBackgroundSubtle)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            NotificationManager.shared.stopActiveSound()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                activeInAppReminder = nil
                            }
                        } label: {
                            Text("Entendido")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.85))
                                .foregroundStyle(.white)
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
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1.2)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: Self.minimumWindowWidth,
            minHeight: Self.minimumWindowHeight
        )
        .enforceMinimumWindowSize(
            width: Self.minimumWindowWidth,
            height: Self.minimumWindowHeight
        )
        .background(AppTheme.background)
        .preferredColorScheme(appState.selectedTheme.colorScheme)
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
