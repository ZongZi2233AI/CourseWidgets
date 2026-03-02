# CourseWidgets

<div align="center">

<img src="https://github.com/ZongZi2233AI/CourseWidgets/blob/main/assets/icon.png" width="128px">

**A Modern Course Schedule App with iOS 26 Liquid Glass Design**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.7+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-2.5.8-FF9BAE)](https://github.com/ZongZi2233AI/CourseWidgets/releases)

English | [简体中文](README.md)

</div>

> **Note**: This application is built entirely with AI-assisted development — [MiMo-V2-Flash](https://github.com/XiaomiMiMo/MiMo-V2-Flash), Claude Sonnet 4.5, Gemini 3.0 Pro, and Gemini 3.1 Pro.

### 📦 Latest Release: [v2.5.7](https://github.com/ZongZi2233AI/CourseWidgets/releases/tag/v2.5.7)

#### v2.5.7 Release Notes (2026-02-28)
- 🎨 **UI Quality Leap**: Removed the global grey hard stroke border from standard glass, universally adopting natural specular shadows to define boundaries while preserving side metallic reflections.
- ⚡ **Animation & Experience Optimization**:
  - **Predictive Back Optimization**: Fixed the issue where the background flashes to the previous page during 2nd/3rd level page swiping, adding a smooth 0.95 to 1.0 scaling and fade-in transition.
  - **Windows Core Experience**: Fixed DPI anomalies during full screen (half black/squished) and the black background flashing issue during minimize/restore.
  - **Loading Experience Improvement**: Adapted to system dark/light modes, fixing the brief black screen flash on app launch.
- 🐛 **Bug Fixes**:
  - Fixed the issue with multiple grey DragHandles appearing when the theme color settings menu pops up.
  - Perfectly adapted to and resolved compilation compatibility warnings related to AGP 9.0.

---

## ✨ Features

### 🎨 Liquid Glass Design
- Full implementation of Apple iOS 26 Liquid Glass design system
- Real-time shader rendering with Impeller engine
- Unified superellipse (squircle) corners throughout
- Adaptive dark/light mode
- Premium interactive effects: stretch, press feedback, chromatic aberration

### 📅 Smart Schedule Management

| Feature | Description |
|---------|-------------|
| ICS Import | Import `.ics` calendar files from other apps |
| HTML Import | Parse HTML schedules exported from school systems |
| Multi-Semester | Unlimited schedule imports with history switching |
| Auto Recognition | Automatic course time, location, and teacher detection |

### 🔔 Smart Notifications
- **Android 16 Live Updates**: Real-time notifications with chronometer (not progress bars)
- **Dual Reminders**: 15 min + 5 min before class
- **System Tray**: Windows tray icon with background operation
- **Click to View**: Tap notification to jump to course details

### 🎯 Multi-Platform

| Platform | Status |
|----------|--------|
| ✅ Android | Released (Phone + Tablet) |
| ✅ Windows | Released (Custom window + sidebar + tray) |
| 🔧 macOS | In development |
| 🔧 iOS / iPadOS | In development |
| ❌ Linux | Contributions welcome |

### 🌈 Personalization
- Default baby pink gradient theme
- Android 12+ **Material You** dynamic colors
- **Monet color extraction** from background images
- Custom background images (Android 14+ Photo Picker)

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
# 1. Clone
git clone https://github.com/ZongZi2233AI/CourseWidgets.git
cd CourseWidgets

# 2. Dependencies
flutter pub get

# 3. Run
flutter run -d android    # Android
flutter run -d windows    # Windows
flutter run -d macos      # macOS
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

| Method | Steps |
|--------|-------|
| **ICS File** | Settings → Data → Import ICS Calendar → Select `.ics` file |
| **HTML File** | Settings → Data → Import HTML Schedule → Select HTML from school system |

### Course Management

| Action | How |
|--------|-----|
| View | Main screen shows weekly course grid |
| Edit | Tap course card → Edit |
| Switch Week | Swipe left/right or tap week button |
| Switch Semester | Settings → Data → History |

### Theme & Background

1. Settings → General → Theme Color
   - **Default** (Baby Pink) · **System** (Material You) · **Monet** (from background)
2. Settings → General → Change Background Image

---

## 🏗️ Project Structure

```
lib/
├── constants/            # Theme & version constants
├── models/               # Data models
├── providers/            # State management (Provider)
├── services/             # Business logic
│   ├── notification_manager.dart       # Unified notification manager
│   ├── live_notification_service_v3.dart  # Android Live Update
│   ├── windows_tray_service.dart       # Windows system tray
│   └── ...
├── ui/
│   ├── screens/          # Pages (Android, Windows, macOS, Settings)
│   ├── widgets/          # Liquid glass components, grids
│   └── transitions/      # Page transition animations
└── utils/                # Utilities
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter + Dart |
| **UI** | `liquid_glass_widgets` · `liquid_glass_renderer` · `figma_squircle` |
| **State** | Provider |
| **Storage** | SQLite · MMKV |
| **Notifications** | `flutter_local_notifications` · `flutter_foreground_task` |
| **Desktop** | `window_manager` · `tray_manager` |
| **Data** | `icalendar_parser` · `rrule` · `intl` |

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Push and open a Pull Request

---

## 🗺️ Roadmap

### v2.5.0 — Planned

- [ ] Nested Navigator for Windows secondary pages
- [ ] Native Android Live Update via MethodChannel
- [ ] Course conflict detection
- [ ] Export to PDF
- [ ] Apple Watch / WearOS support

---

## 📄 License

Licensed under the [Apache 2.0 License](LICENSE). Third-party licenses: [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## 📮 Contact

- **Issues**: [GitHub Issues](https://github.com/ZongZi2233AI/CourseWidgets/issues)

## ⭐ Star History

If this project helps you, please give it a Star ⭐

---

---

## 📦 Open Source Dependencies

This software utilizes the following exceptional open-source projects. We express our sincere gratitude to the original authors and the community. For detailed license texts, please refer to: [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)

| Project Name | License | Homepage |
| :--- | :--- | :--- |
| **Flutter Framework** | BSD 3-Clause | `https://github.com/flutter/flutter` |
| **Cupertino Icons** | MIT | `https://pub.dev/packages/cupertino_icons` |
| **File Selector** | BSD 3-Clause | `https://pub.dev/packages/file_selector` |
| **MMKV** | BSD 3-Clause | `https://pub.dev/packages/mmkv` |
| **Image** | MIT | `https://pub.dev/packages/image` |
| **Material Color Utilities** | Apache 2.0 | `https://pub.dev/packages/material_color_utilities` |
| **SQLite (sqflite)** | MIT | `https://pub.dev/packages/sqflite` |
| **iCalendar Parser** | MIT | `https://pub.dev/packages/icalendar_parser` |
| **RRule** | MIT | `https://pub.dev/packages/rrule` |
| **Intl** | BSD 3-Clause | `https://pub.dev/packages/intl` |
| **Timezone** | BSD 3-Clause | `https://pub.dev/packages/timezone` |
| **System Tray** | MIT | `https://pub.dev/packages/system_tray` |
| **Flutter Local Notifications** | BSD 3-Clause | `https://pub.dev/packages/flutter_local_notifications` |
| **Permission Handler** | MIT | `https://pub.dev/packages/permission_handler` |
| **Provider** | MIT | `https://pub.dev/packages/provider` |
| **Fluent UI** | BSD 3-Clause | `https://pub.dev/packages/fluent_ui` |
| **Window Manager** | MIT | `https://pub.dev/packages/window_manager` |
| **Figma Squircle** | MIT | `https://pub.dev/packages/figma_squircle` |
| **Liquid Glass Renderer** | MIT | `https://pub.dev/packages/liquid_glass_renderer` |
| **Liquid Glass Widgets** | MIT | `https://pub.dev/packages/liquid_glass_widgets` |
| **WebView Flutter** | BSD 3-Clause | `https://pub.dev/packages/webview_flutter` |
| **WebView Windows** | MIT | `https://pub.dev/packages/webview_windows` |
| **URL Launcher** | BSD 3-Clause | `https://pub.dev/packages/url_launcher` |
| **Local Notifier** | MIT | `https://pub.dev/packages/local_notifier` |
| **System Theme** | MIT | `https://pub.dev/packages/system_theme` |
| **Flutter Phoenix** | MIT | `https://pub.dev/packages/flutter_phoenix` |

**Copyright © 2025-2026 ZongZi** · Made with ❤️ and Flutter
