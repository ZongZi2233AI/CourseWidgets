# CourseWidgets（Made with Vibe Coding）

<div align="center">

<img src="https://github.com/ZongZi2233AI/CourseWidgets/blob/main/assets/icon.png" width="128px">

**液态玻璃设计的大学课程表应用**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.2+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.7+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-2.5.9-FF9BAE)](https://github.com/ZongZi2233AI/CourseWidgets/releases)

[English](README_EN.md) | 简体中文

</div>

> **声明**：本软件除开源代码外完全使用 AI 辅助开发。核心由 [MiMo-V2-Flash](https://github.com/XiaomiMiMo/MiMo-V2-Flash) 构建，Windows 部分使用 Claude Sonnet 4.5，部分复杂实现使用 Gemini 3.0 Pro，v2.4+ 版本由 Gemini 3.1 Pro 构建。

### 📦 最新版本：[v2.5.9](https://github.com/ZongZi2233AI/CourseWidgets/releases/tag/v2.5.9)

#### v2.5.9 更新说明 (2026-03-01)
- 🖥️ **跨平台原生适配**：新增针对 macOS 和 iOS 平台的专属 Layout 支持。macOS 采用全沉浸式底部导航交互，iOS 接驳标准苹果端 UI 设计规范。
- 🎨 **着色器品质飞跃**：再次大幅调优 Liquid Glass 着色器算法：恢复边缘折射（Edge Refraction）和高品质视觉；精简了影响性能的边缘多级算法。
- ⚡ **核心效能 & 锯齿消解**：修复因多层 RepaintBoundary 堆叠以及高斯模糊导致的导航栏抗锯齿掉帧问题，使得帧率回归 120hz。
- 🐛 **Windows 优化修复**：修复当从系统托盘唤醒时的透明度失效 Bug，修复全屏渲染布局受阻的纯白屏/黑边现象；重置 Windows 侧边栏为阴影悬浮按钮，去除厚重感。
- 🪄 **预见式返回动作**：优化 Android 预见式侧滑返回动效逻辑：在退出页面时收缩至小比例，背景页面呈现更加大气的由远及近 3D 回收动画。

#### v2.5.7 更新说明 (2026-02-28)
- 🎨 **UI 质感跃升**：移除了标准玻璃全局灰色硬描边框，全局采用自然的高光阴影来界定边界，保留了侧面金属反射亮度。
- ⚡ **动画与体验优化**：
  - **预测返回优化**：修复了二三级界面滑动时背景闪现上一页的问题，新增从 0.95 到 1.0 的平滑缩放与淡入过渡。
  - **Windows 核心体验**：修复全屏时 DPI 异常（半黑半挤压）问题，以及最小化/恢复时的黑色底板闪烁问题。
  - **加载体验提升**：适配系统深色/浅色模式，修复 App 启动时的短暂黑屏闪烁。
- 🐛 **问题修复**：
  - 修复主题色设置菜单弹出时存在多重灰色拖动条 (DragHandle) 的问题。
  - 完美适配并解决了 AGP 9.0 相关的编译兼容性警告。

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

### v2.5.x — 功能演进与性能极致打磨

- [x] Windows 嵌套 Navigator 路由重构（保留标题栏与动画，DWM 原生缩放，杜绝 GPU NaN 死锁）
- [x] 完全纯正的 Android 14+ 预见式侧滑手势返回与卡片压感联动视差
- [x] 莫奈全局取色引擎升级，支持全资源异步快速萃取
- [ ] 课程冲突检测算法优化
- [ ] 课表导出为 PDF/图片 功能
- [ ] Apple Watch / WearOS 同步支持

---

## 📄 许可证

基于 [Apache 2.0 许可证](LICENSE) 开源。第三方依赖许可证见 [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)。

## 📮 联系

- **问题反馈**: [GitHub Issues](https://github.com/ZongZi2233AI/CourseWidgets/issues)

## ⭐ Star History

如果这个项目对你有帮助，请给一个 Star ⭐

---

**Copyright © 2025-2026 ZongZi** · Made with ❤️ and Flutter
