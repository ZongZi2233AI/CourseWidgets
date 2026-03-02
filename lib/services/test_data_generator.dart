import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/course_event.dart';

/// [v2.2.8] 测试数据生成器
/// 生成模拟课表数据用于演示和测试
class TestDataGenerator {
  static final Random _random = Random();

  // 课程名称池
  static const List<String> _courseNames = [
    '高等数学',
    '线性代数',
    '大学物理',
    '程序设计',
    '数据结构',
    '计算机网络',
    '操作系统',
    '数据库原理',
    '软件工程',
    '人工智能',
    '机器学习',
    '大学英语',
    '思想政治',
    '大学体育',
  ];

  // 教室池
  static const List<String> _locations = [
    '教A-101',
    '教A-202',
    '教A-303',
    '教B-101',
    '教B-205',
    '教C-301',
    '实验楼-401',
    '实验楼-502',
    '图书馆-201',
    '体育馆',
  ];

  // 教师姓名池
  static const List<String> _teachers = [
    '张教授',
    '李老师',
    '王教授',
    '刘老师',
    '陈教授',
    '杨老师',
    '赵教授',
    '孙老师',
    '周教授',
    '吴老师',
  ];

  /// 生成测试课表数据
  /// 根据当前日期智能生成：
  /// - 工作日：生成本周 + 下周
  /// - 周末：生成下周 + 下下周
  static List<CourseEvent> generateTestData() {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    List<CourseEvent> courses = [];

    if (isWeekend) {
      // 周末：生成下周和下下周
      debugPrint('📅 周末模式：生成下周和下下周的课表');
      final nextMonday = _getNextMonday(now);
      courses.addAll(_generateWeekCourses(nextMonday)); // 下周
      courses.addAll(
        _generateWeekCourses(nextMonday.add(const Duration(days: 7))),
      ); // 下下周
    } else {
      // 工作日：生成本周和下周
      debugPrint('📅 工作日模式：生成本周和下周的课表');
      final thisMonday = _getThisMonday(now);
      courses.addAll(_generateWeekCourses(thisMonday)); // 本周
      courses.addAll(
        _generateWeekCourses(thisMonday.add(const Duration(days: 7))),
      ); // 下周
    }

    debugPrint('✅ 生成了 ${courses.length} 节测试课程');
    return courses;
  }

  /// 获取本周一
  static DateTime _getThisMonday(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysFromMonday));
  }

  /// 获取下周一
  static DateTime _getNextMonday(DateTime date) {
    final thisMonday = _getThisMonday(date);
    return thisMonday.add(const Duration(days: 7));
  }

  /// 生成一周的课程（周一到周五）
  static List<CourseEvent> _generateWeekCourses(DateTime monday) {
    List<CourseEvent> courses = [];

    // 周一到周五
    for (int day = 0; day < 5; day++) {
      final date = monday.add(Duration(days: day));

      // 每天 4-6 节课
      final coursesPerDay = 4 + _random.nextInt(3);

      // 生成当天的课程
      courses.addAll(_generateDayCourses(date, coursesPerDay));
    }

    return courses;
  }

  /// 生成一天的课程
  static List<CourseEvent> _generateDayCourses(DateTime date, int count) {
    List<CourseEvent> courses = [];

    // 课程时间表（上午、下午、晚上）
    final List<List<int>> timeSlots = [
      [8, 0, 9, 40], // 第1-2节
      [10, 0, 11, 40], // 第3-4节
      [14, 0, 15, 40], // 第5-6节
      [16, 0, 17, 40], // 第7-8节
      [19, 0, 20, 40], // 第9-10节
    ];

    // 随机选择时间段
    final selectedSlots = List<int>.generate(timeSlots.length, (i) => i)
      ..shuffle(_random);

    for (int i = 0; i < count && i < selectedSlots.length; i++) {
      final slot = timeSlots[selectedSlots[i]];

      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        slot[0],
        slot[1],
      );

      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        slot[2],
        slot[3],
      );

      courses.add(
        CourseEvent(
          id: startTime.millisecondsSinceEpoch,
          name: _courseNames[_random.nextInt(_courseNames.length)],
          location: _locations[_random.nextInt(_locations.length)],
          teacher: _teachers[_random.nextInt(_teachers.length)],
          startTime: startTime.millisecondsSinceEpoch,
          endTime: endTime.millisecondsSinceEpoch,
        ),
      );
    }

    // 按时间排序
    courses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return courses;
  }

  /// 生成单个测试课程（用于快速测试）
  static CourseEvent generateSingleCourse({
    DateTime? startTime,
    int durationMinutes = 100,
  }) {
    final start = startTime ?? DateTime.now().add(const Duration(minutes: 15));
    final end = start.add(Duration(minutes: durationMinutes));

    return CourseEvent(
      id: start.millisecondsSinceEpoch,
      name: _courseNames[_random.nextInt(_courseNames.length)],
      location: _locations[_random.nextInt(_locations.length)],
      teacher: _teachers[_random.nextInt(_teachers.length)],
      startTime: start.millisecondsSinceEpoch,
      endTime: end.millisecondsSinceEpoch,
    );
  }
}
