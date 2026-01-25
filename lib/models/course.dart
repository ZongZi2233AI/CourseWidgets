/// ICS日历事件模型
// @JsonSerializable()
class CalendarEvent {
  final String uid;
  final String summary;
  final String description;
  final String location;
  final DateTime dtStart;
  final DateTime dtEnd;
  final String? rrule; // 重复规则
  final List<String> categories;

  CalendarEvent({
    required this.uid,
    required this.summary,
    required this.description,
    required this.location,
    required this.dtStart,
    required this.dtEnd,
    this.rrule,
    required this.categories,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    // 手动实现，不依赖生成的代码
    return CalendarEvent(
      uid: json['uid'] ?? '',
      summary: json['summary'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      dtStart: DateTime.parse(json['dtStart']),
      dtEnd: DateTime.parse(json['dtEnd']),
      rrule: json['rrule'],
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'summary': summary,
      'description': description,
      'location': location,
      'dtStart': dtStart.toIso8601String(),
      'dtEnd': dtEnd.toIso8601String(),
      'rrule': rrule,
      'categories': categories,
    };
  }

  /// 获取课程名称
  String get courseName => summary;

  /// 获取教师名称（从categories中提取）
  String get teacherName {
    if (categories.isEmpty) return '';
    // 过滤掉系统标签，只保留真实的教师姓名
    return categories.where((c) {
      final normalized = c.trim();
      return normalized != 'ShanghaiTech' && 
             normalized != 'Course Table ICS Formatter' &&
             normalized.isNotEmpty &&
             normalized != 'Course Table' &&
             normalized != 'ICS Formatter';
    }).join(',');
  }

  /// 获取周次信息
  List<int> getWeeks() {
    if (rrule == null) return [];
    
    // 解析RRULE获取周次
    // 例如: FREQ=WEEKLY;COUNT=16;INTERVAL=1
    final rruleStr = rrule!;
    final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rruleStr);
    final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rruleStr);
    
    if (countMatch != null) {
      final count = int.parse(countMatch.group(1)!);
      final interval = intervalMatch != null ? int.parse(intervalMatch.group(1)!) : 1;
      
      return List.generate(count, (index) => (index * interval) + 1);
    }
    
    return [];
  }

  /// 获取星期几 (1-7, 周一到周日)
  int get weekday => dtStart.weekday;

  /// 获取时间段名称
  String getTimeSlotName() {
    final hour = dtStart.hour;
    final minute = dtStart.minute;
    
    // 精确匹配时间段
    if (hour == 8 && minute >= 0) return '第1节';
    if (hour == 9 && minute >= 55) return '第2节';
    if (hour == 13 && minute >= 30) return '第3节';
    if (hour == 15 && minute >= 25) return '第4节';
    if (hour == 18 && minute >= 30) return '第5节';
    if (hour == 20 && minute >= 15) return '第6节';
    if (hour == 13 && minute >= 0 && minute < 30) return '第7节';
    if (hour == 14 && minute >= 0 && minute < 45) return '第8节';
    if (hour == 15 && minute >= 0 && minute < 25) return '第9节';
    if (hour == 16 && minute >= 0 && minute < 45) return '第10节';
    if (hour == 17 && minute >= 0 && minute < 45) return '第11节';
    
    // 粗略匹配作为后备
    if (hour >= 8 && hour < 10) return '第1节';
    if (hour >= 10 && hour < 12) return '第2节';
    if (hour >= 13 && hour < 15) return '第3节';
    if (hour >= 15 && hour < 17) return '第4节';
    if (hour >= 18 && hour < 20) return '第5节';
    if (hour >= 20 && hour < 22) return '第6节';
    if (hour >= 13 && hour < 14) return '第7节';
    if (hour >= 14 && hour < 15) return '第8节';
    if (hour >= 15 && hour < 16) return '第9节';
    if (hour >= 16 && hour < 17) return '第10节';
    if (hour >= 17 && hour < 18) return '第11节';
    
    return '未知';
  }

  /// 格式化时间
  String formatTime() {
    final start = '${dtStart.hour.toString().padLeft(2, '0')}:${dtStart.minute.toString().padLeft(2, '0')}';
    final end = '${dtEnd.hour.toString().padLeft(2, '0')}:${dtEnd.minute.toString().padLeft(2, '0')}';
    return '$start-$end';
  }

  /// 检查是否在指定周次有效
  bool isValidInWeek(int week) {
    final weeks = getWeeks();
    return weeks.isEmpty || weeks.contains(week);
  }

  /// 检查是否在指定日期有效
  bool isValidOnDate(DateTime date) {
    // 检查日期是否在课程时间范围内
    if (date.isBefore(dtStart) || date.isAfter(dtEnd)) return false;
    
    // 检查星期
    if (date.weekday != weekday) return false;
    
    // 检查重复规则
    if (rrule == null) return true;
    
    // 计算是第几周
    final weeksSinceStart = date.difference(dtStart).inDays ~/ 7 + 1;
    return isValidInWeek(weeksSinceStart);
  }
}

/// 课程配置
class ScheduleConfig {
  final String startDate;
  final int classDuration;
  final int slotsPerDay;
  final int daysPerWeek;
  final List<TimeSlot> timeSlots;

  ScheduleConfig({
    required this.startDate,
    required this.classDuration,
    required this.slotsPerDay,
    required this.daysPerWeek,
    required this.timeSlots,
  });

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      startDate: json['startDate'] ?? '',
      classDuration: json['classDuration'] ?? 90,
      slotsPerDay: json['slotsPerDay'] ?? 11,
      daysPerWeek: json['daysPerWeek'] ?? 5,
      timeSlots: (json['timeSlots'] as List? ?? [])
          .map((e) => TimeSlot.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'classDuration': classDuration,
      'slotsPerDay': slotsPerDay,
      'daysPerWeek': daysPerWeek,
      'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
    };
  }

  factory ScheduleConfig.defaultConfig() {
    return ScheduleConfig(
      startDate: '2025-09-01',
      classDuration: 90,
      slotsPerDay: 11,
      daysPerWeek: 5,
      timeSlots: TimeSlot.getDefaultTimeSlots(),
    );
  }
}

/// 时间段配置
class TimeSlot {
  final int slotId;
  final String name;
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.slotId,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      slotId: json['slotId'] ?? 1,
      name: json['name'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  static List<TimeSlot> getDefaultTimeSlots() {
    return [
      TimeSlot(slotId: 1, name: '第1节', startTime: '08:00', endTime: '09:35'),
      TimeSlot(slotId: 2, name: '第2节', startTime: '09:55', endTime: '11:30'),
      TimeSlot(slotId: 3, name: '第3节', startTime: '13:30', endTime: '15:05'),
      TimeSlot(slotId: 4, name: '第4节', startTime: '15:25', endTime: '17:00'),
      TimeSlot(slotId: 5, name: '第5节', startTime: '18:30', endTime: '20:05'),
      TimeSlot(slotId: 6, name: '第6节', startTime: '20:15', endTime: '21:50'),
      TimeSlot(slotId: 7, name: '第7节', startTime: '13:00', endTime: '13:45'),
      TimeSlot(slotId: 8, name: '第8节', startTime: '14:00', endTime: '14:45'),
      TimeSlot(slotId: 9, name: '第9节', startTime: '15:00', endTime: '15:45'),
      TimeSlot(slotId: 10, name: '第10节', startTime: '16:00', endTime: '16:45'),
      TimeSlot(slotId: 11, name: '第11节', startTime: '17:00', endTime: '17:45'),
    ];
  }
}

/// 学期数据
class SemesterData {
  final String year;
  final String semester;
  final List<CalendarEvent> events;
  final ScheduleConfig config;

  SemesterData({
    required this.year,
    required this.semester,
    required this.events,
    required this.config,
  });

  factory SemesterData.fromJson(Map<String, dynamic> json) {
    return SemesterData(
      year: json['year'] ?? '',
      semester: json['semester'] ?? '',
      events: (json['events'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e))
          .toList(),
      config: ScheduleConfig.fromJson(json['config'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'semester': semester,
      'events': events.map((e) => e.toJson()).toList(),
      'config': config.toJson(),
    };
  }

  /// 获取指定周次和星期的课程
  List<CalendarEvent> getEventsForWeekAndDay(int week, int weekday) {
    return events.where((event) {
      return event.weekday == weekday && event.isValidInWeek(week);
    }).toList();
  }

  /// 获取所有有效周次
  List<int> getAvailableWeeks() {
    final weeks = <int>[];
    for (var event in events) {
      weeks.addAll(event.getWeeks());
    }
    return weeks.toSet().toList()..sort();
  }

  /// 获取所有有效星期
  List<int> getAvailableDays() {
    final days = events.map((e) => e.weekday).toSet().toList();
    days.sort();
    return days;
  }

  /// 按时间段分组课程
  Map<int, List<CalendarEvent>> groupByTimeSlot(int week, int weekday) {
    final dayEvents = getEventsForWeekAndDay(week, weekday);
    final grouped = <int, List<CalendarEvent>>{};
    
    for (var event in dayEvents) {
      // 根据时间推断时间段ID
      final slotId = getTimeSlotId(event.dtStart);
      if (!grouped.containsKey(slotId)) {
        grouped[slotId] = [];
      }
      grouped[slotId]!.add(event);
    }
    
    return grouped;
  }

  /// 根据时间获取时间段ID
  int getTimeSlotId(DateTime time) {
    final hour = time.hour;
    if (hour >= 8 && hour < 10) return 1;
    if (hour >= 10 && hour < 12) return 2;
    if (hour >= 13 && hour < 15) return 3;
    if (hour >= 15 && hour < 17) return 4;
    if (hour >= 18 && hour < 20) return 5;
    if (hour >= 20 && hour < 22) return 6;
    if (hour >= 13 && hour < 14) return 7;
    if (hour >= 14 && hour < 15) return 8;
    if (hour >= 15 && hour < 16) return 9;
    if (hour >= 16 && hour < 17) return 10;
    if (hour >= 17 && hour < 18) return 11;
    return 1;
  }
}
