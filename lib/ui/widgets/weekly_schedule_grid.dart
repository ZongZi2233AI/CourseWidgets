import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../models/course_event.dart';
import '../../models/schedule_config.dart';
import '../../providers/schedule_provider.dart';
import '../screens/course_edit_screen.dart';
import 'liquid_components.dart' as liquid;
import '../transitions/smooth_slide_transitions.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

/// 本周课程网格视图（平板模式）
class WeeklyScheduleGrid extends StatefulWidget {
  const WeeklyScheduleGrid({super.key});

  @override
  State<WeeklyScheduleGrid> createState() => _WeeklyScheduleGridState();
}

class _WeeklyScheduleGridState extends State<WeeklyScheduleGrid> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 周次切换控制栏
            _buildWeekControl(context, provider),
            const SizedBox(height: 16),

            // 7 天课程网格 - 添加左右滑动手势
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  // [v2.2.1] 左右滑动切换周次
                  if (details.primaryVelocity! > 0) {
                    // 向右滑动 - 上一周
                    _changeWeek(provider, provider.currentWeek - 1);
                  } else if (details.primaryVelocity! < 0) {
                    // 向左滑动 - 下一周
                    _changeWeek(provider, provider.currentWeek + 1);
                  }
                },
                child: _buildWeekGrid(context, provider),
              ),
            ),
          ],
        );
      },
    );
  }

  /// [v2.2.1] 切换周次（带验证）
  void _changeWeek(ScheduleProvider provider, int targetWeek) {
    // Removed async
    final weeks = provider.availableWeeks;
    if (weeks.isEmpty) return;

    // 限制周次范围，防止切换到第0周或负数周
    final validWeek = targetWeek.clamp(weeks.first, weeks.last);

    if (validWeek != provider.currentWeek) {
      HapticFeedback.selectionClick();
      provider.setCurrentWeek(validWeek);
    }
  }

  /// [v2.2.2] 显示周次选择器 - 使用底部菜单而非对话框
  void _showWeekPicker(BuildContext context, ScheduleProvider provider) {
    // Removed async
    final weeks = provider.availableWeeks;
    if (weeks.isEmpty || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        settings: LiquidGlassSettings(
          glassColor: Colors.black.withValues(alpha: 0.4),
          blur: 20,
          thickness: 15,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择周次',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 周次网格
              Container(
                height: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    final week = weeks[index];
                    final isSelected = week == provider.currentWeek;

                    return GlassButton.custom(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.setCurrentWeek(week);
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      height: double.infinity,
                      style: GlassButtonStyle.filled,
                      settings: LiquidGlassSettings(
                        glassColor: isSelected
                            ? AppThemeColors.babyPink.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        blur: 0,
                        thickness: 10,
                      ),
                      shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                      child: Center(
                        child: Text(
                          '第$week周',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 周次切换控制
  Widget _buildWeekControl(BuildContext context, ScheduleProvider provider) {
    return liquid.LiquidCard(
      borderRadius: 20,
      padding: 16,
      quality: GlassQuality.standard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一周
          GlassButton.custom(
            onTap: () => _changeWeek(
              provider,
              provider.currentWeek - 1,
            ), // [v2.2.1] 使用验证方法
            width: 100,
            height: 40,
            style: GlassButtonStyle.filled,
            settings: LiquidGlassSettings(blur: 0, thickness: 10),
            shape: const LiquidRoundedSuperellipse(borderRadius: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.left_chevron,
                  color: Colors.white70,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  '上一周',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // 当前周次 - 点击打开选择器
          GestureDetector(
            onTap: () => _showWeekPicker(context, provider), // [v2.2.1] 点击打开选择器
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeColors.babyPink.withValues(alpha: 0.3),
                    AppThemeColors.softCoral.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '第 ${provider.currentWeek} 周',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // 下一周
          GlassButton.custom(
            onTap: () => _changeWeek(
              provider,
              provider.currentWeek + 1,
            ), // [v2.2.1] 使用验证方法
            width: 100,
            height: 40,
            style: GlassButtonStyle.filled,
            settings: LiquidGlassSettings(blur: 0, thickness: 10),
            shape: const LiquidRoundedSuperellipse(borderRadius: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '下一周',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(width: 4),
                Icon(
                  CupertinoIcons.right_chevron,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 根据时间戳计算最接近的节次（用于绝对定位映射）
  int _getSectionForTime(
    int timestamp,
    ScheduleConfigModel config, {
    bool isEnd = false,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final totalMinutes = dt.hour * 60 + dt.minute;

    int bestSection = 1;
    int minDiff = 10000;

    for (var entry in config.sectionStartTimes.entries) {
      int sectionMin = entry.value;
      if (isEnd) {
        int duration = config.isEqualDuration
            ? config.defaultDuration
            : (config.sectionDurations[entry.key] ?? config.defaultDuration);
        sectionMin += duration;
      }

      int diff = (sectionMin - totalMinutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestSection = entry.key;
      }
    }
    return bestSection;
  }

  /// 7 天或 5 天课程网格 [v2.6.0] 支持双休隐藏
  Widget _buildWeekGrid(BuildContext context, ScheduleProvider provider) {
    final showWeekends = provider.currentConfig.showWeekends;
    final int daysCount = showWeekends ? 7 : 5;

    return DynMouseScroll(
      builder: (context, controller, physics) => SingleChildScrollView(
        controller: controller,
        physics: physics,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 添加左侧时间轴以对应课程节次
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  const SizedBox(height: 60), // 对应 DayColumn 顶部的星期日期高度
                  ...List.generate(12, (i) {
                    return Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            ...List.generate(daysCount, (dayIndex) {
              final day = dayIndex + 1;
              final courses = provider.getCoursesForDay(day);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: dayIndex == 0 ? 4 : 4,
                    right: dayIndex == (daysCount - 1) ? 4 : 4,
                  ),
                  child: _buildDayColumn(context, day, courses, provider),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 单日课程列
  Widget _buildDayColumn(
    BuildContext context,
    int day,
    List<CourseEvent> courses,
    ScheduleProvider provider,
  ) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    // [v2.7.0] 计算实际日期
    final semesterStart = provider.semesterStartDate;
    final weekOffset = (provider.currentWeek - 1) * 7;
    final dayDate = semesterStart.add(Duration(days: weekOffset + day - 1));
    final dateLabel = '${dayDate.month}/${dayDate.day}';

    return liquid.LiquidCard(
      borderRadius: 20,
      padding: 12,
      quality: GlassQuality.standard,
      child: Column(
        children: [
          // 星期标题 + 日期
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Text(
                  weekdays[day - 1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // 课程列表 - 使用绝对定位 Stack 来对齐时间轴
          SizedBox(
            height: 720, // 12节课 * 60.0高度
            child: Stack(
              clipBehavior: Clip.none,
              children: courses.map((course) {
                final config = provider.currentConfig;
                final start = _getSectionForTime(course.startTime, config);
                final end = _getSectionForTime(
                  course.endTime,
                  config,
                  isEnd: true,
                );

                final finalStart = start > 0 ? start : 1;
                final finalEnd = end >= finalStart ? end : finalStart;

                final topOffset = (finalStart - 1) * 60.0;
                final courseHeight = (finalEnd - finalStart + 1) * 60.0;

                return Positioned(
                  top: topOffset,
                  left: 0,
                  right: 0,
                  height: courseHeight,
                  child: _buildCourseCard(context, course),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 课程卡片
  Widget _buildCourseCard(BuildContext context, CourseEvent course) {
    // [v2.2.8修复] 使用 RepaintBoundary 隔离重绘，防止滚动时玻璃效果消失
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _showCourseDetail(context, course),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemeColors.babyPink.withValues(alpha: 0.2),
                AppThemeColors.softCoral.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 节次
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeColors.babyPink.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.timeStr.split('-')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 课程名
              Text(
                course.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 地点与教师并排显示 (解决两行显示奇怪的问题)
              if (course.location.isNotEmpty || course.teacher.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        CupertinoIcons.placemark_fill,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [
                          if (course.location.isNotEmpty) course.location,
                          if (course.teacher.isNotEmpty) course.teacher,
                        ].join('  ·  '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 显示课程详情
  void _showCourseDetail(BuildContext context, CourseEvent course) {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '课程详情',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('课程', course.name),
            const SizedBox(height: 8),
            _buildDetailRow('地点', course.location),
            const SizedBox(height: 8),
            _buildDetailRow('教师', course.teacher),
            const SizedBox(height: 8),
            _buildDetailRow('时间', course.timeStr),
          ],
        ),
        actions: [
          GlassDialogAction(
            label: '编辑',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                TransparentMaterialPageRoute(
                  builder: (_) => CourseEditScreen(course: course),
                ),
              );
            },
          ),
          GlassDialogAction(
            label: '关闭',
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
