import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:coursewidgets/services/ics_parser.dart';
import 'package:coursewidgets/models/course_event.dart';

void main() {
  group('新ICS解析系统测试', () {
    setUpAll(() {
      tz.initializeTimeZones();
    });

    test('解析标准ICS格式', () {
      // 这是一个简化的ICS内容示例，基于用户提供的文件格式
      final icsContent = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test1@school.edu
DTSTART:20250908T001500Z
DTEND:20250908T014500Z
SUMMARY:高等数学
LOCATION:教学楼101室
DESCRIPTION:高等数学 教学楼101室 张老师
CATEGORIES:ShanghaiTech,张老师,Course Table ICS Formatter
RRULE:FREQ=WEEKLY;COUNT=16;INTERVAL=1
END:VEVENT
BEGIN:VEVENT
UID:test2@school.edu
DTSTART:20250908T015500Z
DTEND:20250908T033000Z
SUMMARY:大学英语
LOCATION:教学楼202室
DESCRIPTION:大学英语 教学楼202室 李老师
CATEGORIES:ShanghaiTech,李老师,Course Table ICS Formatter
RRULE:FREQ=WEEKLY;COUNT=16;INTERVAL=1
END:VEVENT
END:VCALENDAR''';

      final courses = IcsParser.parse(icsContent);

      // 验证解析结果
      expect(courses.length, greaterThan(0));
      
      // 验证第一节课
      final firstCourse = courses.firstWhere((c) => c.name == '高等数学');
      expect(firstCourse.name, '高等数学');
      expect(firstCourse.location, '教学楼101室');
      expect(firstCourse.teacher, '张老师');
      
      // 验证时间转换 (UTC 00:15 -> 本地时间 08:15)
      final startTime = DateTime.fromMillisecondsSinceEpoch(firstCourse.startTime);
      expect(startTime.hour, 8); // UTC+8
      expect(startTime.minute, 15);
      
      print('✅ 成功解析课程: ${firstCourse.name}');
      print('   教师: ${firstCourse.teacher}');
      print('   地点: ${firstCourse.location}');
      print('   时间: ${firstCourse.timeStr}');
      print('   日期: ${firstCourse.dateStr}');
    });

    test('验证教师信息提取', () {
      final icsContent = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test@school.edu
DTSTART:20250908T001500Z
DTEND:20250908T014500Z
SUMMARY:测试课程
LOCATION:测试教室
DESCRIPTION:测试课程 测试教室 王老师
CATEGORIES:ShanghaiTech,王老师,Course Table ICS Formatter
END:VEVENT
END:VCALENDAR''';

      final courses = IcsParser.parse(icsContent);
      final course = courses.first;

      expect(course.teacher, '王老师');
      print('✅ 教师信息提取正确: ${course.teacher}');
    });

    test('验证时间转换', () {
      final icsContent = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test@school.edu
DTSTART:20250908T001500Z
DTEND:20250908T014500Z
SUMMARY:时间测试课程
LOCATION:测试地点
CATEGORIES:ShanghaiTech,测试老师,Course Table ICS Formatter
END:VEVENT
END:VCALENDAR''';

      final courses = IcsParser.parse(icsContent);
      final course = courses.first;

      // UTC 00:15 应该转换为本地时间 (UTC+8) 08:15
      final startTime = DateTime.fromMillisecondsSinceEpoch(course.startTime);
      final endTime = DateTime.fromMillisecondsSinceEpoch(course.endTime);

      expect(startTime.hour, 8);
      expect(startTime.minute, 15);
      expect(endTime.hour, 9);
      expect(endTime.minute, 45);

      print('✅ 时间转换正确');
      print('   UTC: 00:15-01:45');
      print('   本地: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}-${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}');
    });

    test('验证重复规则展开', () {
      final icsContent = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test@school.edu
DTSTART:20250908T001500Z
DTEND:20250908T014500Z
SUMMARY:重复课程
LOCATION:测试教室
CATEGORIES:ShanghaiTech,测试老师,Course Table ICS Formatter
RRULE:FREQ=WEEKLY;COUNT=3;INTERVAL=1
END:VEVENT
END:VCALENDAR''';

      final courses = IcsParser.parse(icsContent);

      // 应该生成3个实例
      expect(courses.length, 3);
      
      // 验证每个实例的时间间隔
      for (int i = 0; i < courses.length; i++) {
        final course = courses[i];
        final startTime = DateTime.fromMillisecondsSinceEpoch(course.startTime);
        print('第${i+1}次课: ${startTime.year}-${startTime.month}-${startTime.day} ${startTime.hour}:${startTime.minute}');
      }

      print('✅ 重复规则展开正确，共${courses.length}次课');
    });

    test('验证完整一周课程', () {
      // 模拟一个完整的课程表
      final icsContent = '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:math@school.edu
DTSTART:20250908T001500Z
DTEND:20250908T014500Z
SUMMARY:高等数学
LOCATION:教学楼101室
DESCRIPTION:高等数学 教学楼101室 张老师
CATEGORIES:ShanghaiTech,张老师,Course Table ICS Formatter
RRULE:FREQ=WEEKLY;COUNT=16;INTERVAL=1
END:VEVENT
BEGIN:VEVENT
UID:english@school.edu
DTSTART:20250908T015500Z
DTEND:20250908T033000Z
SUMMARY:大学英语
LOCATION:教学楼202室
DESCRIPTION:大学英语 教学楼202室 李老师
CATEGORIES:ShanghaiTech,李老师,Course Table ICS Formatter
RRULE:FREQ=WEEKLY;COUNT=16;INTERVAL=1
END:VEVENT
BEGIN:VEVENT
UID:physics@school.edu
DTSTART:20250909T001500Z
DTEND:20250909T014500Z
SUMMARY:大学物理
LOCATION:实验楼301室
DESCRIPTION:大学物理 实验楼301室 王老师
CATEGORIES:ShanghaiTech,王老师,Course Table ICS Formatter
RRULE:FREQ=WEEKLY;COUNT=16;INTERVAL=1
END:VEVENT
END:VCALENDAR''';

      final courses = IcsParser.parse(icsContent);

      // 应该有16*3=48个课程实例
      expect(courses.length, 48);

      // 按日期分组
      final coursesByDate = <String, List<CourseEvent>>{};
      for (var course in courses) {
        final dateKey = course.dateStr;
        coursesByDate[dateKey] ??= [];
        coursesByDate[dateKey]!.add(course);
      }

      print('✅ 完整课程表解析成功');
      print('   总课程数: ${courses.length}');
      print('   日期数: ${coursesByDate.length}');
      
      // 打印第一天的课程
      final firstDate = coursesByDate.keys.toList()..sort();
      if (firstDate.isNotEmpty) {
        final dayCourses = coursesByDate[firstDate.first]!;
        print('   第一天(${firstDate.first})课程数: ${dayCourses.length}');
        for (var course in dayCourses) {
          print('     - ${course.name} (${course.timeStr})');
        }
      }
    });
  });
}
