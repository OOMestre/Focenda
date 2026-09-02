import SwiftUI

/// An intuitive, visual, and modern time picker component for macOS.
///
/// Provides a clean interactive trigger pill and a fluid popover interface with:
/// - Instant 1-click productivity presets (Morning, Noon, Afternoon, End of Day, Evening, Night)
/// - Relative time shortcuts (Now, +15m, +30m, +1h)
/// - Scrollable dual columns for hours (1-12) and minutes (5-min intervals)
/// - Digital stepper header for rapid +/- micro adjustments without manual typing
/// - Consistent 12-hour time display with an explicit AM/PM selector
public struct IntuitiveTimePicker: View {
    @Binding public var selection: Date
    public var title: String?
    public var style: Style
    public var showIcon: Bool
    public var showPresets: Bool

    @State private var isShowingPopover: Bool = false
    @State private var isHovered: Bool = false

    public enum Style {
        case standard
        case compact
        case minimal
    }

    public init(
        _ title: String? = nil,
        selection: Binding<Date>,
        style: Style = .standard,
        showIcon: Bool = true,
        showPresets: Bool = true
    ) {
        self._selection = selection
        self.title = title
        self.style = style
        self.showIcon = showIcon
        self.showPresets = showPresets
    }

    // MARK: - Date Calculations & Mutators
    private var calendar: Calendar {
        Calendar.current
    }

    public var currentHour: Int {
        calendar.component(.hour, from: selection)
    }

    public var currentMinute: Int {
        calendar.component(.minute, from: selection)
    }

    public var currentHour12: Int {
        let hour = currentHour % 12
        return hour == 0 ? 12 : hour
    }

    public var currentMeridiem: String {
        currentHour >= 12 ? "PM" : "AM"
    }

    public var formattedTimeString: String {
        AppDateFormatter.time12.string(from: selection)
    }

    public func setTime(hour: Int, minute: Int) {
        var components = calendar.dateComponents([.year, .month, .day, .timeZone], from: selection)
        components.hour = max(0, min(23, hour))
        components.minute = max(0, min(59, minute))
        components.second = 0

        if let newDate = calendar.date(from: components) {
            selection = newDate
        }
    }

    public func setMeridiem(isPM: Bool) {
        setTime(hour: hour24(from: currentHour12, isPM: isPM), minute: currentMinute)
    }

    public func adjustHour(by delta: Int) {
        let newHour = (currentHour + delta + 24) % 24
        setTime(hour: newHour, minute: currentMinute)
    }

    public func adjustMinute(by delta: Int) {
        var newTotalMinutes = currentHour * 60 + currentMinute + delta
        if newTotalMinutes < 0 {
            newTotalMinutes += 24 * 60
        }
        newTotalMinutes %= (24 * 60)
        let newHour = newTotalMinutes / 60
        let newMinute = newTotalMinutes % 60
        setTime(hour: newHour, minute: newMinute)
    }

    public func applyPreset(hour: Int, minute: Int) {
        setTime(hour: hour, minute: minute)
    }

    public func applyRelativeOffset(minutes: Int) {
        let baseDate = Date()
        if let offsetDate = calendar.date(byAdding: .minute, value: minutes, to: baseDate) {
            let hour = calendar.component(.hour, from: offsetDate)
            let minute = calendar.component(.minute, from: offsetDate)
            setTime(hour: hour, minute: minute)
        }
    }

    public func applyRoundedNow() {
        let now = Date()
        let minute = calendar.component(.minute, from: now)
        let roundedMinute = ((minute + 2) / 5) * 5
        let hour = calendar.component(.hour, from: now)
        if roundedMinute >= 60 {
            setTime(hour: (hour + 1) % 24, minute: 0)
        } else {
            setTime(hour: hour, minute: roundedMinute)
        }
    }

    private func hour24(from hour12: Int, isPM: Bool) -> Int {
        let normalizedHour = hour12 == 12 ? 0 : hour12
        return normalizedHour + (isPM ? 12 : 0)
    }

    // MARK: - View Body
    public var body: some View {
        Button {
            isShowingPopover.toggle()
        } label: {
            triggerPillView
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            popoverContentView
        }
    }

    // MARK: - Trigger Pill View
    @ViewBuilder
    private var triggerPillView: some View {
        switch style {
        case .standard:
            HStack(spacing: 6) {
                if showIcon {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isHovered ? AppTheme.accent : AppTheme.textSecondary)
                }

                Text(formattedTimeString)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isHovered ? AppTheme.accent.opacity(0.6) : AppTheme.subtleBorder, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)

        case .compact:
            HStack(spacing: 4) {
                if showIcon {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isHovered ? AppTheme.accent : AppTheme.textSecondary)
                }

                Text(formattedTimeString)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isHovered ? AppTheme.accent.opacity(0.6) : AppTheme.subtleBorder, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isHovered)

        case .minimal:
            HStack(spacing: 3) {
                Text(formattedTimeString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isHovered ? AppTheme.cardBackgroundSubtle : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    // MARK: - Popover Content
    private var popoverContentView: some View {
        VStack(spacing: 12) {
            // Header: Title & Done
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.accent)

                    Text(title ?? "Select Time")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()

                Button("Done") {
                    isShowingPopover = false
                }
                .font(.system(size: 11, weight: .bold))
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.small)
            }

            // Digital Time Readout with Stepper Micro-Adjusters
            digitalReadoutStepperView

            Divider()
                .background(AppTheme.border)

            if showPresets {
                // Quick Time Presets
                presetsSectionView

                Divider()
                    .background(AppTheme.border)
            }

            // Dual Column Hour & Minute Selector
            dualColumnPickerView
        }
        .padding(14)
        .frame(width: 300)
        .background(AppTheme.cardBackground)
    }

    // MARK: - Digital Readout & Steppers
    private var digitalReadoutStepperView: some View {
        HStack(spacing: 8) {
            // Hour Stepper
            VStack(spacing: 2) {
                Button {
                    adjustHour(by: 1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 18)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)

                Text(String(currentHour12))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 44, height: 32)
                    .background(AppTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )

                Button {
                    adjustHour(by: -1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 18)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }

            Text(":")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)

            // Minute Stepper
            VStack(spacing: 2) {
                Button {
                    adjustMinute(by: 1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 18)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)

                Text(String(format: "%02d", currentMinute))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 44, height: 32)
                    .background(AppTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )

                Button {
                    adjustMinute(by: -1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 18)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }

            meridiemSelectorView

            Spacer(minLength: 4)

            // Micro Fine-tuning Quick Buttons (+5m, -5m, +15m, +30m)
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    quickAdjustButton(label: "+5m") { adjustMinute(by: 5) }
                    quickAdjustButton(label: "-5m") { adjustMinute(by: -5) }
                }
                HStack(spacing: 4) {
                    quickAdjustButton(label: "+15m") { adjustMinute(by: 15) }
                    quickAdjustButton(label: "+30m") { adjustMinute(by: 30) }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func quickAdjustButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var meridiemSelectorView: some View {
        HStack(spacing: 2) {
            meridiemButton("AM", isSelected: currentMeridiem == "AM") {
                setMeridiem(isPM: false)
            }

            meridiemButton("PM", isSelected: currentMeridiem == "PM") {
                setMeridiem(isPM: true)
            }
        }
        .padding(2)
        .background(AppTheme.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .accessibilityLabel("AM/PM")
    }

    private func meridiemButton(
        _ label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? AppTheme.textOnAccent : AppTheme.textSecondary)
                .frame(width: 25, height: 22)
                .background(isSelected ? AppTheme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Set \(label)")
    }

    // MARK: - Presets Section
    private var presetsSectionView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("QUICK PRESETS")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)

            // Standard Schedule Presets (Morning, Noon, Afternoon, EOD, Night)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    presetChip(label: "9:00 AM", name: "Morning", hour: 9, minute: 0)
                    presetChip(label: "12:00 PM", name: "Noon", hour: 12, minute: 0)
                    presetChip(label: "2:00 PM", name: "Afternoon", hour: 14, minute: 0)
                }

                HStack(spacing: 4) {
                    presetChip(label: "5:00 PM", name: "EOD", hour: 17, minute: 0)
                    presetChip(label: "7:00 PM", name: "Evening", hour: 19, minute: 0)
                    presetChip(label: "9:00 PM", name: "Night", hour: 21, minute: 0)
                }
            }

            // Relative Presets
            HStack(spacing: 4) {
                Button {
                    applyRoundedNow()
                } label: {
                    Text("Now")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)

                relativeChip(label: "+15 min", offsetMinutes: 15)
                relativeChip(label: "+30 min", offsetMinutes: 30)
                relativeChip(label: "+1 hour", offsetMinutes: 60)
            }
        }
    }

    private func presetChip(label: String, name: String, hour: Int, minute: Int) -> some View {
        let isSelected = (currentHour == hour && currentMinute == minute)
        return Button {
            applyPreset(hour: hour, minute: minute)
        } label: {
            Text(label)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .monospaced))
                .foregroundStyle(isSelected ? AppTheme.textOnAccent : AppTheme.textPrimary)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(isSelected ? AppTheme.accent : AppTheme.cardBackgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .help("\(name) (\(label))")
    }

    private func relativeChip(label: String, offsetMinutes: Int) -> some View {
        Button {
            applyRelativeOffset(minutes: offsetMinutes)
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dual Column Picker View
    private var dualColumnPickerView: some View {
        HStack(spacing: 12) {
            // Hours Column (1 - 12)
            VStack(alignment: .leading, spacing: 4) {
                Text("HOUR")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 2) {
                            ForEach(1...12, id: \.self) { hour in
                                let isSelected = (currentHour12 == hour)
                                Button {
                                    setTime(
                                        hour: hour24(from: hour, isPM: currentMeridiem == "PM"),
                                        minute: currentMinute
                                    )
                                } label: {
                                    Text(String(hour))
                                        .font(.system(size: 12, weight: isSelected ? .bold : .regular, design: .monospaced))
                                        .foregroundStyle(isSelected ? AppTheme.textOnAccent : AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 24)
                                        .background(isSelected ? AppTheme.accent : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                                .id(hour)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(height: 120)
                    .background(AppTheme.inputBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
                    .onAppear {
                        proxy.scrollTo(currentHour12, anchor: .center)
                    }
                }
            }

            // Minutes Column (00, 05, 10, ..., 55)
            VStack(alignment: .leading, spacing: 4) {
                Text("MINUTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                let isSelected = (currentMinute == minute)
                                Button {
                                    setTime(hour: currentHour, minute: minute)
                                } label: {
                                    Text(String(format: "%02d", minute))
                                        .font(.system(size: 12, weight: isSelected ? .bold : .regular, design: .monospaced))
                                        .foregroundStyle(isSelected ? AppTheme.textOnAccent : AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 24)
                                        .background(isSelected ? AppTheme.accent : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                                .id(minute)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(height: 120)
                    .background(AppTheme.inputBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
                    .onAppear {
                        let nearestFive = (currentMinute / 5) * 5
                        proxy.scrollTo(nearestFive, anchor: .center)
                    }
                }
            }
        }
    }
}
