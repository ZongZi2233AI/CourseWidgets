import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/course_event.dart';

class LiveNotificationService {
  static final LiveNotificationService _instance = LiveNotificationService._internal();
  factory LiveNotificationService() => _instance;
  LiveNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  
  // 渠道 ID
  static const String _channelId = 'live_course_countdown';
  static const String _channelName = '实时课程倒计时';
  static const String _channelDesc = '显示下一节课的倒计时信息';
  static const int _notificationId = 888;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 配置 (虽然主要针对 Android)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(requestSoundPermission: false, requestBadgePermission: false, requestAlertPermission: false);

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // v20版本的初始化语法 - 使用命名参数
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 处理通知点击事件
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
    
    // 创建高优先级的 Notification Channel
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.low, // Low 避免声音震动，只更新 UI
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> startLiveUpdate(CourseEvent? nextCourse) async {
    // 请求权限
    if (await Permission.notification.request().isDenied) return;

    if (nextCourse == null) {
      cancelNotification();
      return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateNotification(nextCourse);
    });
    // 立即执行一次
    _updateNotification(nextCourse);
  }

  Future<void> _updateNotification(CourseEvent course) async {
    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(course.startTime);
    final diff = start.difference(now);

    String title;
    String body;
    double progress;

    if (diff.isNegative) {
      // 正在上课
      final durationMinutes = (course.endTime - course.startTime) ~/ 60000;
      title = "正在上课: ${course.name}";
      body = "${course.location} | 下课还有 ${durationMinutes + diff.inMinutes} 分钟";
      progress = 1.0; // 或者计算上课进度
    } else {
      // 即将上课
      if (diff.inMinutes > 60) {
        title = "下节课: ${course.name}";
        body = "${course.location} | ${start.hour}:${start.minute.toString().padLeft(2, '0')} 开始";
      } else {
        title = "即将开始: ${course.name}";
        body = "${course.location} | 还有 ${diff.inMinutes} 分钟";
      }
      progress = 0.0;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // 常驻通知，不可滑动删除
      autoCancel: false,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: (progress * 100).toInt(),
      indeterminate: false,
      styleInformation: BigTextStyleInformation(body),
      // Android 12+ 兼容
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancelNotification() async {
    _timer?.cancel();
    await _notificationsPlugin.cancel(id: _notificationId);
  }
}
