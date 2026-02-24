import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/schedule_provider.dart';
import '../../models/course_event.dart';
import '../../constants/theme_constants.dart';
import '../../services/data_import_service.dart';
import '../../utils/responsive_utils.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/glass_context_menu.dart';
import '../transitions/smooth_slide_transitions.dart';
import 'course_edit_screen.dart';
import 'package:flutter/cupertino.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});
  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate = DateTime.now();
  bool _isMonthView = true;
  final DataImportService _importService = DataImportService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  DateTime get _firstDayOfMonth =>
      DateTime(_currentMonth.year, _currentMonth.month, 1);
  DateTime get _lastDayOfMonth =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
  void _changeMonth(int offset) => setState(
    () => _currentMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + offset,
      1,
    ),
  );
  void _toggleViewMode() => setState(() => _isMonthView = !_isMonthView);
  void _selectDate(DateTime date) => setState(() => _selectedDate = date);
  List<CourseEvent> _getCoursesForDate(DateTime date, List<CourseEvent> all) =>
      all.where((c) {
        final d = DateTime.fromMillisecondsSinceEpoch(c.startTime);
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      }).toList();
  bool _isToday(DateTime date) {
    final n = DateTime.now();
    return date.year == n.year && date.month == n.month && date.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final isTablet = ResponsiveUtils.isTabletMode(context);

    if (isTablet) {
      // 平板模式：左右分屏
      return _buildTabletLayout(provider);
    } else {
      // 手机模式：上下布局
      return _buildPhoneLayout(provider);
    }
  }

  /// 平板布局：左侧日历（45%）+ 右侧课程列表（55%）
  Widget _buildTabletLayout(ScheduleProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：日历选择器（45%）
            Expanded(
              flex: 45,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GlassPanel(
                      shape: const LiquidRoundedSuperellipse(borderRadius: 32),
                      padding: const EdgeInsets.all(16),
                      settings: LiquidGlassSettings(
                        glassColor: Colors.white.withValues(alpha: 0.05),
                        blur: 15,
                        thickness: 0.8,
                      ),
                      child: _buildCalendarGrid(provider),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // 右侧：课程列表（55%）
            Expanded(flex: 55, child: _buildSelectedDateCourses(provider)),
          ],
        ),
      ),
    );
  }

  /// 手机布局：上下布局
  Widget _buildPhoneLayout(ScheduleProvider provider) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        GlassPanel(
          shape: const LiquidRoundedSuperellipse(borderRadius: 32),
          padding: const EdgeInsets.all(16),
          settings: LiquidGlassSettings(
            glassColor: Colors.white.withValues(alpha: 0.05),
            blur: 15,
            thickness: 0.8,
          ),
          child: _buildCalendarGrid(provider),
        ),
        const SizedBox(height: 20),
        Expanded(child: _buildSelectedDateCourses(provider)),
      ],
    );
  }

  // 仅修改 _buildHeader
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: liquid.LiquidCard(
        padding: 12,
        borderRadius: 24,
        styleType: liquid.LiquidStyleType.standard, // 恢复标准高光模糊
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(
                CupertinoIcons.left_chevron,
                color: Colors.white,
              ),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '${_currentMonth.year}年${_currentMonth.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(
                CupertinoIcons.right_chevron,
                color: Colors.white,
              ),
              onPressed: () => _changeMonth(1),
            ),
            SizedBox(
              width: 80,
              child: liquid.LiquidButton(
                text: _isMonthView ? '收起' : '展开',
                onTap: _toggleViewMode,
                // [修复] 亮色
                color: Colors.cyanAccent.withValues(alpha: 0.9),
                isOutline: true, // 使用轮廓模式更通透
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ...

  Widget _buildCalendarGrid(ScheduleProvider provider) {
    List<DateTime> days = [];
    if (_isMonthView) {
      final firstDay = _firstDayOfMonth;
      final daysInMonth = _lastDayOfMonth.day;
      final firstWeekday = firstDay.weekday;
      for (int i = 1; i < firstWeekday; i++) {
        days.add(
          DateTime(firstDay.year, firstDay.month, 1 - (firstWeekday - i)),
        );
      }
      for (int i = 1; i <= daysInMonth; i++) {
        days.add(DateTime(firstDay.year, firstDay.month, i));
      }
      while (days.length % 7 != 0) {
        final lastDate = days.last;
        days.add(DateTime(lastDate.year, lastDate.month, lastDate.day + 1));
      }
    } else {
      final target = _selectedDate ?? DateTime.now();
      final monday = target.subtract(Duration(days: target.weekday - 1));
      for (int i = 0; i < 7; i++) {
        days.add(monday.add(Duration(days: i)));
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isMonthView ? 320 : 70, // 减小高度
      child: Column(
        children: [
          if (_isMonthView)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: ['一', '二', '三', '四', '五', '六', '日']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: _isMonthView ? 1.0 : 1.2, // 调整比例
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final hasCourses = _getCoursesForDate(
                  date,
                  provider.courses,
                ).isNotEmpty;
                final isSelected =
                    _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;
                return _buildDayCell(
                  date,
                  isSelected,
                  hasCourses,
                  _isToday(date),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    bool isSelected,
    bool hasCourses,
    bool isToday,
  ) {
    Widget content = Stack(
      alignment: Alignment.center,
      children: [
        if (isToday && !isSelected)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppThemeColors.babyPink.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (hasCourses)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppThemeColors.softCoral,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ],
    );

    if (isSelected) {
      // 修复长条白块：给选中项一个固定的正方形区域，防止被拉伸
      return Center(
        child: SizedBox(
          width: 36,
          height: 36, // 减小尺寸
          child: liquid.LiquidCard(
            borderRadius: 12,
            isSelected: true,
            padding: 0,
            styleType: liquid.LiquidStyleType.micro, // 使用 micro 样式 (低光照防白块)
            child: Center(child: content),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _selectDate(date),
        child: Container(
          color: Colors.transparent,
          child: Center(child: content),
        ),
      );
    }
  }

  Widget _buildSelectedDateCourses(ScheduleProvider provider) {
    if (_selectedDate == null) return const SizedBox.shrink();
    final courses = _getCoursesForDate(_selectedDate!, provider.courses);
    courses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // 添加水平边距
      child: liquid.LiquidCard(
        padding: 0,
        borderRadius: 28,
        child: courses.isEmpty
            ? Center(
                child: Text('该日无课', style: TextStyle(color: Colors.white38)),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 180), // 留出导航栏空间
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: liquid.LiquidCard(
                      borderRadius: 20,
                      padding: 14,
                      // [v2.5.2] 恢复真玻璃带光柱质感
                      quality: GlassQuality.standard,
                      styleType: liquid.LiquidStyleType.standard,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppThemeColors.babyPink.withValues(
                                    alpha: 0.8,
                                  ),
                                  AppThemeColors.softCoral.withValues(
                                    alpha: 0.8,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  course.timeStr.split('-')[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  course.location,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                if (course.teacher.isNotEmpty)
                                  Text(
                                    course.teacher,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // [v2.2.9] 使用自定义 GlassContextMenu
                          GlassContextMenu(
                            items: [
                              GlassContextMenuItem(
                                title: '编辑课程',
                                icon: CupertinoIcons.pencil,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    TransparentMaterialPageRoute(
                                      builder: (_) =>
                                          CourseEditScreen(course: course),
                                    ),
                                  );
                                },
                              ),
                              GlassContextMenuItem(
                                title: '删除本节课程',
                                icon: CupertinoIcons.delete,
                                isDestructive: true,
                                onTap: () async {
                                  final provider =
                                      Provider.of<ScheduleProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await _importService.deleteCourse(course);
                                  await provider.loadSavedData();
                                  if (mounted)
                                    liquid.showLiquidToast(context, '已删除本节课程');
                                },
                              ),
                              GlassContextMenuItem(
                                title: '删除所有本课程',
                                icon: CupertinoIcons.trash,
                                isDestructive: true,
                                onTap: () async {
                                  final provider =
                                      Provider.of<ScheduleProvider>(
                                        context,
                                        listen: false,
                                      );
                                  await _importService.deleteAllCoursesWithName(
                                    course.name,
                                  );
                                  await provider.loadSavedData();
                                  if (mounted)
                                    liquid.showLiquidToast(
                                      context,
                                      '已删除所有${course.name}课程',
                                    );
                                },
                              ),
                            ],
                            trigger: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.ellipsis_vertical,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
