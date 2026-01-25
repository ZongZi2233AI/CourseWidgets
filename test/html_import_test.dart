import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:coursewidgets/services/html_to_ics_converter.dart';

void main() {
  group('HTML导入功能测试', () {
    test('HTML数据解析测试', () {
      // 模拟HTML数据（JSON格式）
      String mockHtmlData = jsonEncode({
        'activities': List.generate(77, (index) {
          // 模拟每节课的数据
          if (index % 11 == 0 && index < 33) {
            // 第1-3周的周一第1节有课
            return [{
              'courseName': '高等数学',
              'roomName': '教学楼101室',
              'teacherName': '张老师',
              'vaildWeeks': '11100000000000000'
            }];
          }
          return [];
        })
      });

      // 测试解析
      List<Course> courses = HtmlDataParser.parseFromHtml(mockHtmlData);
      
      expect(courses.isNotEmpty, true);
      expect(courses.first.name, '高等数学');
      expect(courses.first.teacher, '张老师');
      expect(courses.first.location, '教学楼101室');
      expect(courses.first.dayOfWeek, 1); // 周一
      expect(courses.first.startSection, 1);
      expect(courses.first.weeks, [1, 2, 3]);
    });

    test('课程合并测试', () {
      String mockHtmlData = jsonEncode({
        'activities': List.generate(77, (index) {
          if (index == 0) {
            return [{'courseName': '高等数学', 'roomName': '101', 'teacherName': '张老师', 'vaildWeeks': '11100000000000000'}];
          } else if (index == 1) {
            return [{'courseName': '高等数学', 'roomName': '101', 'teacherName': '张老师', 'vaildWeeks': '11100000000000000'}];
          }
          return [];
        })
      });

      List<Course> courses = HtmlDataParser.parseFromHtml(mockHtmlData);
      
      // 应该合并为一节课，第1-2节
      expect(courses.length, 1);
      expect(courses.first.startSection, 1);
      expect(courses.first.endSection, 2);
    });

    test('ICS生成测试', () {
      final courses = [
        Course(
          name: '高等数学',
          location: '教学楼101室',
          teacher: '张老师',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [1, 2, 3],
        )
      ];

      final config = ScheduleConfig();
      String icsContent = IcsGenerator.generate(courses, config);

      expect(icsContent.contains('BEGIN:VCALENDAR'), true);
      expect(icsContent.contains('SUMMARY:高等数学'), true);
      expect(icsContent.contains('LOCATION:教学楼101室 张老师'), true);
      expect(icsContent.contains('BEGIN:VEVENT'), true);
    });

    test('完整转换流程测试', () async {
      String mockHtmlData = jsonEncode({
        'activities': List.generate(77, (index) {
          if (index == 0) {
            return [{'courseName': '高等数学', 'roomName': '101', 'teacherName': '张老师', 'vaildWeeks': '11100000000000000'}];
          }
          return [];
        })
      });

      String? icsContent = await HtmlImportService.convertHtmlToIcs(mockHtmlData);
      
      expect(icsContent, isNotNull);
      expect(icsContent!.contains('BEGIN:VCALENDAR'), true);
      expect(icsContent.contains('SUMMARY:高等数学'), true);
    });
  });

  group('历史记录管理测试', () {
    test('课程数据序列化测试', () {
      final courses = [
        Course(
          name: '高等数学',
          location: '教学楼101室',
          teacher: '张老师',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: [1, 2, 3],
        )
      ];

      final jsonData = HtmlImportService.extractCourseData(courses);
      expect(jsonData.length, 1);
      expect(jsonData[0]['name'], '高等数学');
      expect(jsonData[0]['weeks'], [1, 2, 3]);

      final restoredCourses = HtmlImportService.restoreCourseData(jsonData);
      expect(restoredCourses.length, 1);
      expect(restoredCourses[0].name, '高等数学');
      expect(restoredCourses[0].weeks, [1, 2, 3]);
    });
  });
}
