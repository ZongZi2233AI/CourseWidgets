import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';
import '../providers/schedule_provider.dart';
import 'notification_manager.dart';

/// [v2.2.8] Windows 系统托盘服务 - 使用 tray_manager
class WindowsTrayService with TrayListener {
  static final WindowsTrayService _instance = WindowsTrayService._internal();
  factory WindowsTrayService() => _instance;

  WindowsTrayService._internal();

  bool _isInitialized = false;
  bool _isBackgroundMode = false;
  final NotificationManager _notificationManager = NotificationManager();

  /// 初始化托盘服务
  Future<void> initialize() async {
    if (kIsWeb || !Platform.isWindows) {
      debugPrint('⚠️ 非 Windows 平台，跳过托盘服务初始化');
      return;
    }

    if (_isInitialized) return;

    try {
      // 初始化通知管理器
      await _notificationManager.initialize();

      // 初始化系统托盘
      await _initializeSystemTray();

      _isInitialized = true;
      debugPrint('✅ Windows 托盘服务初始化成功');
    } catch (e) {
      debugPrint('❌ 初始化托盘服务失败: $e');
    }
  }

  /// 初始化系统托盘
  Future<void> _initializeSystemTray() async {
    try {
      // 查找托盘图标
      String iconPath = await _findTrayIcon();
      debugPrint('🎨 托盘图标路径: $iconPath');

      // 设置托盘图标
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('CourseWidgets - 课程表');

      // 创建托盘菜单
      await _createTrayMenu();

      // 注册事件监听
      trayManager.addListener(this);

      debugPrint('✅ Windows 托盘初始化完成');
    } catch (e, stackTrace) {
      debugPrint('❌ 初始化 Windows 托盘失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }

  /// 查找托盘图标 — 必须返回绝对路径（tray_manager 要求）
  Future<String> _findTrayIcon() async {
    final String exePath = Platform.resolvedExecutable;
    final String exeDir = path.dirname(exePath);

    // 候选路径（按优先级）
    final candidates = [
      // [v2.4.9] 优先使用 32x32 的 tray_icon.ico（系统托盘专用）
      path.join(exeDir, 'data', 'flutter_assets', 'assets', 'tray_icon.ico'),
      path.join(exeDir, 'data', 'flutter_assets', 'assets', 'app_icon.ico'),
      path.join(exeDir, 'assets', 'tray_icon.ico'),
      path.join(exeDir, 'assets', 'app_icon.ico'),
      path.join(exeDir, 'app_icon.ico'),
      // Debug 模式：从项目根目录查找
      path.join(Directory.current.path, 'assets', 'tray_icon.ico'),
      path.join(Directory.current.path, 'assets', 'app_icon.ico'),
      path.join(
        Directory.current.path,
        'windows',
        'runner',
        'resources',
        'app_icon.ico',
      ),
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        debugPrint('✅ 找到托盘图标: $candidate');
        return candidate;
      }
    }

    // 最后的回退
    debugPrint('⚠️ 未找到托盘图标，使用默认路径');
    return path.join(
      exeDir,
      'data',
      'flutter_assets',
      'assets',
      'app_icon.ico',
    );
  }

  /// 创建托盘菜单
  Future<void> _createTrayMenu() async {
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show', label: '显示窗口'),
        MenuItem.separator(),
        MenuItem(key: 'notification', label: '通知设置'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: '退出'),
      ],
    );
    await trayManager.setContextMenu(menu);
    debugPrint('✅ 托盘菜单设置成功');
  }

  // TrayListener 回调
  @override
  void onTrayIconMouseDown() {
    // 左键点击显示窗口
    _showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击显示菜单
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'notification':
        _showWindow();
        // TODO: 导航到通知设置页面
        break;
      case 'exit':
        _exitApp();
        break;
    }
  }

  /// 退出应用
  Future<void> _exitApp() async {
    await dispose();
    await windowManager.destroy();
    exit(0); // [v2.4.8] 确保 Dart isolate 终止
  }

  /// 显示窗口
  Future<void> _showWindow() async {
    try {
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      }
      await windowManager.show();
      await windowManager.focus();
      _isBackgroundMode = false;
      debugPrint('📱 窗口已显示');
    } catch (e) {
      debugPrint('❌ 显示窗口失败: $e');
    }
  }

  /// 启动课程提醒
  void startCourseReminder(ScheduleProvider provider) {
    if (!Platform.isWindows) return;

    final courses = provider.courses;
    _notificationManager.startCourseCheck(courses);

    debugPrint('🔔 Windows 课程提醒已启动');
  }

  /// 停止课程提醒
  void stopCourseReminder() {
    _notificationManager.stopCourseCheck();
    debugPrint('🛑 Windows 课程提醒已停止');
  }

  /// 进入后台模式（最小化到托盘）
  Future<void> enterBackgroundMode() async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.hide();
      _isBackgroundMode = true;
      debugPrint('🌙 已进入后台模式');
    } catch (e) {
      debugPrint('❌ 进入后台模式失败: $e');
    }
  }

  /// 退出后台模式（显示窗口）
  Future<void> exitBackgroundMode() async {
    await _showWindow();
  }

  /// 检查是否在后台模式
  bool get isBackgroundMode => _isBackgroundMode;

  /// 清理资源
  Future<void> dispose() async {
    _notificationManager.stopCourseCheck();
    trayManager.removeListener(this);
    await trayManager.destroy();

    _isInitialized = false;
    _isBackgroundMode = false;

    debugPrint('🧹 Windows 托盘服务已清理');
  }
}
