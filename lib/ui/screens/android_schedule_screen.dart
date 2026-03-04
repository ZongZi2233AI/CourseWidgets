import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/course_event.dart';
import '../../services/data_import_service.dart';
import '../../services/database_helper.dart';
import 'android_schedule_config_screen.dart';
import 'course_edit_screen.dart';
import 'calendar_view_screen.dart';
import 'settings_about_screen.dart';
import '../transitions/smooth_slide_transitions.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

// 常量定义
const String appName = "CourseWidgets";

/// 安卓端的课表显示界面 - 使用Cupertino UI (iOS风格)
class AndroidScheduleScreen extends StatefulWidget {
  const AndroidScheduleScreen({super.key});

  @override
  State<AndroidScheduleScreen> createState() => _AndroidScheduleScreenState();
}

class _AndroidScheduleScreenState extends State<AndroidScheduleScreen> {
  // 移除未使用的变量 _selectedTabIndex
  bool _hasAutoJumped = false; // 防止重复自动跳转

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

    // 数据加载完成后执行自动跳转
    if (provider.hasData && !_hasAutoJumped) {
      await _jumpToCurrentDate();
      _hasAutoJumped = true;
    }
  }

  /// 自动跳转到当前日期
  Future<void> _jumpToCurrentDate() async {
    final provider = context.read<ScheduleProvider>();
    final now = DateTime.now();

    // 获取可用周次
    final availableWeeks = await provider.getAvailableWeeks();
    if (availableWeeks.isEmpty) return;

    final minWeek = availableWeeks.first;
    final maxWeek = availableWeeks.last;

    // 计算当前周次
    final weeksSinceStart =
        now.difference(provider.semesterStartDate).inDays ~/ 7 + 1;

    // 智能判断课程状态
    if (weeksSinceStart < minWeek) {
      // 课程未开始，显示第一周
      provider.setCurrentWeek(minWeek);
      if (mounted) {
        _showCupertinoAlert('课程未开始', '当前显示第一周课程');
      }
    } else if (weeksSinceStart > maxWeek) {
      // 课程已结束，显示最后一周
      provider.setCurrentWeek(maxWeek);
      if (mounted) {
        _showCupertinoAlert('课程已结束', '当前显示最后一周课程');
      }
    } else {
      // 课程进行中，显示当前周
      provider.setCurrentWeek(weeksSinceStart);
    }

    // 智能处理星期
    final currentDay = now.weekday; // 1-7，周一到周日
    final availableDays = provider.getAvailableDays();

    // 如果是周末且当天无课程，自动切换到周一
    if (currentDay > 5 && !availableDays.contains(currentDay)) {
      if (availableDays.isNotEmpty) {
        provider.setCurrentDay(availableDays.first);
      }
    } else {
      provider.setCurrentDay(currentDay);
    }
  }

  /// 显示Cupertino风格的警告框
  void _showCupertinoAlert(String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: '课表',
          ),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: '日历'),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_arrow_down),
            label: '导入',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: '设置',
          ),
        ],
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
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text("CourseWidgets"),
            backgroundColor: CupertinoColors.systemBackground,
          ),
          child: SafeArea(
            child: provider.isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : provider.errorMessage != null
                ? _buildErrorView(provider)
                : provider.hasData
                ? _buildScheduleView(provider)
                : _buildEmptyView(provider),
          ),
        );
      },
    );
  }

  /// 构建日历标签页
  Widget _buildCalendarTab() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('日历视图'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(child: CalendarViewScreen()),
    );
  }

  /// 构建导入标签页
  Widget _buildImportTab() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('数据导入'),
            backgroundColor: CupertinoColors.systemBackground,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCupertinoCard(
                    title: '从ICS文件导入',
                    subtitle: '导入标准ICS格式的课表文件',
                    icon: CupertinoIcons.doc_text,
                    onPressed: () async {
                      final result = await provider.importData();
                      if (result && mounted) {
                        _showCupertinoAlert('导入成功', '课表导入成功！');
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '从HTML文件导入',
                    subtitle: '导入HTML并自动转换为ICS格式',
                    icon: CupertinoIcons.doc_chart,
                    onPressed: () async {
                      final result = await provider.importHtmlData();
                      if (result && mounted) {
                        _showCupertinoAlert('导入成功', 'HTML导入并转换成功！');
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '从Assets导入测试数据',
                    subtitle: '使用内置测试数据快速体验',
                    icon: CupertinoIcons.lab_flask,
                    onPressed: () async {
                      final result = await provider.importFromAssets();
                      if (result && mounted) {
                        _showCupertinoAlert('导入成功', '从assets导入成功！');
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '导出数据',
                    subtitle: '导出为JSON格式',
                    icon: CupertinoIcons.square_arrow_down,
                    onPressed: () async {
                      if (!provider.hasData) {
                        _showCupertinoAlert('提示', '请先导入课表数据');
                        return;
                      }
                      final result = await provider.exportData();
                      if (mounted) {
                        _showCupertinoAlert(
                          result ? '导出成功' : '导出失败',
                          result ? '数据已导出到当前目录' : '导出失败，请重试',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '清除数据',
                    subtitle: '删除所有课表数据',
                    icon: CupertinoIcons.trash,
                    isDestructive: true,
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
                        await provider.clearData();
                        if (mounted) {
                          Phoenix.rebirth(context);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建设置标签页
  Widget _buildSettingsTab() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('设置'),
            backgroundColor: CupertinoColors.systemBackground,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCupertinoCard(
                    title: '添加课程',
                    subtitle: '手动添加新的课程到课表',
                    icon: CupertinoIcons.plus_circle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        TransparentMaterialPageRoute(
                          builder: (context) => CourseEditScreen(
                            week: provider.currentWeek,
                            day: provider.currentDay,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '导出JSON',
                    subtitle: '导出为JSON格式',
                    icon: CupertinoIcons.square_arrow_down,
                    onPressed: () async {
                      if (!provider.hasData) {
                        _showCupertinoAlert('提示', '请先导入课表数据');
                        return;
                      }
                      final result = await provider.exportData();
                      if (mounted) {
                        _showCupertinoAlert(
                          result ? '导出成功' : '导出失败',
                          result ? '数据已导出到当前目录' : '导出失败，请重试',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '导出ICS',
                    subtitle: '导出为ICS格式',
                    icon: CupertinoIcons.square_arrow_down,
                    onPressed: () async {
                      if (!provider.hasData) {
                        _showCupertinoAlert('提示', '请先导入课表数据');
                        return;
                      }
                      // 使用历史记录导出ICS
                      final dataImportService = DataImportService();
                      final activeSchedule = await dataImportService
                          .getActiveSchedule();
                      if (activeSchedule != null) {
                        final path = await dataImportService.exportHistoryToIcs(
                          activeSchedule['id'],
                        );
                        if (mounted) {
                          _showCupertinoAlert(
                            path != null ? '导出成功' : '导出失败',
                            path != null ? 'ICS 已导出到:\n$path' : '导出失败，请重试',
                          );
                        }
                      } else {
                        _showCupertinoAlert('提示', '没有可导出的历史记录');
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '学期配置',
                    subtitle: '设置学期开始日期',
                    icon: CupertinoIcons.calendar,
                    onPressed: () {
                      _showSemesterConfigDialog(provider);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '课时配置',
                    subtitle: '调整每节课的开始时间、时长和休息时间',
                    icon: CupertinoIcons.clock,
                    onPressed: () {
                      Navigator.push(
                        context,
                        TransparentMaterialPageRoute(
                          builder: (context) =>
                              const AndroidScheduleConfigScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '历史记录',
                    subtitle: '查看和管理课程表历史记录',
                    icon: CupertinoIcons.clock,
                    onPressed: () {
                      _showHistoryDialog(context);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildCupertinoCard(
                    title: '关于软件',
                    subtitle: '查看版本信息和开发者信息',
                    icon: CupertinoIcons.info_circle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        TransparentMaterialPageRoute(
                          builder: (context) => const SettingsAboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 通用的Cupertino卡片组件
  Widget _buildCupertinoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? CupertinoColors.systemRed.withValues(alpha: 0.1)
                    : CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? CupertinoColors.systemRed
                    : CupertinoColors.systemBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? CupertinoColors.systemRed
                          : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示学期配置对话框
  void _showSemesterConfigDialog(ScheduleProvider provider) {
    final dateController = TextEditingController(
      text:
          '${provider.semesterStartDate.year}-${provider.semesterStartDate.month.toString().padLeft(2, '0')}-${provider.semesterStartDate.day.toString().padLeft(2, '0')}',
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('学期配置'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: dateController,
              placeholder: '2025-09-01',
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              try {
                final parts = dateController.text.split('-');
                if (parts.length == 3) {
                  final date = DateTime(
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                    int.parse(parts[2]),
                  );
                  provider.setSemesterStartDate(date);
                  Navigator.pop(context);
                  _showCupertinoAlert('配置已更新', '学期开始日期已保存');
                }
              } catch (e) {
                _showCupertinoAlert('错误', '日期格式错误，请使用 YYYY-MM-DD');
              }
            },
            child: const Text('保存'),
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
          height: 300,
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
                        size: 40,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 8),
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

              return ListView.builder(
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
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey5),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(12),
                      onPressed: null,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isActive
                                        ? CupertinoColors.systemBlue
                                        : CupertinoColors.label,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['source_type'].toUpperCase()} | ${item['semester']} | ${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    '✓ 当前使用',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.all(4),
                                onPressed: isActive
                                    ? null
                                    : () async {
                                        final success = await dataImportService
                                            .switchToHistory(item['id']);
                                        if (success && context.mounted) {
                                          Navigator.pop(context);
                                          _showCupertinoAlert(
                                            '已切换',
                                            '已切换到 ${item['name']}',
                                          );
                                          context
                                              .read<ScheduleProvider>()
                                              .loadSavedData();
                                        }
                                      },
                                child: const Icon(
                                  CupertinoIcons.arrow_2_squarepath,
                                  size: 18,
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(4),
                                onPressed: () async {
                                  final path = await dataImportService
                                      .exportHistoryToIcs(item['id']);
                                  if (path != null && context.mounted) {
                                    _showCupertinoAlert(
                                      '导出成功',
                                      'ICS 已导出到:\n$path',
                                    );
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.square_arrow_down,
                                  size: 18,
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(4),
                                onPressed: () async {
                                  final confirm =
                                      await showCupertinoDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoAlertDialog(
                                              title: const Text('确认删除'),
                                              content: Text(
                                                '确定要删除 "${item['name']}" 吗？',
                                              ),
                                              actions: [
                                                CupertinoDialogAction(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('取消'),
                                                ),
                                                CupertinoDialogAction(
                                                  isDestructiveAction: true,
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('删除'),
                                                ),
                                              ],
                                            ),
                                      );

                                  if (confirm == true) {
                                    final success = await dataImportService
                                        .deleteHistory(item['id']);
                                    if (success && context.mounted) {
                                      _showCupertinoAlert('已删除', '记录已删除');
                                      setState(() {});
                                    }
                                  }
                                },
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  size: 18,
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

  /// 构建空状态视图
  Widget _buildEmptyView(ScheduleProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.calendar,
            size: 80,
            color: CupertinoColors.systemGrey3,
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
            style: TextStyle(color: CupertinoColors.secondaryLabel),
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

  /// 构建错误视图
  Widget _buildErrorView(ScheduleProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            style: const TextStyle(
              color: CupertinoColors.systemRed,
              fontSize: 16,
            ),
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

  /// 构建课表视图
  Widget _buildScheduleView(ScheduleProvider provider) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // 左右滑动切换天
        if (details.primaryVelocity == null) return;

        final velocity = details.primaryVelocity!;
        final availableDays = provider.getAvailableDays();
        final currentIndex = availableDays.indexOf(provider.currentDay);

        if (velocity < 0 && currentIndex < availableDays.length - 1) {
          // 向左滑动 - 下一天
          provider.setCurrentDay(availableDays[currentIndex + 1]);
        } else if (velocity > 0 && currentIndex > 0) {
          // 向右滑动 - 上一天
          provider.setCurrentDay(availableDays[currentIndex - 1]);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // 周次和星期选择器
            _buildWeekAndDaySelector(provider),

            // 课程列表（带滑动动画和层级效果）
            Expanded(child: _buildAnimatedCourseList(provider)),
          ],
        ),
      ),
    );
  }

  /// 周次和星期选择器
  Widget _buildWeekAndDaySelector(ScheduleProvider provider) {
    return Container(
      color: CupertinoColors.systemBackground,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          // 周次选择
          FutureBuilder<List<int>>(
            future: provider.getAvailableWeeks(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final weeks = snapshot.data!;
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    final week = weeks[index];
                    final isSelected = week == provider.currentWeek;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? CupertinoColors.systemBlue
                            : CupertinoColors.systemGrey5,
                        onPressed: () {
                          provider.setCurrentWeek(week);
                        },
                        child: Text(
                          '第$week周',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.label,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // 星期选择
          _buildDaySelector(provider),
        ],
      ),
    );
  }

  /// 星期选择器（带日期标识）
  Widget _buildDaySelector(ScheduleProvider provider) {
    final days = provider.getAvailableDays();
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    // [v2.7.0] 计算每天的实际日期
    final semesterStart = provider.semesterStartDate;
    final weekOffset = (provider.currentWeek - 1) * 7;

    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == provider.currentDay;
          // 计算该天的实际日期
          final dayDate = semesterStart.add(
            Duration(days: weekOffset + day - 1),
          );
          final dateLabel = '${dayDate.month}/${dayDate.day}';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              borderRadius: BorderRadius.circular(6),
              color: isSelected
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemGrey5,
              onPressed: () {
                provider.setCurrentDay(day);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.getDayName(day),
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
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? CupertinoColors.white.withOpacity(0.8)
                          : CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 动画课程列表（带滑动动画）
  Widget _buildAnimatedCourseList(ScheduleProvider provider) {
    final courses = provider.getCurrentDayCourses();

    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_square,
              size: 64,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 16),
            Text(
              '当天无课程',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      );
    }

    // 按时间排序
    courses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      margin: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _buildCourseCard(course),
          );
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
        onPressed: () {
          _showCourseDetailDialog(course);
        },
        onLongPress: () {
          _showCourseActions(course);
        },
        child: Row(
          children: [
            // 时间指示器
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getCourseColor(course.name),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  course.timeStr.split('-')[0].substring(0, 5),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 课程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                  if (course.teacher.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '👨‍🏫 ${course.teacher}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '⏰ ${course.timeStr}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示课程操作菜单
  void _showCourseActions(CourseEvent course) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(course.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editCourse(course);
            },
            child: const Text('编辑课程'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('确认删除'),
                  content: Text('确定要删除 "${course.name}" 吗？'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _deleteCourse(course);
              }
            },
            isDestructiveAction: true,
            child: const Text('删除课程'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 编辑课程
  void _editCourse(CourseEvent course) {
    Navigator.push(
      context,
      TransparentMaterialPageRoute(
        builder: (context) => CourseEditScreen(
          course: course,
          week: context.read<ScheduleProvider>().currentWeek,
          day: context.read<ScheduleProvider>().currentDay,
        ),
      ),
    );
  }

  /// 删除课程
  Future<void> _deleteCourse(CourseEvent course) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteCourses([course]);
      await context.read<ScheduleProvider>().loadSavedData();

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('成功'),
            content: Text('已删除 "${course.name}"'),
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
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('错误'),
            content: Text('删除失败: $e'),
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
    }
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
            onPressed: () {
              Navigator.pop(context);
              _editCourse(course);
            },
            child: const Text('编辑'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
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
}
