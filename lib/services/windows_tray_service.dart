import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/schedule_provider.dart';

/// Windows系统托盘服务 - 完整实现 v2.1.7
class WindowsTrayService {
  static final WindowsTrayService _instance = WindowsTrayService._internal();
  factory WindowsTrayService() => _instance;
  
  WindowsTrayService._internal();

  FlutterLocalNotificationsPlugin? _notifications;
  SystemTray? _systemTray;
  bool _isInitialized = false;
  bool _isBackgroundMode = false;
  Timer? _notificationTimer;
  final Set<int> _notifiedCourses = {}; // 记录已提醒的课程ID

  /// 初始化托盘和通知服务
  Future<void> initialize() async {
    // Web平台不支持
    if (kIsWeb) {
      debugPrint('Web平台跳过托盘服务初始化');
      return;
    }

    if (_isInitialized) return;

    try {
      // 初始化系统托盘（仅Windows）
      if (Platform.isWindows) {
        await _initializeSystemTray();
        await _initializeWindowsNotifications();
      }

      // 初始化通知服务（Android/iOS）
      if (Platform.isAndroid || Platform.isIOS) {
        await _initializeNotifications();
      }

      _isInitialized = true;
      debugPrint('托盘服务初始化成功');
    } catch (e) {
      debugPrint('初始化托盘服务失败: $e');
    }
  }

  /// 初始化系统托盘
  Future<void> _initializeSystemTray() async {
    try {
      _systemTray = SystemTray();

      // [v2.2.0修复] 使用绝对路径或相对于可执行文件的路径
      String iconPath;
      if (Platform.isWindows) {
        // 尝试多个可能的图标路径
        final possiblePaths = [
          'data/flutter_assets/assets/app_icon.ico',  // Flutter 打包后的路径
          'assets/app_icon.ico',                       // 开发时的路径
          'app_icon.ico',                              // 备用路径
        ];
        
        iconPath = possiblePaths.first;
        for (final path in possiblePaths) {
          if (await File(path).exists()) {
            iconPath = path;
            debugPrint('找到托盘图标: $path');
            break;
          }
        }
      } else {
        iconPath = 'assets/app_icon.ico';
      }

      debugPrint('尝试初始化托盘，图标路径: $iconPath');

      // 初始化托盘
      await _systemTray!.initSystemTray(
        title: "CourseWidgets",
        iconPath: iconPath,
      );

      debugPrint('✅ 托盘初始化成功');

      // 创建托盘菜单
      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: '显示窗口', onClicked: (menuItem) async {
          debugPrint('点击：显示窗口');
          await windowManager.show();
          await windowManager.focus();
          _isBackgroundMode = false;
        }),
        MenuSeparator(),
        MenuItemLabel(label: '退出', onClicked: (menuItem) async {
          debugPrint('点击：退出');
          await dispose();
          await windowManager.destroy();
        }),
      ]);
      await _systemTray!.setContextMenu(menu);

      debugPrint('✅ 托盘菜单设置成功');

      // 处理托盘点击事件
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        debugPrint('📌 托盘事件: $eventName');
        if (eventName == kSystemTrayEventClick) {
          // 左键点击显示窗口
          debugPrint('左键点击托盘');
          windowManager.show();
          windowManager.focus();
          _isBackgroundMode = false;
        } else if (eventName == kSystemTrayEventRightClick) {
          // 右键点击显示菜单
          debugPrint('右键点击托盘');
          _systemTray!.popUpContextMenu();
        }
      });

      debugPrint('✅ Windows托盘初始化完成');
    } catch (e, stackTrace) {
      debugPrint('❌ 初始化Windows托盘失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }

  /// 初始化Windows通知服务
  Future<void> _initializeWindowsNotifications() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();
      
      // Windows通知初始化
      await _notifications!.initialize(
        settings: const InitializationSettings(
          windows: WindowsInitializationSettings(
            appName: 'CourseWidgets',
            appUserModelId: 'com.zongzi.schedule',
            guid: '00000000-0000-0000-0000-000000000000',
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          windowManager.show();
          windowManager.focus();
        },
      );
      
      debugPrint('Windows通知服务初始化成功');
    } catch (e) {
      debugPrint('初始化Windows通知服务失败: $e');
      // 即使初始化失败，也不影响其他功能
    }
  }

  /// 初始化通知服务（Android/iOS）
  Future<void> _initializeNotifications() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();
      await _notifications!.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          // Handle notification tap
        },
      );
      debugPrint('通知服务初始化成功');
    } catch (e) {
      debugPrint('初始化通知服务失败: $e');
    }
  }

  /// [v2.2.0修复2] 显示系统通知 - 使用液态玻璃Toast（Windows端）
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_notifications == null) return;

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (Platform.isWindows) {
        // [v2.2.0修复2] Windows使用原生通知（系统托盘通知）
        // 液态玻璃Toast将在UI层显示
        await _notifications!.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            windows: WindowsNotificationDetails(),
          ),
          payload: payload,
        );
      } else if (Platform.isAndroid) {
        // Android通知
        await _notifications!.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'schedule_channel',
              '课程提醒',
              channelDescription: '课程即将开始提醒',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: payload,
        );
      }
      
      debugPrint('通知已显示: $title - $body');
    } catch (e) {
      debugPrint('显示通知失败: $e');
    }
  }

  /// 启动课程提醒定时器（Windows专用，20分钟提前提醒）
  void startCourseReminderTimer(ScheduleProvider provider) {
    if (!Platform.isWindows) return;
    
    // 停止旧定时器
    _notificationTimer?.cancel();
    
    // 每分钟检查一次
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkUpcomingCourses(provider);
    });
    
    // 立即检查一次
    _checkUpcomingCourses(provider);
    
    debugPrint('课程提醒定时器已启动');
  }

  /// 检查即将开始的课程（20分钟提前提醒）
  void _checkUpcomingCourses(ScheduleProvider provider) {
    if (!provider.hasData) return;

    final now = DateTime.now();
    final courses = provider.courses;
    
    for (var course in courses) {
      // 跳过已提醒的课程
      if (_notifiedCourses.contains(course.id)) continue;
      
      final courseTime = DateTime.fromMillisecondsSinceEpoch(course.startTime);
      final timeDiff = courseTime.difference(now);
      
      // 20分钟提前提醒（18-22分钟之间触发，避免重复）
      if (timeDiff.inMinutes >= 18 && timeDiff.inMinutes <= 22) {
        _notifiedCourses.add(course.id ?? 0);
        
        showNotification(
          title: '课程提醒',
          body: '${course.name} 将在20分钟后开始\n地点: ${course.location}\n教师: ${course.teacher}',
          payload: 'course_${course.id}',
        );
        
        debugPrint('已发送课程提醒: ${course.name}');
      }
      
      // 清理已过期的课程ID（课程开始后1小时清理）
      if (timeDiff.inMinutes < -60) {
        _notifiedCourses.remove(course.id ?? 0);
      }
    }
  }

  /// 进入后台模式（最小化到托盘）
  Future<void> enterBackgroundMode() async {
    if (!Platform.isWindows) return;
    
    try {
      await windowManager.hide();
      _isBackgroundMode = true;
      debugPrint('已进入后台模式');
    } catch (e) {
      debugPrint('进入后台模式失败: $e');
    }
  }

  /// 退出后台模式（显示窗口）
  Future<void> exitBackgroundMode() async {
    if (!Platform.isWindows) return;
    
    try {
      await windowManager.show();
      await windowManager.focus();
      _isBackgroundMode = false;
      debugPrint('已退出后台模式');
    } catch (e) {
      debugPrint('退出后台模式失败: $e');
    }
  }

  /// 检查是否在后台模式
  bool get isBackgroundMode => _isBackgroundMode;

  /// 清理资源
  Future<void> dispose() async {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _notifiedCourses.clear();
    
    if (_notifications != null) {
      await _notifications!.cancelAll();
    }
    if (_systemTray != null) {
      await _systemTray!.destroy();
    }
    _isInitialized = false;
    _isBackgroundMode = false;
  }
}
