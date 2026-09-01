# Changelog

All notable changes, new features, and bug fixes for **Focenda** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-01

### Summary
Focenda v0.1.0 is the first official release of the native macOS focus, task, and calendar productivity suite. It provides a complete, distraction-free productivity environment combining intelligent focus timers, unified Kanban task workflows, an interactive monthly calendar, recurring reminders, a multi-notebook scratchpad, an instant-access menu bar control center, 5 refined visual themes, global keyboard shortcuts, guided onboarding, and encrypted local storage.

### Key Highlights & Features
- **Intelligent Focus Timer:** Deep focus, short break, and long break intervals with circular progress animations, mini floating HUD, and session counters.
- **Unified Tasks & Kanban:** 3-column drag-and-drop Kanban board with seamless toggle to linear list view, priority flags, due dates, and Pomodoro session counts.
- **Interactive Calendar:** Monthly schedule grid with focus heatmaps, scheduled task indicators, and pinned date previews.
- **Recurring Reminders:** Scheduled alerts for daily, weekday, weekly, and monthly intervals with native macOS notifications and rich chime alerts.
- **Multi-Notebook Scratchpad:** Debounced AES-GCM encrypted notes with instant search, folder organization, and keystroke persistence.
- **Menu Bar Control Center:** Quick timer controls, note capture, and task addition directly from the macOS menu bar.
- **Global Keyboard Shortcuts:** System-wide hotkeys (`⌥ ⌘ F`, `⌥ ⌘ 1-3`, etc.) to control timers and focus cycles from any app.
- **5 Refined Aesthetic Themes:** Zen Calm Light, Obsidian Minimal Dark, Warm Sandstone, Nordic Frost, and Forest Matcha with instant color switching.
- **Direct DMG Installer:** Automated `.dmg` drag-and-drop disk image releases (`Focenda-macOS.dmg`) and private in-app updates.
- **100% Local, Private & Secure:** Authenticated AES-GCM encryption on device with zero telemetry and no cloud tracking.

---

## [0.1.0-beta.9] - 2026-08-26

### Summary
Focenda v0.1.0-beta.9 removes remaining right-edge clipping from dense layouts and adds direct navigation between Kanban columns.

### Added
- **Kanban Column Navigator:** Added one-click status buttons and directional controls to jump between the To Do, In Progress, and Done columns.

### Fixed & Changed
- **Elastic Kanban Layout:** Made columns and task rows adapt to the available width without clipping.
- **Compact Reminder Rows:** Tightened reminder cards so times, recurrence details, next-fire information, and actions remain visible in constrained layouts.

---

## [0.1.0-beta.8] - 2026-08-26

### Summary
Focenda v0.1.0-beta.8 improves mouse discoverability and responsive behavior across Calendar, Tasks, and Reminders.

### Fixed & Changed
- **Visible Horizontal Scrollbars:** Kept horizontal scrollbars available for mouse navigation in wide calendar and Kanban content.
- **Responsive Calendar Layout:** Reworked the monthly calendar and agenda pane to preserve their usable widths while allowing horizontal navigation.
- **Responsive Reminders Layout:** Adapted the Reminders & Alerts header, cards, and summary grid for narrower window sizes.

---

## [0.1.0-beta.7] - 2026-08-26

### Summary
Focenda v0.1.0-beta.7 adds a dedicated Reminders & Alerts workspace and strengthens navigation across the app.

### Added
- **Reminders & Alerts Workspace:** Added a dedicated sidebar view for searching, creating, editing, enabling, disabling, and deleting recurring reminders.
- **Reminder Verification Tools:** Added per-reminder sound testing and a view of timed task reminders and upcoming alert information.

### Fixed & Changed
- **Sidebar Navigation:** Added the Reminders destination and improved navigation split-view behavior.
- **Cross-Screen Scrolling:** Prevented sidebar text clipping and enabled horizontal scrolling where wide content requires it.

---

## [0.1.0-beta.6] - 2026-08-26

### Summary
Focenda v0.1.0-beta.6 refines calendar previews, improves light-theme readability, and simplifies task navigation.

### Added
- **Click-to-Pin Calendar Preview:** Added a one-second hover delay and lets users click a date to keep its preview open while using quick actions.
- **Compact Tasks Switcher:** Renamed the sidebar destination to Tasks and added a compact board/list view switcher with horizontal navigation.

### Fixed & Changed
- **Light-Theme Contrast:** Increased contrast for primary, secondary, and tertiary text, form fields, and controls across light themes.

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
