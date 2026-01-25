import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../models/course_event.dart';
import '../../providers/schedule_provider.dart';
import '../../services/database_helper.dart';
import '../../constants/theme_constants.dart';
import '../widgets/liquid_components.dart';
import '../widgets/liquid_glass_pickers.dart'; // [修复5] 导入液态玻璃选择器

class CourseEditScreen extends StatefulWidget {
  final CourseEvent? course; 
  final int? week; 
  final int? day; 

  const CourseEditScreen({super.key, this.course, this.week, this.day});

  @override
  State<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _teacherController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late DateTime _selectedDate;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _locationController = TextEditingController(text: widget.course?.location ?? '');
    _teacherController = TextEditingController(text: widget.course?.teacher ?? '');
    final now = DateTime.now();
    _selectedDate = now;
    _selectedDay = widget.day ?? now.weekday;
    _startTimeController = TextEditingController(text: '08:00');
    _endTimeController = TextEditingController(text: '09:40');
    if (widget.course != null) {
       final start = DateTime.fromMillisecondsSinceEpoch(widget.course!.startTime);
       final end = DateTime.fromMillisecondsSinceEpoch(widget.course!.endTime);
       _selectedDate = start;
       _selectedDay = widget.course!.weekday;
       _startTimeController.text = '${start.hour.toString().padLeft(2,'0')}:${start.minute.toString().padLeft(2,'0')}';
       _endTimeController.text = '${end.hour.toString().padLeft(2,'0')}:${end.minute.toString().padLeft(2,'0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 必须透明
      body: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: 0.8,
          blur: 12.0,
          glassColor: Colors.white.withOpacity(0.1),
        ),
        child: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const LiquidBackButton(),
                    const SizedBox(width: 12),
                    Text(
                      widget.course == null ? '添加课程' : '编辑课程',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('基本信息'),
                      const SizedBox(height: 12),
                      LiquidCard(
                        borderRadius: 24,
                        padding: 20,
                        useFakeGlass: true, 
                        glassColor: Colors.white.withOpacity(0.02),
                        child: Column(
                          children: [
                            LiquidInput(controller: _nameController, label: '课程名称', icon: CupertinoIcons.book, placeholder: '例如：高等数学'),
                            const SizedBox(height: 20),
                            LiquidInput(controller: _locationController, label: '上课地点', icon: CupertinoIcons.location, placeholder: '例如：教A-101'),
                            const SizedBox(height: 20),
                            LiquidInput(controller: _teacherController, label: '任课教师', icon: CupertinoIcons.person, placeholder: '例如：张教授'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle('时间信息'),
                      const SizedBox(height: 12),
                      LiquidCard(
                        borderRadius: 24,
                        padding: 20,
                        useFakeGlass: true,
                        glassColor: Colors.white.withOpacity(0.02),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildDateSelector()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDaySelector()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildTimeInput(_startTimeController, '开始')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeInput(_endTimeController, '结束')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          if (widget.course != null)
                            Expanded(child: LiquidButton(text: '删除', onTap: _deleteCourse, color: Colors.redAccent)),
                          if (widget.course != null)
                            const SizedBox(width: 16),
                          Expanded(child: LiquidButton(text: '保存', onTap: _saveCourse, color: AppThemeColors.babyPink)),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  // [v2.1.7] 使用GlassTextField替代LiquidInput用于时间输入
  Widget _buildTimeInput(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GlassTextField(
          controller: controller,
          placeholder: 'HH:MM',
          keyboardType: TextInputType.datetime,
        ),
      ],
    );
  }

  // [修复5] 使用液态玻璃日期选择器
  Widget _buildDateSelector() {
    return LiquidInput(
      label: '日期',
      icon: CupertinoIcons.calendar,
      valueText: '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
      onTap: () async {
        final date = await showLiquidGlassDatePicker(
          context: context,
          initialDate: _selectedDate,
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
    );
  }

  // [修复5] 使用液态玻璃星期选择器
  Widget _buildDaySelector() {
    return LiquidInput(
      label: '星期',
      icon: CupertinoIcons.calendar_today,
      valueText: '周${['一', '二', '三', '四', '五', '六', '日'][_selectedDay - 1]}',
      onTap: () async {
        final day = await showLiquidGlassWeekdayPicker(
          context: context,
          initialWeekday: _selectedDay,
        );
        if (day != null) {
          setState(() => _selectedDay = day);
        }
      },
    );
  }
  
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 解析时间
    final startTimeParts = _startTimeController.text.split(':');
    final endTimeParts = _endTimeController.text.split(':');
    if (startTimeParts.length != 2 || endTimeParts.length != 2) {
      _showAlert('错误', '时间格式错误，请使用 HH:MM 格式');
      return;
    }
    
    final startHour = int.tryParse(startTimeParts[0]);
    final startMinute = int.tryParse(startTimeParts[1]);
    final endHour = int.tryParse(endTimeParts[0]);
    final endMinute = int.tryParse(endTimeParts[1]);
    
    if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
      _showAlert('错误', '时间格式错误');
      return;
    }
    
    // 创建时间戳
    final startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, startHour, startMinute);
    final endTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, endHour, endMinute);
    
    if (endTime.isBefore(startTime)) {
      _showAlert('错误', '结束时间必须晚于开始时间');
      return;
    }
    
    final course = CourseEvent(
      id: widget.course?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text,
      location: _locationController.text,
      teacher: _teacherController.text,
      startTime: startTime.millisecondsSinceEpoch,
      endTime: endTime.millisecondsSinceEpoch,
    );
    
    final db = await DatabaseHelper.instance.database;
    
    if (widget.course == null) {
      await db.insert('courses', course.toMap());
      _showAlert('成功', '课程添加成功');
    } else {
      await db.update('courses', course.toMap(), where: 'id = ?', whereArgs: [course.id]);
      _showAlert('成功', '课程更新成功');
    }
    
    if (mounted) {
      context.read<ScheduleProvider>().loadSavedData();
      Navigator.pop(context);
    }
  }
  
  Future<void> _deleteCourse() async {
    if (widget.course == null) return;
    
    final db = await DatabaseHelper.instance.database;
    await db.delete('courses', where: 'id = ?', whereArgs: [widget.course!.id]);
    
    if (mounted) {
      context.read<ScheduleProvider>().loadSavedData();
      _showAlert('成功', '课程已删除');
      Navigator.pop(context);
    }
  }
  
  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => LiquidGlassDialog(title: title, content: Text(content)),
    );
  }
}
