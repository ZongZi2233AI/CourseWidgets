import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/course_event.dart';

/// Android 16 Live Updates 实时通知服务
/// 遵循官方文档: https://developer.android.com/develop/ui/views/notifications/live-update
class LiveNotificationServiceV2 {
  static final LiveNotificationServiceV2 _instance = LiveNotificationServiceV2._internal();
  factory LiveNotificationServiceV2() => _instance;
  LiveNotificationServiceV2._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _updateTimer;
  CourseEvent? _currentCourse;
  
  // 通知 ID
  static const int _liveNotificationId = 1000;
  static const String _channelId = 'live_course_updates';
  static const String _channelName = '课程实时提醒';
  static const String _channelDesc = 'Android 16 Live Updates 课程倒计时';

  /// 初始化通知服务
  Future<void> initialize() async {
    // Android 初始化设置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 初始化设置
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 初始化插件
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // 创建 Android 16 Live Updates 通知通道
    await _createNotificationChannel();
    
    debugPrint('✅ Android 16 Live Updates 通知服务初始化完成');
  }

  /// 创建通知通道（Android 16 Live Updates 优化）
  Future<void> _createNotificationChannel() async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high, // Live Updates 需要 high importance
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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

  /// 启动实时更新（每分钟更新一次）
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
    
    // 取消之前的定时器
    _updateTimer?.cancel();
    
    // 立即显示一次
    await _updateNotification();
    
    // 每分钟更新一次
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateNotification();
    });
    
    debugPrint('🚀 实时通知已启动: ${nextCourse.name}');
  }

  /// 更新通知内容（使用 Android 16 Live Updates API）
  /// 注意：flutter_local_notifications 包目前还不支持 setShortCriticalText API
  /// 需要等待包更新或使用原生代码实现
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

    if (diff.isNegative) {
      // 正在上课
      final totalMinutes = (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) ~/ 60000;
      final elapsedMinutes = now.difference(start).inMinutes;
      final remainingMinutes = totalMinutes - elapsedMinutes;
      
      title = '正在上课';
      body = '${_currentCourse!.name} · ${_currentCourse!.location} · 还有 $remainingMinutes 分钟';
      progress = elapsedMinutes;
      maxProgress = totalMinutes;
    } else {
      // 即将上课
      final minutesUntil = diff.inMinutes;
      
      if (minutesUntil > 60) {
        title = '下节课';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · ${start.hour}:${start.minute.toString().padLeft(2, '0')} 开始';
        progress = 0;
        maxProgress = 100;
      } else if (minutesUntil > 20) {
        title = '即将开始';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 还有 $minutesUntil 分钟';
        progress = 60 - minutesUntil;
        maxProgress = 60;
      } else if (minutesUntil > 0) {
        title = '马上开始';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 还有 $minutesUntil 分钟';
        progress = 20 - minutesUntil;
        maxProgress = 20;
      } else {
        title = '课程开始';
        body = '${_currentCourse!.name} · ${_currentCourse!.location} · 现在开始';
        progress = 100;
        maxProgress = 100;
      }
    }

    // Android 16 Live Updates 样式
    // 使用 ProgressStyle（通过 showProgress 实现）
    // 不使用 colorized（Live Updates 不允许）
    // 不使用 BigTextStyle（Live Updates 不允许）
    // TODO: 等待 flutter_local_notifications 支持 setShortCriticalText API
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
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'course_${_currentCourse!.startTime}',
    );
  }

  /// 取消通知
  Future<void> cancelNotification() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _currentCourse = null;
    await _notificationsPlugin.cancel(id: _liveNotificationId);
    debugPrint('🛑 Live Updates 通知已取消');
  }

  /// 停止服务
  Future<void> dispose() async {
    await cancelNotification();
  }
}
