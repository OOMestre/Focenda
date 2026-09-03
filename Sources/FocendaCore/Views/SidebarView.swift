import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel?
    var bookmarkVM: BookmarkViewModel?
    var recurringReminderVM: RecurringReminderViewModel?

    @State private var isPulsingDot = false

    public init(
        appState: AppState,
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel? = nil,
        bookmarkVM: BookmarkViewModel? = nil,
        recurringReminderVM: RecurringReminderViewModel? = nil
    ) {
        self.appState = appState
        self.timerVM = timerVM
        self.taskVM = taskVM
        self.bookmarkVM = bookmarkVM
        self.recurringReminderVM = recurringReminderVM
    }

    public var body: some View {
        List(appState.availableTabs, id: \.self, selection: $appState.selectedTab) { tab in
            NavigationLink(value: tab) {
                SidebarRowItem(
                    tab: tab,
                    isSelected: appState.selectedTab == tab,
                    timerIsRunning: timerVM.status == .running,
                    pendingTasksCount: taskVM?.pendingTasksCount ?? 0,
                    inProgressTasksCount: taskVM?.inProgressTasksCount ?? 0,
                    totalBookmarksCount: bookmarkVM?.bookmarks.count ?? 0,
                    activeRemindersCount: recurringReminderVM?.activeReminders.count ?? 0,
                    isPulsingDot: isPulsingDot
                )
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 12))
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            bottomMiniTimerView
        }
        .onAppear {
            if timerVM.status == .running {
                isPulsingDot = true
            }
        }
        .onChange(of: timerVM.status) { _, newStatus in
            isPulsingDot = (newStatus == .running)
        }
    }

    // MARK: - Bottom Mini-Timer Widget
    private var bottomMiniTimerView: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: timerVM.currentMode.iconName)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timerVM.currentMode.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(timerVM.formattedTimeRemaining)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        if timerVM.status == .running {
                            timerVM.pause()
                        } else {
                            timerVM.start()
                        }
                    }
                } label: {
                    Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textOnAccent)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(AppTheme.accent)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(timerVM.status == .running ? "Pause timer" : "Start timer")
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Sidebar Row Item

public struct SidebarRowItem: View {
    public let tab: AppTab
    public let isSelected: Bool
    public let timerIsRunning: Bool
    public let pendingTasksCount: Int
    public let inProgressTasksCount: Int
    public let totalBookmarksCount: Int
    public let activeRemindersCount: Int
    public let isPulsingDot: Bool

    public init(
        tab: AppTab,
        isSelected: Bool,
        timerIsRunning: Bool = false,
        pendingTasksCount: Int = 0,
        inProgressTasksCount: Int = 0,
        totalBookmarksCount: Int = 0,
        activeRemindersCount: Int = 0,
        isPulsingDot: Bool = false
    ) {
        self.tab = tab
        self.isSelected = isSelected
        self.timerIsRunning = timerIsRunning
        self.pendingTasksCount = pendingTasksCount
        self.inProgressTasksCount = inProgressTasksCount
        self.totalBookmarksCount = totalBookmarksCount
        self.activeRemindersCount = activeRemindersCount
        self.isPulsingDot = isPulsingDot
    }

    public var body: some View {
        HStack(spacing: 9) {
            Image(systemName: tab.iconName)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                .frame(width: 18, alignment: .center)

            Text(tab.rawValue)
                .font(.body.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Spacer()

            // Status Badges
            if tab == .timer && timerIsRunning {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isPulsingDot ? 1.15 : 0.85)
                        .opacity(isPulsingDot ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsingDot)

                    Text("RUNNING")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.success.opacity(0.12))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)
            } else if tab == .kanban && pendingTasksCount > 0 {
                Text("\(pendingTasksCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? AppTheme.accent.opacity(0.15) : AppTheme.cardBackgroundSubtle)
                    )
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            } else if tab == .reminders && activeRemindersCount > 0 {
                Text("\(activeRemindersCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? AppTheme.accent.opacity(0.15) : AppTheme.cardBackgroundSubtle)
                    )
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            } else if tab == .bookmarks && totalBookmarksCount > 0 {
                Text("\(totalBookmarksCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.leading, 2)
        .frame(minHeight: 28, alignment: .leading)
    }
}
