# CourseWidgets（完全使用AI生成，将在几天内开源本软件）

<div align="center">

![CourseWidgets Logo](assets/icon.png)

**液态玻璃设计的大学课程表应用**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.7+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.7+-0175C2?logo=dart)](https://dart.dev)

[English](README_EN.md) | 简体中文

</div>
Made With https://github.com/XiaomiMiMo/MiMo-V2-Flash
# 声明：本软件除开源代码完全使用MiMo-V2-Flash开发（几乎本文档和license也由ai构建），Windows部分使用Claude Sonnet 4.5开发，图标和部分复杂实现指导使用Gemini3.0Pro

## ✨ 特性

### 🎨 液态玻璃设计
- 模拟Liquid Glass Design的UI样式
- 真实的着色器渲染
- 全新Impeller引擎加持和极致优化省电的动效
- 自适应深色/浅色模式
- 测试期间有可能会出现渲染错误问题等
- 全局统一超椭圆圆角（部分对话框尚未实现统一，将在未来重构）

### 📅 智能课表管理
- 支持 ICS 格式导入（可以通过其他课程表软件导出导入）
- 支持 HTML 课表解析（就是其他课程表在教务网站导出的数据，现在导入的存在一些无法合并数据的问题）
- 自动识别课程时间和地点
- 多学期课表管理
- 无限导入课表（历史记录）切换
- 有其他导入课表方法可以告诉我，再来开发
- 记得根据学校作息时间调整

### 🔔 智能提醒
- Android 16 Live Updates 实时通知及HyperOS3.0.300.x + 超级岛通知（暂未实现，AI不知道api长啥样）
- 课程开始前自动提醒（安卓似乎可以实现）
- 通知点击直达课程详情（emmm没试过）
- 系统托盘集成（Windows/macOS）（暂未实现，代码存在问题）

### 🎯 多平台支持
- ✅ Android
- ✅ Android平板
- ✅ Windows
- ✅ macOS（正在准备开发，欢迎加入开发或自行开发）
- ✅ iOS (正在准备开发，欢迎加入开发或自行开发）
- ✅ iPad OS（正在准备开发，欢迎加入开发或自行开发）
- ❎ Linux 暂时没有开发计划，欢迎加入开发

### 🌈 个性化色彩
- 默认主题色彩同软件图标（由Nano Banana Pro自行设计和生成）
- Android 12+ Material You 动态颜色
- 提取背景主色（莫奈取色）
- 自定义背景图片

## 🚀 快速开始

### 环境要求

- Flutter SDK: 3.38.7+
- Dart SDK: 3.10.7+
- Android Studio / VS Code
- Xcode (macOS/iOS 开发)
- Visual Studio 2026/微软大战代码 (Windows 开发)
- AGP9.0+
- kotlin2.3+
- java 21

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/ZongZi2233AI/CourseWidgets.git
cd CourseWidgets
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**（不建议使用热重载模式测试安卓端因为很卡）
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

### 构建发布版本（建议开启分包和代码混淆）

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
3. 选择从教务系统导出的 HTML 文件（通过其他软件也可以，要是不可以你把文件发给我我让ai看看）
4. 自动解析课程信息

### 课程管理

- **查看课程**: 主界面显示本周课程网格
- **编辑课程**: 点击课程卡片 → 编辑
- **切换周次**: 左右滑动或点击周次按钮
- **切换学期**: 设置 → 数据管理 → 历史记录管理

### 主题设置

1. 打开设置 → 通用设置 → 主题色设置
2. 选择主题模式：
   - **默认主题**
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

## 📮 联系方式
- **问题反馈**: [GitHub Issues](https://github.com/ZongZi2233AI/CourseWidgets/issues)

## 🗺️ 路线图

### v2.3.0
#### 该大版本将在未来发布，请提供意见和反馈（通过issue）可能会更新以下内容
- [ ] 修复Windows端渲染问题
- [ ] 修复全局统一圆角覆盖问题
- [ ] 修复着色器掉帧问题
- [ ] 更多的导入数据方式
- [ ] ...


## ⭐ Star History

如果这个项目对你有帮助，请给一个 Star ⭐

---

**Copyright © 2025-2026 ZongZi**  
Made with ❤️ and Flutter
