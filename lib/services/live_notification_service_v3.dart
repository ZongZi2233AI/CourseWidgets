import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/course_event.dart';

/// [v2.2.9] Live Update 实时通知服务 V3
/// 
/// 修复后台保活问题：
/// - 使用 Foreground Service 确保后台持续运行
/// - 符合 Android Live Update 规范
/// - 解决 Timer.periodic 在后台被挂起的问题
/// 
/// 架构：
/// - Foreground Service: 保持应用在后台运行
/// - Notification: 显示实时进度条
/// - Isolate: 独立线程处理定时更新
class LiveNotificationServiceV3 {
  static const String _channelId = 'live_update_channel';
  static const String _channelName = 'Live Update';
  static const int _notificationId = 1001;
  
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  CourseEvent? _currentCourse;
  bool _isRunning = false;

  /// 初始化服务
  Future<void> initialize() async {
    try {
      // 初始化通知
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // 处理通知点击
        },
      );
      
      // 初始化前台服务
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: _channelId,
          channelName: _channelName,
          channelDescription: '课程倒计时实时更新',
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000), // 每5秒更新一次
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
      
      debugPrint('✅ LiveNotificationServiceV3 初始化完成');
    } catch (e) {
      debugPrint('❌ LiveNotificationServiceV3 初始化失败: $e');
    }
  }

  /// 启动实时更新
  Future<void> startLiveUpdate(CourseEvent course) async {
    if (_isRunning) {
      debugPrint('⚠️ Live Update 已在运行中');
      return;
    }

    try {
      _currentCourse = course;
      _isRunning = true;

      // 启动前台服务
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: '课程提醒',
        notificationText: '正在监控课程: ${course.name}',
        notificationIcon: null,
        callback: startCallback,
      );

      // 发送课程数据到前台服务
      FlutterForegroundTask.sendDataToTask({
        'courseName': course.name,
        'courseLocation': course.location,
        'startTime': course.startTime,
        'endTime': course.endTime,
      });
      
      debugPrint('🚀 Live Update 已启动: ${course.name}');
    } catch (e) {
      debugPrint('❌ 启动 Live Update 失败: $e');
      _isRunning = false;
    }
  }

  /// 停止实时更新
  Future<void> stopLiveUpdate() async {
    if (!_isRunning) return;

    try {
      await FlutterForegroundTask.stopService();
      await _notifications.cancel(
        id: _notificationId,
      );
      
      _currentCourse = null;
      _isRunning = false;
      
      debugPrint('🛑 Live Update 已停止');
    } catch (e) {
      debugPrint('❌ 停止 Live Update 失败: $e');
    }
  }

  /// 检查是否正在运行
  bool get isRunning => _isRunning;
  
  /// 获取当前课程
  CourseEvent? get currentCourse => _currentCourse;
}

/// 前台服务回调入口点
/// 必须是顶级函数
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LiveUpdateTaskHandler());
}

/// Live Update 任务处理器
class LiveUpdateTaskHandler extends TaskHandler {
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  String _courseName = '';
  String _courseLocation = '';
  int _startTime = 0;
  int _endTime = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🔄 Live Update Task 开始');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 每5秒执行一次
    _updateNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('🛑 Live Update Task 销毁');
  }

  @override
  void onReceiveData(Object data) {
    // 接收课程数据
    if (data is Map) {
      _courseName = data['courseName'] as String? ?? '';
      _courseLocation = data['courseLocation'] as String? ?? '';
      _startTime = data['startTime'] as int? ?? 0;
      _endTime = data['endTime'] as int? ?? 0;
      
      debugPrint('📚 收到课程数据: $_courseName');
      _updateNotification();
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    // 处理通知按钮点击
  }

  @override
  void onNotificationPressed() {
    // 处理通知点击
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {
    // 处理通知消失
  }

  /// 更新通知
  Future<void> _updateNotification() async {
    if (_startTime == 0) return;

    try {
      final now = DateTime.now();
      final start = DateTime.fromMillisecondsSinceEpoch(_startTime);
      final end = DateTime.fromMillisecondsSinceEpoch(_endTime);
      final diff = start.difference(now);

      // 计算进度
      final totalMinutes = end.difference(start).inMinutes;
      final remainingMinutes = diff.inMinutes;
      final progress = ((totalMinutes - remainingMinutes) / totalMinutes * 100).clamp(0, 100).toInt();

      // 格式化时间
      String timeText;
      if (diff.isNegative) {
        // 课程已开始
        final elapsed = now.difference(start);
        if (elapsed.inHours > 0) {
          timeText = '已上课 ${elapsed.inHours} 小时 ${elapsed.inMinutes % 60} 分钟';
        } else {
          timeText = '已上课 ${elapsed.inMinutes} 分钟';
        }
      } else {
        // 课程未开始
        if (diff.inHours > 0) {
          timeText = '${diff.inHours} 小时 ${diff.inMinutes % 60} 分钟后上课';
        } else if (diff.inMinutes > 0) {
          timeText = '${diff.inMinutes} 分钟后上课';
        } else {
          timeText = '即将上课';
        }
      }

      // 构建通知
      final androidDetails = AndroidNotificationDetails(
        'live_update_channel',
        'Live Update',
        channelDescription: '课程倒计时实时更新',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // 持续通知
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        playSound: false,
        enableVibration: false,
        styleInformation: BigTextStyleInformation(
          '$timeText\n$_courseLocation',
          contentTitle: _courseName,
        ),
      );

      final details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        id: 1001,
        title: _courseName,
        body: timeText,
        notificationDetails: details,
      );

      // 更新前台服务通知
      FlutterForegroundTask.updateService(
        notificationTitle: _courseName,
        notificationText: timeText,
      );

      // 如果课程已结束，停止服务
      if (now.isAfter(end)) {
        debugPrint('✅ 课程已结束，停止 Live Update');
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('❌ 更新通知失败: $e');
    }
  }
}
