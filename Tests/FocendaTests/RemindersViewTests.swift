import XCTest
import SwiftUI
@testable import FocendaCore

@MainActor
final class RemindersViewTests: XCTestCase {

    var recurringReminderVM: RecurringReminderViewModel!
    var taskVM: TaskListViewModel!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "focenda_saved_recurring_reminders")
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        recurringReminderVM = RecurringReminderViewModel()
        taskVM = TaskListViewModel()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "focenda_saved_recurring_reminders")
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        recurringReminderVM = nil
        taskVM = nil
        super.tearDown()
    }

    func testRemindersViewInitialization() {
        let view = RemindersView(
            recurringReminderVM: recurringReminderVM,
            taskVM: taskVM,
            initialFilter: .all,
            initialSearchQuery: ""
        )
        XCTAssertEqual(view.selectedFilter, .all)
        XCTAssertEqual(view.searchQuery, "")
        XCTAssertFalse(view.showingAddSheet)
        XCTAssertNil(view.editingReminder)
        XCTAssertNotNil(view.body)
    }

    func testRemindersViewCustomInitialFilter() {
        let view = RemindersView(
            recurringReminderVM: recurringReminderVM,
            taskVM: taskVM,
            initialFilter: .weekdays,
            initialSearchQuery: "standup"
        )
        XCTAssertEqual(view.selectedFilter, .weekdays)
        XCTAssertEqual(view.searchQuery, "standup")
    }

    func testReminderFilterEnum() {
        let allCases = ReminderFilter.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertEqual(ReminderFilter.all.rawValue, "All")
        XCTAssertEqual(ReminderFilter.daily.rawValue, "Daily")
        XCTAssertEqual(ReminderFilter.weekdays.rawValue, "Weekdays")
        XCTAssertEqual(ReminderFilter.weekly.rawValue, "Weekly")
        XCTAssertEqual(ReminderFilter.monthly.rawValue, "Monthly")
        XCTAssertEqual(ReminderFilter.taskReminders.rawValue, "Task Reminders")

        for filter in allCases {
            XCTAssertEqual(filter.id, filter.rawValue)
            XCTAssertFalse(filter.iconName.isEmpty)
        }
    }

    func testAppTabRemindersIntegration() {
        let allTabs = AppTab.allCases
        XCTAssertTrue(allTabs.contains(.reminders))
        XCTAssertEqual(AppTab.reminders.rawValue, "Reminders")
        XCTAssertEqual(AppTab.reminders.iconName, "bell.badge")

        // Verify ordering: between calendar and scratchpad
        guard let calendarIndex = allTabs.firstIndex(of: .calendar),
              let remindersIndex = allTabs.firstIndex(of: .reminders),
              let scratchpadIndex = allTabs.firstIndex(of: .scratchpad) else {
            XCTFail("AppTabs should contain calendar, reminders, and scratchpad")
            return
        }

        XCTAssertEqual(remindersIndex, calendarIndex + 1)
        XCTAssertEqual(scratchpadIndex, remindersIndex + 1)
    }

    func testReminderFilterDistribution() {
        recurringReminderVM.reminders = [
            RecurringReminder(title: "Daily Standup", time: Date(), repeatFrequency: .daily, isEnabled: true),
            RecurringReminder(title: "Weekday Sync", time: Date(), repeatFrequency: .weekdays, isEnabled: true),
            RecurringReminder(title: "Weekly Planning", time: Date(), repeatFrequency: .weekly, isEnabled: true),
            RecurringReminder(title: "Monthly Review", time: Date(), repeatFrequency: .monthly, isEnabled: true)
        ]

        taskVM.tasks = [
            TaskItem(title: "Task with Reminder", reminderDate: Date().addingTimeInterval(3600)),
            TaskItem(title: "Task without Reminder", reminderDate: nil)
        ]

        let view = RemindersView(recurringReminderVM: recurringReminderVM, taskVM: taskVM)

        // Filter counts
        XCTAssertEqual(view.countForFilter(.all), 5)
        XCTAssertEqual(view.countForFilter(.daily), 1)
        XCTAssertEqual(view.countForFilter(.weekdays), 1)
        XCTAssertEqual(view.countForFilter(.weekly), 1)
        XCTAssertEqual(view.countForFilter(.monthly), 1)
        XCTAssertEqual(view.countForFilter(.taskReminders), 1)

        // Filtered lists
        let dailyItems = view.filteredRecurringReminders(filter: .daily, query: "")
        XCTAssertEqual(dailyItems.count, 1)
        XCTAssertEqual(dailyItems.first?.title, "Daily Standup")

        let weekdayItems = view.filteredRecurringReminders(filter: .weekdays, query: "")
        XCTAssertEqual(weekdayItems.count, 1)
        XCTAssertEqual(weekdayItems.first?.title, "Weekday Sync")

        let weeklyItems = view.filteredRecurringReminders(filter: .weekly, query: "")
        XCTAssertEqual(weeklyItems.count, 1)
        XCTAssertEqual(weeklyItems.first?.title, "Weekly Planning")

        let monthlyItems = view.filteredRecurringReminders(filter: .monthly, query: "")
        XCTAssertEqual(monthlyItems.count, 1)
        XCTAssertEqual(monthlyItems.first?.title, "Monthly Review")

        let taskItems = view.filteredTaskReminders(query: "")
        XCTAssertEqual(taskItems.count, 1)
        XCTAssertEqual(taskItems.first?.title, "Task with Reminder")
    }

    func testReminderSearchFiltering() {
        recurringReminderVM.reminders = [
            RecurringReminder(title: "Morning Meditation", time: Date(), repeatFrequency: .daily, notes: "Deep breath"),
            RecurringReminder(title: "Evening Retro", time: Date(), repeatFrequency: .weekdays, notes: "Sprint check")
        ]

        taskVM.tasks = [
            TaskItem(title: "Write documentation", notes: "API reference", reminderDate: Date().addingTimeInterval(1800))
        ]

        let view = RemindersView(recurringReminderVM: recurringReminderVM, taskVM: taskVM)

        let searchMeditation = view.filteredRecurringReminders(filter: .all, query: "meditation")
        XCTAssertEqual(searchMeditation.count, 1)
        XCTAssertEqual(searchMeditation.first?.title, "Morning Meditation")

        let searchNotes = view.filteredRecurringReminders(filter: .all, query: "sprint")
        XCTAssertEqual(searchNotes.count, 1)
        XCTAssertEqual(searchNotes.first?.title, "Evening Retro")

        let searchTask = view.filteredTaskReminders(query: "documentation")
        XCTAssertEqual(searchTask.count, 1)
        XCTAssertEqual(searchTask.first?.title, "Write documentation")

        let searchEmpty = view.filteredRecurringReminders(filter: .all, query: "")
        XCTAssertEqual(searchEmpty.count, 2)
    }

    func testStatsBannerCalculations() {
        let calendar = Calendar.current
        let today = Date()

        let reminderToday = RecurringReminder(
            title: "Today Alert",
            time: today,
            repeatFrequency: .daily,
            isEnabled: true
        )

        recurringReminderVM.reminders = [reminderToday]

        taskVM.tasks = [
            TaskItem(
                title: "Today Task",
                status: .todo,
                reminderDate: calendar.date(byAdding: .minute, value: 30, to: today)
            )
        ]

        let view = RemindersView(recurringReminderVM: recurringReminderVM, taskVM: taskVM)

        let activeToday = view.calculateActiveTodayCount()
        XCTAssertEqual(activeToday, 2)

        let nextAlarm = view.calculateNextAlarm()
        XCTAssertFalse(nextAlarm.time.isEmpty)
        XCTAssertFalse(nextAlarm.title.isEmpty)
    }

    func testCRUDWorkflowWithRemindersView() {
        recurringReminderVM.reminders = []

        // Add
        let added = recurringReminderVM.addReminder(
            title: "Hydration Alert",
            time: Date(),
            repeatFrequency: .daily,
            notes: "Drink water",
            isEnabled: true
        )

        XCTAssertEqual(recurringReminderVM.reminders.count, 1)
        XCTAssertEqual(recurringReminderVM.reminders.first?.title, "Hydration Alert")

        // Toggle
        recurringReminderVM.toggleReminder(id: added.id)
        XCTAssertFalse(recurringReminderVM.reminders.first?.isEnabled ?? true)

        recurringReminderVM.toggleReminder(id: added.id)
        XCTAssertTrue(recurringReminderVM.reminders.first?.isEnabled ?? false)

        // Update
        var modified = added
        modified.title = "Hydration & Movement Alert"
        recurringReminderVM.updateReminder(modified)
        XCTAssertEqual(recurringReminderVM.reminders.first?.title, "Hydration & Movement Alert")

        // Delete
        recurringReminderVM.deleteReminder(id: added.id)
        XCTAssertTrue(recurringReminderVM.reminders.isEmpty)
    }

    func testTaskRemindersSectionIntegration() {
        taskVM.tasks = []

        let futureDate = Date().addingTimeInterval(7200)
        taskVM.addTask(
            title: "Timed Project Task",
            notes: "Complete milestone deliverable",
            priority: .high,
            status: .inProgress,
            reminderDate: futureDate
        )

        let taskWithReminder = taskVM.tasks.first { $0.reminderDate != nil }
        XCTAssertNotNil(taskWithReminder)
        XCTAssertEqual(taskWithReminder?.title, "Timed Project Task")
        XCTAssertEqual(taskWithReminder?.priority, .high)

        // Toggle task completion
        if let task = taskWithReminder {
            taskVM.toggleTaskCompletion(task)
            XCTAssertTrue(taskVM.tasks.first?.isCompleted ?? false)

            // Remove reminder
            taskVM.removeReminder(for: task.id)
            XCTAssertNil(taskVM.tasks.first?.reminderDate)
        }
    }

    func testSoundChimeExecution() {
        // Test that playRichAlertChime runs safely without exceptions
        NotificationManager.shared.playRichAlertChime()
        NotificationManager.shared.playRichAlertChime(soundName: "Ping")
    }

    func testSidebarBadgeReflectsActiveReminders() {
        recurringReminderVM.reminders = [
            RecurringReminder(title: "Active 1", time: Date(), repeatFrequency: .daily, isEnabled: true),
            RecurringReminder(title: "Active 2", time: Date(), repeatFrequency: .weekdays, isEnabled: true),
            RecurringReminder(title: "Disabled", time: Date(), repeatFrequency: .daily, isEnabled: false)
        ]

        XCTAssertEqual(recurringReminderVM.activeReminders.count, 2)

        let sidebarView = SidebarView(
            appState: AppState(),
            timerVM: FocusTimerViewModel(),
            taskVM: taskVM,
            recurringReminderVM: recurringReminderVM
        )
        XCTAssertNotNil(sidebarView.body)
    }

    func testSimplifiedRemindersViewFiltersAndEmptyState() {
        recurringReminderVM.reminders = []
        taskVM.tasks = []

        let viewAll = RemindersView(recurringReminderVM: recurringReminderVM, taskVM: taskVM, initialFilter: .all)
        XCTAssertNotNil(viewAll.body)

        let viewTasks = RemindersView(recurringReminderVM: recurringReminderVM, taskVM: taskVM, initialFilter: .taskReminders)
        XCTAssertNotNil(viewTasks.body)

        let viewDaily = RemindersView(recurringReminderVM: recurringReminderVM, taskVM: taskVM, initialFilter: .daily)
        XCTAssertNotNil(viewDaily.body)
    }
}
