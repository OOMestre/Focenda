# Changelog

All notable changes, new features, and bug fixes for **Focenda** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Keychain Prompt Removal:** Moved the local encryption key to a protected
  Application Support file so normal launches and app updates no longer trigger
  recurring macOS Keychain authorization prompts. Existing installations are
  migrated from the previous Keychain entry once.
- **Productivity Profiles:** Added saved workspace profiles that open selected applications, restore each window's monitor, position, and size, and can be activated from anywhere with a configurable global shortcut.
- **Global Keyboard Shortcuts for Focus:** Implemented native system-wide keyboard shortcuts using macOS Carbon HIToolbox (`RegisterEventHotKey`) and `AppKit` to start/pause focus (`⌥ ⌘ F`), launch deep focus mode (`⌥ ⌘ 1`), trigger short breaks (`⌥ ⌘ 2`), start long breaks (`⌥ ⌘ 3`), reset the timer (`⌥ ⌘ R`), and skip sessions (`⌥ ⌘ S`) from any application across macOS.
- **Global Shortcuts Settings & Custom Presets:** Added a dedicated Keyboard Shortcuts preferences section in Settings with Apple-style keycap badges, scheme presets (Standard `⌥ ⌘`, Power User `⌃ ⌥ ⌘`, Compact `⌃ ⌥`), and audio feedback options.
- **macOS Menu Bar Focus Commands:** Integrated a native `CommandMenu("Focus")` with standard keyboard shortcuts in the macOS menu bar.
- **Private GitHub Updates:** Added manual and daily automatic release checks in Settings, native macOS update notifications, release-archive validation, and local app replacement/relaunch without uploading user data.
- **Native DMG Releases:** Automated GitHub Actions release packaging to generate and upload direct drag-and-drop installer `.dmg` disk images (`Focenda-macOS.dmg`) alongside update archives.
- **Post-Update Guide (temporarily hidden):** The implementation remains available while the post-update experience is refined.
- **Post-Update Guide Replay (temporarily hidden):** The latest completed update guide remains retained for future reactivation from Settings.

- **Duplicate Reminder Delivery:** Task and recurring reminders now use the in-app HUD while Focenda is active and the native macOS notification when it is inactive, avoiding duplicate alerts.
- **Focus History Persistence:** Completed timer sessions and their counters now persist locally and are restored for dashboard metrics and calendar history after relaunching Focenda.
- **Pomodoro Completion Alert:** Timer completion now uses the floating alert HUD without activating the app, and plays the configured alert chime (Hero by default) only once.
- **Pomodoro Alert Motion:** Completion alerts animate the timer badge with a subtle pulse that respects Reduce Motion.

- **Calendar Day Preview:** Clicking a calendar date now pins its preview while the cursor moves to the quick actions, and the preview has been simplified to reduce visual density.
- **Simplified Scratchpad Notes:** Removed the generic color categories and their filter controls. The Scratchpad now starts empty, allows the final note to be deleted, uses neutral untitled notes, and migrates old category placeholders without losing user-written content.

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
