# ⏱️ Focenda

<div align="center">

**The native macOS focus and task productivity app.**

*100% Swift • Free & Open Source • Designed for Apple Silicon & macOS*

[![CI Build & Test](https://github.com/OOMestre/Focenda/actions/workflows/ci.yml/badge.svg)](https://github.com/OOMestre/Focenda/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-black?logo=apple)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)

[✨ Features](#-key-features) •
[🚀 Quick Start](#-quick-start) •
[📥 Installation](#-installation) •
[🛠️ Local Development](#-local-development) •
[🤝 Contributing](#-contributing) •
[📄 License](#-license)

---

</div>

## 🌟 What is Focenda?

**Focenda** is a lightweight, distraction-free macOS application built to help you maintain deep focus on what truly matters.

Combining proven focus techniques (Pomodoro & Timeboxing) with an intuitive task manager and modern macOS design language, Focenda fits right into your daily workflow.

---

## ✨ Key Features

- 🎯 **Intelligent Focus Timer:** Configurable intervals for deep work, short breaks, and long breaks with animated progress rings.
- 📋 **Fluid Task Management:** Capture tasks, assign priorities (`High`, `Medium`, `Low`), add tags, and track completed pomodoros.
- 📊 **Productivity Analytics:** Track daily focus minutes, completed sessions, and consistency metrics.
- ⚡ **100% Swift & Native:** Built purely with **SwiftUI, Swift Concurrency, and AppKit**, consuming minimal memory and battery.
- 🎨 **macOS Human Interface Design:** Native translucent sidebars, Light & Dark mode support, SF Symbols, and keyboard shortcuts.
- 🔒 **100% Local & Private:** All data remains entirely on your Mac. No logins, accounts, or background tracking.

---

## 🚀 Quick Start

1. **Start a Focus Session:** In the *Focus Timer* tab, start your countdown with a single click.
2. **Organize Tasks:** In the *Tasks* tab, capture your daily priorities and check them off as you complete them.
3. **Track Your Day:** In the *Dashboard*, see your accumulated focus minutes and completed goals.

---

## 📥 Installation

### Option 1: Direct Download (Releases)
Download the latest release from [GitHub Releases](https://github.com/OOMestre/Focenda/releases), extract the `.zip` archive, and drag `Focenda.app` to your `Applications` folder.

### Option 2: Build from Source
```bash
git clone https://github.com/OOMestre/Focenda.git
cd Focenda
make staging
```

---

## 🛠️ Local Development

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15+ / 16+ or Swift 5.9+ / 6.0+

### Development Commands
```bash
# Run unit test suite
make test

# Build staging application bundle and launch
make staging

# Clean build artifacts
make clean
```

---

## 🤝 Contributing

Contributions are warmly welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on code style and pull request guidelines.

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
