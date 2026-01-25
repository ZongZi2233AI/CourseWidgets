/// 课程表配置模型 - 支持自定义课时设置
class ScheduleConfigModel {
  // 学期开始日期
  final DateTime semesterStartDate;
  
  // 每节课的开始时间（分钟，从00:00开始计算）
  // 例如：8:00 = 480, 9:00 = 540
  final Map<int, int> sectionStartTimes;
  
  // 每节课的时长（分钟）
  final Map<int, int> sectionDurations;
  
  // 课间休息时间（分钟）
  final int breakTime;
  
  // 是否使用自定义配置
  final bool useCustomConfig;

  ScheduleConfigModel({
    required this.semesterStartDate,
    required this.sectionStartTimes,
    required this.sectionDurations,
    this.breakTime = 10,
    this.useCustomConfig = true,
  });

  // 默认配置：8:00开始，每节课50分钟，课间休息10分钟
  factory ScheduleConfigModel.defaultConfig() {
    return ScheduleConfigModel(
      semesterStartDate: DateTime(2025, 9, 8),
      sectionStartTimes: {
        1: 480,  // 8:00
        2: 540,  // 9:00
        3: 610,  // 10:10
        4: 670,  // 11:10
        5: 810,  // 13:30
        6: 870,  // 14:30
        7: 940,  // 15:40
        8: 1000, // 16:40
        9: 1110, // 18:30
        10: 1170, // 19:30
        11: 1230, // 20:30
      },
      sectionDurations: {
        1: 50, 2: 50, 3: 50, 4: 50, 5: 50, 6: 50, 7: 50, 8: 50, 9: 50, 10: 50, 11: 50
      },
      breakTime: 10,
      useCustomConfig: false,
    );
  }

  // 从JSON创建配置
  factory ScheduleConfigModel.fromJson(Map<String, dynamic> json) {
    return ScheduleConfigModel(
      semesterStartDate: DateTime.parse(json['semesterStartDate']),
      sectionStartTimes: Map<int, int>.from(json['sectionStartTimes']),
      sectionDurations: Map<int, int>.from(json['sectionDurations']),
      breakTime: json['breakTime'] ?? 10,
      useCustomConfig: json['useCustomConfig'] ?? true,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'semesterStartDate': semesterStartDate.toIso8601String(),
      'sectionStartTimes': sectionStartTimes,
      'sectionDurations': sectionDurations,
      'breakTime': breakTime,
      'useCustomConfig': useCustomConfig,
    };
  }

  // 获取某节课的具体开始时间
  DateTime getStartTime(int week, int dayOfWeek, int section) {
    final startDate = semesterStartDate;
    final targetDate = startDate.add(Duration(days: (week - 1) * 7 + (dayOfWeek - 1)));
    
    final startTimeMinutes = sectionStartTimes[section] ?? 480; // 默认8:00
    final hour = startTimeMinutes ~/ 60;
    final minute = startTimeMinutes % 60;
    
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }

  // 获取某节课的结束时间
  DateTime getEndTime(int week, int dayOfWeek, int section) {
    final startTime = getStartTime(week, dayOfWeek, section);
    final duration = sectionDurations[section] ?? 50; // 默认50分钟
    return startTime.add(Duration(minutes: duration));
  }

  // 获取连续多节课的总时长（包含课间休息）
  int getTotalDuration(int startSection, int endSection) {
    int totalMinutes = 0;
    for (int i = startSection; i <= endSection; i++) {
      totalMinutes += sectionDurations[i] ?? 50;
      if (i < endSection) {
        totalMinutes += breakTime;
      }
    }
    return totalMinutes;
  }

  // 获取某节课的结束时间（包含连续课程）
  DateTime getEndTimeWithDuration(int week, int dayOfWeek, int startSection, int endSection) {
    final startTime = getStartTime(week, dayOfWeek, startSection);
    final totalDuration = getTotalDuration(startSection, endSection);
    return startTime.add(Duration(minutes: totalDuration));
  }

  // 验证配置是否有效
  bool isValid() {
    if (sectionStartTimes.isEmpty || sectionDurations.isEmpty) return false;
    if (semesterStartDate.isBefore(DateTime(2000))) return false;
    return true;
  }

  // 创建配置副本并更新
  ScheduleConfigModel copyWith({
    DateTime? semesterStartDate,
    Map<int, int>? sectionStartTimes,
    Map<int, int>? sectionDurations,
    int? breakTime,
    bool? useCustomConfig,
  }) {
    return ScheduleConfigModel(
      semesterStartDate: semesterStartDate ?? this.semesterStartDate,
      sectionStartTimes: sectionStartTimes ?? Map.from(this.sectionStartTimes),
      sectionDurations: sectionDurations ?? Map.from(this.sectionDurations),
      breakTime: breakTime ?? this.breakTime,
      useCustomConfig: useCustomConfig ?? this.useCustomConfig,
    );
  }

  // 获取配置描述文本
  String getDescription() {
    if (!useCustomConfig) {
      return '默认配置 (8:00开始, 50分钟/节, 10分钟休息)';
    }
    
    final firstStart = sectionStartTimes[1] ?? 480;
    final firstDuration = sectionDurations[1] ?? 50;
    final hour = firstStart ~/ 60;
    final minute = firstStart % 60;
    
    return '自定义配置 (${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}开始, $firstDuration分钟/节, $breakTime分钟休息)';
  }
}
