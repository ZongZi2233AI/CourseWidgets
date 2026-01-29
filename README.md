# CourseWidgets

<div align="center">

![CourseWidgets Logo](assets/icon.png)

**一款采用 iOS 26 液态玻璃设计的现代化课程表应用**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.7+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.7+-0175C2?logo=dart)](https://dart.dev)

[English](README_EN.md) | 简体中文

</div>

## ✨ 特性

### 🎨 液态玻璃设计
- 完整实现 Apple iOS 26 液态玻璃设计系统
- Premium 级别渲染质量
- 流畅的动画和交互效果
- 自适应深色/浅色模式

### 📅 智能课表管理
- 支持 ICS 日历格式导入
- 支持 HTML 课表解析
- 自动识别课程时间和地点
- 多学期课表管理
- 历史记录切换

### 🔔 智能提醒
- Android 16 Live Updates 实时通知
- 课程开始前自动提醒
- 通知点击直达课程详情
- 系统托盘集成（Windows/macOS）

### 🎯 多平台支持
- ✅ Android (手机 & 平板)
- ✅ Windows (桌面)
- ✅ macOS (桌面)
- ✅ iOS (手机 & 平板)
- ✅ Linux (桌面)

### 🌈 个性化主题
- 默认嫩粉色主题
- Android 12+ Material You 动态颜色
- 莫奈取色（从背景图片提取主题色）
- 自定义背景图片

## 📸 截图

### Android 平板端
- 液态玻璃主界面
- 圆角矩形导航栏
- 本周课程网格视图
- 底部弹出菜单

### Windows 桌面端
- 自定义窗口标题栏
- 系统托盘集成
- 课程网格视图
- 设置界面

### iOS 风格
- Cupertino 设计语言
- 液态玻璃组件
- 流畅的页面切换
- 原生交互体验

## 🚀 快速开始

### 环境要求

- Flutter SDK: 3.38.7+
- Dart SDK: 3.10.7+
- Android Studio / VS Code
- Xcode (macOS/iOS 开发)
- Visual Studio (Windows 开发)

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/coursewidgets.git
cd coursewidgets
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
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

### 构建发布版本

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

## 📖 使用指南

### 导入课表

#### 方法 1: ICS 文件导入
1. 打开设置 → 数据管理
2. 点击"导入 ICS 日历"
3. 选择 `.ics` 文件
4. 自动解析并导入课程

#### 方法 2: HTML 课表导入
1. 打开设置 → 数据管理
2. 点击"导入 HTML 课表"
3. 选择学校教务系统导出的 HTML 文件
4. 自动解析课程信息

### 课程管理

- **查看课程**: 主界面显示本周课程网格
- **编辑课程**: 点击课程卡片 → 编辑
- **切换周次**: 左右滑动或点击周次按钮
- **切换学期**: 设置 → 数据管理 → 历史记录管理

### 主题设置

1. 打开设置 → 通用设置 → 主题色设置
2. 选择主题模式：
   - **默认主题**: 嫩粉色渐变
   - **系统主题**: Material You 动态颜色 (Android 12+)
   - **莫奈取色**: 从背景图片提取主题色

### 背景图片

1. 打开设置 → 通用设置
2. 点击"更换背景图片"
3. 选择图片（支持 Android 14+ Photo Picker）
4. 如使用莫奈取色，主题色将自动更新

## 🏗️ 项目结构

```
lib/
├── constants/          # 常量定义
│   ├── theme_constants.dart
│   └── version.dart
├── models/            # 数据模型
│   ├── course.dart
│   ├── course_event.dart
│   └── schedule_config.dart
├── providers/         # 状态管理
│   └── schedule_provider.dart
├── services/          # 业务逻辑
│   ├── database_helper.dart
│   ├── data_import_service.dart
│   ├── html_to_ics_converter.dart
│   ├── ics_parser.dart
│   ├── live_notification_service_v2.dart
│   ├── storage_service.dart
│   ├── theme_service.dart
│   └── windows_tray_service.dart
├── ui/                # 用户界面
│   ├── screens/       # 页面
│   │   ├── android_liquid_glass_main.dart
│   │   ├── windows_schedule_screen.dart
│   │   ├── macos_schedule_screen.dart
│   │   ├── settings_*.dart
│   │   └── ...
│   └── widgets/       # 组件
│       ├── liquid_components.dart
│       ├── liquid_glass_pickers.dart
│       ├── tablet_sidebar.dart
│       └── weekly_schedule_grid.dart
└── utils/             # 工具类
    └── responsive_utils.dart
```

## 🛠️ 技术栈

### 核心框架
- **Flutter**: 跨平台 UI 框架
- **Dart**: 编程语言

### UI 组件
- **liquid_glass_widgets**: 液态玻璃组件库
- **liquid_glass_renderer**: 液态玻璃渲染引擎
- **figma_squircle**: 超椭圆形状

### 状态管理
- **Provider**: 轻量级状态管理

### 数据存储
- **SQLite**: 本地数据库
- **MMKV**: 高性能键值存储

### 平台特性
- **flutter_local_notifications**: 本地通知
- **window_manager**: 窗口管理 (桌面)
- **system_tray**: 系统托盘 (桌面)
- **file_selector**: 文件选择器

### 数据处理
- **icalendar_parser**: ICS 日历解析
- **rrule**: 重复规则处理
- **intl**: 国际化支持

## 📝 开发指南

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范
- 使用 `flutter_lints` 进行代码检查
- 保持代码简洁，避免过度注释

### 提交规范

```
feat: 添加新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具链更新
```

### 分支管理

- `main`: 稳定版本
- `develop`: 开发版本
- `feature/*`: 新功能分支
- `fix/*`: Bug 修复分支

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目基于 [Apache 2.0 许可证](LICENSE) 开源。

### 第三方许可证

所有第三方依赖的许可证信息请查看 [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)。

主要依赖许可证：
- Flutter Framework: BSD 3-Clause
- liquid_glass_widgets: MIT
- liquid_glass_renderer: MIT
- MMKV: BSD 3-Clause
- Provider: MIT

## 🙏 致谢

- [Flutter](https://flutter.dev) - 优秀的跨平台框架
- [liquid_glass_widgets](https://pub.dev/packages/liquid_glass_widgets) - 液态玻璃组件库
- [liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer) - 液态玻璃渲染引擎
- 所有开源贡献者

## 📮 联系方式

- **作者**: ZongZi
- **邮箱**: your.email@example.com
- **问题反馈**: [GitHub Issues](https://github.com/yourusername/coursewidgets/issues)

## 🗺️ 路线图

### v2.3.0 (计划中)
- [ ] 课程冲突检测
- [ ] 课程统计分析
- [ ] 导出为 PDF
- [ ] 云同步支持

### v2.4.0 (计划中)
- [ ] 小组件支持
- [ ] Apple Watch 支持
- [ ] 更多主题选项
- [ ] AI 课表识别

## ⭐ Star History

如果这个项目对你有帮助，请给一个 Star ⭐

---

**Copyright © 2025-2026 ZongZi**  
Made with ❤️ and Flutter
