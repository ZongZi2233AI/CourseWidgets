import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/schedule_provider.dart';
import 'notification_manager.dart';

/// [v2.2.8] Windows 系统托盘服务 - 重构版
/// 使用统一的通知管理器
class WindowsTrayService {
  static final WindowsTrayService _instance = WindowsTrayService._internal();
  factory WindowsTrayService() => _instance;
  
  WindowsTrayService._internal();

  SystemTray? _systemTray;
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
      _systemTray = SystemTray();

      // 查找托盘图标
      String iconPath = await _findTrayIcon();
      
      debugPrint('🎨 托盘图标路径: $iconPath');

      // 初始化托盘
      await _systemTray!.initSystemTray(
        title: "CourseWidgets",
        iconPath: iconPath,
        toolTip: "CourseWidgets - 课程表",
      );

      debugPrint('✅ 托盘初始化成功');

      // 创建托盘菜单
      await _createTrayMenu();

      // 处理托盘点击事件
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        debugPrint('📌 托盘事件: $eventName');
        if (eventName == kSystemTrayEventClick) {
          // 左键点击显示窗口
          _showWindow();
        } else if (eventName == kSystemTrayEventRightClick) {
          // 右键点击显示菜单
          _systemTray!.popUpContextMenu();
        }
      });

      debugPrint('✅ Windows 托盘初始化完成');
    } catch (e, stackTrace) {
      debugPrint('❌ 初始化 Windows 托盘失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }

  /// 查找托盘图标
  Future<String> _findTrayIcon() async {
    final possiblePaths = [
      'data/flutter_assets/assets/app_icon.ico',
      'assets/app_icon.ico',
      'app_icon.ico',
    ];
    
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        return path;
      }
    }
    
    // 返回第一个路径作为默认值
    return possiblePaths.first;
  }

  /// 创建托盘菜单
  Future<void> _createTrayMenu() async {
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示窗口',
        onClicked: (menuItem) => _showWindow(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '通知设置',
        onClicked: (menuItem) {
          _showWindow();
          // TODO: 导航到通知设置页面
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) async {
          await dispose();
          await windowManager.destroy();
        },
      ),
    ]);
    await _systemTray!.setContextMenu(menu);
    debugPrint('✅ 托盘菜单设置成功');
  }

  /// 显示窗口
  Future<void> _showWindow() async {
    try {
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
    
    if (_systemTray != null) {
      await _systemTray!.destroy();
    }
    
    _isInitialized = false;
    _isBackgroundMode = false;
    
    debugPrint('🧹 Windows 托盘服务已清理');
  }
}

