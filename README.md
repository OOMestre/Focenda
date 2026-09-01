<div align="center">

<img src="assets/focenda-mascot.png" alt="Focenda Owl Mascot" width="160" />
<br/>

<h1>Focenda</h1>

<hr />

**The native macOS focus, task, and calendar productivity suite.**

*100% Swift | Free & Open Source | Designed for Apple Silicon & Intel macOS*

[![CI Build & Test](https://github.com/OOMestre/Focenda/actions/workflows/ci.yml/badge.svg)](https://github.com/OOMestre/Focenda/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-black?logo=apple)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)

[Features](#key-features) |
[Quick Start](#quick-start) |
[Installation](#installation) |
[Local Development](#local-development) |
[Contributing](#contributing) |
[Privacy & Security](docs/PRIVACY.md) |
[License](#license)

---

</div>

## Overview

Focenda is a high-performance, distraction-free macOS application engineered to maximize daily focus, calendar timeboxing, and task management.

Combining structured focus cycles (Pomodoro and deep work timers), visual Kanban workflows, notebook scratchpads, quick web resource hubs, and recurring reminders with native macOS system alerts, Focenda delivers a unified, clutter-free productivity system.

---

## Key Features & Visual Showcase

### Intelligent Focus Timer
Configurable intervals for deep focus, short breaks, and long breaks with smooth circular progress animations, audio chimes, and quick time adjustments (+5m / -5m).

<p align="center">
  <img src="assets/gifs/focus-timer.gif" alt="Focus Timer" width="650" />
</p>

---

### Unified Tasks & Kanban Board
Interactive 3-column Kanban workflow with drag-and-drop support, direct status progression pills (To Do, In Progress, Done), Pomodoro counters, due dates, and seamless toggling to a linear list view.

<p align="center">
  <img src="assets/gifs/tasks-kanban.gif" alt="Tasks & Kanban Board" width="650" />
</p>

---

### Interactive Calendar & Day Previews
Full monthly calendar grid with daily focus heatmaps, scheduled tasks, due date milestone indicators, and compact hover previews that stay pinned after clicking a date for quick actions.

<p align="center">
  <img src="assets/gifs/calendar.gif" alt="Interactive Calendar" width="650" />
</p>

---

### Recurring Reminders
Dedicated scheduler for daily, weekday, weekly, and monthly recurring tasks with native macOS banner alerts, rich chime notifications, and overdue tracking.

<p align="center">
  <img src="assets/gifs/reminders.gif" alt="Recurring Reminders" width="650" />
</p>

---

### Multi-Notebook Scratchpad
Master-detail quick notes system organized into custom folders (General, Projects, Work, Personal, Ideas) with live character/word counters, search, and keystroke persistence.

<p align="center">
  <img src="assets/gifs/scratchpad.gif" alt="Multi-Notebook Scratchpad" width="650" />
</p>

---

### Menu Bar Control Center
Floating, top-down animated macOS menu bar utility providing quick timer controls, instant note capture into user folders, rapid task creation, and bookmark access without interrupting your workflow.

<p align="center">
  <img src="assets/gifs/menu-bar.gif" alt="Menu Bar Control Center" width="650" />
</p>

---

### Focus Hub & Bookmarks
Responsive quick-launch directory for essential development references, tools, and documentation with 1-click browser integration.

### Productivity Profiles
Save a complete workspace with selected applications, per-window monitor/position/size layouts, and a global shortcut that opens and organizes it on demand.

### Guided First-Launch Onboarding
A complete tour of every workspace section and the menu bar control center, replayable from Settings whenever needed.

### Customizable Visual Themes
Five refined aesthetic themes selectable in Settings (Zen Calm Light, Obsidian Minimal Dark, Warm Sandstone, Nordic Frost, Forest Matcha) without disruptive automatic color shifts.

### Private In-App Updates
Settings can check GitHub Releases manually or once a day, show native macOS update notifications, and install validated Focenda archives locally without sending personal data or app content anywhere.

### 100% Local, Private & Secure
Tasks, notes, reminders, bookmarks, and preferences stay on device in authenticated encrypted local storage. Zero telemetry, no third-party accounts, and zero cloud tracking.

---

## Quick Start

On the first launch, Focenda opens a guided tour covering the Dashboard, Focus Timer, Tasks, Calendar, Reminders, Scratchpad, Bookmarks, Profiles, Settings, Support and the menu bar control center. You can replay it at any time from Settings → Getting Started.

1. **Start a Focus Session:** Open the Focus Timer and start your target interval with one click or spacebar.
2. **Manage Tasks in Kanban:** Navigate to Tasks & Kanban to organize items across columns, set priority levels (High, Medium, Low), or switch to the linear list view.
3. **Inspect Schedule in Calendar:** Open Calendar and hover over any date to preview scheduled items; click a date to keep the preview open and use its quick actions.
4. **Capture Notes:** Use Scratchpad or the Menu Bar popover to take quick notes into dedicated notebooks.
5. **Restore a Workspace:** Open Profiles, add your applications, choose each monitor and a simple position on it, adjust window sizes, record a shortcut, and activate the profile whenever you want to return to that setup.

---

## Installation

### Option 1: Direct DMG Download (Releases)
Download the latest `Focenda-macOS.dmg` from [GitHub Releases](https://github.com/OOMestre/Focenda/releases), open the disk image, and drag `Focenda.app` into `/Applications`.

### Option 2: Build from Source
```bash
git clone https://github.com/OOMestre/Focenda.git
cd Focenda
make staging
```

### Option 3: Homebrew Tap
Install the current Focenda release from the [Focenda Homebrew Tap](https://github.com/OOMestre/homebrew-focenda):

```bash
brew tap oomestre/focenda
brew trust --cask oomestre/focenda/focenda
brew install --cask focenda
```

The tap currently installs the latest public Focenda beta release. The command
above trusts only the Focenda Cask. If you prefer to trust every formula, Cask,
and command from this tap, use whole-tap trust instead:

```bash
brew tap oomestre/focenda
brew trust --tap oomestre/focenda
brew install --cask focenda
```

For a one-line install, Homebrew can tap the repository and trust only this
Cask automatically:

```bash
brew install --cask oomestre/focenda/focenda
```

Update or remove the installation with:

```bash
brew upgrade --cask focenda
brew uninstall --cask focenda
```

---

## Local Development

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15+ / 16+ or Swift 5.9+ / 6.0+

### Development Commands
```bash
# Run unit test suite (294 automated tests)
make test

# Build staging application bundle and launch
make staging

# Clean build artifacts
make clean
```

---

## Contributing

Contributions are welcome. Please consult [CONTRIBUTING.md](CONTRIBUTING.md) for code style standards, testing requirements, and submission guidelines.

## Privacy & Security

See the [Focenda Privacy and Security Policy](docs/PRIVACY.md) for local
encryption, hardened-runtime behavior, notification handling, and update-service
details.

---

## License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
