import XCTest
import SwiftUI
@testable import FocendaCore

final class CalendarViewTests: XCTestCase {

    func testCalendarViewInitialization() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let habitVM = HabitViewModel()

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM
        )

        XCTAssertNotNil(calendarView)
        XCTAssertNotNil(calendarView.timerVM)
        XCTAssertNotNil(calendarView.taskVM)
        XCTAssertNotNil(calendarView.habitVM)
        XCTAssertTrue(Calendar.current.isDateInToday(calendarView.selectedDate))
    }

    func testCalendarViewCustomInitialDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let habitVM = HabitViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 15
        let customDate = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
            initialDate: customDate
        )

        XCTAssertEqual(Calendar.current.component(.day, from: calendarView.selectedDate), 15)
        XCTAssertEqual(Calendar.current.component(.month, from: calendarView.displayedMonth), 8)
        XCTAssertEqual(Calendar.current.component(.year, from: calendarView.displayedMonth), 2026)
    }

    func testCalculateDaysInMonth() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let habitVM = HabitViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 1
        let august2026 = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
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
        let habitVM = HabitViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 20
        components.hour = 10
        let testDate = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
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
            habitsCompletedCount: 0,
            tasksCount: 0,
            hasHabitStreak: false
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
            habitsCompletedCount: 0,
            tasksCount: 0,
            hasHabitStreak: false
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
            habitsCompletedCount: 0,
            tasksCount: 0,
            hasHabitStreak: false
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
            habitsCompletedCount: 0,
            tasksCount: 0,
            hasHabitStreak: false
        )
        XCTAssertEqual(dayLevel0.focusHeatmapLevel, 0)
    }

    func testHabitsCompletedForDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let habitVM = HabitViewModel()
        habitVM.habits = []

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 10
        let testDate = Calendar.current.date(from: components)!

        let habit1 = HabitItem(
            title: "Morning Routine",
            completedDates: [testDate]
        )
        let habit2 = HabitItem(
            title: "Hydration",
            completedDates: []
        )
        habitVM.habits = [habit1, habit2]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
            initialDate: testDate
        )

        let completed = calendarView.habitsCompleted(for: testDate)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.title, "Morning Routine")
    }

    func testTasksForDate() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []
        let habitVM = HabitViewModel()

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
            habitVM: habitVM,
            initialDate: testDate
        )

        let tasks = calendarView.tasks(for: testDate)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Ship Calendar Feature")
    }

    func testMonthlyStatsCalculation() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        taskVM.tasks = []
        let habitVM = HabitViewModel()
        habitVM.habits = []

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

        habitVM.habits = [
            HabitItem(title: "Read", completedDates: [aug5, aug10])
        ]

        taskVM.tasks = [
            TaskItem(title: "Task 1", isCompleted: true, createdAt: aug5, completedAt: aug5)
        ]

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
            initialDate: aug5
        )

        let stats = calendarView.calculateMonthlyStats(for: aug5)
        XCTAssertEqual(stats.totalFocusMinutes, 50)
        XCTAssertEqual(stats.sessionsCount, 2)
        XCTAssertEqual(stats.habitsCompleted, 2)
        XCTAssertEqual(stats.tasksCompleted, 1)
        XCTAssertEqual(stats.activeDays, 2)
    }

    func testMonthNavigationDates() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let habitVM = HabitViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 1
        let august = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
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
        let habitVM = HabitViewModel()

        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 26
        let date = Calendar.current.date(from: components)!

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM,
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
        let habitVM = HabitViewModel()

        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            habitVM: habitVM
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
            habitsCompletedCount: 2,
            tasksCount: 3,
            hasHabitStreak: true
        )

        XCTAssertEqual(day.id, "2026-08-26")
        XCTAssertEqual(day.dayNumber, 26)
        XCTAssertTrue(day.isCurrentMonth)
        XCTAssertTrue(day.isToday)
        XCTAssertFalse(day.isSelected)
        XCTAssertTrue(day.hasHabitStreak)
    }
}
