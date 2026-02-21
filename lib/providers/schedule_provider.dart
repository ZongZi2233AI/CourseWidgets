import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/course_event.dart';
import '../services/data_import_service.dart';
import '../services/storage_service.dart'; // [v2.3.0] 用于清除配置数据
import '../models/schedule_config.dart';
import '../services/database_helper.dart';

/// 课表状态管理器 - 基于SQLite数据库
class ScheduleProvider with ChangeNotifier {
  final DataImportService _importService = DataImportService();

  List<CourseEvent> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 当前显示状态
  int _currentWeek = 1;
  int _currentDay = 1; // 1-7, 周一到周日
  DateTime _semesterStartDate = DateTime(2025, 9, 1); // 学期开始日期

  // 课时配置
  ScheduleConfigModel _currentConfig = ScheduleConfigModel.defaultConfig();

  List<CourseEvent> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _courses.isNotEmpty;

  int get currentWeek => _currentWeek;
  int get currentDay => _currentDay;
  DateTime get semesterStartDate => _semesterStartDate;
  ScheduleConfigModel get currentConfig => _currentConfig;

  // 缓存有效周次
  List<int> _availableWeeks = [1];

  /// 获取所有有效周次（使用缓存）
  List<int> get availableWeeks => _availableWeeks;

  /// 刷新有效周次缓存
  Future<void> _refreshAvailableWeeks() async {
    _availableWeeks = await _importService.getAvailableWeeks(
      _semesterStartDate,
    );
    if (_availableWeeks.isEmpty) {
      _availableWeeks = [1];
    }
    notifyListeners();
  }

  /// 导入数据（ICS文件）
  Future<bool> importData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _importService.importFromIcsFile();
      if (result != null) {
        _courses = result;
        await _refreshAvailableWeeks(); // 刷新缓存

        // 自动跳转到当前日期对应的周次和星期
        await _jumpToCurrentDate();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = '导入失败: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 导入HTML数据
  Future<bool> importHtmlData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _importService.importFromHtmlFile();
      if (result != null) {
        _courses = result;
        await _refreshAvailableWeeks(); // 刷新缓存

        // 自动跳转到当前日期对应的周次和星期
        await _jumpToCurrentDate();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'HTML导入失败: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 从assets导入（用于测试）
  Future<bool> importFromAssets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _importService.importFromAssets();
      if (result != null) {
        _courses = result;
        await _refreshAvailableWeeks(); // 刷新缓存

        _currentWeek = 1;
        _currentDay = DateTime.now().weekday;
        if (_currentDay > 5) _currentDay = 1;

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = '从assets导入失败: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 加载保存的数据
  Future<void> loadSavedData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final courses = await _importService.getAllCourses();
      if (courses.isNotEmpty) {
        _courses = courses;
        await _refreshAvailableWeeks(); // 刷新缓存

        // [v2.3.0修复] 确保数据加载完成后再跳转
        // 使用 Future.microtask 确保在下一个事件循环中执行
        await Future.microtask(() async {
          await _jumpToCurrentDate();
          debugPrint('✅ 数据加载完成，已跳转到当前日期：第 $_currentWeek 周，星期 $_currentDay');
        });
      } else {
        // 没有数据时，确保周次和星期有效
        _availableWeeks = [1];
        if (_currentWeek < 1) _currentWeek = 1;
        if (_currentDay < 1 || _currentDay > 7) _currentDay = 1;
        debugPrint('⚠️ 没有课程数据，使用默认周次和星期');
      }
    } catch (e) {
      _errorMessage = '加载数据失败: $e';
      debugPrint('❌ 加载数据失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ... (keeping other methods same until getAvailableWeeks)

  /// 导出数据
  Future<bool> exportData() async {
    if (_courses.isEmpty) return false;

    try {
      final result = await _importService.exportData();
      return result;
    } catch (e) {
      _errorMessage = '导出失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 清除数据
  Future<void> clearData() async {
    // 清除数据库中的课程数据
    await _importService.clearAllData();

    // [v2.3.0修复] 清除 MMKV 中的课程相关配置
    final storage = StorageService();
    await storage.remove('semester_start_date');
    await storage.remove('schedule_config');
    await storage.remove('current_week');
    await storage.remove('current_day');

    // 重置状态
    _courses = [];
    _availableWeeks = [1]; // 重置周次缓存
    _currentWeek = 1;
    _currentDay = 1;
    _semesterStartDate = DateTime(2025, 9, 1);
    _currentConfig = ScheduleConfigModel.defaultConfig();

    notifyListeners();

    debugPrint('✅ 所有数据已清除（包括数据库和配置）');
  }

  /// 设置当前周次
  void setCurrentWeek(int week) {
    if (_currentWeek != week) {
      _currentWeek = week;
      debugPrint('📅 切换到第 $week 周');
      notifyListeners();
    }
  }

  /// 设置当前星期
  void setCurrentDay(int day) {
    if (day >= 1 && day <= 7 && _currentDay != day) {
      _currentDay = day;
      debugPrint('📅 切换到星期 $day');
      notifyListeners();
    }
  }

  /// 获取当前周次的所有课程
  List<CourseEvent> getCurrentWeekCourses() {
    final weekCourses = _courses.where((course) {
      final week = course.getWeekNumber(_semesterStartDate);
      return week == _currentWeek;
    }).toList();
    debugPrint('📚 第 $_currentWeek 周共有 ${weekCourses.length} 节课');
    return weekCourses;
  }

  /// 获取当前选中日期的课程
  List<CourseEvent> getCurrentDayCourses() {
    final weekCourses = getCurrentWeekCourses();
    final dayCourses = weekCourses
        .where((course) => course.weekday == _currentDay)
        .toList();
    debugPrint('📚 星期 $_currentDay 共有 ${dayCourses.length} 节课');
    return dayCourses;
  }

  /// 获取指定星期的课程（用于平板模式的周视图）
  List<CourseEvent> getCoursesForDay(int day) {
    final weekCourses = getCurrentWeekCourses();
    return weekCourses.where((course) => course.weekday == day).toList();
  }

  /// 获取下一个课程
  CourseEvent? getNextCourse() {
    final now = DateTime.now();
    final todayCourses = _courses.where((course) {
      final courseDate = DateTime.fromMillisecondsSinceEpoch(course.startTime);
      return courseDate.year == now.year &&
          courseDate.month == now.month &&
          courseDate.day == now.day;
    }).toList();

    for (var course in todayCourses) {
      if (course.startTime > now.millisecondsSinceEpoch) {
        return course;
      }
    }

    return null;
  }

  /// 获取所有有效周次（即将废弃，请使用 availableWeeks getter）
  Future<List<int>> getAvailableWeeks_deprecated() async {
    if (_availableWeeks.isNotEmpty && _availableWeeks.length > 1) {
      return _availableWeeks;
    }
    // Fallback if needed, but normally use cache
    _availableWeeks = await _importService.getAvailableWeeks(
      _semesterStartDate,
    );
    return _availableWeeks;
  }

  /// 兼容旧版调用的方法
  Future<List<int>> getAvailableWeeks() async {
    return getAvailableWeeks_deprecated();
  }

  /// 获取所有有效星期
  List<int> getAvailableDays() {
    final days = _courses.map((e) => e.weekday).toSet().toList();
    days.sort();
    return days;
  }

  /// 获取星期名称
  String getDayName(int day) {
    const dayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return dayNames[day];
  }

  /// 检查是否需要提醒（5分钟内开始）
  bool needsReminder(CourseEvent course) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = course.startTime - now;
    final minutes = difference ~/ 60000;
    return minutes >= 0 && minutes <= 5;
  }

  /// 设置学期开始日期
  void setSemesterStartDate(DateTime date) {
    _semesterStartDate = date;
    notifyListeners();
  }

  /// 更新课时配置
  void updateConfig(ScheduleConfigModel newConfig) {
    _currentConfig = newConfig;
    _semesterStartDate = newConfig.semesterStartDate;
    notifyListeners();
  }

  /// 使用默认配置
  void useDefaultConfig() {
    _currentConfig = ScheduleConfigModel.defaultConfig();
    _semesterStartDate = _currentConfig.semesterStartDate;
    notifyListeners();
  }

  /// 从HTML导入（带配置）
  Future<bool> importHtmlDataWithConfig(ScheduleConfigModel config) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 先更新配置
      _currentConfig = config;

      // 使用HTML导入服务，但需要传递配置
      final result = await _importService.importFromHtmlFile();
      if (result != null) {
        _courses = result;
        _currentWeek = 1;
        _currentDay = DateTime.now().weekday;
        if (_currentDay > 5) _currentDay = 1;

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'HTML导入失败: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 获取配置描述
  String getConfigDescription() {
    return _currentConfig.getDescription();
  }

  /// 自动跳转到当前日期对应的周次和星期
  Future<void> _jumpToCurrentDate() async {
    if (_courses.isEmpty) return;

    final now = DateTime.now();
    final availableWeeks = this.availableWeeks;

    if (availableWeeks.isEmpty) return;

    // 计算当前日期相对于学期开始日期的周次
    final weeksSinceStart = now.difference(_semesterStartDate).inDays ~/ 7 + 1;

    // 检查课程是否已经结束
    final maxWeek = availableWeeks.last;
    final minWeek = availableWeeks.first;

    if (weeksSinceStart < minWeek) {
      // 课程还没开始，显示第一周
      _currentWeek = minWeek;
      _currentDay = now.weekday;
    } else if (weeksSinceStart > maxWeek) {
      // 课程已结束，显示最后一周
      _currentWeek = maxWeek;
      _currentDay = now.weekday;
      // 显示假期提示
      _errorMessage = '本学期课程已结束，当前显示最后一周课程';
    } else {
      // 课程进行中，显示当前周
      _currentWeek = weeksSinceStart;
      _currentDay = now.weekday;
    }

    // 确保星期在有效范围内（1-7）
    if (_currentDay < 1 || _currentDay > 7) {
      _currentDay = 1; // 默认显示周一
    }

    // 如果当前天是周末，且没有课程，自动切换到周一
    if (_currentDay > 5) {
      final dayCourses = _courses.where((course) {
        final week = course.getWeekNumber(_semesterStartDate);
        return week == _currentWeek && course.weekday == _currentDay;
      }).toList();

      if (dayCourses.isEmpty) {
        _currentDay = 1; // 切换到周一
      }
    }
  }

  /// 开机自动生成测试课程（从本周开始往后生成4个星期）
  Future<void> generateTestCourses() async {
    // 检查是否已有数据，如果有则不生成
    if (_courses.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 生成4周的测试数据
      final testCourses = <CourseEvent>[];

      // 定义一些测试课程
      final testCourseTemplates = [
        {
          'name': '高等数学',
          'location': '教学楼A101',
          'teacher': '张教授',
          'dayOfWeek': 1, // 周一
          'startSection': 1,
          'endSection': 2,
        },
        {
          'name': '大学英语',
          'location': '教学楼B202',
          'teacher': '李老师',
          'dayOfWeek': 2, // 周二
          'startSection': 3,
          'endSection': 4,
        },
        {
          'name': '计算机基础',
          'location': '实验楼C303',
          'teacher': '王老师',
          'dayOfWeek': 3, // 周三
          'startSection': 5,
          'endSection': 6,
        },
        {
          'name': '体育',
          'location': '操场',
          'teacher': '刘教练',
          'dayOfWeek': 4, // 周四
          'startSection': 7,
          'endSection': 8,
        },
        {
          'name': '线性代数',
          'location': '教学楼D404',
          'teacher': '陈教授',
          'dayOfWeek': 5, // 周五
          'startSection': 1,
          'endSection': 2,
        },
      ];

      // 为每个模板生成4周的课程
      for (int week = 0; week < 4; week++) {
        for (var template in testCourseTemplates) {
          final dayOfWeek = template['dayOfWeek'] as int;
          final startSection = template['startSection'] as int;
          final endSection = template['endSection'] as int;

          // 计算具体日期 (保留注释)

          // 使用当前配置计算时间
          final startTime = _currentConfig.getStartTime(
            week + 1,
            dayOfWeek,
            startSection,
          );
          final endTime = _currentConfig.getEndTimeWithDuration(
            week + 1,
            dayOfWeek,
            startSection,
            endSection,
          );

          final course = CourseEvent(
            name: template['name'] as String,
            location: template['location'] as String,
            teacher: template['teacher'] as String,
            startTime: startTime.millisecondsSinceEpoch,
            endTime: endTime.millisecondsSinceEpoch,
          );

          testCourses.add(course);
        }
      }

      // 保存到数据库
      final db = DatabaseHelper.instance;
      await db.clearAll();
      await db.insertCourses(testCourses);

      // 保存到历史记录
      final courseData = testCourses.map((e) => e.toMap()).toList();
      final courseDataJson = jsonEncode(courseData);

      await db.saveScheduleHistory(
        name: '测试课表_${DateTime.now().toString().substring(0, 16)}',
        sourceType: 'test',
        sourceData: 'auto_generated',
        courseData: courseDataJson,
        semester: '2025-2026学年',
      );

      _courses = testCourses;

      // 自动跳转到当前日期
      await _jumpToCurrentDate();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '生成测试课程失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 检查当前是否在学期内
  bool isDuringSemester() {
    if (_courses.isEmpty) return false;

    // 注意：这里需要同步获取，实际使用时可能需要调整
    return true; // 简化处理
  }

  /// 获取学期状态描述
  String getSemesterStatus() {
    if (_courses.isEmpty) return '无课程数据';

    final now = DateTime.now();
    final weeksSinceStart = now.difference(_semesterStartDate).inDays ~/ 7 + 1;

    // 这里需要同步获取可用周次，暂时简化处理
    // 实际使用时应该缓存可用周次
    return '第$weeksSinceStart周';
  }
}
