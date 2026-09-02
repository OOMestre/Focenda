# Changelog

All notable changes, new features, and bug fixes for **Focenda** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-09-02

### Summary
Focenda v1.0.1 introduces the Repeat Until Done reminder alert mode, Menu Bar bookmark synchronization with Focus Hub, Menu Bar popover geometry stabilization, an intuitive 12-hour AM/PM time picker, and smart audio playback for sound tests.

### Added
- **Repeat Until Done Alert Mode:** Added configurable persistent repeat chimes and banner reminders until explicitly acknowledged or completed in the alert HUD.

### Fixed & Changed
- **Menu Bar Bookmark Synchronization:** Menu Bar Links and Focus Hub bookmarks share synchronized local storage and categorized launching.
- **Menu Bar Popover Geometry Stabilization:** Fixed popover height jumping and stabilized layout sizing across tab transitions.
- **Intuitive 12-Hour Time Format Picker:** Standardized time input in reminder creation to a clean 12-hour AM/PM layout.
- **Smart Sound Preview & Test Audio:** Limited test alerts and sound previews in Settings and Reminders to 3 gentle pulses with immediate pause support.
- **Enhanced Persistence & Preference Bindings:** Verified 100% data retention across update cycles with responsive preference persistence.

---

## [1.0.0] - 2026-09-01

### Summary
Focenda v1.0.0 is the first official release of the native macOS focus, task, and calendar productivity suite. It provides a complete, distraction-free productivity environment combining intelligent focus timers, unified Kanban task workflows, an interactive monthly calendar, recurring reminders, a multi-notebook scratchpad, an instant-access menu bar control center, 5 refined visual themes, global keyboard shortcuts, guided onboarding, and encrypted local storage.

### Features & Workspaces

#### Focus Timer & Flow Engine
- **Multiple Interval Modes:** Deep Focus (25 min default), Short Break (5 min), and Long Break (15 min) with custom duration sliders in Settings.
- **Circular Animated Visualizer:** Hardware-accelerated progress ring with elapsed/remaining countdowns and pulse animations.
- **Floating Mini Timer HUD:** Lightweight, draggable floating panel (`NSPanel`) designed for multi-space desktop setups.
- **Energy-Efficient Execution:** Background throttling, window minimization pause handling, and low CPU usage.
- **Audio Completion Chimes:** Configurable alert sounds (Hero, Glass, Ping, Submarine) and support for custom audio files with multi-pulse chimes.
- **Session History & Analytics:** Daily focus minutes, completed sessions, and productivity streaks persisted locally and reflected in dashboard stats.

#### Tasks & Kanban Board
- **Unified Switcher:** One-click toggle between interactive 3-column Kanban board (`To Do`, `In Progress`, `Done`) and compact linear list view.
- **Drag & Drop Workflow:** Native macOS drag-and-drop support across Kanban columns and lists.
- **Priority & Due Date Tracking:** Categorize tasks with Low, Medium, High, and Urgent priority flags, accompanied by deadline scheduling.
- **Pomodoro Estimation:** Assign estimated focus sessions per task and increment completed sessions directly from the card.
- **Search & Filtering:** Real-time fuzzy query filtering across task titles and descriptions.

#### Interactive Monthly Calendar & Heatmap
- **Monthly Schedule Grid:** Responsive monthly grid displaying daily productivity heatmaps based on completed focus time.
- **Task & Reminder Indicators:** Day pills displaying scheduled tasks, due tasks, and active recurring reminders.
- **Pinned Date Preview:** Click or hover on dates to inspect scheduled items and execute quick task or reminder creation.
- **Monthly Productivity Summary:** Automatic calculations for total focus hours, session counts, completed tasks, and active workdays.

#### Recurring Reminders & Alerts
- **Flexible Recurrence Intervals:** Schedule daily, weekday, weekly, and monthly repeating reminder notifications.
- **Native macOS Notifications:** Timed alerts delivered via Apple UserNotifications framework with action triggers.
- **Active Reminder HUD:** Non-intrusive in-app banner alerts preventing duplicate notifications while the app is in the foreground.
- **Sound Testing & Verification:** Per-reminder sound audition and upcoming alert countdowns.

#### Multi-Notebook Encrypted Scratchpad
- **Ultra-Fluid 120 FPS Typing:** 400ms debounced persistence avoiding UI thread blocking during rapid typing.
- **Encrypted Local Storage:** All notes, titles, and notebook metadata are encrypted locally using AES-GCM 256-bit cryptography.
- **Notebooks & Folder Organization:** Group notes into custom folders with quick sidebar navigation and search.
- **Word & Character Counters:** Live stats and clean distraction-free typography.

#### Focus Hub & Menu Bar Control Center
- **Instant Menu Bar Access:** Fast popover panel from the macOS menu bar icon.
- **Quick Controls:** Start, pause, or switch focus modes without leaving active fullscreen applications.
- **Quick Note & Task Capture:** Add thoughts or new tasks straight into your notebooks and Kanban columns.
- **Project Bookmarks:** Fast launcher for essential documentation, design tools, and development URLs.
- **Clean First Launch:** New installations start with empty bookmarks, tasks, and quick links; user data is created only through user actions.

#### System-Wide Global Keyboard Shortcuts
- **Carbon Hotkey Integration:** Native system-wide keyboard shortcuts operating across any application:
  - `⌥ ⌘ F` — Start / Pause Focus Timer
  - `⌥ ⌘ 1` — Start Deep Focus
  - `⌥ ⌘ 2` — Start Short Break
  - `⌥ ⌘ 3` — Start Long Break
  - `⌥ ⌘ R` — Reset Timer
  - `⌥ ⌘ S` — Skip Session
- **Custom Shortcut Schemes:** Select between Standard (`⌥ ⌘`), Power User (`⌃ ⌥ ⌘`), and Compact (`⌃ ⌥`) with keycap preview badges.

#### 5 Handcrafted Visual Themes
- **Zen Calm Light:** Soothing minimalist light theme with high-contrast slate accents.
- **Obsidian Minimal Dark:** Deep true-black dark theme optimized for low-light focus sessions.
- **Warm Sandstone:** Soft, warm neutral tones for extended work sessions.
- **Nordic Frost:** Cool glacial blues and crisp styling.
- **Forest Matcha:** Earthy greens and calm botanical hues.

#### Privacy, Security & Offline-First Architecture
- **100% Local & Offline:** Zero telemetry, no cloud analytics, and zero external tracking.
- **Apple CryptoKit Encryption:** Authenticated encryption using hardware-backed cryptographic keys.
- **Hermetic In-App Updates:** Check for official releases securely on GitHub with signed DMGs (`Focenda-macOS.dmg`).

### Fixed & Changed
- **Silent Legacy Keychain Migration:** Legacy Keychain entries are checked without authentication UI, so a first launch after installation or update never asks for the login Keychain password.

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
