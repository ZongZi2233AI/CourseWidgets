import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../constants/theme_constants.dart';

/// [修复5] 液态玻璃日期选择器 - iOS风格三列滚轮（月，日，年）
class LiquidGlassDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  const LiquidGlassDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<LiquidGlassDatePicker> createState() => _LiquidGlassDatePickerState();
}

class _LiquidGlassDatePickerState extends State<LiquidGlassDatePicker> {
  late int selectedMonth;
  late int selectedDay;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
    selectedYear = widget.initialDate.year;
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDate() {
    final maxDay = _daysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDay) {
      selectedDay = maxDay;
    }
    widget.onDateChanged(DateTime(selectedYear, selectedMonth, selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    // 横屏时限制最大宽度和高度
    final maxWidth = isLandscape ? screenWidth * 0.6 : screenWidth;
    final maxHeight = isLandscape ? screenHeight * 0.5 : 250.0;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: GlassContainer(
          shape: LiquidRoundedSuperellipse(borderRadius: 24),
          settings: LiquidGlassSettings(
            glassColor: Colors.black.withValues(alpha: 0.3),
            blur: 20,
            thickness: 15,
          ),
          child: Container(
            height: maxHeight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
          children: [
            // 月份选择
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedMonth - 1,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedMonth = index + 1;
                    _updateDate();
                  });
                },
                children: List.generate(
                  12,
                  (index) => Center(
                    child: Text(
                      '${index + 1}月',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none, // [v2.2.9修复] 移除下划线
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 日期选择
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedDay - 1,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedDay = index + 1;
                    _updateDate();
                  });
                },
                children: List.generate(
                  _daysInMonth(selectedYear, selectedMonth),
                  (index) => Center(
                    child: Text(
                      '${index + 1}日',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none, // [v2.2.9修复] 移除下划线
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 年份选择
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedYear - 2020,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedYear = 2020 + index;
                    _updateDate();
                  });
                },
                children: List.generate(
                  20, // 2020-2039
                  (index) => Center(
                    child: Text(
                      '${2020 + index}年',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none, // [v2.2.9修复] 移除下划线
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

/// [修复5] 液态玻璃星期选择器 - 单列滚轮
class LiquidGlassWeekdayPicker extends StatelessWidget {
  final int initialWeekday; // 1-7
  final ValueChanged<int> onWeekdayChanged;

  const LiquidGlassWeekdayPicker({
    super.key,
    required this.initialWeekday,
    required this.onWeekdayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    // 横屏时限制最大宽度和高度
    final maxWidth = isLandscape ? screenWidth * 0.5 : screenWidth;
    final maxHeight = isLandscape ? screenHeight * 0.5 : 250.0;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: GlassContainer(
          shape: LiquidRoundedSuperellipse(borderRadius: 24),
          settings: LiquidGlassSettings(
            glassColor: Colors.black.withValues(alpha: 0.3),
            blur: 20,
            thickness: 15,
          ),
          child: Container(
            height: maxHeight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
            initialItem: initialWeekday - 1,
          ),
          itemExtent: 40,
          onSelectedItemChanged: (index) {
            onWeekdayChanged(index + 1);
          },
          children: [
            '周一',
            '周二',
            '周三',
            '周四',
            '周五',
            '周六',
            '周日',
          ].map((day) => Center(
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none, // [v2.2.9修复] 移除下划线
              ),
            ),
          )).toList(),
        ),
      ),
        ),
      ),
    );
  }
}

/// 显示液态玻璃日期选择器
Future<DateTime?> showLiquidGlassDatePicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  DateTime? selectedDate = initialDate;
  
  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassDatePicker(
            initialDate: initialDate,
            onDateChanged: (date) {
              selectedDate = date;
            },
          ),
          const SizedBox(height: 12),
          GlassButton.custom(
            onTap: () => Navigator.pop(ctx),
            width: double.infinity,
            height: 48,
            style: GlassButtonStyle.filled,
            settings: LiquidGlassSettings(
              glassColor: AppThemeColors.babyPink.withValues(alpha: 0.8),
              blur: 0,
            ),
            shape: LiquidRoundedSuperellipse(borderRadius: 16),
            child: const Center(
              child: Text(
                '确定',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  
  return selectedDate;
}

/// 显示液态玻璃星期选择器
Future<int?> showLiquidGlassWeekdayPicker({
  required BuildContext context,
  required int initialWeekday,
}) async {
  int? selectedWeekday = initialWeekday;
  
  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassWeekdayPicker(
            initialWeekday: initialWeekday,
            onWeekdayChanged: (weekday) {
              selectedWeekday = weekday;
            },
          ),
          const SizedBox(height: 12),
          GlassButton.custom(
            onTap: () => Navigator.pop(ctx),
            width: double.infinity,
            height: 48,
            style: GlassButtonStyle.filled,
            settings: LiquidGlassSettings(
              glassColor: AppThemeColors.babyPink.withValues(alpha: 0.8),
              blur: 0,
            ),
            shape: LiquidRoundedSuperellipse(borderRadius: 16),
            child: const Center(
              child: Text(
                '确定',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  
  return selectedWeekday;
}

/// 液态玻璃日历选择器 - 月历视图
class LiquidGlassCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  const LiquidGlassCalendarPicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<LiquidGlassCalendarPicker> createState() => _LiquidGlassCalendarPickerState();
}

class _LiquidGlassCalendarPickerState extends State<LiquidGlassCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDay = _currentMonth;
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // 获取第一天是星期几（1=周一，7=周日）
    final firstWeekday = firstDay.weekday;
    
    // 创建日期列表，前面补空
    final days = <DateTime?>[];
    
    // 补充前面的空白
    for (int i = 1; i < firstWeekday; i++) {
      days.add(null);
    }
    
    // 添加本月的日期
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    
    return GlassContainer(
      shape: LiquidRoundedSuperellipse(borderRadius: 24),
      settings: LiquidGlassSettings(
        glassColor: Colors.black.withValues(alpha: 0.3),
        blur: 20,
        thickness: 15,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 月份导航
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassButton.custom(
                  onTap: _previousMonth,
                  width: 40,
                  height: 40,
                  style: GlassButtonStyle.filled,
                  settings: LiquidGlassSettings(
                    glassColor: Colors.white.withValues(alpha: 0.1),
                    blur: 0,
                  ),
                  shape: LiquidRoundedSuperellipse(borderRadius: 12),
                  child: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Text(
                  '${_currentMonth.year}年${_currentMonth.month}月',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GlassButton.custom(
                  onTap: _nextMonth,
                  width: 40,
                  height: 40,
                  style: GlassButtonStyle.filled,
                  settings: LiquidGlassSettings(
                    glassColor: Colors.white.withValues(alpha: 0.1),
                    blur: 0,
                  ),
                  shape: LiquidRoundedSuperellipse(borderRadius: 12),
                  child: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 星期标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['一', '二', '三', '四', '五', '六', '日']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            
            // 日期网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                if (date == null) {
                  return const SizedBox();
                }
                
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                
                return GlassButton.custom(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateChanged(date);
                  },
                  width: 40,
                  height: 40,
                  style: GlassButtonStyle.filled,
                  settings: LiquidGlassSettings(
                    glassColor: isSelected
                        ? AppThemeColors.babyPink.withValues(alpha: 0.6)
                        : isToday
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                    blur: 0,
                  ),
                  shape: LiquidRoundedSuperellipse(borderRadius: 12),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示液态玻璃日历选择器
Future<DateTime?> showLiquidGlassCalendarPicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  DateTime? selectedDate = initialDate;
  
  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassCalendarPicker(
            initialDate: initialDate,
            onDateChanged: (date) {
              selectedDate = date;
            },
          ),
          const SizedBox(height: 12),
          GlassButton.custom(
            onTap: () => Navigator.pop(ctx),
            width: double.infinity,
            height: 48,
            style: GlassButtonStyle.filled,
            settings: LiquidGlassSettings(
              glassColor: AppThemeColors.babyPink.withValues(alpha: 0.8),
              blur: 0,
            ),
            shape: LiquidRoundedSuperellipse(borderRadius: 16),
            child: const Center(
              child: Text(
                '确定',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  
  return selectedDate;
}
