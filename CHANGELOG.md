# Changelog

All notable changes, new features, and bug fixes for **Focenda** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Global Keyboard Shortcuts for Focus:** Implemented native system-wide keyboard shortcuts using macOS Carbon HIToolbox (`RegisterEventHotKey`) and `AppKit` to start/pause focus (`⌥ ⌘ F`), launch deep focus mode (`⌥ ⌘ 1`), trigger short breaks (`⌥ ⌘ 2`), start long breaks (`⌥ ⌘ 3`), reset the timer (`⌥ ⌘ R`), and skip sessions (`⌥ ⌘ S`) from any application across macOS.
- **Global Shortcuts Settings & Custom Presets:** Added a dedicated Keyboard Shortcuts preferences section in Settings with Apple-style keycap badges, scheme presets (Standard `⌥ ⌘`, Power User `⌃ ⌥ ⌘`, Compact `⌃ ⌥`), and audio feedback options.
- **macOS Menu Bar Focus Commands:** Integrated a native `CommandMenu("Focus")` with standard keyboard shortcuts in the macOS menu bar.

---

## [0.1.0-beta.5] - 2026-08-26

### Summary
Focenda v0.1.0-beta.5 consolidates task management into a single Tasks & Kanban view with seamless list/board switching, introduces 5 user-selectable visual themes in Settings, adds an interactive Calendar Hover Popover for instant schedule previews, implements recurring reminders with native notification chimes, refactors the Scratchpad and Bookmarks layouts for fluid responsiveness, and synchronizes real user folders in the Menu Bar popover.

### Added
- **Unified Tasks & Kanban Section:** Replaced duplicate Tasks and Kanban tabs with a single view featuring a top segmented switcher `[ Kanban Board (Default) | List View ]`.
- **Custom Visual Themes:** Added 5 themes in Settings (Zen Calm Light, Obsidian Minimal Dark, Warm Sandstone, Nordic Frost, Forest Matcha) with live swatches and persistence.
- **Calendar Hover Popover Preview:** Added an animated tooltip popover on day cells in the monthly grid showing focus minutes, scheduled tasks, and recurring reminders on hover.
- **Recurring Reminders Engine:** Implemented `RecurringReminder` and `RecurringReminderViewModel` supporting daily, weekday, weekly, and monthly repetitions with macOS notification triggers.
- **Audible Notification Alert:** Added multi-pulse alert chime and Menu Bar reminder banners.
- **Menu Bar Real Folders Sync:** Integrated user-created Scratchpad folders directly into the Menu Bar note capture panel.

### Fixed & Changed
- **Removed Habits Feature:** Completely removed habit items and streak cards from sidebar, dashboard, and calendar.
- **Fixed Text Wrapping:** Enforced `.lineLimit(1)` and `.fixedSize()` on priority pills (`Low`, `Medium`, `High`), Pomodoro badges, and action buttons.
- **Layout Responsiveness:** Resolved sidebar squeezing on Bookmarks and Scratchpad using `.navigationSplitViewStyle(.balanced)` and flexible grid constraints.
- **Menu Bar Opening Transition:** Fixed opening animation to smoothly expand downwards from the menu bar icon.

---

## [0.1.0-beta.4] - 2026-08-26

### Added
- Full calendar date synchronization with task `dueDate`, `reminderDate`, and scheduled milestones.
- Responsive bookmarks grid with horizontal category scrolling and adaptive stat cards.

### Fixed
- Fixed leading character clipping on macOS sidebar items.

---

## [0.1.0-beta.3] - 2026-08-26

### Added
- Drag-and-drop support for Kanban task cards across columns.
- Timed task reminders scheduled with native `UNCalendarNotificationTrigger`.

---

## [0.1.0-beta.2] - 2026-08-26

### Added
- Multi-folder notebook hierarchy in Scratchpad with live keystroke persistence.
- Bookmarks focus hub for quick browser access to documentation and tools.
- Interactive Calendar agenda pane.

---

## [0.1.0-beta.1] - 2026-08-26

### Added
- Master-detail Scratchpad note editor.
- Floating MenuBarExtra utility with timer controls and live countdown.
- Initial Zen minimalist theme and design tokens.

