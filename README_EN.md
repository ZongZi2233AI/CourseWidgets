# CourseWidgets (Made with Vibe Coding)

<div align="center">

<img src="https://github.com/ZongZi2233AI/CourseWidgets/blob/main/assets/icon.png" width="128px">

**A Modern Course Schedule App with iOS 26 Liquid Glass Design**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.0+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-2.6.0.21-FF9BAE)](https://github.com/ZongZi2233AI/CourseWidgets/releases/)

English | [简体中文](README.md)

</div>

> **Note**: This application is built entirely with AI-assisted development. Core by [MiMo-V2-Flash](https://github.com/XiaomiMiMo/MiMo-V2-Flash), Windows portion by Claude Opus 4.6, complex implementations by Gemini 3.0 Pro, v2.4+ by Gemini 3.1 Pro.

### **Reminder**: The v2.6.0 release removed some real Liquid Glass code due to unresolved issues. To prioritize build completion, it will be restored around v2.6.0-beta8 (shader refactoring, rendering pipeline optimization, and rendering bug fixes are now complete).

### 📦 Latest Release: [v2.6.0](https://github.com/ZongZi2233AI/CourseWidgets/releases/tag/v2.6.0.21)

The latest version is still unstable and debugging is being accelerated.

## ✨ Core Features

### 🎨 Liquid Glass Design

- Full implementation of Apple iOS 26 Liquid Glass design language
- Real-time shader rendering + Impeller engine
- Unified superellipse (squircle) corners throughout
- Adaptive dark/light mode
- Premium interactive effects: stretch, press feedback, chromatic edge dispersion
- Highly optimized power-saving animations

### 📅 Smart Schedule Management

| Feature | Description |
|---------|-------------|
| ICS Import | Import `.ics` calendar files from other schedule apps |
| HTML Import | Parse HTML schedules exported from school systems |
| Multi-Semester | Unlimited schedule imports with history switching |
| Auto Recognition | Automatic course time, location, and teacher detection |
| Custom Schedule | Flexibly adjust based on school bell schedules |

### 🔔 Smart Notifications

- **Android 16 Live Updates**: Real-time notifications with chronometer countdown (not progress bars)
- **Dual Reminders**: 15 min + 5 min before class
- **System Tray**: Windows tray icon with background running on window close
- **Notification Interaction**: Tap notification to jump to course details

### 🎯 Multi-Platform Support

| Platform | Status | Description |
|----------|--------|-------------|
| ✅ Android | Released | Phone + Tablet landscape adaptation |
| ✅ Windows | Released | Custom window + sidebar navigation + system tray |
| 🔧 macOS | In Development | Contributions welcome |
| 🔧 iOS / iPadOS | In Development | Contributions welcome |
| ❌ Linux | Not Started | Contributions welcome |

### 🌈 Personalization

- Default theme color (Baby Pink gradient)
- Android 12+ **Material You** dynamic colors
- **Monet Color Extraction**: Natively uses `ColorScheme.fromImageProvider` for fast async primary color extraction from any background photo or asset wallpaper.
- Custom background images (supports Android 14+ Photo Picker)

---

## 🚀 Quick Start

### Requirements

```
Flutter SDK    ≥ 3.38.7
Dart SDK       ≥ 3.10.7
AGP            ≥ 9.0
Kotlin         ≥ 2.3
Java           21
```

### Install & Run

```bash
# 1. Clone the repository
git clone https://github.com/ZongZi2233AI/CourseWidgets.git
cd CourseWidgets

# 2. Install dependencies
flutter pub get

# 3. Run (hot reload not recommended for Android, may cause lag)
flutter run -d android    # Android
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d ios        # iOS
```

### Build Release

```bash
# Android (recommended: split ABI + obfuscation)
flutter build apk --split-per-abi --obfuscate --split-debug-info=build/debug-info

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

---

## 📖 User Guide

### Import Schedule

#### Method 1: ICS File
1. Settings → Data Management → Import ICS Calendar
2. Select `.ics` file → Auto parse and import

#### Method 2: HTML Schedule
1. Settings → Data Management → Import HTML Schedule
2. Select HTML file exported from school system → Auto parse

### Course Operations

| Action | Method |
|--------|--------|
| View Courses | Main screen shows current week's course grid |
| Edit Course | Tap course card → Edit |
| Switch Week | Swipe left/right or tap week button |
| Switch Semester | Settings → Data Management → History |

### Theme & Background

1. Settings → General → Theme Color
   - **Default Theme** (Baby Pink)
   - **System Theme** (Material You, Android 12+)
   - **Monet Extraction** (from background image)
2. Settings → General → Change Background Image

---

## 🏗️ Project Structure

```
lib/
├── constants/            # Constants (theme, version)
├── models/               # Data models
├── providers/            # State management (Provider)
├── services/             # Business logic
│   ├── notification_manager.dart       # Unified notification manager
│   ├── live_notification_service_v3.dart  # Android Live Update
│   ├── windows_tray_service.dart       # Windows system tray
│   ├── data_import_service.dart        # Data import
│   └── ...
├── ui/
│   ├── screens/          # Pages
│   │   ├── android_liquid_glass_main.dart   # Android main screen
│   │   ├── windows_custom_window.dart       # Windows custom window
│   │   ├── settings_*.dart                  # Settings pages
│   │   └── ...
│   ├── widgets/          # Components (liquid glass widgets, grids, etc.)
│   └── transitions/      # Page transition animations
└── utils/                # Utilities
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter + Dart |
| **UI** | `liquid_glass_widgets` · `liquid_glass_renderer` · `figma_squircle` |
| **State Management** | Provider |
| **Storage** | SQLite · MMKV |
| **Notifications** | `flutter_local_notifications` · `flutter_foreground_task` |
| **Desktop** | `window_manager` · `tray_manager` |
| **Data** | `icalendar_parser` · `rrule` · `intl` |
| **File** | `file_selector` |

---

## 📝 Development Guide

### Code Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` for code checking

### Commit Format

```
feat: Add new feature      fix: Fix bug
docs: Update docs          style: Code formatting
refactor: Refactoring      chore: Build/tooling
```

---

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push and open a Pull Request

---

## 🗺️ Roadmap

### v2.6.x
Will focus on educational system integration optimization and UI design improvements.

---

## 📄 License

Licensed under the [Apache 2.0 License](LICENSE). Third-party licenses: [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## 📮 Contact

- **Issues**: [GitHub Issues](https://github.com/ZongZi2233AI/CourseWidgets/issues)

## ⭐ Star History

If this project helps you, please give it a Star ⭐

---

**Copyright © 2025-2026 ZongZi** · Made with ❤️ and Flutter
