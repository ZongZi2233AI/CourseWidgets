# CourseWidgets（Made with Vibe Coding）

<div align="center">

<img src="https://github.com/ZongZi2233AI/CourseWidgets/blob/main/assets/icon.png" width="128px">

**液态玻璃设计的大学课程表应用**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.0+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-2.6.0-FF9BAE)](https://github.com/ZongZi2233AI/CourseWidgets/releases/)

[English](README_EN.md) | 简体中文

</div>

> **声明**：本软件除开源代码外完全使用 AI 辅助开发。核心由 [MiMo-V2-Flash](https://github.com/XiaomiMiMo/MiMo-V2-Flash) 构建，Windows 部分使用 Claude Sonnet 4.5，部分复杂实现使用 Gemini 3.0 Pro，v2.4+ 版本由 Gemini 3.1 Pro 构建。

### **提醒** 2.6.0版本移除了部分真实液态玻璃代码，因为存在部分未解决问题，为了优先完成构建，将在大约v2.6.0-beta8等版本恢复

### 📦 最新版本：[v2.6.0](https://github.com/ZongZi2233AI/CourseWidgets/releases/tag/v2.6.0)

#### v2.6.0 (Post v2.5.9 updates) Dev version
```
This update focuses exclusively on User Interface (UI) polishing, data mapping bug fixes, and improving the app's onboarding experience as well as implementing deep scraping logic for targeted educational systems.

What Was Changed
1. UI Bug Fixes & Refinements
Android Title Bar Clipping: Solved the issue where scrollable content inside the main schedule page was clipping abruptly behind the title bar. Uses a Stack overlay for transparent, liquid-glass header styles allowing ListView's padding to scroll underneath smoothly.
Onboarding Reordering: Moved the Personalization (Theme) screen right after the Welcome screen to establish a better user experience flow before configuring details.
Auto-restart App on Final UI: Modified the onboarding flow to physically close the application returning the user to their device launcher utilizing SystemNavigator.pop() upon finishing onboarding. This guarantees fresh MMKV state re-initialization upon their next open instead of hot-restarting the state causing UI glitches.
Unused Lints Resolved: Cleaned up various unresolved Dart analyzer lints left behind by deprecated libraries (like flutter_phoenix).
2. Enhanced Webview Importer & Direct Scrapers
Cookie Retention & Payload Injections: Fully explored and verified that  WebView instances persist standard cookies natively.
Targeted Scripting:
Inserted specific Javascript routines directly into webview_import_screen.dart to sniff logic corresponding to Suwei and Qiangzhi systems.
Added native Javascript fetch() API hooks wrapping form encoded payload calls fetching the internal schedule structures natively without breaking the page interface.
JSON Data Mapping Pipeline: Resolved the bug reported by users stating that "data wasn't showing up after import". Extracted JSON elements fetched by JS directly within Webview are now properly passed to a new importFromJsonData() resolver inside DataImportService, which instantiates CourseEvent blocks.

Reactive UI Rebuilds: Fixed  ScheduleProvider so that after manual or native Webview imports, the system automatically runs _autoCalculateSemesterStart, caches week constraints, recalculates currentWeek/Day, and triggers notifyListeners() which instantly reveals the newly scraped courses on screen instead of requiring a manual app reload.

Verification
Code Quality Checks: Verified all generated internal lints surrounding the new data import service injections using the Dart Analyzer. Addressed TypeCasting (num -> int) issues for cross-platform parsing of Javascript maps.
Navigation Bounds: Ensured isLastPage assertions across the newly shuffled onboarding pages resolve cleanly to "Finish Setup" or "Close App".
```
```
v2.6.0（v2.5.9 更新后）Dev测试中 中文更新内容由谷歌翻译

本次更新主要集中在用户界面 (UI) 优化、数据映射错误修复、改进应用的引导体验以及为特定教育系统实现深度数据抓取逻辑。

更新内容

1. UI 错误修复及优化

Android 标题栏裁剪：修复了主日程页面内可滚动内容被标题栏遮挡的问题。使用 Stack overlay 实现透明的液态玻璃标题样式，使 ListView 的内边距能够平滑滚动。

引导流程重新排序：将个性化（主题）屏幕移至欢迎屏幕之后，以便在配置详细信息之前建立更佳的用户体验流程。

最终界面自动重启应用：修改了引导流程，在完成引导后，使用 SystemNavigator.pop() 强制关闭应用并返回到设备启动器。这确保了下次打开应用时 MMKV 状态的重新初始化，而不是通过热重启状态导致 UI 故障。 1. 修复未使用的 Lint 问题：清理了已弃用库（例如 flutter_phoenix）遗留的各种未解决的 Dart 分析器 Lint 问题。

2. 增强 Webview 导入器和直接抓取器

Cookie 保留和有效负载注入：全面探索并验证了 WebView 实例原生持久化标准 cookie 的功能。

目标脚本：

将特定的 JavaScript 例程直接插入 webview_import_screen.dart，以嗅探与 Suwei 和 Qiangzhi 系统对应的逻辑。

添加了原生 JavaScript fetch() API hook，用于封装表单编码的有效负载调用，从而在不破坏页面界面的情况下原生获取内部日程结构。

JSON 数据映射管道：修复了用户报告的“导入后数据未显示”的错误。现在，Webview 中直接由 JS 获取的提取的 JSON 元素会正确传递给 DataImportService 内部新的 importFromJsonData() 解析器，该解析器会实例化 CourseEvent 块。

响应式 UI 重建：修复了 ScheduleProvider，使其在手动或原生 Webview 导入后，系统会自动运行 `_autoCalculateSemesterStart`，缓存周约束，重新计算当前周/日，并触发 `notifyListeners()`，从而立即在屏幕上显示新抓取的课程，而无需手动重新加载应用程序。

验证

代码质量检查：使用 Dart Analyzer 验证了所有与新数据导入服务注入相关的内部 lint 代码。解决了跨平台解析 JavaScript map 时的类型转换（num -> int）问题。

导航边界：确保新重新排列的引导页面中的 `isLastPage` 断言能够正确解析为“完成设置”或“关闭应用程序”。
```
#### v2.5.9 (beta)更新说明 (2026-03-01)
- 🖥️ **跨平台原生适配**：新增针对 macOS 和 iOS 平台的专属 Layout 支持。macOS 采用全沉浸式底部导航交互，iOS 接驳标准苹果端 UI 设计规范。
- 🎨 **着色器品质飞跃**：再次大幅调优 Liquid Glass 着色器算法：恢复边缘折射（Edge Refraction）和高品质视觉；精简了影响性能的边缘多级算法。
- ⚡ **核心效能 & 锯齿消解**：修复因多层 RepaintBoundary 堆叠以及高斯模糊导致的导航栏抗锯齿掉帧问题，使得帧率回归 120hz。
- 🐛 **Windows 优化修复**：修复当从系统托盘唤醒时的透明度失效 Bug，修复全屏渲染布局受阻的纯白屏/黑边现象；重置 Windows 侧边栏为阴影悬浮按钮，去除厚重感。
- 🪄 **预见式返回动作**：优化 Android 预见式侧滑返回动效逻辑：在退出页面时收缩至小比例，背景页面呈现更加大气的由远及近 3D 回收动画。

#### 关于v2.5.9测试版本的提醒
- 本次测试版尚存在以下已知问题
- 预测式返回存在一些问题，安卓端快速退出可能造成不太好的观感和掉帧
- Windows端大部分已知问题已修复
- 教务系统仍不完善，需要长期优化更新（移动端体验较差等问题）
- Windows端重构了边栏和质感以及窗口
- 新增macOS和iOS的支持但是未经验证请勿轻易尝试
---

## ✨ 核心特性

### 🎨 液态玻璃设计

- 完整实现 Apple iOS 26 Liquid Glass 设计语言
- 真实着色器渲染 + Impeller 引擎加持
- 全局统一超椭圆（Squircle）圆角
- 自适应深色/浅色模式
- 高级交互效果：拉伸、按压反馈、色散边缘
- 极致优化的省电动效

### 📅 智能课表管理

| 功能 | 说明 |
|------|------|
| ICS 导入 | 支持 `.ics` 日历格式，可从其他课程表软件导出 |
| HTML 导入 | 解析从教务系统导出的 HTML 课表 |
| 多学期管理 | 无限导入课表，历史记录切换 |
| 智能识别 | 自动识别课程时间、地点、教师 |
| 自定义时间 | 根据学校作息时间灵活调整 |

### 🔔 智能提醒

- **Android 16 Live Updates**：实时通知 + 计时器倒计时（非进度条）
- **双次提醒**：课前 15 分钟 + 5 分钟
- **系统托盘**：Windows 托盘常驻，关闭窗口后台运行
- **通知交互**：点击通知直达课程详情

### 🎯 多平台支持

| 平台 | 状态 | 说明 |
|------|------|------|
| ✅ Android | 已发布 | 手机 + 平板横屏适配 |
| ✅ Windows | 已发布 | 自定义窗口 + 侧栏导航 + 系统托盘 |
| 🔧 macOS | 开发中 | 欢迎贡献 |
| 🔧 iOS / iPadOS | 开发中 | 欢迎贡献 |
| ❌ Linux | 未开始 | 欢迎贡献 |

### 🌈 个性化

- 默认主题色（Baby Pink 渐变）
- Android 12+ **Material You** 动态颜色
- **莫奈取色**：原生利用 `ColorScheme.fromImageProvider` 从任意背景照片或资产壁纸中极速异步提取主色调。
- 自定义背景图片（支持 Android 14+ Photo Picker）

---

## 🚀 快速开始

### 环境要求

```
Flutter SDK    ≥ 3.38.7
Dart SDK       ≥ 3.10.7
AGP            ≥ 9.0
Kotlin         ≥ 2.3
Java           21
```

### 安装与运行

```bash
# 1. 克隆仓库
git clone https://github.com/ZongZi2233AI/CourseWidgets.git
cd CourseWidgets

# 2. 安装依赖
flutter pub get

# 3. 运行（不建议 Android 使用热重载，会很卡）
flutter run -d android    # Android
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d ios        # iOS
```

### 构建发布版本

```bash
# Android（推荐分包 + 代码混淆）
flutter build apk --split-per-abi --obfuscate --split-debug-info=build/debug-info

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

---

## 📖 使用指南

### 导入课表

#### 方法 1: ICS 文件
1. 设置 → 数据管理 → 导入 ICS 日历
2. 选择 `.ics` 文件 → 自动解析导入

#### 方法 2: HTML 课表
1. 设置 → 数据管理 → 导入 HTML 课表
2. 选择教务系统导出的 HTML 文件 → 自动解析

### 课程操作

| 操作 | 方式 |
|------|------|
| 查看课程 | 主界面显示本周课程网格 |
| 编辑课程 | 点击课程卡片 → 编辑 |
| 切换周次 | 左右滑动或点击周次按钮 |
| 切换学期 | 设置 → 数据管理 → 历史记录 |

### 主题与背景

1. 设置 → 通用设置 → 主题色
   - **默认主题**（Baby Pink）
   - **系统主题**（Material You, Android 12+）
   - **莫奈取色**（从背景提取）
2. 设置 → 通用设置 → 更换背景图片

---

## 🏗️ 项目结构

```
lib/
├── constants/            # 常量（主题、版本）
├── models/               # 数据模型
├── providers/            # 状态管理（Provider）
├── services/             # 业务逻辑
│   ├── notification_manager.dart       # 统一通知管理
│   ├── live_notification_service_v3.dart  # Android Live Update
│   ├── windows_tray_service.dart       # Windows 系统托盘
│   ├── data_import_service.dart        # 数据导入
│   └── ...
├── ui/
│   ├── screens/          # 页面
│   │   ├── android_liquid_glass_main.dart   # Android 主界面
│   │   ├── windows_custom_window.dart       # Windows 自定义窗口
│   │   ├── settings_*.dart                  # 设置页面
│   │   └── ...
│   ├── widgets/          # 组件（液态玻璃组件、网格等）
│   └── transitions/      # 页面过渡动画
└── utils/                # 工具类
```

---

## 🛠️ 技术栈

| 类别 | 技术 |
|------|------|
| **框架** | Flutter + Dart |
| **UI** | `liquid_glass_widgets` · `liquid_glass_renderer` · `figma_squircle` |
| **状态管理** | Provider |
| **存储** | SQLite · MMKV |
| **通知** | `flutter_local_notifications` · `flutter_foreground_task` |
| **桌面** | `window_manager` · `tray_manager` |
| **数据** | `icalendar_parser` · `rrule` · `intl` |
| **文件** | `file_selector` |

---

## 📝 开发指南

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范
- 使用 `flutter_lints` 代码检查

### 提交格式

```
feat: 添加新功能      fix: 修复 bug
docs: 文档更新        style: 代码格式
refactor: 重构        chore: 构建/工具
```

---

## 🤝 贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送并开启 Pull Request

---

## 🗺️ 路线图

### v2.6.x
将着重在教务系统优化和UI设计改进上

---

## 📄 许可证

基于 [Apache 2.0 许可证](LICENSE) 开源。第三方依赖许可证见 [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)。

## 📮 联系

- **问题反馈**: [GitHub Issues](https://github.com/ZongZi2233AI/CourseWidgets/issues)

## ⭐ Star History

如果这个项目对你有帮助，请给一个 Star ⭐

---

**Copyright © 2025-2026 ZongZi** · Made with ❤️ and Flutter
