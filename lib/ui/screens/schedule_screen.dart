import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import '../../providers/schedule_provider.dart';
import '../../models/course_event.dart';
import '../../services/data_import_service.dart';
import '../../services/database_helper.dart';
import 'schedule_config_screen.dart';
import 'course_edit_screen.dart';
import '../transitions/smooth_slide_transitions.dart';

/// WinUI3风格的课表显示界面 - 基于SQLite数据库
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动加载保存的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSavedData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'CourseWidgets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (provider.hasData) ...[
              const SizedBox(height: 2),
              Text(
                provider.getSemesterStatus(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getSemesterStatusColor(provider),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: '导入ICS文件',
            onPressed: () async {
              final result = await provider.importData();
              if (result && mounted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('课表导入成功！')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.html),
            tooltip: '导入HTML文件',
            onPressed: () async {
              final result = await provider.importHtmlData();
              if (result && mounted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('HTML导入成功！')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '课程表历史',
            onPressed: () {
              _showHistoryDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出数据',
            onPressed: () async {
              if (!provider.hasData) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请先导入课表数据')));
                }
                return;
              }
              final result = await provider.exportData();
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result ? '数据导出成功！' : '导出失败')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: '添加课程',
            onPressed: () {
              Navigator.push(
                context,
                TransparentMaterialPageRoute(
                  builder: (context) => CourseEditScreen(
                    week: context.read<ScheduleProvider>().currentWeek,
                    day: context.read<ScheduleProvider>().currentDay,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '课时配置',
            onPressed: () {
              Navigator.push(
                context,
                TransparentMaterialPageRoute(
                  builder: (context) => const ScheduleConfigScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: '学期配置',
            onPressed: () {
              _showSemesterConfigDialog(context, provider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除数据',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清除'),
                  content: const Text('确定要清除所有课表数据吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '确定',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await provider.clearData();
                if (mounted && context.mounted) {
                  Phoenix.rebirth(context);
                }
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSavedData(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : provider.hasData
          ? _buildScheduleView(provider)
          : _buildEmptyView(),
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            '暂无课表数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请导入ICS格式的课表文件',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<ScheduleProvider>().importData(),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('导入ICS文件', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 40),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              // 从assets导入测试数据
              final result = await context
                  .read<ScheduleProvider>()
                  .importFromAssets();
              if (result && mounted && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('从assets导入成功！')));
              }
            },
            child: const Text('从assets导入测试数据', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// 构建课表视图
  Widget _buildScheduleView(ScheduleProvider provider) {
    return Column(
      children: [
        // 周次和星期选择器
        _buildWeekAndDaySelector(provider),

        // 课程列表
        Expanded(child: _buildCourseList(provider)),
      ],
    );
  }

  /// 周次和星期选择器
  Widget _buildWeekAndDaySelector(ScheduleProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // 周次选择 - 动态获取可用周次
          Builder(
            builder: (context) {
              final weeks = provider.availableWeeks;
              if (weeks.isEmpty) {
                return const SizedBox.shrink();
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: weeks.map((week) {
                    final isSelected = week == provider.currentWeek;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('第$week周'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            provider.setCurrentWeek(week);
                          }
                        },
                        selectedColor: Colors.blue[600],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue[600]!
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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

  /// 星期选择器
  Widget _buildDaySelector(ScheduleProvider provider) {
    final days = provider.getAvailableDays();
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: days.map((day) {
          final isSelected = day == provider.currentDay;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: FilterChip(
              label: Text(provider.getDayName(day)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.setCurrentDay(day);
                }
              },
              selectedColor: Colors.green[600],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '当天无课程',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          return _buildCourseCard(course);
        },
      ),
    );
  }

  /// 课程卡片
  Widget _buildCourseCard(CourseEvent course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
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
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '📍 ${course.location}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (course.teacher.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '👨‍🏫 ${course.teacher}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              '⏰ ${course.timeStr}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey[400],
        ),
        onTap: () {
          _showCourseDetailDialog(context, course);
        },
        onLongPress: () {
          _showCourseActions(context, course);
        },
      ),
    );
  }

  /// 显示课程操作菜单
  void _showCourseActions(BuildContext context, CourseEvent course) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('编辑课程'),
            onTap: () {
              Navigator.pop(context);
              _editCourse(course);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('删除课程'),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: Text('确定要删除 "${course.name}" 吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '删除',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _deleteCourse(course);
              }
            },
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
        ],
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

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除 "${course.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 根据课程名称生成颜色
  Color _getCourseColor(String courseName) {
    final colors = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
      Colors.indigo[400]!,
      Colors.pink[400]!,
    ];

    final hash = courseName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// 显示课程详情弹窗
  void _showCourseDetailDialog(BuildContext context, CourseEvent course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// 显示学期配置弹窗
  void _showSemesterConfigDialog(
    BuildContext context,
    ScheduleProvider provider,
  ) {
    final dateController = TextEditingController(
      text:
          '${provider.semesterStartDate.year}-${provider.semesterStartDate.month.toString().padLeft(2, '0')}-${provider.semesterStartDate.day.toString().padLeft(2, '0')}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学期配置'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: '学期开始日期',
                  hintText: '2025-09-01',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ), // 增加内边距
                ),
                style: const TextStyle(fontSize: 16),
                onTap: () async {
                  // 弹出日期选择器
                  final date = await showDatePicker(
                    context: context,
                    initialDate: provider.semesterStartDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: const TextTheme(
                            bodyLarge: TextStyle(fontSize: 16),
                            bodyMedium: TextStyle(fontSize: 14),
                            labelLarge: TextStyle(fontSize: 16),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    dateController.text =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text(
                '提示: 选择本学期的开始日期，用于计算当前周次',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('配置已更新')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日期格式错误，请使用 YYYY-MM-DD')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 根据学期状态获取颜色
  Color _getSemesterStatusColor(ScheduleProvider provider) {
    if (!provider.hasData) return Colors.grey;

    // 检查是否在学期内（简化逻辑）
    final now = DateTime.now();
    final weeksSinceStart =
        now.difference(provider.semesterStartDate).inDays ~/ 7 + 1;

    // 这里应该检查实际的可用周次，但为了简化，我们假设如果当前周大于15周就是假期
    if (weeksSinceStart > 15) {
      return Colors.orange; // 假期中
    }

    return Colors.blue; // 学期内
  }

  /// 显示历史记录管理弹窗
  void _showHistoryDialog(BuildContext context) {
    final dataImportService = DataImportService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('课程表历史记录'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: dataImportService.getAllHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无历史记录', style: TextStyle(color: Colors.grey)),
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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isActive ? Colors.blue[50] : null,
                    child: ListTile(
                      title: Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.blue[700] : null,
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
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 切换按钮
                          IconButton(
                            icon: Icon(
                              Icons.check_circle,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                            tooltip: '切换到此记录',
                            onPressed: isActive
                                ? null
                                : () async {
                                    final success = await dataImportService
                                        .switchToHistory(item['id']);
                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('已切换到 ${item['name']}'),
                                        ),
                                      );
                                      // 重新加载数据
                                      context
                                          .read<ScheduleProvider>()
                                          .loadSavedData();
                                    }
                                  },
                          ),
                          // 导出按钮
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.blue,
                            ),
                            tooltip: '导出为ICS',
                            onPressed: () async {
                              final success = await dataImportService
                                  .exportHistoryToIcs(item['id']);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ICS文件已导出')),
                                );
                              }
                            },
                          ),
                          // 删除按钮
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: '删除记录',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: Text('确定要删除 "${item['name']}" 吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        '删除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final success = await dataImportService
                                    .deleteHistory(item['id']);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('记录已删除')),
                                  );
                                  // 刷新列表
                                  setState(() {});
                                }
                              }
                            },
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
