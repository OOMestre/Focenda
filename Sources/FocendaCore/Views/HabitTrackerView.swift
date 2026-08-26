import SwiftUI

public struct HabitTrackerView: View {
    @Bindable var habitVM: HabitViewModel
    @State private var showingAddSheet = false

    // New Habit State
    @State private var newTitle = ""
    @State private var selectedIcon = "flame.fill"
    @State private var selectedColorHex = "#344E41"
    @State private var targetDaysPerWeek = 7

    public init(habitVM: HabitViewModel) {
        self.habitVM = habitVM
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                overviewStatsSection
                habitsListSection
            }
            .padding(28)
        }
        .background(AppTheme.background)
        .navigationTitle("Habits")
        .sheet(isPresented: $showingAddSheet) {
            addHabitSheet
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Habits & Streaks")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Build consistency through daily repetition and track your momentum.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                newTitle = ""
                selectedIcon = "flame.fill"
                selectedColorHex = "#344E41"
                targetDaysPerWeek = 7
                showingAddSheet = true
            } label: {
                Label("New Habit", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepFocus)
            .controlSize(.large)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Overview Stats
    private var overviewStatsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Active Habits",
                value: "\(habitVM.habits.count)",
                subtitle: "\(habitVM.habits.count) total tracked routines",
                icon: "repeat",
                color: AppTheme.deepFocus
            )

            StatCard(
                title: "Completed Today",
                value: "\(habitVM.totalCompletionsToday)/\(habitVM.habits.count)",
                subtitle: "\(Int(habitVM.completionRateToday * 100))% consistency rate",
                icon: "checkmark.seal.fill",
                color: AppTheme.success
            )

            StatCard(
                title: "Best Streak",
                value: "\(habitVM.longestStreak) \(habitVM.longestStreak == 1 ? "day" : "days")",
                subtitle: habitVM.longestStreak > 0 ? "Momentum in progress" : "Start your streak today",
                icon: "flame.fill",
                color: AppTheme.sandstone
            )
        }
    }

    // MARK: - Habits List Section
    private var habitsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Habits")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if !habitVM.habits.isEmpty {
                    Text("Click any day dot or toggle button to mark complete")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if habitVM.habits.isEmpty {
                emptyHabitsView
            } else {
                VStack(spacing: 14) {
                    ForEach(habitVM.habits) { habit in
                        HabitCardView(
                            habit: habit,
                            onToggleDay: { date in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                    habitVM.toggleHabitCompletion(id: habit.id, on: date)
                                }
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    habitVM.deleteHabit(withId: habit.id)
                                }
                            }
                        )
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: habitVM.habits)
            }
        }
    }

    private var emptyHabitsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "flame")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.sandstone.opacity(0.7))
            Text("No habits configured yet")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Create a new routine or reload sample habits to start building streaks.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Button("Load Default Habits") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    habitVM.loadDefaultHabits()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .calmCard(cornerRadius: 14)
    }

    // MARK: - New Habit Sheet
    private var addHabitSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create New Habit")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Habit Title")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                TextField("e.g. Read 20 Pages, Morning Meditation", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Target")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                Stepper("Target: \(targetDaysPerWeek) \(targetDaysPerWeek == 1 ? "day" : "days") per week", value: $targetDaysPerWeek, in: 1...7)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                let availableIcons = [
                    "flame.fill", "drop.fill", "brain.head.profile", "book.fill",
                    "figure.run", "dumbbell.fill", "bed.double.fill", "leaf.fill",
                    "cup.and.saucer.fill", "pencil.and.outline", "sparkles", "laptopcomputer",
                    "heart.fill", "sun.max.fill", "moon.stars.fill", "cross.case.fill"
                ]

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : AppTheme.textSecondary)
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.16) : AppTheme.cardBackgroundSubtle)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedIcon == icon ? Color(hex: selectedColorHex) : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Theme Color")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                let availableColors = [
                    "#344E41", "#4D6A53", "#9C5B42", "#B27B38",
                    "#4A6B7C", "#5B8266", "#A67C38", "#6B657D",
                    "#8C584E", "#3C4858"
                ]

                HStack(spacing: 12) {
                    ForEach(availableColors, id: \.self) { colorHex in
                        Button {
                            selectedColorHex = colorHex
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.textPrimary, lineWidth: selectedColorHex == colorHex ? 2.5 : 0)
                                        .padding(selectedColorHex == colorHex ? -3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    showingAddSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Habit") {
                    habitVM.addHabit(
                        title: newTitle,
                        iconName: selectedIcon,
                        colorHex: selectedColorHex,
                        targetDaysPerWeek: targetDaysPerWeek
                    )
                    showingAddSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding(24)
        .frame(width: 480)
    }
}

// MARK: - Habit Card View

struct HabitCardView: View {
    let habit: HabitItem
    let onToggleDay: (Date) -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var isBouncing = false

    var body: some View {
        VStack(spacing: 16) {
            // Top row: Icon, title, target, streak badge & delete
            HStack(spacing: 14) {
                // Habit Icon
                Image(systemName: habit.iconName)
                    .font(.title2)
                    .foregroundStyle(habit.color)
                    .frame(width: 44, height: 44)
                    .background(habit.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Target: \(habit.targetDaysPerWeek) \(habit.targetDaysPerWeek == 1 ? "day" : "days")/week")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                // Calm Streak Badge
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(habit.streakCount > 0 ? AppTheme.sandstone : AppTheme.textTertiary)

                    Text("\(habit.streakCount) \(habit.streakCount == 1 ? "day" : "days")")
                        .font(.subheadline.bold())
                        .foregroundStyle(habit.streakCount > 0 ? AppTheme.sandstone : AppTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(habit.streakCount > 0 ? AppTheme.sandstone.opacity(0.12) : AppTheme.cardBackgroundSubtle)
                )

                // Delete Habit Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(AppTheme.terracotta.opacity(isHovered ? 0.9 : 0.4))
                        .frame(width: 24, height: 24)
                        .background(isHovered ? AppTheme.terracotta.opacity(0.12) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Delete habit")
            }

            Divider()

            // Middle row: Week mini-calendar dots (Monday to Sunday) & Quick Complete Button
            HStack(spacing: 20) {
                // 7 Days Mini-Calendar
                HStack(spacing: 10) {
                    ForEach(getWeekDays()) { day in
                        DayCompletionDot(
                            day: day,
                            isCompleted: habit.isCompleted(on: day.date),
                            color: habit.color,
                            onTap: {
                                onToggleDay(day.date)
                            }
                        )
                    }
                }

                Spacer()

                // One-click Big Toggle Button with Spring Bounce
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        isBouncing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isBouncing = false
                    }
                    onToggleDay(Date())
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.headline)

                        Text(habit.isCompletedToday ? "Completed Today" : "Mark Complete")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(habit.isCompletedToday ? Color.white : habit.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(habit.isCompletedToday ? habit.color : habit.color.opacity(0.12))
                    )
                    .scaleEffect(isBouncing ? 1.15 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .calmCard(isHovered: isHovered, cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    habit.isCompletedToday ? habit.color.opacity(0.35) : AppTheme.subtleBorder,
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func getWeekDays() -> [WeekDayModel] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        let weekday = calendar.component(.weekday, from: todayStart)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: todayStart) else {
            return []
        }

        let symbols = ["M", "T", "W", "T", "F", "S", "S"]
        var result: [WeekDayModel] = []

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                let dayNum = "\(calendar.component(.day, from: date))"
                let isToday = calendar.isDate(date, inSameDayAs: now)
                let isFuture = date > todayStart
                result.append(WeekDayModel(
                    id: date,
                    date: date,
                    symbol: symbols[i],
                    dayNumber: dayNum,
                    isToday: isToday,
                    isFuture: isFuture
                ))
            }
        }
        return result
    }
}

// MARK: - Day Completion Dot

struct WeekDayModel: Identifiable {
    let id: Date
    let date: Date
    let symbol: String
    let dayNumber: String
    let isToday: Bool
    let isFuture: Bool
}

struct DayCompletionDot: View {
    let day: WeekDayModel
    let isCompleted: Bool
    let color: Color
    let onTap: () -> Void

    @State private var isDotHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(day.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(day.isToday ? AppTheme.accent : AppTheme.textSecondary)

                ZStack {
                    Circle()
                        .fill(
                            isCompleted
                                ? color
                                : (day.isToday ? color.opacity(0.12) : AppTheme.cardBackgroundSubtle)
                        )
                        .frame(width: 26, height: 26)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    } else if day.isToday {
                        Circle()
                            .stroke(color, lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                    }
                }
                .scaleEffect(isDotHovered ? 1.15 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDotHovered)

                Text(day.dayNumber)
                    .font(.system(size: 9))
                    .foregroundStyle(day.isToday ? AppTheme.accent : AppTheme.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isDotHovered = hovering
        }
        .help(day.isToday ? "Today: Click to toggle" : "\(day.date.formatted(date: .abbreviated, time: .omitted))")
    }
}
