import 'package:flutter/foundation.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:rrule/rrule.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/course_event.dart';

/// ICS解析器 - 核心逻辑
class IcsParser {
  static bool _timezoneInitialized = false;

  /// 初始化时区数据 (必须在使用前调用)
  static void initTimezone() {
    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      _timezoneInitialized = true;
    }
  }

  /// 主入口：解析 ICS 字符串并返回课程列表
  static List<CourseEvent> parse(String icsContent) {
    initTimezone();
    
    final List<CourseEvent> courses = [];
    
    try {
      // 1. 解析 ICS 文本结构
      final iCalendar = ICalendar.fromString(icsContent);
      
      // 2. 遍历所有事件
      final data = iCalendar.data;
      for (var item in data) {
        if (item['type'] == 'VEVENT') {
          // 将解析出的单个事件（可能包含重复规则）展开为具体日期的列表
          var events = _expandEvent(item);
          courses.addAll(events);
        }
      }
    } catch (e) {
      debugPrint('ICS解析错误: $e');
      // 如果解析失败，返回空列表而不是抛出异常
    }
    
    return courses;
  }

  /// 核心逻辑：处理单条 ICS 记录，展开重复规则
  static List<CourseEvent> _expandEvent(Map<String, dynamic> eventData) {
    List<CourseEvent> instances = [];

    // --- A. 提取基础信息 ---
    final summary = eventData['summary']?.toString() ?? '未知课程';
    final location = eventData['location']?.toString() ?? '未知地点';
    
    // 尝试从 Description 提取老师 (格式: "课程 教室 老师")
    // 或者从 CATEGORIES 提取
    String teacher = '';
    
    // 首先尝试从 CATEGORIES 提取
    if (eventData['categories'] != null) {
      // CATEGORIES 可能是 List 或 String
      List<String> catList = [];
      if (eventData['categories'] is List) {
        catList = (eventData['categories'] as List).map((e) => e.toString().trim()).toList();
      } else {
        catList = eventData['categories'].toString().split(',').map((c) => c.trim()).toList();
      }
      
      // 过滤掉系统标签，保留真实的教师姓名
      final teacherCandidates = catList.where((c) => 
        c != 'ShanghaiTech' && 
        c != 'Course Table ICS Formatter' &&
        c.isNotEmpty &&
        c != 'Course Table' &&
        c != 'ICS Formatter'
      ).toList();
      if (teacherCandidates.isNotEmpty) {
        teacher = teacherCandidates.join(',');
      }
    }
    
    // 如果 CATEGORIES 没有，尝试从 DESCRIPTION 提取
    if (teacher.isEmpty) {
      final description = eventData['description']?.toString() ?? '';
      if (description.isNotEmpty) {
        // 从描述中提取老师，通常是最后一部分
        final parts = description.split(' ').where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          teacher = parts.last;
        }
      }
    }

    // --- B. 处理时间 (UTC -> Local) ---
    final dtStartObj = eventData['dtstart'];
    final dtEndObj = eventData['dtend'];

    if (dtStartObj == null || dtEndObj == null) return [];

    // 将 ICS 的时间对象转为 Dart 的 DateTime (UTC)
    DateTime startUtc = _parseIcsDateTime(dtStartObj);
    DateTime endUtc = _parseIcsDateTime(dtEndObj);
    
    // 计算单节课时长
    final duration = endUtc.difference(startUtc);

    // --- C. 处理重复规则 (RRULE) ---
    final rruleString = eventData['rrule']?.toString();

    if (rruleString != null && rruleString.isNotEmpty) {
      try {
        // 1. 解析 RRULE 字符串
        // rrule 库比较严格，ICS 里的字符串有时带尾部分号，最好清理一下
        final cleanRrule = rruleString.replaceAll(RegExp(r';$'), ''); 
        
        // 确保格式正确，如果缺少 RRULE: 前缀，直接解析属性
        RecurrenceRule rrule;
        if (cleanRrule.startsWith('RRULE:')) {
          rrule = RecurrenceRule.fromString(cleanRrule);
        } else {
          // 直接解析属性，如 FREQ=WEEKLY;COUNT=16;INTERVAL=1
          rrule = RecurrenceRule.fromString('RRULE:$cleanRrule');
        }

        // 2. 计算所有重复的时间点
        // 注意：rrule 计算需要基于 UTC 时间
        final occurrences = rrule.getInstances(
          start: startUtc.toUtc(), 
        );

        // 3. 遍历每一个计算出的时间点
        for (var occ in occurrences) {
          // 转换为本地时间 (假设用户在中国)
          final localStart = occ.toLocal(); 
          final localEnd = localStart.add(duration);

          instances.add(CourseEvent(
            name: summary,
            location: location,
            teacher: teacher,
            startTime: localStart.millisecondsSinceEpoch,
            endTime: localEnd.millisecondsSinceEpoch,
          ));
        }
      } catch (e) {
        debugPrint('RRULE解析失败: $e, 使用默认处理');
        // 如果 RRULE 失败，至少添加第一次课程
        instances.add(CourseEvent(
          name: summary,
          location: location,
          teacher: teacher,
          startTime: startUtc.toLocal().millisecondsSinceEpoch,
          endTime: endUtc.toLocal().millisecondsSinceEpoch,
        ));
      }
    } else {
      // --- D. 没有重复规则，直接添加 ---
      instances.add(CourseEvent(
        name: summary,
        location: location,
        teacher: teacher,
        startTime: startUtc.toLocal().millisecondsSinceEpoch,
        endTime: endUtc.toLocal().millisecondsSinceEpoch,
      ));
    }

    return instances;
  }

  // 辅助函数：统一处理 ICS 时间格式
  static DateTime _parseIcsDateTime(dynamic dt) {
    if (dt is IcsDateTime) {
      return dt.toDateTime() ?? DateTime.now(); // 库自带转换
    } else if (dt is String) {
      // 手动兜底处理 '20250908T001500Z'
      try {
        final icsDt = IcsDateTime(dt: dt);
        return icsDt.toDateTime() ?? DateTime.now();
      } catch (e) {
        return DateTime.now(); // 错误处理
      }
    }
    return DateTime.now();
  }
}
