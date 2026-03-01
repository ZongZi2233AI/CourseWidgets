import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/schedule_provider.dart';
import '../../models/course_event.dart';
import '../../constants/theme_constants.dart';
import '../widgets/liquid_components.dart' as liquid;
import 'course_edit_screen.dart';
import '../transitions/smooth_slide_transitions.dart';

/// [v2.2.1] 完全复刻 Android 平板端的 Windows 课表界面
class WindowsScheduleScreen extends StatefulWidget {
  const WindowsScheduleScreen({super.key});
  @override
  State<WindowsScheduleScreen> createState() => _WindowsScheduleScreenState();
}

class _WindowsScheduleScreenState extends State<WindowsScheduleScreen> {
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
    if (weeks.isEmpty || !mounted) return;

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
                child: const Text(
                  '选择周次',
                  style: TextStyle(
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
                    crossAxisCount: 5,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekSelector(provider),
            const SizedBox(height: 16),

            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(child: _buildWeekGrid(provider)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 周次选择器 - 复刻 Android 平板端
  Widget _buildWeekSelector(ScheduleProvider provider) {
    return SizedBox(
      height: 44,
      child: Builder(
        builder: (context) {
          final weeks = provider.availableWeeks;
          if (weeks.isEmpty) return const SizedBox();
          return Row(
            children: [
              // 左箭头按钮
              GlassButton.custom(
                onTap: () => _changeWeek(
                  provider,
                  provider.currentWeek - 1,
                ), // [v2.2.1] 使用验证方法
                width: 44,
                height: 44,
                style: GlassButtonStyle.filled,
                settings: LiquidGlassSettings(
                  glassColor: Colors.white.withValues(alpha: 0.05),
                  blur: 0,
                  thickness: 10,
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),

              // 周次列表
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    final week = weeks[index];
                    final isSelected = week == provider.currentWeek;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppThemeColors.babyPink.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                            : null,
                        child: GestureDetector(
                          onLongPress: () {
                            if (mounted)
                              _showWeekPicker(
                                context,
                                provider,
                              ); // [v2.2.1] 长按打开选择器
                          },
                          child: GlassButton.custom(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              provider.setCurrentWeek(week);
                            },
                            width: 80,
                            height: 44,
                            style: GlassButtonStyle.filled,
                            settings: LiquidGlassSettings(
                              glassColor: isSelected
                                  ? AppThemeColors.babyPink.withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.white.withValues(alpha: 0.05),
                              blur: 0,
                              thickness: 10,
                            ),
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 100,
                            ),
                            child: Center(
                              child: Text(
                                '第$week周',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),
              // 右箭头按钮
              GlassButton.custom(
                onTap: () => _changeWeek(
                  provider,
                  provider.currentWeek + 1,
                ), // [v2.2.1] 使用验证方法
                width: 44,
                height: 44,
                style: GlassButtonStyle.filled,
                settings: LiquidGlassSettings(
                  glassColor: Colors.white.withValues(alpha: 0.05),
                  blur: 0,
                  thickness: 10,
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 本周课程网格 - 星期和课程分别作为独立container
  Widget _buildWeekGrid(ScheduleProvider provider) {
    // [v2.2.9修复] 添加 key 强制重建
    return AdaptiveLiquidGlassLayer(
      key: ValueKey('week_grid_${provider.currentWeek}'),
      settings: LiquidGlassSettings(
        glassColor: Colors.white.withValues(alpha: 0.03),
        blur: 8,
        thickness: 0.6,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间轴
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  ...List.generate(12, (i) {
                    return Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // 7天列
            ...List.generate(7, (index) {
              final day = index + 1;
              return Expanded(child: _buildDayColumn(provider, day));
            }),
          ],
        ),
      ),
    );
  }

  /// 构建单天列 - 星期和课程分别作为独立container
  Widget _buildDayColumn(ScheduleProvider provider, int day) {
    final isToday = DateTime.now().weekday == day;
    final weekCourses = provider.getCurrentWeekCourses();
    final dayCourses = weekCourses.where((c) => c.weekday == day).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // 星期标题 - 独立的 GlassContainer
          GlassContainer(
            useOwnLayer: true,
            settings: LiquidGlassSettings(
              glassColor: isToday
                  ? AppThemeColors.babyPink.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              blur: 0,
              thickness: 10,
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: 12),
            height: 40,
            child: Center(
              child: Text(
                ['周一', '二', '三', '四', '五', '六', '日'][day - 1],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 课程列表 - 每节课独立的 GlassContainer
          ...dayCourses.map((course) => _buildCourseCard(course)),
        ],
      ),
    );
  }

  /// 构建课程卡片 - 独立的 GlassContainer
  Widget _buildCourseCard(CourseEvent course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        useOwnLayer: true,
        settings: LiquidGlassSettings(
          glassColor: AppThemeColors.softCoral.withValues(alpha: 0.6),
          blur: 0,
          thickness: 10,
        ),
        shape: const LiquidRoundedSuperellipse(borderRadius: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCourseDetail(course),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (course.teacher.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      course.teacher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    course.timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示课程详情
  void _showCourseDetail(CourseEvent course) {
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
