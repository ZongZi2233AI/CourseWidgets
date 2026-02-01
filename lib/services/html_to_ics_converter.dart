import 'dart:convert';
import '../models/schedule_config.dart';

/// 数据模型
class Course {
  final String name;
  final String location;
  final String teacher;
  final int dayOfWeek; // 1=周一, 7=周日
  final int startSection;
  final int endSection;
  final List<int> weeks;

  Course({
    required this.name,
    required this.location,
    required this.teacher,
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    required this.weeks,
  });

  // 判断是否可以合并两个相邻的课
  bool canMerge(Course other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    if (endSection + 1 != other.startSection) return false;
    if (name != other.name) return false;
    if (location != other.location) return false;
    if (teacher != other.teacher) return false;
    
    // 比较周次列表是否一致 - 使用集合比较更灵活
    if (weeks.length != other.weeks.length) return false;
    Set<int> weeksSet = weeks.toSet();
    Set<int> otherWeeksSet = other.weeks.toSet();
    if (weeksSet.length != otherWeeksSet.length) return false;
    for (int week in weeksSet) {
      if (!otherWeeksSet.contains(week)) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'teacher': teacher,
      'dayOfWeek': dayOfWeek,
      'startSection': startSection,
      'endSection': endSection,
      'weeks': weeks,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'],
      location: json['location'],
      teacher: json['teacher'],
      dayOfWeek: json['dayOfWeek'],
      startSection: json['startSection'],
      endSection: json['endSection'],
      weeks: List<int>.from(json['weeks']),
    );
  }
}

/// 配置与时间计算 - 使用新的配置模型
class ScheduleConfig {
  final ScheduleConfigModel config;

  ScheduleConfig([ScheduleConfigModel? customConfig]) 
    : config = customConfig ?? ScheduleConfigModel.defaultConfig();

  // 获取某节课的具体开始时间
  DateTime getStartTime(int week, int dayOfWeek, int section) {
    return config.getStartTime(week, dayOfWeek, section);
  }

  // 获取某节课的结束时间
  DateTime getEndTime(int week, int dayOfWeek, int section) {
    return config.getEndTime(week, dayOfWeek, section);
  }

  // 获取连续课程的结束时间
  DateTime getEndTimeWithDuration(int week, int dayOfWeek, int startSection, int endSection) {
    return config.getEndTimeWithDuration(week, dayOfWeek, startSection, endSection);
  }
}

/// HTML数据解析器
class HtmlDataParser {
  static List<Course> parseFromHtml(String jsonString) {
    Map<String, dynamic> data = jsonDecode(jsonString);
    List<dynamic> activities = data['activities'];
    
    List<Course> courses = [];
    int unitsPerDay = 11;

    for (int day = 0; day < 7; day++) {
      for (int section = 1; section <= unitsPerDay; section++) {
        int index = day * unitsPerDay + (section - 1);
        
        if (index >= activities.length) break;
        
        List<dynamic> slotCourses = activities[index];
        if (slotCourses.isEmpty) continue;

        for (var item in slotCourses) {
          // [v2.3.0修复] 清理换行符和额外空格
          String name = (item['courseName'] ?? '')
              .toString()
              .replaceAll('\n', ' ')
              .replaceAll('\r', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          String location = (item['roomName'] ?? '')
              .toString()
              .replaceAll('\n', ' ')
              .replaceAll('\r', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          String teacher = (item['teacherName'] ?? '')
              .toString()
              .replaceAll('\n', ' ')
              .replaceAll('\r', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          String validWeeksStr = item['vaildWeeks'] ?? '';

          // 解析周次字符串
          // 假设格式是 "11100000000000000"，索引0代表第1周
          List<int> weeks = [];
          for (int i = 0; i < validWeeksStr.length; i++) {
            if (validWeeksStr[i] == '1') {
              weeks.add(i + 1); // 索引0代表第1周，所以加1
            }
          }
          
          // 如果没有解析到周次，使用默认值（第1周）
          if (weeks.isEmpty) {
            weeks = [1];
          }

          if (weeks.isEmpty) continue;

          Course newCourse = Course(
            name: name,
            location: location,
            teacher: teacher,
            dayOfWeek: day + 1,
            startSection: section,
            endSection: section,
            weeks: weeks,
          );

          // 尝试合并逻辑 - 检查是否可以与前一个课程合并
          bool merged = false;
          if (courses.isNotEmpty) {
            Course lastCourse = courses.last;
            if (lastCourse.canMerge(newCourse)) {
              // 合并课程
              courses.removeLast();
              courses.add(Course(
                name: lastCourse.name,
                location: lastCourse.location,
                teacher: lastCourse.teacher,
                dayOfWeek: lastCourse.dayOfWeek,
                startSection: lastCourse.startSection,
                endSection: newCourse.endSection,
                weeks: lastCourse.weeks,
              ));
              merged = true;
            }
          }
          
          // 如果没有合并成功，添加新课程
          if (!merged) {
            courses.add(newCourse);
          }
        }
      }
    }
    return courses;
  }
}

/// ICS生成器 - 优化版本，匹配参考ICS格式
class IcsGenerator {
  static String generate(List<Course> courses, ScheduleConfig config) {
    StringBuffer sb = StringBuffer();
    String nowStr = _formatDate(DateTime.now());

    sb.writeln('BEGIN:VCALENDAR');
    sb.writeln('VERSION:2.0');
    sb.writeln('PRODID:-//YZune//WakeUpSchedule//EN');
    
    // 时区信息 - 匹配参考格式
    sb.writeln('BEGIN:VTIMEZONE');
    sb.writeln('TZID:Asia/Shanghai');
    sb.writeln('LAST-MODIFIED:${nowStr}Z');
    sb.writeln('TZURL:https://www.tzurl.org/zoneinfo-outlook/Asia/Shanghai');
    sb.writeln('X-LIC-LOCATION:Asia/Shanghai');
    sb.writeln('BEGIN:STANDARD');
    sb.writeln('TZNAME:CST');
    sb.writeln('TZOFFSETFROM:+0800');
    sb.writeln('TZOFFSETTO:+0800');
    sb.writeln('DTSTART:19700101T000000');
    sb.writeln('END:STANDARD');
    sb.writeln('END:VTIMEZONE');

    // 生成VEVENT - 按课程和周次生成
    for (var course in courses) {
      // 获取课程的周次范围，用于生成RRULE
      if (course.weeks.isEmpty) continue;
      
      // 按连续的周次分组生成事件
      List<List<int>> weekGroups = _groupWeeks(course.weeks);
      
      for (var weekGroup in weekGroups) {
        // 使用第一周的时间作为基础
        int firstWeek = weekGroup.first;
        
        // 计算开始和结束时间
        DateTime startTime = config.getStartTime(firstWeek, course.dayOfWeek, course.startSection);
        DateTime endTime = config.getEndTimeWithDuration(firstWeek, course.dayOfWeek, course.startSection, course.endSection);
        
        // 生成UID
        String uid = 'WakeUpSchedule-${_generateUID()}-$firstWeek-${course.dayOfWeek}';
        
        sb.writeln('BEGIN:VEVENT');
        sb.writeln('DTSTAMP:${nowStr}Z');
        sb.writeln('UID:$uid');
        sb.writeln('SUMMARY:${course.name}');
        sb.writeln('DTSTART;TZID=Asia/Shanghai:${_formatDate(startTime)}');
        sb.writeln('DTEND;TZID=Asia/Shanghai:${_formatDate(endTime)}');
        
        // 生成重复规则 - 只有当有多周时才添加RRULE
        if (weekGroup.length > 1) {
          int lastWeek = weekGroup.last;
          DateTime untilDate = config.getEndTime(lastWeek, course.dayOfWeek, course.endSection);
          sb.writeln('RRULE:FREQ=WEEKLY;UNTIL=${_formatDateUntil(untilDate)}Z;INTERVAL=1');
        }
        
        // 格式化地点和教师
        String location = course.location.isNotEmpty ? course.location : '';
        String teacher = course.teacher.isNotEmpty ? course.teacher : '';
        String locationStr = location;
        if (teacher.isNotEmpty) {
          locationStr += ' $teacher';
        }
        
        sb.writeln('LOCATION:$locationStr');
        
        // 格式化描述 - 匹配参考格式
        String description = '第${course.startSection} - ${course.endSection}节';
        if (location.isNotEmpty) {
          description += '\\n$location';
        }
        if (teacher.isNotEmpty) {
          description += '\\n$teacher';
        }
        sb.writeln('DESCRIPTION:$description');
        
        // 提醒设置 - 匹配参考格式
        sb.writeln('BEGIN:VALARM');
        sb.writeln('ACTION:DISPLAY');
        sb.writeln('TRIGGER;RELATED=START:-PT20M');
        sb.writeln('DESCRIPTION:${course.name}${location.isNotEmpty ? '@$location' : ''}\\n');
        sb.writeln('END:VALARM');
        
        sb.writeln('END:VEVENT');
      }
    }

    sb.writeln('END:VCALENDAR');
    return sb.toString();
  }

  /// 将周次分组为连续的区间
  static List<List<int>> _groupWeeks(List<int> weeks) {
    if (weeks.isEmpty) return [];
    
    List<List<int>> groups = [];
    List<int> currentGroup = [weeks[0]];
    
    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] == weeks[i - 1] + 1) {
        // 连续的周次
        currentGroup.add(weeks[i]);
      } else {
        // 不连续，开始新的组
        groups.add(currentGroup);
        currentGroup = [weeks[i]];
      }
    }
    
    // 添加最后一组
    groups.add(currentGroup);
    return groups;
  }

  /// 生成唯一的UID后缀
  static String _generateUID() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36) + 
           (DateTime.now().microsecondsSinceEpoch % 1000000).toRadixString(36);
  }

  static String _formatDate(DateTime dt) {
    String twoDigits(int n) => n >= 10 ? "$n" : "0$n";
    return "${dt.year}${twoDigits(dt.month)}${twoDigits(dt.day)}T${twoDigits(dt.hour)}${twoDigits(dt.minute)}${twoDigits(dt.second)}";
  }

  static String _formatDateUntil(DateTime dt) {
    String twoDigits(int n) => n >= 10 ? "$n" : "0$n";
    // 截止时间通常是当天的结束时间，但参考格式使用的是16:00:00
    return "${dt.year}${twoDigits(dt.month)}${twoDigits(dt.day)}T160000";
  }
}

/// HTML导入服务
class HtmlImportService {
  static Future<String?> convertHtmlToIcs(String htmlContent) async {
    try {
      // 解析HTML数据为课程对象
      List<Course> courses = HtmlDataParser.parseFromHtml(htmlContent);
      
      if (courses.isEmpty) {
        return null;
      }

      // 生成ICS内容
      final config = ScheduleConfig();
      String icsContent = IcsGenerator.generate(courses, config);
      
      return icsContent;
    } catch (e) {
      print('HTML转换ICS失败: $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> extractCourseData(List<Course> courses) {
    return courses.map((course) => course.toJson()).toList();
  }

  static List<Course> restoreCourseData(List<Map<String, dynamic>> jsonData) {
    return jsonData.map((e) => Course.fromJson(e)).toList();
  }
}
