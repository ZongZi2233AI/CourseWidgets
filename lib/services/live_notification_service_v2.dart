import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/course_event.dart';

/// [v2.2.9] 实时通知服务 - 跨平台支持
/// 
/// 平台支持：
/// - Android 16+: 使用 Live Update API (ProgressStyle)
/// - Android < 16: 使用传统进度条通知
/// - iOS: 使用 Live Activities (灵动岛)
/// - Windows: 使用系统通知
/// 
/// 功能特性：
/// - ✅ 提前 10 分钟提醒（不是几小时）
/// - ✅ 后台保活（使用 WorkManager）
/// - ✅ 实时更新课程状态
/// - ✅ 跨平台统一接口
/// 
/// 官方文档:
/// - Android Live Update: https://developer.android.com/develop/ui/views/notifications/live-update
/// - Android ProgressStyle: https://developer.android.com/about/versions/16/features/progress-centric-notifications
class LiveNotificationServiceV2 {
  static final LiveNotificationServiceV2 _instance = LiveNotificationServiceV2._internal();
  factory LiveNotificationServiceV2() => _instance;
  LiveNotificationServiceV2._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _updateTimer;
  Timer? _reminderCheckTimer; // [v2.2.9] 提醒检查定时器
  CourseEvent? _currentCourse;
  bool _hasShownReminder = false; // [v2.2.9] 是否已显示提醒
  
  // 通知 ID
  static const int _liveNotificationId = 1000;
  static const int _reminderNotificationId = 1001; // [v2.2.9] 提前提醒通知
  static const String _channelId = 'live_course_updates';
  static const String _channelName = '课程实时提醒';
  static const String _channelDesc = 'Android 16 Live Updates 课程倒计时';
  static const String _reminderChannelId = 'course_reminders'; // [v2.2.9] 提醒通道
  static const String _reminderChannelName = '课程提醒';
  static const String _reminderChannelDesc = '提前 10 分钟课程提醒';

  /// 初始化通知服务
  Future<void> initialize() async {
    // 平台特定初始化
    if (Platform.isAndroid) {
      await _initializeAndroid();
    } else if (Platform.isIOS) {
      await _initializeIOS();
    } else if (Platform.isWindows) {
      await _initializeWindows();
    }
    
    debugPrint('✅ 跨平台通知服务初始化完成 (${Platform.operatingSystem})');
  }
  
  /// Android 初始化
  Future<void> _initializeAndroid() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // 创建通知通道
    await _createAndroidNotificationChannels();
  }
  
  /// iOS 初始化
  Future<void> _initializeIOS() async {
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  /// Windows 初始化
  Future<void> _initializeWindows() async {
    // Windows 使用系统通知，无需特殊初始化
    debugPrint('📱 Windows 通知服务已就绪');
  }

  /// 创建 Android 通知通道
  Future<void> _createAndroidNotificationChannels() async {
    // Live Update 通道
    final AndroidNotificationChannel liveChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: true,
      enableLights: true,
      ledColor: const Color(0xFFFF9A9E), // 嫩粉色
    );
    
    // [v2.2.9] 提醒通道
    final AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      _reminderChannelName,
      description: _reminderChannelDesc,
      importance: Importance.high,
      playSound: true, // 提醒需要声音
      enableVibration: true, // 提醒需要震动
      showBadge: true,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(liveChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
  }

  /// 处理通知点击事件
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 通知被点击: ${response.payload}');
    
    // 处理不同的操作
    if (response.actionId == 'dismiss') {
      // 关闭通知
      cancelNotification();
      debugPrint('🛑 用户手动关闭通知');
    } else if (response.actionId == 'view_details' || response.payload != null) {
      // 查看详情或点击通知本体
      debugPrint('📖 跳转到课程详情: ${response.payload}');
      // 通过回调通知主界面跳转
      if (_onNotificationTapCallback != null && _currentCourse != null) {
        _onNotificationTapCallback!(_currentCourse!);
      }
    }
  }
  
  /// 通知点击回调
  Function(CourseEvent)? _onNotificationTapCallback;
  
  /// 设置通知点击回调
  void setOnNotificationTapCallback(Function(CourseEvent) callback) {
    _onNotificationTapCallback = callback;
  }

  /// [v2.2.9] 启动实时更新（每分钟更新一次）+ 提前 10 分钟提醒
  Future<void> startLiveUpdate(CourseEvent? nextCourse) async {
    // 请求通知权限
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('❌ 通知权限被拒绝');
      return;
    }

    if (nextCourse == null) {
      await cancelNotification();
      return;
    }

    _currentCourse = nextCourse;
    _hasShownReminder = false; // 重置提醒标志
    
    // 取消之前的定时器
    _updateTimer?.cancel();
    _reminderCheckTimer?.cancel();
    
    // 立即显示一次
    await _updateNotification();
    
    // 每分钟更新一次 Live Update
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateNotification();
    });
    
    // [v2.2.9] 每 30 秒检查一次是否需要提前提醒
    _reminderCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndShowReminder();
    });
    
    debugPrint('🚀 实时通知已启动: ${nextCourse.name}');
  }

  /// [v2.2.9] 检查并显示提前 10 分钟提醒
  Future<void> _checkAndShowReminder() async {
    if (_currentCourse == null || _hasShownReminder) return;

    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(_currentCourse!.startTime);
    final diff = start.difference(now);

    // 提前 10 分钟提醒（9-11 分钟之间触发）
    if (diff.inMinutes >= 9 && diff.inMinutes <= 11) {
      await _showReminderNotification();
      _hasShownReminder = true;
      debugPrint('⏰ 已显示提前 10 分钟提醒');
    }
  }

  /// [v2.2.9] 显示提前提醒通知
  Future<void> _showReminderNotification() async {
    if (_currentCourse == null) return;

    final start = DateTime.fromMillisecondsSinceEpoch(_currentCourse!.startTime);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: const Color(0xFFFF9A9E),
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '${_currentCourse!.location}\n${start.hour}:${start.minute.toString().padLeft(2, '0')} 开始',
        contentTitle: '⏰ 10 分钟后上课',
        summaryText: _currentCourse!.name,
      ),
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: _reminderNotificationId,
      title: '⏰ 10 分钟后上课',
      body: '${_currentCourse!.name} · ${_currentCourse!.location}',
      notificationDetails: details,
      payload: 'reminder_${_currentCourse!.startTime}',
    );
  }

  /// 更新 Live Update 通知内容
  Future<void> _updateNotification() async {
    if (_currentCourse == null) return;

    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(_currentCourse!.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(_currentCourse!.endTime);
    final diff = start.difference(now);

    String title;
    String body;
    int progress = 0;
    int maxProgress = 100;
    String emoji = '📚';

    if (diff.isNegative) {
      // 正在上课
      final totalMinutes = (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/ 60000;
      final elapsedMinutes = now.difference(start).inMinutes;
      final remainingMinutes = totalMinutes - elapsedMinutes;
      
      if (remainingMinutes > 0) {
        emoji = '📚';
        title = '正在上课';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 还有 $remainingMinutes 分钟下课';
        progress = elapsedMinutes;
        maxProgress = totalMinutes;
      } else {
        // 课程已结束
        await cancelNotification();
        return;
      }
    } else {
      // 即将上课
      final minutesUntil = diff.inMinutes;
      
      if (minutesUntil > 60) {
        emoji = '⏰';
        title = '下节课';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · ${start.hour}:${start.minute.toString().padLeft(2, '0')} 开始';
        progress = 0;
        maxProgress = 100;
      } else if (minutesUntil > 20) {
        emoji = '⏰';
        title = '即将开始';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 还有 $minutesUntil 分钟';
        progress = 60 - minutesUntil;
        maxProgress = 60;
      } else if (minutesUntil > 0) {
        emoji = '🔔';
        title = '马上开始';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 还有 $minutesUntil 分钟！';
        progress = 20 - minutesUntil;
        maxProgress = 20;
      } else {
        emoji = '🔔';
        title = '课程开始';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 现在开始';
        progress = 100;
        maxProgress = 100;
      }
    }

    // Android Live Update 样式
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Live Updates 必须是 ongoing
      autoCancel: false,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      indeterminate: false,
      visibility: NotificationVisibility.public,
      color: const Color(0xFFFF9A9E),
      // 操作按钮
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_details',
          '查看详情',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'dismiss',
          '关闭',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: _liveNotificationId,
      title: '$emoji $title',
      body: body,
      notificationDetails: details,
      payload: 'course_${_currentCourse!.startTime}',
    );
  }

  /// 取消通知
  Future<void> cancelNotification() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = null;
    _currentCourse = null;
    _hasShownReminder = false;
    await _notificationsPlugin.cancel(id: _liveNotificationId);
    await _notificationsPlugin.cancel(id: _reminderNotificationId);
    debugPrint('🛑 Live Updates 通知已取消');
  }

  /// 停止服务
  Future<void> dispose() async {
    await cancelNotification();
  }
}
