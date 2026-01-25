# CourseWidgets

<div align="center">

![CourseWidgets Logo](assets/icon.png)

**A Modern Course Schedule App with iOS 26 Liquid Glass Design**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.7+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.7+-0175C2?logo=dart)](https://dart.dev)

English | [简体中文](README.md)

</div>

## ✨ Features

### 🎨 Liquid Glass Design
- Full implementation of Apple iOS 26 Liquid Glass design system
- Premium quality rendering
- Smooth animations and interactions
- Adaptive dark/light mode

### 📅 Smart Schedule Management
- ICS calendar format import
- HTML schedule parsing
- Automatic course time and location recognition
- Multi-semester schedule management
- History switching

### 🔔 Smart Notifications
- Android 16 Live Updates real-time notifications
- Automatic reminders before class
- Tap notification to view course details
- System tray integration (Windows/macOS)

### 🎯 Multi-Platform Support
- ✅ Android (Phone & Tablet)
- ✅ Windows (Desktop)
- ✅ macOS (Desktop)
- ✅ iOS (Phone & Tablet)
- ✅ Linux (Desktop)

### 🌈 Personalized Themes
- Default baby pink theme
- Android 12+ Material You dynamic colors
- Monet color extraction (from background image)
- Custom background images

## 🚀 Quick Start

### Requirements

- Flutter SDK: 3.38.7+
- Dart SDK: 3.10.7+
- Android Studio / VS Code
- Xcode (for macOS/iOS development)
- Visual Studio (for Windows development)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/coursewidgets.git
cd coursewidgets
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 📖 User Guide

### Import Schedule

#### Method 1: ICS File Import
1. Open Settings → Data Management
2. Tap "Import ICS Calendar"
3. Select `.ics` file
4. Automatically parse and import courses

#### Method 2: HTML Schedule Import
1. Open Settings → Data Management
2. Tap "Import HTML Schedule"
3. Select HTML file exported from school system
4. Automatically parse course information

### Course Management

- **View Courses**: Main screen shows weekly course grid
- **Edit Course**: Tap course card → Edit
- **Switch Week**: Swipe left/right or tap week button
- **Switch Semester**: Settings → Data Management → History Management

### Theme Settings

1. Open Settings → General Settings → Theme Settings
2. Select theme mode:
   - **Default Theme**: Baby pink gradient
   - **System Theme**: Material You dynamic colors (Android 12+)
   - **Monet Colors**: Extract colors from background image

### Background Image

1. Open Settings → General Settings
2. Tap "Change Background Image"
3. Select image (supports Android 14+ Photo Picker)
4. If using Monet colors, theme will update automatically

## 🛠️ Tech Stack

### Core Framework
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language

### UI Components
- **liquid_glass_widgets**: Liquid glass component library
- **liquid_glass_renderer**: Liquid glass rendering engine
- **figma_squircle**: Superellipse shapes

### State Management
- **Provider**: Lightweight state management

### Data Storage
- **SQLite**: Local database
- **MMKV**: High-performance key-value storage

### Platform Features
- **flutter_local_notifications**: Local notifications
- **window_manager**: Window management (desktop)
- **system_tray**: System tray (desktop)
- **file_selector**: File picker

### Data Processing
- **icalendar_parser**: ICS calendar parsing
- **rrule**: Recurrence rule processing
- **intl**: Internationalization support

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the [Apache 2.0 License](LICENSE).

### Third-Party Licenses

For all third-party dependency licenses, see [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

Main dependency licenses:
- Flutter Framework: BSD 3-Clause
- liquid_glass_widgets: MIT
- liquid_glass_renderer: MIT
- MMKV: BSD 3-Clause
- Provider: MIT

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Excellent cross-platform framework
- [liquid_glass_widgets](https://pub.dev/packages/liquid_glass_widgets) - Liquid glass component library
- [liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer) - Liquid glass rendering engine
- All open source contributors

## 📮 Contact

- **Author**: ZongZi
- **Email**: your.email@example.com
- **Issues**: [GitHub Issues](https://github.com/yourusername/coursewidgets/issues)

## 🗺️ Roadmap

### v2.3.0 (Planned)
- [ ] Course conflict detection
- [ ] Course statistics
- [ ] Export to PDF
- [ ] Cloud sync support

### v2.4.0 (Planned)
- [ ] Widget support
- [ ] Apple Watch support
- [ ] More theme options
- [ ] AI schedule recognition

## ⭐ Star History

If this project helps you, please give it a Star ⭐

---

**Copyright © 2025-2026 ZongZi**  
Made with ❤️ and Flutter
