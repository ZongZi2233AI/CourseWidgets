import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart';
import 'ics_parser.dart';
import 'database_helper.dart';
import 'html_to_ics_converter.dart';
import '../models/course_event.dart';
import '../models/schedule_config.dart';

/// 数据导入服务 - 支持ICS和HTML格式
class DataImportService {
  /// 选择ICS文件并导入
  Future<List<CourseEvent>?> importFromIcsFile() async {
    try {
      const typeGroup = XTypeGroup(label: 'ics', extensions: ['ics']);

      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        return null;
      }

      String icsContent;

      if (kIsWeb) {
        // Web平台需要特殊处理
        final bytes = await file.readAsBytes();
        icsContent = String.fromCharCodes(bytes);
      } else {
        icsContent = await File(file.path).readAsString();
      }

      // 解析ICS内容
      final courses = IcsParser.parse(icsContent);

      // 保存到数据库
      await DatabaseHelper.instance.insertCourses(courses);

      // 保存到历史记录
      await _saveToHistory(
        name: 'ICS导入_${DateTime.now().toString().substring(0, 16)}',
        sourceType: 'ics',
        sourceData: icsContent,
        courses: courses,
        semester: '2025-2026学年',
      );

      return courses;
    } catch (e) {
      debugPrint('ICS导入失败: $e');
      return null;
    }
  }

  /// 选择HTML文件并导入
  Future<List<CourseEvent>?> importFromHtmlFile() async {
    try {
      const typeGroup = XTypeGroup(label: 'html', extensions: ['html', 'json']);

      final file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        return null;
      }

      String htmlContent;

      if (kIsWeb) {
        // Web平台需要特殊处理
        final bytes = await file.readAsBytes();
        htmlContent = String.fromCharCodes(bytes);
      } else {
        htmlContent = await File(file.path).readAsString();
      }

      // 使用HTML转换器转换为ICS
      String? icsContent = await HtmlImportService.convertHtmlToIcs(
        htmlContent,
      );

      if (icsContent == null) {
        debugPrint('HTML转换ICS失败');
        return null;
      }

      // 解析ICS内容
      final courses = IcsParser.parse(icsContent);

      // 保存到数据库
      await DatabaseHelper.instance.insertCourses(courses);

      // 保存到历史记录
      await _saveToHistory(
        name: 'HTML导入_${DateTime.now().toString().substring(0, 16)}',
        sourceType: 'html',
        sourceData: htmlContent,
        courses: courses,
        semester: '2025-2026学年',
      );

      return courses;
    } catch (e) {
      debugPrint('HTML导入失败: $e');
      return null;
    }
  }

  /// [v2.5.9] 从 HTML 字符串直接导入（用于 WebView 抓取）
  Future<List<CourseEvent>?> importFromHtmlString(String htmlContent) async {
    try {
      String? icsContent = await HtmlImportService.convertHtmlToIcs(
        htmlContent,
      );
      if (icsContent == null) {
        debugPrint('HTML字符串转换ICS失败');
        return null;
      }
      final courses = IcsParser.parse(icsContent);
      if (courses.isEmpty) return null;

      await DatabaseHelper.instance.insertCourses(courses);
      await _saveToHistory(
        name: '教务导入_${DateTime.now().toString().substring(0, 16)}',
        sourceType: 'webview_html',
        sourceData: htmlContent.length > 10000
            ? htmlContent.substring(0, 10000)
            : htmlContent,
        courses: courses,
        semester: '2025-2026学年',
      );
      return courses;
    } catch (e) {
      debugPrint('HTML字符串导入失败: $e');
      return null;
    }
  }

  /// [v2.6.0] 专门接收 Webview WebView Javascript `courses` 原生解析数组
  /// [v2.6.5] 接受用户配置来计算正确的时间戳
  Future<List<CourseEvent>?> importFromJsonData(
    List<dynamic> jsonList, {
    ScheduleConfigModel? config,
  }) async {
    try {
      // [v2.6.5] 使用用户配置而非默认配置，确保时间戳与用户的学期日期匹配
      final configModel = config ?? ScheduleConfigModel.defaultConfig();

      // 步骤1: 解析所有条目，按(name, teacher, location, dayOfWeek, weeks)分组
      // 同组内合并连续 section
      final Map<String, _CourseGroup> groups = {};

      for (var item in jsonList) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final teacher = (item['teacher'] ?? '').toString().trim();
        final location = (item['location'] ?? '').toString().trim();
        final dayOfWeekRaw = item['dayOfWeek'] ?? 1;
        final int dayOfWeek = dayOfWeekRaw is num
            ? dayOfWeekRaw.toInt()
            : int.parse(dayOfWeekRaw.toString());
        final sectionRaw = item['section'] ?? 1;
        final int section = sectionRaw is num
            ? sectionRaw.toInt()
            : int.parse(sectionRaw.toString());
        final String weeksStr = (item['weeks'] ?? '').toString();

        // 解析 weeks 位串 → 周次列表
        List<int> weeksList = [];
        for (int i = 0; i < weeksStr.length; i++) {
          if (weeksStr[i] == '1') weeksList.add(i + 1);
        }
        // 如果没有解析到周次，默认1-20周
        if (weeksList.isEmpty) {
          weeksList = List.generate(20, (i) => i + 1);
        }

        final key = '$name|$teacher|$location|$dayOfWeek|$weeksStr';
        groups.putIfAbsent(
          key,
          () => _CourseGroup(
            name: name,
            teacher: teacher,
            location: location,
            dayOfWeek: dayOfWeek,
            weeks: weeksList,
          ),
        );
        groups[key]!.sections.add(section);
      }

      if (groups.isEmpty) return null;

      // 步骤2: 合并连续节次 → 生成 CourseEvent
      List<CourseEvent> courses = [];

      for (var group in groups.values) {
        // 排序 sections 并合并连续的
        final sortedSections = group.sections.toList()..sort();
        List<List<int>> mergedRanges = [];
        List<int> current = [sortedSections.first];

        for (int i = 1; i < sortedSections.length; i++) {
          if (sortedSections[i] == current.last + 1) {
            current.add(sortedSections[i]);
          } else {
            mergedRanges.add(current);
            current = [sortedSections[i]];
          }
        }
        mergedRanges.add(current);

        // 对每个合并后的节次范围 × 每个周次 → 生成一个 CourseEvent
        for (var range in mergedRanges) {
          final startSection = range.first;
          final endSection = range.last;

          for (var week in group.weeks) {
            final startTime = configModel.getStartTime(
              week,
              group.dayOfWeek,
              startSection,
            );
            final endTime = configModel.getEndTimeWithDuration(
              week,
              group.dayOfWeek,
              startSection,
              endSection,
            );

            courses.add(
              CourseEvent(
                name: group.name,
                location: group.location,
                teacher: group.teacher,
                startTime: startTime.millisecondsSinceEpoch,
                endTime: endTime.millisecondsSinceEpoch,
              ),
            );
          }
        }
      }

      if (courses.isEmpty) return null;

      // 按时间排序
      courses.sort((a, b) => a.startTime.compareTo(b.startTime));

      await DatabaseHelper.instance.insertCourses(courses);
      await _saveToHistory(
        name: '教务极速捕获_${DateTime.now().toString().substring(0, 16)}',
        sourceType: 'webview_json',
        sourceData: jsonEncode(jsonList),
        courses: courses,
        semester: '2025-2026学年',
      );
      return courses;
    } catch (e) {
      debugPrint('JSON原生导入失败: $e');
      return null;
    }
  }

  /// 从assets导入（用于测试）
  Future<List<CourseEvent>?> importFromAssets() async {
    try {
      // 注意：需要在pubspec.yaml中声明assets
      final icsContent = await File('assets/calendar.ics').readAsString();
      final courses = IcsParser.parse(icsContent);

      // 保存到数据库
      await DatabaseHelper.instance.insertCourses(courses);

      // 保存到历史记录
      await _saveToHistory(
        name: 'Assets导入_${DateTime.now().toString().substring(0, 16)}',
        sourceType: 'ics',
        sourceData: icsContent,
        courses: courses,
        semester: '2025-2026学年',
      );

      return courses;
    } catch (e) {
      debugPrint('从assets导入失败: $e');
      return null;
    }
  }

  /// 保存到历史记录
  Future<void> _saveToHistory({
    required String name,
    required String sourceType,
    required String sourceData,
    required List<CourseEvent> courses,
    required String semester,
  }) async {
    try {
      // 将课程转换为JSON数据
      final courseData = courses.map((e) => e.toMap()).toList();
      final courseDataJson = jsonEncode(courseData);

      await DatabaseHelper.instance.saveScheduleHistory(
        name: name,
        sourceType: sourceType,
        sourceData: sourceData,
        courseData: courseDataJson,
        semester: semester,
      );

      // 清理旧的历史记录
      await DatabaseHelper.instance.cleanupOldHistory();

      debugPrint('已保存到历史记录: $name');
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
  }

  /// 获取所有历史记录
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    return await DatabaseHelper.instance.getAllScheduleHistory();
  }

  /// 获取当前激活的课程表
  Future<Map<String, dynamic>?> getActiveSchedule() async {
    return await DatabaseHelper.instance.getActiveSchedule();
  }

  /// 切换到指定的历史记录
  Future<bool> switchToHistory(int id) async {
    final success = await DatabaseHelper.instance.switchToSchedule(id);
    if (success) {
      // 重新加载该历史记录的课程数据
      final db = await DatabaseHelper.instance.database;
      final historyResult = await db.query(
        'schedule_history',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (historyResult.isNotEmpty) {
        final sourceType = historyResult.first['source_type'] as String;
        final courseDataStr = historyResult.first['course_data'] as String;
        final courseDataRaw = jsonDecode(courseDataStr) as List;
        final courseDataList = courseDataRaw.cast<Map<String, dynamic>>();

        List<CourseEvent> courses = [];
        if (sourceType == 'html') {
          // [v2.6.5修复] HTML导入通过 ICS 转换器生成完整的 CourseEvent（带时间戳）
          final htmlCourses = HtmlImportService.restoreCourseData(
            courseDataList,
          );
          // 使用应用当前的排课配置对象而不是固定时间
          final fakeConfig = ScheduleConfig();
          final icsStr = IcsGenerator.generate(htmlCourses, fakeConfig);
          courses = IcsParser.parse(icsStr);
        } else {
          // webview_json 或常规完整 ICS 导入，直接带有完整 toMap 结构
          courses = courseDataList.map((e) => CourseEvent.fromMap(e)).toList();
        }

        // [v2.7.0] 先清空主表再写入历史数据，防止累加
        await DatabaseHelper.instance.clearAll();
        await DatabaseHelper.instance.insertCourses(courses);
      }
    }
    return success;
  }

  /// 删除历史记录
  Future<bool> deleteHistory(int id) async {
    return await DatabaseHelper.instance.deleteScheduleHistory(id);
  }

  /// 导出指定历史记录为ICS文件，返回文件路径
  Future<String?> exportHistoryToIcs(int id) async {
    try {
      final icsContent = await DatabaseHelper.instance.exportScheduleToIcs(id);
      if (icsContent == null) return null;

      // 保存文件 - 使用Documents目录作为导出路径
      String exportDir;
      try {
        if (Platform.isWindows) {
          // 使用用户文档目录
          final appData = Platform.environment['USERPROFILE'] ?? '.';
          exportDir = join(appData, 'Documents', 'ScheduleExports');
        } else if (Platform.isAndroid) {
          // Android使用外部存储目录
          exportDir = '/storage/emulated/0/Download';
        } else {
          exportDir = '.';
        }

        // 确保目录存在
        final dir = Directory(exportDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (e) {
        // 如果失败，使用当前工作目录
        exportDir = '.';
      }

      final fileName =
          'schedule_export_${DateTime.now().millisecondsSinceEpoch}.ics';
      final filePath = join(exportDir, fileName);

      await File(filePath).writeAsString(icsContent);

      debugPrint('ICS文件已导出到: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('导出ICS失败: $e');
      return null;
    }
  }

  /// 导出当前数据为JSON文件
  Future<bool> exportData() async {
    try {
      final courses = await DatabaseHelper.instance.getAllCourses();
      if (courses.isEmpty) return false;

      // 使用Documents目录作为导出路径
      String exportDir;
      try {
        if (Platform.isWindows) {
          // 使用用户文档目录
          final appData = Platform.environment['USERPROFILE'] ?? '.';
          exportDir = join(appData, 'Documents', 'ScheduleExports');
        } else if (Platform.isAndroid) {
          // Android使用外部存储目录
          exportDir = '/storage/emulated/0/Download';
        } else {
          exportDir = '.';
        }

        // 确保目录存在
        final dir = Directory(exportDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (e) {
        // 如果失败，使用当前工作目录
        exportDir = '.';
      }

      final fileName =
          'schedule_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = join(exportDir, fileName);

      // 转换为可序列化的格式
      final jsonData = courses.map((e) => e.toMap()).toList();
      final jsonString = jsonEncode(jsonData);

      await File(filePath).writeAsString(jsonString);

      debugPrint('数据已导出到: $filePath');
      return true;
    } catch (e) {
      debugPrint('导出数据失败: $e');
      return false;
    }
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    await DatabaseHelper.instance.clearAll();
  }

  /// 获取所有课程
  Future<List<CourseEvent>> getAllCourses() async {
    return await DatabaseHelper.instance.getAllCourses();
  }

  /// 获取指定日期的课程
  Future<List<CourseEvent>> getCoursesByDate(DateTime date) async {
    return await DatabaseHelper.instance.getCoursesByDate(date);
  }

  /// 获取指定周次的课程
  Future<List<CourseEvent>> getCoursesByWeek(
    int week,
    DateTime startDate,
  ) async {
    return await DatabaseHelper.instance.getCoursesByWeek(week, startDate);
  }

  /// 获取所有可用周次
  Future<List<int>> getAvailableWeeks(DateTime startDate) async {
    return await DatabaseHelper.instance.getAvailableWeeks(startDate);
  }

  /// [v2.2.9] 删除单节课程
  Future<bool> deleteCourse(CourseEvent course) async {
    try {
      await DatabaseHelper.instance.deleteCourse(course.startTime);
      debugPrint('已删除课程: ${course.name}');
      return true;
    } catch (e) {
      debugPrint('删除课程失败: $e');
      return false;
    }
  }

  /// [v2.2.9] 删除所有同名课程
  Future<bool> deleteAllCoursesWithName(String courseName) async {
    try {
      await DatabaseHelper.instance.deleteAllCoursesWithName(courseName);
      debugPrint('已删除所有课程: $courseName');
      return true;
    } catch (e) {
      debugPrint('删除所有课程失败: $e');
      return false;
    }
  }
}

/// 课程分组辅助类
class _CourseGroup {
  final String name;
  final String teacher;
  final String location;
  final int dayOfWeek;
  final List<int> weeks;
  final Set<int> sections = {};

  _CourseGroup({
    required this.name,
    required this.teacher,
    required this.location,
    required this.dayOfWeek,
    required this.weeks,
  });
}
