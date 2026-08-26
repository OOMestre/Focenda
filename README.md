# Focenda

<div align="center">

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
[License](#license)

---

</div>

## Overview

Focenda is a high-performance, distraction-free macOS application engineered to maximize daily focus, calendar timeboxing, and task management.

Combining structured focus cycles (Pomodoro and deep work timers), visual Kanban workflows, notebook scratchpads, quick web resource hubs, and recurring reminders with native macOS system alerts, Focenda delivers a unified, clutter-free productivity system.

---

## Key Features

- **Intelligent Focus Timer:** Configurable intervals for deep focus, short breaks, and long breaks with smooth circular progress animations and custom time adjustments (+5m / -5m).
- **Unified Tasks & Kanban Board:** Interactive 3-column Kanban workflow with drag-and-drop support, direct status progression pills (To Do, In Progress, Done), Pomodoro counters, due dates, and a seamless toggle to list view.
- **Interactive Calendar & Day Previews:** Full monthly calendar grid with daily focus heatmaps, scheduled tasks, due date milestone indicators, and animated hover preview popovers to inspect daily commitments without scrolling.
- **Recurring Reminders:** Dedicated scheduler for daily, weekday, weekly, and monthly recurring tasks with native macOS banner alerts and rich chime notifications.
- **Multi-Notebook Scratchpad:** Master-detail quick notes system organized into custom folders (General, Projects, Work, Personal, Ideas) with live character/word counters and keystroke persistence.
- **Focus Hub & Bookmarks:** Responsive quick-launch directory for essential development references, tools, and documentation with 1-click browser integration.
- **Menu Bar Control Center:** Floating, top-down animated macOS menu bar utility providing timer controls, quick note capture into user folders, instant task addition, and bookmarks access.
- **Customizable Visual Themes:** Five refined aesthetic themes selectable in Settings (Zen Calm Light, Obsidian Minimal Dark, Warm Sandstone, Nordic Frost, Forest Matcha) without disruptive automatic color shifts.
- **100% Local & Private:** All state persists strictly on device via macOS storage primitives. Zero telemetry, no third-party accounts, and zero cloud tracking.

---

## Quick Start

1. **Start a Focus Session:** Open the Focus Timer and start your target interval with one click or spacebar.
2. **Manage Tasks in Kanban:** Navigate to Tasks & Kanban to organize items across columns, set priority levels (High, Medium, Low), or switch to the linear list view.
3. **Inspect Schedule in Calendar:** Open Calendar and hover over any date to inspect scheduled due dates, recurring reminders, and logged focus sessions.
4. **Capture Notes:** Use Scratchpad or the Menu Bar popover to take quick notes into dedicated notebooks.

---

## Installation

### Option 1: Direct Download (Releases)
Download the latest staging or production bundle from [GitHub Releases](https://github.com/OOMestre/Focenda/releases), extract the archive, and place `Focenda.app` into `/Applications`.

### Option 2: Build from Source
```bash
git clone https://github.com/OOMestre/Focenda.git
cd Focenda
make staging
```

---

## Local Development

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15+ / 16+ or Swift 5.9+ / 6.0+

### Development Commands
```bash
# Run unit test suite (154+ automated tests)
make test

# Build staging application bundle and launch
make staging

# Clean build artifacts
make clean
```

---

## Contributing

Contributions are welcome. Please consult [CONTRIBUTING.md](CONTRIBUTING.md) for code style standards, testing requirements, and submission guidelines.

---

## License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
