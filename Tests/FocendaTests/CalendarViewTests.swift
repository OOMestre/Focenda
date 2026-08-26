import XCTest
import SwiftUI
@testable import FocendaCore

final class CalendarViewTests: XCTestCase {

    func testCalendarViewInitialization() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM
        )

        XCTAssertNotNil(calendarView)
        XCTAssertNotNil(calendarView.timerVM)
        XCTAssertNotNil(calendarView.taskVM)
        XCTAssertTrue(Calendar.current.isDateInToday(calendarView.selectedDate))
    }

    func testCalendarViewCustomInitialDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 15
        let customDate = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: customDate
        )

        XCTAssertEqual(Calendar.current.component(.day, from: calendarView.selectedDate), 15)
        XCTAssertEqual(Calendar.current.component(.month, from: calendarView.displayedMonth), 8)
        XCTAssertEqual(Calendar.current.component(.year, from: calendarView.displayedMonth), 2026)
    }

    func testCalculateDaysInMonth() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 1
        let august2026 = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: august2026
        )

        let days = calendarView.calculateDaysInMonth(for: august2026)

        // The grid must be padded to full weeks (multiples of 7)
        XCTAssertTrue(days.count % 7 == 0)
        XCTAssertTrue(days.count >= 28 && days.count <= 42)

        // Count days belonging to August 2026
        let augustDays = days.filter { $0.isCurrentMonth }
        XCTAssertEqual(augustDays.count, 31)

        // August 1, 2026 was a Saturday (first day of August)
        if let firstAugustDay = augustDays.first {
            XCTAssertEqual(firstAugustDay.dayNumber, 1)
        }
    }

    func testFocusMinutesAndHeatmapLevels() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 20
        components.hour = 10
        let testDate = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: testDate
        )

        // Initially 0 focus minutes
        XCTAssertEqual(calendarView.focusMinutes(for: testDate), 0)

        // Add 25 min work session
        let session1 = FocusSession(mode: .work, durationSeconds: 25 * 60, completedAt: testDate)
        timerVM.completedSessions.append(session1)

        XCTAssertEqual(calendarView.focusMinutes(for: testDate), 25)
        XCTAssertEqual(calendarView.sessions(for: testDate).count, 1)

        let day1 = CalendarDay(
            date: testDate,
            dayNumber: 20,
            isCurrentMonth: true,
            isToday: false,
            isSelected: true,
            focusMinutes: 25,
            focusSessionsCount: 1,
            tasksCount: 0
        )
        XCTAssertEqual(day1.focusHeatmapLevel, 1)

        // Add another 40 min session -> total 65 min (>60)
        let session2 = FocusSession(mode: .work, durationSeconds: 40 * 60, completedAt: testDate)
        timerVM.completedSessions.append(session2)

        XCTAssertEqual(calendarView.focusMinutes(for: testDate), 65)

        let day2 = CalendarDay(
            date: testDate,
            dayNumber: 20,
            isCurrentMonth: true,
            isToday: false,
            isSelected: true,
            focusMinutes: 65,
            focusSessionsCount: 2,
            tasksCount: 0
        )
        XCTAssertEqual(day2.focusHeatmapLevel, 3)

        // Level 2 check (e.g. 50 min)
        let dayLevel2 = CalendarDay(
            date: testDate,
            dayNumber: 20,
            isCurrentMonth: true,
            isToday: false,
            isSelected: false,
            focusMinutes: 50,
            focusSessionsCount: 2,
            tasksCount: 0
        )
        XCTAssertEqual(dayLevel2.focusHeatmapLevel, 2)

        let dayLevel0 = CalendarDay(
            date: testDate,
            dayNumber: 20,
            isCurrentMonth: true,
            isToday: false,
            isSelected: false,
            focusMinutes: 0,
            focusSessionsCount: 0,
            tasksCount: 0
        )
        XCTAssertEqual(dayLevel0.focusHeatmapLevel, 0)
    }

    func testTasksForDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 12
        let testDate = Calendar.current.date(from: components)!

        let task1 = TaskItem(
            title: "Ship Calendar Feature",
            isCompleted: true,
            createdAt: testDate,
            completedAt: testDate
        )
        taskVM.tasks = [task1]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: testDate
        )

        let tasks = calendarView.tasks(for: testDate)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Ship Calendar Feature")
    }

    func testTasksForDateWithDueDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []

        let createdDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let futureDueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        let taskWithDue = TaskItem(
            title: "Prepare Release Notes",
            createdAt: createdDate,
            dueDate: futureDueDate
        )
        taskVM.tasks = [taskWithDue]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: futureDueDate
        )

        // Matching dueDate on future date
        let matchingTasks = calendarView.tasks(for: futureDueDate)
        XCTAssertEqual(matchingTasks.count, 1)
        XCTAssertEqual(matchingTasks.first?.title, "Prepare Release Notes")

        // Non-matching other date (e.g. 4 days from now)
        let otherDate = Calendar.current.date(byAdding: .day, value: 4, to: Date())!
        let nonMatching = calendarView.tasks(for: otherDate)
        XCTAssertEqual(nonMatching.count, 0)
    }

    func testTasksForDateWithReminderDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []

        let createdDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let reminderDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        let taskWithReminder = TaskItem(
            title: "Follow up on feedback",
            createdAt: createdDate,
            reminderDate: reminderDate
        )
        taskVM.tasks = [taskWithReminder]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: reminderDate
        )

        let tasksOnReminderDay = calendarView.tasks(for: reminderDate)
        XCTAssertEqual(tasksOnReminderDay.count, 1)
        XCTAssertEqual(tasksOnReminderDay.first?.title, "Follow up on feedback")
    }

    func testDueDateBadgeLabels() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let calendarView = CalendarView(timerVM: timerVM, taskVM: taskVM)

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        // 1. Overdue task
        let overdueTask = TaskItem(title: "Overdue", dueDate: yesterday)
        let overdueBadge = calendarView.dueDateBadge(for: overdueTask, on: today)
        XCTAssertNotNil(overdueBadge)
        XCTAssertEqual(overdueBadge?.text, "Overdue")

        // Completed task in the past is NOT overdue
        let completedPastTask = TaskItem(title: "Done", isCompleted: true, dueDate: yesterday)
        let completedBadge = calendarView.dueDateBadge(for: completedPastTask, on: today)
        XCTAssertNotNil(completedBadge)
        XCTAssertNotEqual(completedBadge?.text, "Overdue")

        // 2. Due Today
        let dueTodayTask = TaskItem(title: "Due Today", dueDate: today)
        let todayBadge = calendarView.dueDateBadge(for: dueTodayTask, on: today)
        XCTAssertNotNil(todayBadge)
        XCTAssertEqual(todayBadge?.text, "Due Today")

        // 3. Due Tomorrow
        let dueTomorrowTask = TaskItem(title: "Due Tomorrow", dueDate: tomorrow)
        let tomorrowBadge = calendarView.dueDateBadge(for: dueTomorrowTask, on: today)
        XCTAssertNotNil(tomorrowBadge)
        XCTAssertEqual(tomorrowBadge?.text, "Due Tomorrow")

        // 4. Due on selected day
        let dueNextWeekTask = TaskItem(title: "Due Next Week", dueDate: nextWeek)
        let onDayBadge = calendarView.dueDateBadge(for: dueNextWeekTask, on: nextWeek)
        XCTAssertNotNil(onDayBadge)
        XCTAssertEqual(onDayBadge?.text, "Due on this day")

        // 5. No due date
        let noDueTask = TaskItem(title: "No Due Date")
        XCTAssertNil(calendarView.dueDateBadge(for: noDueTask, on: today))
    }

    func testReminderBadgeFormat() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let calendarView = CalendarView(timerVM: timerVM, taskVM: taskVM)

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 26
        components.hour = 15
        components.minute = 30
        let reminderTime = Calendar.current.date(from: components)!

        let taskWithReminder = TaskItem(title: "Reminder Task", reminderDate: reminderTime)
        let badge = calendarView.reminderBadge(for: taskWithReminder)
        XCTAssertEqual(badge, "🔔 15:30")

        let taskNoReminder = TaskItem(title: "Regular Task")
        XCTAssertNil(calendarView.reminderBadge(for: taskNoReminder))
    }

    func testCalendarDayIndicatorsAndCounters() {
        let date = Date()
        let day = CalendarDay(
            date: date,
            dayNumber: 26,
            isCurrentMonth: true,
            isToday: true,
            isSelected: false,
            focusMinutes: 45,
            focusSessionsCount: 2,
            tasksCount: 4,
            dueTasksCount: 2,
            hasDueTasks: true,
            hasReminders: true
        )

        XCTAssertEqual(day.dueTasksCount, 2)
        XCTAssertTrue(day.hasDueTasks)
        XCTAssertTrue(day.hasReminders)
        XCTAssertEqual(day.tasksCount, 4)
        XCTAssertEqual(day.focusHeatmapLevel, 2)
    }

    func testCalculateDaysInMonthIncludesDueAndReminders() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 18
        components.hour = 14
        let aug18 = Calendar.current.date(from: components)!

        let task1 = TaskItem(title: "August 18 Due Task", dueDate: aug18)
        let task2 = TaskItem(title: "August 18 Reminder Task", reminderDate: aug18)
        taskVM.tasks = [task1, task2]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: aug18
        )

        let days = calendarView.calculateDaysInMonth(for: aug18)
        let targetDay = days.first(where: { $0.isCurrentMonth && $0.dayNumber == 18 })

        XCTAssertNotNil(targetDay)
        XCTAssertEqual(targetDay?.dueTasksCount, 1)
        XCTAssertEqual(targetDay?.hasDueTasks, true)
        XCTAssertEqual(targetDay?.hasReminders, true)
        XCTAssertEqual(targetDay?.tasksCount, 2)
    }

    func testMonthlyStatsCalculation() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 5
        let aug5 = Calendar.current.date(from: components)!

        components.day = 10
        let aug10 = Calendar.current.date(from: components)!

        timerVM.completedSessions = [
            FocusSession(mode: .work, durationSeconds: 30 * 60, completedAt: aug5),
            FocusSession(mode: .work, durationSeconds: 20 * 60, completedAt: aug10)
        ]

        taskVM.tasks = [
            TaskItem(title: "Task 1", isCompleted: true, createdAt: aug5, completedAt: aug5)
        ]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: aug5
        )

        let stats = calendarView.calculateMonthlyStats(for: aug5)
        XCTAssertEqual(stats.totalFocusMinutes, 50)
        XCTAssertEqual(stats.sessionsCount, 2)
        XCTAssertEqual(stats.tasksCompleted, 1)
        XCTAssertEqual(stats.activeDays, 2)
    }

    func testMonthNavigationDates() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 1
        let august = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: august
        )

        let nextMonth = calendarView.nextMonthDate(from: august)
        XCTAssertEqual(Calendar.current.component(.month, from: nextMonth), 9)

        let prevMonth = calendarView.previousMonthDate(from: august)
        XCTAssertEqual(Calendar.current.component(.month, from: prevMonth), 7)
    }

    func testFormattersAndRelativeLabels() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 26
        let date = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            initialDate: date
        )

        XCTAssertEqual(calendarView.formattedMonthTitle(from: date), "August 2026")
        XCTAssertFalse(calendarView.formattedDayHeader(date).isEmpty)
        XCTAssertEqual(calendarView.formattedFullDate(date), "August 26, 2026")

        let todayLabel = calendarView.relativeDayLabel(Date())
        XCTAssertEqual(todayLabel, "TODAY")

        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            XCTAssertEqual(calendarView.relativeDayLabel(yesterday), "YESTERDAY")
        }

        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            XCTAssertEqual(calendarView.relativeDayLabel(tomorrow), "TOMORROW")
        }
    }

    func testCalendarViewBodyRendering() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM
        )

        let body = calendarView.body
        XCTAssertNotNil(body)
    }

    func testDayIdentifierFormat() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 26
        let date = Calendar.current.date(from: components)!

        let day = CalendarDay(
            date: date,
            dayNumber: 26,
            isCurrentMonth: true,
            isToday: true,
            isSelected: false,
            focusMinutes: 15,
            focusSessionsCount: 1,
            tasksCount: 3,
            dueTasksCount: 1,
            hasDueTasks: true,
            hasReminders: false
        )

        XCTAssertEqual(day.id, "2026-08-26")
        XCTAssertEqual(day.dayNumber, 26)
        XCTAssertTrue(day.isCurrentMonth)
        XCTAssertTrue(day.isToday)
        XCTAssertFalse(day.isSelected)
        XCTAssertEqual(day.dueTasksCount, 1)
        XCTAssertTrue(day.hasDueTasks)
        XCTAssertFalse(day.hasReminders)
    }

    func testCalendarViewWithRecurringReminders() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let habitVM = HabitViewModel()
        let reminderVM = RecurringReminderViewModel()
        reminderVM.reminders = []

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 26 // Wednesday
        components.hour = 9
        let august26 = Calendar.current.date(from: components)!

        reminderVM.addReminder(
            title: "Daily Standup",
            time: august26,
            repeatFrequency: .weekdays,
            notes: "Sync with team"
        )

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
            recurringReminderVM: reminderVM,
            initialDate: august26
        )

        let days = calendarView.calculateDaysInMonth(for: august26)
        let wednesdayDay = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: august26) })
        XCTAssertNotNil(wednesdayDay)
        XCTAssertTrue(wednesdayDay?.hasRecurringReminders == true)
        XCTAssertTrue(wednesdayDay?.hasReminders == true)
        XCTAssertEqual(wednesdayDay?.recurringRemindersCount, 1)

        // Saturday August 29 should NOT have weekday reminder
        components.day = 29
        let august29 = Calendar.current.date(from: components)!
        let saturdayDay = days.first(where: { Calendar.current.isDate($0.date, inSameDayAs: august29) })
        XCTAssertNotNil(saturdayDay)
        XCTAssertFalse(saturdayDay?.hasRecurringReminders == true)
    }

    func testCalendarDayWithRecurringRemindersInitialization() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 26
        let date = Calendar.current.date(from: components)!

        let day = CalendarDay(
            date: date,
            dayNumber: 26,
            isCurrentMonth: true,
            isToday: true,
            isSelected: true,
            focusMinutes: 45,
            focusSessionsCount: 2,
            habitsCompletedCount: 1,
            tasksCount: 2,
            dueTasksCount: 0,
            hasDueTasks: false,
            hasReminders: true,
            hasHabitStreak: true,
            recurringRemindersCount: 2,
            hasRecurringReminders: true
        )

        XCTAssertEqual(day.recurringRemindersCount, 2)
        XCTAssertTrue(day.hasRecurringReminders)
        XCTAssertTrue(day.hasReminders)
        XCTAssertEqual(day.focusHeatmapLevel, 2)
    }
}
