import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/course_event.dart';
import '../services/storage_service.dart';
import 'package:local_notifier/local_notifier.dart';

/// [v2.2.8] 统一通知管理器
/// 支持多平台、多种通知方式
/// - Android API < 34: 双次提醒 + RemoteViews
/// - Android API ≥ 34: Live Updates (通过 live_activities_service.dart)
/// - iOS/iPadOS/macOS: Live Activities (通过 live_activities_service.dart)
/// - Windows: 系统通知
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();

  Timer? _checkTimer;
  final Set<int> _notifiedCourses = {};

  // 通知设置键
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyAdvanceMinutes = 'notification_advance_minutes';
  static const String keyDoubleReminder = 'notification_double_reminder';

  // 默认值
  static const bool defaultEnabled = true;
  static const int defaultAdvanceMinutes = 15;
  static const bool defaultDoubleReminder = true;

  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 请求通知权限
      await _requestPermissions();

      // 初始化插件
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'CourseWidgets',
        appUserModelId: 'com.zongzi.coursewidgets',
        guid: '12345678-1234-1234-1234-123456789012',
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        windows: windowsSettings,
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 创建通知通道
      if (Platform.isAndroid) {
        await _createAndroidChannels();
      }

      _isInitialized = true;
      debugPrint('✅ 通知管理器初始化成功');
    } catch (e) {
      debugPrint('❌ 通知管理器初始化失败: $e');
    }
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        debugPrint('⚠️ 通知权限被拒绝');
      }
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 创建 Android 通知通道
  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // 课程提醒通道
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'course_reminder',
        '课程提醒',
        description: '课程即将开始的提醒通知',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // 上课通知通道
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'course_ongoing',
        '正在上课',
        description: '当前正在进行的课程',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  /// 处理通知点击
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 通知被点击: ${response.payload}');
    // TODO: 导航到课程详情
  }

  /// 启动课程检查定时器
  void startCourseCheck(List<CourseEvent> Function() getCourses) {
    if (!isNotificationEnabled) {
      debugPrint('⚠️ 通知已禁用');
      return;
    }

    // 停止旧定时器
    _checkTimer?.cancel();

    // 每分钟动态拉取最新课程数据进行检查
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkUpcomingCourses(getCourses());
    });

    // 立即检查一次
    _checkUpcomingCourses(getCourses());

    debugPrint('🔔 课程检查定时器已启动');
  }

  /// 检查即将开始的课程
  void _checkUpcomingCourses(List<CourseEvent> courses) {
    final now = DateTime.now();
    final advanceMinutes = getAdvanceMinutes();
    final doubleReminder = isDoubleReminderEnabled;

    for (var course in courses) {
      final courseTime = DateTime.fromMillisecondsSinceEpoch(course.startTime);
      final diff = courseTime.difference(now);

      // 跳过已过期的课程
      if (diff.isNegative) continue;

      final courseId = course.id ?? course.startTime;

      // 第一次提醒（提前 N 分钟）
      if (diff.inMinutes >= advanceMinutes - 1 &&
          diff.inMinutes <= advanceMinutes + 1) {
        if (!_notifiedCourses.contains(courseId)) {
          _sendCourseReminder(course, advanceMinutes);
          _notifiedCourses.add(courseId);
        }
      }

      // 第二次提醒（上课前 5 分钟，仅 Android API < 34 和 Windows）
      if (doubleReminder && diff.inMinutes >= 4 && diff.inMinutes <= 6) {
        final secondId = courseId + 1000000; // 避免 ID 冲突
        if (!_notifiedCourses.contains(secondId)) {
          _sendCourseReminder(course, 5, isSecondReminder: true);
          _notifiedCourses.add(secondId);
        }
      }

      // 清理已过期的通知记录
      if (diff.inMinutes < -60) {
        _notifiedCourses.remove(courseId);
        _notifiedCourses.remove(courseId + 1000000);
      }
    }
  }

  /// 发送课程提醒通知
  Future<void> _sendCourseReminder(
    CourseEvent course,
    int minutesBefore, {
    bool isSecondReminder = false,
  }) async {
    try {
      final courseTime = DateTime.fromMillisecondsSinceEpoch(course.startTime);
      final timeStr =
          '${courseTime.hour.toString().padLeft(2, '0')}:${courseTime.minute.toString().padLeft(2, '0')}';

      final title = isSecondReminder ? '课程即将开始' : '课程提醒';
      final body =
          '${course.name}\n$timeStr · ${course.location}${course.teacher.isNotEmpty ? ' · ${course.teacher}' : ''}';

      final notificationId = (course.id ?? course.startTime) % 100000;

      if (Platform.isAndroid) {
        await _sendAndroidNotification(
          id: notificationId,
          title: title,
          body: body,
          course: course,
        );
      } else if (Platform.isWindows) {
        await _sendWindowsNotification(
          id: notificationId,
          title: title,
          body: body,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        await _sendIOSNotification(
          id: notificationId,
          title: title,
          body: body,
        );
      }

      debugPrint('📬 已发送通知: $title - ${course.name}');
    } catch (e) {
      debugPrint('❌ 发送通知失败: $e');
    }
  }

  /// 发送 Android 通知
  Future<void> _sendAndroidNotification({
    required int id,
    required String title,
    required String body,
    required CourseEvent course,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'course_reminder',
      '课程提醒',
      channelDescription: '课程即将开始的提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
      actions: [
        const AndroidNotificationAction(
          'view',
          '查看详情',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          '关闭',
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'course_${course.id}',
    );
  }

  /// 发送 Windows 通知
  Future<void> _sendWindowsNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // [v2.6.0.19] 使用专门应对裸 EXE 的 local_notifier 而非 flutter_local_notifications
    try {
      final notification = LocalNotification(
        identifier: id.toString(),
        title: title,
        body: body,
      );

      notification.onShow = () {
        debugPrint('🔔 Windows 通知已展示');
      };

      await notification.show();
    } catch (e) {
      debugPrint('❌ Windows 通知发送失败: $e');
    }
  }

  /// 发送 iOS 通知
  Future<void> _sendIOSNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(iOS: iosDetails),
    );
  }

  /// 停止课程检查
  void stopCourseCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _notifiedCourses.clear();
    debugPrint('🛑 课程检查定时器已停止');
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _notifiedCourses.clear();
  }

  /// 清理资源
  Future<void> dispose() async {
    stopCourseCheck();
    await cancelAll();
  }

  // ==================== 设置相关 ====================

  /// 通知是否启用
  bool get isNotificationEnabled {
    return _storage.getBool(keyNotificationEnabled) ?? defaultEnabled;
  }

  /// 设置通知启用状态
  Future<void> setNotificationEnabled(bool enabled) async {
    await _storage.setBool(keyNotificationEnabled, enabled);
  }

  /// 获取提前通知时间（分钟）
  int getAdvanceMinutes() {
    return _storage.getInt(keyAdvanceMinutes) ?? defaultAdvanceMinutes;
  }

  /// 设置提前通知时间
  Future<void> setAdvanceMinutes(int minutes) async {
    await _storage.setInt(keyAdvanceMinutes, minutes);
  }

  /// 是否启用双次提醒
  bool get isDoubleReminderEnabled {
    return _storage.getBool(keyDoubleReminder) ?? defaultDoubleReminder;
  }

  /// 设置双次提醒
  Future<void> setDoubleReminder(bool enabled) async {
    await _storage.setBool(keyDoubleReminder, enabled);
  }

  // ==================== Live Activities 设置 ====================

  static const String keyLiveActivitiesEnabled = 'live_activities_enabled';

  /// Live Activities 是否启用（默认开启）
  bool get isLiveActivitiesEnabled {
    return _storage.getBool(keyLiveActivitiesEnabled) ?? true;
  }

  /// 设置 Live Activities 启用状态
  Future<void> setLiveActivitiesEnabled(bool enabled) async {
    await _storage.setBool(keyLiveActivitiesEnabled, enabled);
  }
}
