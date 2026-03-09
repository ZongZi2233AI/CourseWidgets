import 'package:flutter/foundation.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:rrule/rrule.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/course_event.dart';
import '../models/schedule_config.dart';

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
    // [v2.6.0.19] 清理 \n, \r 等所有的转义换行符和额外空格
    final summary = (eventData['summary']?.toString() ?? '未知课程')
        .replaceAll(RegExp(r'\\n|\n|\\r|\r'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    String location = (eventData['location']?.toString() ?? '未知地点')
        .replaceAll(RegExp(r'\\n|\n|\\r|\r'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 尝试从 Description 提取老师 (格式: "课程 教室 老师")
    // 或者从 CATEGORIES 提取
    String teacher = '';

    // 首先尝试从 CATEGORIES 提取
    if (eventData['categories'] != null) {
      // CATEGORIES 可能是 List 或 String
      List<String> catList = [];
      if (eventData['categories'] is List) {
        catList = (eventData['categories'] as List)
            .map((e) => e.toString().trim())
            .toList();
      } else {
        catList = eventData['categories']
            .toString()
            .split(',')
            .map((c) => c.trim())
            .toList();
      }

      // 过滤掉系统标签，保留真实的教师姓名
      final teacherCandidates = catList
          .where(
            (c) =>
                c != 'ShanghaiTech' &&
                c != 'Course Table ICS Formatter' &&
                c.isNotEmpty &&
                c != 'Course Table' &&
                c != 'ICS Formatter',
          )
          .toList();
      if (teacherCandidates.isNotEmpty) {
        teacher = teacherCandidates.join(',');
      }
    }

    // 从描述中提取老师，如果有类似于 "实1301 王梅" 这样的模式
    if (teacher.isEmpty) {
      final description = eventData['description']?.toString() ?? '';
      if (description.isNotEmpty) {
        final cleanDesc = description
            .replaceAll(RegExp(r'\\n|\n|\\r|\r'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final parts = cleanDesc.split(' ').where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          teacher = parts.last;
        }
      }
    }

    // 针对用户提供的：把老师信息和教室内嵌的情况
    // 教务系统 ICS 往往会把地点写得很长 例如“8节\n实1301室\n张三,李四”
    // 所以再次强制清洗 teacher 字段
    teacher = teacher
        .replaceAll(RegExp(r'\\n|\n|\\r|\r'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 如果 location 包含类似 teacher 的逗号名，或者含有未清理干净的斜杠，可以进一步切分
    if (location.contains(',')) {
      // 简单试探性修复如果包含逗号可能包含名字
      final locParts = location.split(' ');
      if (locParts.length > 1) {
        String lastPart = locParts.last;
        // 姓名可能在最后一部分被连带上
        if (lastPart.contains(',') || lastPart.length < 5) {
          if (teacher.isEmpty) teacher = lastPart;
          location = location.replaceAll(lastPart, '').trim();
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
        final occurrences = rrule.getInstances(start: startUtc.toUtc());

        // 3. 遍历每一个计算出的时间点
        for (var occ in occurrences) {
          // 转换为本地时间 (假设用户在中国)
          final localStart = occ.toLocal();
          final localEnd = localStart.add(duration);

          instances.add(
            CourseEvent(
              name: summary,
              location: location,
              teacher: teacher,
              startTime: localStart.millisecondsSinceEpoch,
              endTime: localEnd.millisecondsSinceEpoch,
            ),
          );
        }
      } catch (e) {
        debugPrint('RRULE解析失败: $e, 使用默认处理');
        // 如果 RRULE 失败，至少添加第一次课程
        instances.add(
          CourseEvent(
            name: summary,
            location: location,
            teacher: teacher,
            startTime: startUtc.toLocal().millisecondsSinceEpoch,
            endTime: endUtc.toLocal().millisecondsSinceEpoch,
          ),
        );
      }
    } else {
      // --- D. 没有重复规则，直接添加 ---
      instances.add(
        CourseEvent(
          name: summary,
          location: location,
          teacher: teacher,
          startTime: startUtc.toLocal().millisecondsSinceEpoch,
          endTime: endUtc.toLocal().millisecondsSinceEpoch,
        ),
      );
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

  /// [v2.7.0] 自动从解析出的课程列表中推导 ScheduleConfigModel
  /// 返回一个新的 ScheduleConfigModel 对象，如果无法推导则返回空
  static ScheduleConfigModel? deduceConfigFromCourses(
    List<CourseEvent> courses,
    String rawIcsContent,
  ) {
    if (courses.isEmpty) return null;

    // 1. 推断开学日期
    CourseEvent earliestCourse = courses.first;
    for (var course in courses) {
      if (course.startTime < earliestCourse.startTime) {
        earliestCourse = course;
      }
    }
    final earliestDate = DateTime.fromMillisecondsSinceEpoch(
      earliestCourse.startTime,
    );
    final icsMonday = earliestDate.subtract(
      Duration(days: earliestDate.weekday - 1),
    );
    final semesterStartDate = DateTime(
      icsMonday.year,
      icsMonday.month,
      icsMonday.day,
    );

    // 2. 解析每节课对应的起止时间
    final Map<int, int> extractedStartTimes = {};
    final Map<int, int> extractedEndTimes = {};
    final Map<int, int> sectionDurations = {};
    final Map<int, int> sectionStartTimes = {};

    // 通过正则从原始 ICS 中匹配每个 VEVENT 的 description 提取 startSection 和 endSection
    final List<String> events = rawIcsContent.split('BEGIN:VEVENT');
    for (int i = 1; i < events.length; i++) {
      final vEvent = events[i];
      // 提取 DTSTART 和 DTEND
      final RegExp dtStartReg = RegExp(r'DTSTART(?:;[^:]*)?:(\d{8}T\d{6}Z?)');
      final RegExp dtEndReg = RegExp(r'DTEND(?:;[^:]*)?:(\d{8}T\d{6}Z?)');
      final RegExp descReg = RegExp(
        r'DESCRIPTION:.*?第\s*(\d+)\s*[-|到|~|～]\s*(\d+)\s*节',
        dotAll: true,
      );
      // 或者匹配 "[1-2节]" 这种
      final RegExp descReg2 = RegExp(
        r'DESCRIPTION:.*?\[\s*(\d+)\s*[-|到|~|～]\s*(\d+)\s*节\]',
        dotAll: true,
      );

      final dtStartMatch = dtStartReg.firstMatch(vEvent);
      final dtEndMatch = dtEndReg.firstMatch(vEvent);

      Match? secMatch = descReg.firstMatch(vEvent);
      secMatch ??= descReg2.firstMatch(vEvent);

      if (dtStartMatch != null && dtEndMatch != null && secMatch != null) {
        final startSection = int.tryParse(secMatch.group(1)!);
        final endSection = int.tryParse(secMatch.group(2)!);
        if (startSection == null || endSection == null) continue;

        final dtStartStr = dtStartMatch.group(1)!;
        final dtEndStr = dtEndMatch.group(1)!;

        DateTime startDt = _parseIcsDateTime(dtStartStr).toLocal();
        DateTime endDt = _parseIcsDateTime(dtEndStr).toLocal();

        final startMinutes = startDt.hour * 60 + startDt.minute;
        final endMinutes = endDt.hour * 60 + endDt.minute;

        // 保存此组合
        extractedStartTimes[startSection] = startMinutes;
        extractedEndTimes[endSection] = endMinutes;
      }
    }

    // 3. 推算未提取到的节次时间并生成完整的 1-12 节配置
    if (extractedStartTimes.isEmpty) {
      return ScheduleConfigModel.defaultConfig().copyWith(
        semesterStartDate: semesterStartDate,
      );
    }

    // 假设等长时间
    int totalClassDuration = 0;
    int classesCount = 0;

    extractedStartTimes.forEach((startSec, startMin) {
      if (extractedEndTimes.containsKey(startSec)) {
        totalClassDuration += (extractedEndTimes[startSec]! - startMin);
        classesCount++;
      } else {
        int? matchingEndSec;
        for (int endSec = startSec; endSec <= 12; endSec++) {
          if (extractedEndTimes.containsKey(endSec)) {
            matchingEndSec = endSec;
            break;
          }
        }
        if (matchingEndSec != null && matchingEndSec >= startSec) {
          totalClassDuration +=
              ((extractedEndTimes[matchingEndSec]! - startMin) /
                      (matchingEndSec - startSec + 1))
                  .round();
          classesCount++;
        }
      }
    });

    final int defaultDuration = classesCount > 0
        ? (totalClassDuration / classesCount).round()
        : 45;

    // 如果找不到指定的 section，用前后的推断
    for (int i = 1; i <= 12; i++) {
      sectionDurations[i] = defaultDuration;
    }

    // 补全 sectionStartTimes
    final List<int> sortedSections = extractedStartTimes.keys.toList()..sort();

    if (sortedSections.isNotEmpty) {
      for (int i = 1; i <= 12; i++) {
        if (extractedStartTimes.containsKey(i)) {
          sectionStartTimes[i] = extractedStartTimes[i]!;
        } else {
          // 往前找最近的已知起点
          int prevAnc = -1;
          for (int j = i - 1; j >= 1; j--) {
            if (extractedStartTimes.containsKey(j)) {
              prevAnc = j;
              break;
            }
          }
          if (prevAnc != -1) {
            int gap = i - prevAnc;
            sectionStartTimes[i] =
                extractedStartTimes[prevAnc]! + gap * (defaultDuration + 10);
          } else {
            // 往后找最近的起点
            int nextAnc = -1;
            for (int j = i + 1; j <= 12; j++) {
              if (extractedStartTimes.containsKey(j)) {
                nextAnc = j;
                break;
              }
            }
            if (nextAnc != -1) {
              int gap = nextAnc - i;
              sectionStartTimes[i] =
                  extractedStartTimes[nextAnc]! - gap * (defaultDuration + 10);
            } else {
              sectionStartTimes[i] = 480 + (i - 1) * (defaultDuration + 10);
            }
          }
        }
      }
    } else {
      for (int i = 1; i <= 12; i++) {
        sectionStartTimes[i] = 480 + (i - 1) * (defaultDuration + 10);
      }
    }

    return ScheduleConfigModel(
      semesterStartDate: semesterStartDate,
      sectionStartTimes: sectionStartTimes,
      sectionDurations: sectionDurations,
      breakTime: 10,
      useCustomConfig: true,
      showWeekends: true,
      isEqualDuration: true,
      defaultDuration: defaultDuration,
    );
  }
}
