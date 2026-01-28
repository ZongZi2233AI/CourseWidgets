import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../providers/schedule_provider.dart';
import 'live_notification_service_v2.dart';

/// [v2.2.9] 后台任务服务
/// 
/// 功能：
/// - 使用 WorkManager 实现后台保活
/// - 定期检查即将到来的课程
/// - 触发实时通知服务
/// - 支持应用关闭后继续运行
/// 
/// 使用方法：
/// ```dart
/// // 初始化
/// await BackgroundTaskService.initialize();
/// 
/// // 注册后台任务
/// await BackgroundTaskService.registerPeriodicTask();
/// 
/// // 取消后台任务
/// await BackgroundTaskService.cancelTask();
/// ```
class BackgroundTaskService {
  static const String _taskName = 'course_reminder_task';
  static const String _uniqueName = 'course_reminder_unique';
  
  /// 初始化 WorkManager
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
      debugPrint('✅ WorkManager 初始化完成');
    } catch (e) {
      debugPrint('❌ WorkManager 初始化失败: $e');
    }
  }
  
  /// 注册周期性后台任务
  /// 
  /// 参数：
  /// - frequency: 执行频率（默认 15 分钟）
  static Future<void> registerPeriodicTask({
    Duration frequency = const Duration(minutes: 15),
  }) async {
    try {
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: NetworkType.notRequired, // 不需要网络 (v0.9.0: not_required -> notRequired)
          requiresBatteryNotLow: false, // 不要求电量充足
          requiresCharging: false, // 不要求充电
          requiresDeviceIdle: false, // 不要求设备空闲
          requiresStorageNotLow: false, // 不要求存储充足
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // 替换已存在的任务 (v0.9.0: ExistingWorkPolicy -> ExistingPeriodicWorkPolicy)
        backoffPolicy: BackoffPolicy.linear, // 线性退避策略
        backoffPolicyDelay: const Duration(minutes: 5), // 失败后 5 分钟重试
      );
      debugPrint('✅ 后台任务已注册 (频率: ${frequency.inMinutes} 分钟)');
    } catch (e) {
      debugPrint('❌ 后台任务注册失败: $e');
    }
  }
  
  /// 注册一次性后台任务（立即执行）
  static Future<void> registerOneOffTask() async {
    try {
      await Workmanager().registerOneOffTask(
        '${_uniqueName}_oneoff',
        _taskName,
        constraints: Constraints(
          networkType: NetworkType.notRequired, // v0.9.0: not_required -> notRequired
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      debugPrint('✅ 一次性后台任务已注册');
    } catch (e) {
      debugPrint('❌ 一次性后台任务注册失败: $e');
    }
  }
  
  /// 取消后台任务
  static Future<void> cancelTask() async {
    try {
      await Workmanager().cancelByUniqueName(_uniqueName);
      debugPrint('✅ 后台任务已取消');
    } catch (e) {
      debugPrint('❌ 后台任务取消失败: $e');
    }
  }
  
  /// 取消所有后台任务
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('✅ 所有后台任务已取消');
    } catch (e) {
      debugPrint('❌ 取消所有后台任务失败: $e');
    }
  }
}

/// WorkManager 回调分发器
/// 
/// 注意：此函数必须是顶级函数，不能是类的成员函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 后台任务开始执行: $task');
    
    try {
      // 检查即将到来的课程
      await _checkUpcomingCourses();
      
      debugPrint('✅ 后台任务执行成功');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ 后台任务执行失败: $e');
      return Future.value(false);
    }
  });
}

/// 检查即将到来的课程并触发通知
Future<void> _checkUpcomingCourses() async {
  try {
    // 创建 ScheduleProvider 实例
    final provider = ScheduleProvider();
    
    // 加载保存的课程数据
    await provider.loadSavedData();
    
    if (!provider.hasData) {
      debugPrint('📚 没有课程数据');
      return;
    }
    
    // 获取下一节课
    final nextCourse = provider.getNextCourse();
    
    if (nextCourse == null) {
      debugPrint('📚 没有即将到来的课程');
      return;
    }
    
    // 计算距离上课的时间
    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(nextCourse.startTime);
    final diff = start.difference(now);
    
    debugPrint('📚 下一节课: ${nextCourse.name}');
    debugPrint('⏰ 距离上课: ${diff.inMinutes} 分钟');
    
    // 如果距离上课时间在 60 分钟内，启动实时通知
    if (diff.inMinutes >= 0 && diff.inMinutes <= 60) {
      final liveService = LiveNotificationServiceV2();
      await liveService.initialize();
      await liveService.startLiveUpdate(nextCourse);
      debugPrint('🚀 已启动实时通知服务');
    } else {
      debugPrint('⏰ 距离上课时间较远，暂不启动通知');
    }
  } catch (e) {
    debugPrint('❌ 检查课程失败: $e');
    rethrow;
  }
}
