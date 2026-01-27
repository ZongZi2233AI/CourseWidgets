import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import '../models/course_event.dart';

/// [v2.2.8] Live Activities 服务
/// 支持 iOS Dynamic Island 和 Android Live Updates
/// 使用 live_activities 2.4.6 包
class LiveActivitiesService {
  static final LiveActivitiesService _instance = LiveActivitiesService._internal();
  factory LiveActivitiesService() => _instance;
  LiveActivitiesService._internal();

  final LiveActivities _liveActivities = LiveActivities();
  Timer? _updateTimer;
  CourseEvent? _currentCourse;
  String? _activityId;
  
  bool _isInitialized = false;
  bool _isSupported = false;

  /// 初始化 Live Activities
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 检查平台支持
      if (Platform.isIOS || Platform.isMacOS) {
        // iOS/macOS 始终支持 Live Activities
        _isSupported = true;
      } else if (Platform.isAndroid) {
        // Android 需要 API 34+ (Android 14+)
        // 这里简化处理，实际应该检查 SDK 版本
        _isSupported = true; // TODO: 添加 SDK 版本检查
      } else {
        _isSupported = false;
      }
      
      if (_isSupported) {
        await _liveActivities.init(
          appGroupId: 'group.com.zongzi.coursewidgets',
        );
        debugPrint('✅ Live Activities 初始化成功');
      } else {
        debugPrint('⚠️ 当前平台不支持 Live Activities');
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Live Activities 初始化失败: $e');
      _isSupported = false;
    }
  }

  /// 是否支持 Live Activities
  bool get isSupported => _isSupported;

  /// 启动课程 Live Activity
  Future<void> startCourseActivity(CourseEvent course) async {
    if (!_isSupported) {
      debugPrint('⚠️ Live Activities 不支持，跳过');
      return;
    }
    
    try {
      // 停止之前的 Activity
      await stopCourseActivity();
      
      _currentCourse = course;
      
      // 创建 Activity 数据
      final data = _buildActivityData(course);
      
      // 启动 Activity
      _activityId = await _liveActivities.createActivity(
        'course_activity',
        data,
      );
      
      if (_activityId != null) {
        debugPrint('🎯 Live Activity 已启动: $_activityId');
        
        // 启动定时更新（每分钟）
        _startUpdateTimer();
      }
    } catch (e) {
      debugPrint('❌ 启动 Live Activity 失败: $e');
    }
  }

  /// 停止课程 Live Activity
  Future<void> stopCourseActivity() async {
    if (_activityId != null) {
      try {
        await _liveActivities.endActivity(_activityId!);
        debugPrint('🛑 Live Activity 已停止: $_activityId');
      } catch (e) {
        debugPrint('❌ 停止 Live Activity 失败: $e');
      }
      _activityId = null;
    }
    
    _updateTimer?.cancel();
    _updateTimer = null;
    _currentCourse = null;
  }

  /// 启动定时更新
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    
    // 立即更新一次
    _updateActivity();
    
    // 每分钟更新一次
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateActivity();
    });
  }

  /// 更新 Activity 数据
  Future<void> _updateActivity() async {
    if (_activityId == null || _currentCourse == null) return;
    
    try {
      final data = _buildActivityData(_currentCourse!);
      await _liveActivities.updateActivity(_activityId!, data);
      debugPrint('🔄 Live Activity 已更新');
    } catch (e) {
      debugPrint('❌ 更新 Live Activity 失败: $e');
    }
  }

  /// 构建 Activity 数据
  Map<String, dynamic> _buildActivityData(CourseEvent course) {
    final now = DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(course.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(course.endTime);
    final diff = start.difference(now);
    
    String status;
    String timeText;
    int progress;
    int maxProgress;
    
    if (diff.isNegative) {
      // 正在上课
      final totalMinutes = end.difference(start).inMinutes;
      final elapsedMinutes = now.difference(start).inMinutes;
      final remainingMinutes = totalMinutes - elapsedMinutes;
      
      if (remainingMinutes > 0) {
        status = 'ongoing';
        timeText = '还有 $remainingMinutes 分钟下课';
        progress = elapsedMinutes;
        maxProgress = totalMinutes;
      } else {
        // 课程已结束
        status = 'ended';
        timeText = '课程已结束';
        progress = 100;
        maxProgress = 100;
      }
    } else {
      // 即将上课
      final minutesUntil = diff.inMinutes;
      
      if (minutesUntil > 60) {
        status = 'upcoming';
        timeText = '${start.hour}:${start.minute.toString().padLeft(2, '0')} 开始';
        progress = 0;
        maxProgress = 100;
      } else if (minutesUntil > 0) {
        status = 'soon';
        timeText = '还有 $minutesUntil 分钟上课';
        progress = 60 - minutesUntil;
        maxProgress = 60;
      } else {
        status = 'starting';
        timeText = '课程开始';
        progress = 100;
        maxProgress = 100;
      }
    }
    
    return {
      'courseName': course.name,
      'location': course.location,
      'teacher': course.teacher,
      'status': status,
      'timeText': timeText,
      'progress': progress,
      'maxProgress': maxProgress,
      'startTime': course.startTime,
      'endTime': course.endTime,
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    await stopCourseActivity();
  }
}
