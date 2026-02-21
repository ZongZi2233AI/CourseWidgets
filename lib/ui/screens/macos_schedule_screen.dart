import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/course_event.dart';
import '../../providers/schedule_provider.dart';
import '../../services/data_import_service.dart';
import 'schedule_config_screen.dart';

import 'calendar_view_screen.dart';
import 'course_edit_screen.dart';
import 'macos_about_screen.dart';

/// macOS端的课表显示界面 - 使用Cupertino UI
class MacOSScheduleScreen extends StatefulWidget {
  const MacOSScheduleScreen({super.key});

  @override
  State<MacOSScheduleScreen> createState() => _MacOSScheduleScreenState();
}

class _MacOSScheduleScreenState extends State<MacOSScheduleScreen> {
  int _selectedTabIndex = 0;
  bool _hasAutoJumped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final provider = context.read<ScheduleProvider>();
    await provider.loadSavedData();

    if (provider.hasData && !_hasAutoJumped) {
      await _jumpToCurrentDate();
      _hasAutoJumped = true;
    }
  }

  Future<void> _jumpToCurrentDate() async {
    final provider = context.read<ScheduleProvider>();
    final now = DateTime.now();

    final availableWeeks = await provider.getAvailableWeeks();
    if (availableWeeks.isEmpty) return;

    final minWeek = availableWeeks.first;
    final maxWeek = availableWeeks.last;

    final weeksSinceStart =
        now.difference(provider.semesterStartDate).inDays ~/ 7 + 1;

    if (weeksSinceStart < minWeek) {
      provider.setCurrentWeek(minWeek);
    } else if (weeksSinceStart > maxWeek) {
      provider.setCurrentWeek(maxWeek);
    } else {
      provider.setCurrentWeek(weeksSinceStart);
    }

    final currentDay = now.weekday;
    final availableDays = provider.getAvailableDays();

    if (currentDay > 5 && !availableDays.contains(currentDay)) {
      if (availableDays.isNotEmpty) {
        provider.setCurrentDay(availableDays.first);
      }
    } else {
      provider.setCurrentDay(currentDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: '课表',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.today),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.arrow_down_circle),
            label: '导入',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: '设置',
          ),
        ],
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildScheduleTab();
          case 1:
            return _buildCalendarTab();
          case 2:
            return _buildImportTab();
          case 3:
            return _buildSettingsTab();
          default:
            return _buildScheduleTab();
        }
      },
    );
  }

  /// 构建课表标签页
  Widget _buildScheduleTab() {
    final provider = context.watch<ScheduleProvider>();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('课程表'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(child: _buildScheduleBody(provider)),
    );
  }

  /// 构建日历标签页
  Widget _buildCalendarTab() {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('日历视图'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(child: CalendarViewScreen()),
    );
  }

  /// 构建导入标签页
  Widget _buildImportTab() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('数据导入'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(child: _buildImportBody()),
    );
  }

  /// 构建设置标签页
  Widget _buildSettingsTab() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('设置'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(child: _buildSettingsBody()),
    );
  }

  /// 构建课表主体
  Widget _buildScheduleBody(ScheduleProvider provider) {
    if (!provider.hasData &&
        !provider.isLoading &&
        provider.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          provider.loadSavedData();
        }
      });
    }

    if (provider.isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 20));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              '错误: ${provider.errorMessage!}',
              style: const TextStyle(color: CupertinoColors.systemRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => provider.loadSavedData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (!provider.hasData) {
      return _buildEmptyView(provider);
    }

    return _buildScheduleView(provider);
  }

  /// 构建空状态视图
  Widget _buildEmptyView(ScheduleProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.calendar,
            size: 80,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无课表数据',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '请导入ICS格式的课表文件',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: () => provider.importData(),
            child: const Text('导入ICS文件'),
          ),
        ],
      ),
    );
  }

  /// 构建课表视图
  Widget _buildScheduleView(ScheduleProvider provider) {
    return Column(
      children: [
        _buildWeekAndDaySelector(provider),
        Expanded(child: _buildCourseList(provider)),
      ],
    );
  }

  /// 周次和星期选择器
  Widget _buildWeekAndDaySelector(ScheduleProvider provider) {
    return Container(
      color: CupertinoColors.systemBackground,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          FutureBuilder<List<int>>(
            future: provider.getAvailableWeeks(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final weeks = snapshot.data!;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: weeks.map((week) {
                  final isSelected = week == provider.currentWeek;
                  return CupertinoButton(
                    minimumSize: const Size(32, 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey5,
                    onPressed: () => provider.setCurrentWeek(week),
                    child: Text(
                      '第$week周',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildDaySelector(provider),
        ],
      ),
    );
  }

  /// 星期选择器
  Widget _buildDaySelector(ScheduleProvider provider) {
    final days = provider.getAvailableDays();
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((day) {
        final isSelected = day == provider.currentDay;
        return CupertinoButton(
          minimumSize: const Size(28, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          borderRadius: BorderRadius.circular(6),
          color: isSelected
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemGrey6,
          onPressed: () => provider.setCurrentDay(day),
          child: Text(
            provider.getDayName(day),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? CupertinoColors.white : CupertinoColors.label,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 课程列表
  Widget _buildCourseList(ScheduleProvider provider) {
    final courses = provider.getCurrentDayCourses();

    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 16),
            Text(
              '当天无课程',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      );
    }

    courses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(courses[index]);
        },
      ),
    );
  }

  /// 课程卡片
  Widget _buildCourseCard(CourseEvent course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        onPressed: () => _showCourseDetailDialog(course),
        child: Row(
          children: [
            // 时间指示器
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCourseColor(course.name),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  course.timeStr.split('-')[0].substring(0, 5),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 课程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.label,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${course.location}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                  if (course.teacher.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '👨‍🏫 ${course.teacher}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '⏰ ${course.timeStr}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemGrey2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 箭头图标
            const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据课程名称生成颜色
  Color _getCourseColor(String courseName) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF009688), // Teal
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFE91E63), // Pink
    ];

    final hash = courseName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// 显示课程详情弹窗
  void _showCourseDetailDialog(CourseEvent course) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('课程详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('课程名称', course.name),
            _buildDetailRow('上课时间', course.timeStr),
            _buildDetailRow('上课地点', course.location),
            _buildDetailRow('任课教师', course.teacher),
            _buildDetailRow('日期', course.dateStr),
            _buildDetailRow(
              '星期',
              context.read<ScheduleProvider>().getDayName(course.weekday),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _editCourse(course);
            },
            child: const Text('编辑'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label：',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// 编辑课程
  void _editCourse(CourseEvent course) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CourseEditScreen(course: course),
      ),
    );
  }

  /// 构建导入主体
  Widget _buildImportBody() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据导入',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // ICS导入
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '从ICS文件导入课表数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () async {
                    final provider = context.read<ScheduleProvider>();
                    final result = await provider.importData();
                    if (result && mounted) {
                      _showSuccessDialog('课表导入成功！');
                    }
                  },
                  child: const Text('选择ICS文件'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // HTML导入
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '从HTML文件导入并自动转换为ICS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () async {
                    final provider = context.read<ScheduleProvider>();
                    final result = await provider.importHtmlData();
                    if (result && mounted) {
                      _showSuccessDialog('HTML导入并转换成功！');
                    }
                  },
                  child: const Text('选择HTML文件'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Assets导入
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '从Assets导入测试数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () async {
                    final provider = context.read<ScheduleProvider>();
                    final result = await provider.importFromAssets();
                    if (result && mounted) {
                      _showSuccessDialog('从assets导入成功！');
                    }
                  },
                  child: const Text('导入测试数据'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 导出数据
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '导出数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () async {
                          final provider = context.read<ScheduleProvider>();
                          if (!provider.hasData) {
                            _showErrorDialog('请先导入课表数据');
                            return;
                          }
                          final result = await provider.exportData();
                          if (mounted) {
                            if (result) {
                              _showSuccessDialog('数据导出成功！');
                            } else {
                              _showErrorDialog('导出失败');
                            }
                          }
                        },
                        child: const Text('导出为JSON'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () async {
                          final provider = context.read<ScheduleProvider>();
                          if (!provider.hasData) {
                            _showErrorDialog('请先导入课表数据');
                            return;
                          }
                          final dataImportService = DataImportService();
                          final activeSchedule = await dataImportService
                              .getActiveSchedule();
                          if (activeSchedule != null) {
                            final result = await dataImportService
                                .exportHistoryToIcs(activeSchedule['id']);
                            if (mounted) {
                              if (result) {
                                _showSuccessDialog('ICS文件已导出到当前目录');
                              } else {
                                _showErrorDialog('导出失败');
                              }
                            }
                          } else {
                            _showErrorDialog('没有可导出的历史记录');
                          }
                        },
                        child: const Text('导出为ICS'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 清除数据
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '清除数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () async {
                    final confirm = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('确认清除'),
                        content: const Text('确定要清除所有课表数据吗？'),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await context.read<ScheduleProvider>().clearData();
                      if (mounted) {
                        _showSuccessDialog('数据已清除');
                      }
                    }
                  },
                  child: const Text('清除所有数据'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置主体
  Widget _buildSettingsBody() {
    final dateController = TextEditingController(
      text:
          '${context.read<ScheduleProvider>().semesterStartDate.year}-${context.read<ScheduleProvider>().semesterStartDate.month.toString().padLeft(2, '0')}-${context.read<ScheduleProvider>().semesterStartDate.day.toString().padLeft(2, '0')}',
    );

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学期配置',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // 学期开始日期
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '学期开始日期',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: dateController,
                  placeholder: '2025-09-01',
                  suffix: CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    onPressed: () async {
                      // 使用CupertinoDatePicker的正确方式
                      final date = await showCupertinoDialog<DateTime>(
                        context: context,
                        builder: (context) {
                          DateTime? selectedDate = context
                              .read<ScheduleProvider>()
                              .semesterStartDate;
                          return CupertinoAlertDialog(
                            title: const Text('选择日期'),
                            content: SizedBox(
                              height: 200,
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.date,
                                initialDateTime: selectedDate,
                                minimumDate: DateTime(2020),
                                maximumDate: DateTime(2030),
                                onDateTimeChanged: (DateTime newDate) {
                                  selectedDate = newDate;
                                },
                              ),
                            ),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () =>
                                    Navigator.pop(context, selectedDate),
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
                      if (date != null) {
                        dateController.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }
                    },
                    child: const Icon(CupertinoIcons.calendar, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    try {
                      final parts = dateController.text.split('-');
                      if (parts.length == 3) {
                        final date = DateTime(
                          int.parse(parts[0]),
                          int.parse(parts[1]),
                          int.parse(parts[2]),
                        );
                        context.read<ScheduleProvider>().setSemesterStartDate(
                          date,
                        );
                        _showSuccessDialog('配置已更新');
                      }
                    } catch (e) {
                      _showErrorDialog('日期格式错误，请使用 YYYY-MM-DD');
                    }
                  },
                  child: const Text('保存配置'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 课时配置
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '课时配置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  '调整每节课的开始时间、时长和课间休息时间',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const ScheduleConfigScreen(),
                      ),
                    );
                  },
                  child: const Text('打开课时配置'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 历史记录
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '历史记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  '查看和管理课程表历史记录',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    _showHistoryDialog(context);
                  },
                  child: const Text('查看历史记录'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 关于软件
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '关于软件',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  '查看版本信息和开发者信息',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const MacOSSAboutScreen(),
                      ),
                    );
                  },
                  child: const Text('查看关于'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示历史记录管理弹窗
  void _showHistoryDialog(BuildContext context) {
    final dataImportService = DataImportService();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('课程表历史记录'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: dataImportService.getAllHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 48,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无历史记录',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                );
              }

              final history = snapshot.data!;
              final activeSchedule = history.firstWhere(
                (item) => item['is_active'] == 1,
                orElse: () => {},
              );

              return CupertinoScrollbar(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isActive = item['id'] == activeSchedule['id'];
                    final createdAt = DateTime.fromMillisecondsSinceEpoch(
                      item['created_at'],
                    );

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE3F2FD)
                            : CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF1976D2)
                              : CupertinoColors.systemGrey5,
                        ),
                      ),
                      child: CupertinoListTile(
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? const Color(0xFF1976D2)
                                : CupertinoColors.label,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('类型: ${item['source_type'].toUpperCase()}'),
                            Text('学期: ${item['semester']}'),
                            Text(
                              '创建: ${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                            ),
                            if (isActive)
                              const Text(
                                '✓ 当前使用',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 切换按钮
                            CupertinoButton(
                              padding: const EdgeInsets.all(4),
                              onPressed: isActive
                                  ? null
                                  : () async {
                                      final success = await dataImportService
                                          .switchToHistory(item['id']);
                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        _showSuccessDialog(
                                          '已切换到 ${item['name']}',
                                        );
                                        context
                                            .read<ScheduleProvider>()
                                            .loadSavedData();
                                      }
                                    },
                              child: Icon(
                                isActive
                                    ? CupertinoIcons.check_mark_circled
                                    : CupertinoIcons.add_circled,
                                size: 20,
                                color: isActive
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemBlue,
                              ),
                            ),
                            // 导出按钮
                            CupertinoButton(
                              padding: const EdgeInsets.all(4),
                              onPressed: () async {
                                final success = await dataImportService
                                    .exportHistoryToIcs(item['id']);
                                if (success && context.mounted) {
                                  _showSuccessDialog('ICS文件已导出');
                                }
                              },
                              child: const Icon(
                                CupertinoIcons.download_circle,
                                size: 20,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                            // 删除按钮
                            CupertinoButton(
                              padding: const EdgeInsets.all(4),
                              onPressed: () async {
                                final confirm = await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('确认删除'),
                                    content: Text('确定要删除 "${item['name']}" 吗？'),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await dataImportService
                                      .deleteHistory(item['id']);
                                  if (success && context.mounted) {
                                    _showSuccessDialog('记录已删除');
                                    setState(() {});
                                  }
                                }
                              },
                              child: const Icon(
                                CupertinoIcons.trash_circle,
                                size: 20,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示成功对话框
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          children: [
            Icon(
              CupertinoIcons.check_mark_circled,
              color: CupertinoColors.systemGreen,
            ),
            SizedBox(width: 8),
            Text('成功'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemRed,
            ),
            SizedBox(width: 8),
            Text('错误'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
