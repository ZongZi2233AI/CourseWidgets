import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/schedule_provider.dart';
import '../../constants/theme_constants.dart';
import 'android_schedule_config_screen.dart';
import 'course_edit_screen.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/liquid_glass_pickers.dart';

class NewSettingsScreen extends StatefulWidget {
  const NewSettingsScreen({super.key});
  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends State<NewSettingsScreen> {
  Color get _textColor => Colors.white; // 强制白色文字，适应玻璃背景
  Color get _textSecondaryColor => Colors.white70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: 0.8,
          blur: 12.0,
          glassColor: Colors.white.withOpacity(0.1),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const liquid.LiquidBackButton(),
                    const SizedBox(width: 8),
                    Text('课程设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSectionTitle('课程管理'),
                  _buildSettingCard(
                    title: '添加课程',
                    subtitle: '手动添加新课程',
                    icon: CupertinoIcons.add_circled,
                    color: AppThemeColors.babyPink,
                    onTap: () {
                      final provider = context.read<ScheduleProvider>();
                      Navigator.push(context, CupertinoPageRoute(
                        builder: (_) => CourseEditScreen(week: provider.currentWeek, day: provider.currentDay)
                      ));
                    },
                  ),
                  _buildSettingCard(
                    title: '课时配置',
                    subtitle: '调整每节课的时间',
                    icon: CupertinoIcons.time,
                    color: AppThemeColors.softCoral,
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AndroidScheduleConfigScreen())),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('学期设置'),
                  _buildSettingCard(
                    title: '当前周次',
                    subtitle: '设置当前是第几周',
                    icon: CupertinoIcons.calendar_today,
                    color: Colors.blueAccent,
                    onTap: _showWeekPicker,
                  ),
                  _buildSettingCard(
                    title: '开学日期',
                    subtitle: '设置本学期第一周的周一',
                    icon: CupertinoIcons.time_solid,
                    color: Colors.purpleAccent,
                    onTap: _pickSemesterStartDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _textColor,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: liquid.LiquidCard(
        onTap: onTap,
        borderRadius: 20,
        padding: 16,
        glassColor: Colors.white.withOpacity(0.05),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: _textSecondaryColor)),
                ],
              ),
            ),
            Icon(CupertinoIcons.right_chevron, color: _textSecondaryColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSemesterStartDate() async {
    final provider = context.read<ScheduleProvider>();
    
    final selectedDate = await showLiquidGlassCalendarPicker(
      context: context,
      initialDate: provider.semesterStartDate,
    );
    
    if (selectedDate != null) {
      provider.setSemesterStartDate(selectedDate);
    }
  }

  void _showWeekPicker() {
    final provider = context.read<ScheduleProvider>();
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '选择周次',
        content: SizedBox(
          height: 200,
          child: CupertinoPicker(
            itemExtent: 40,
            scrollController: FixedExtentScrollController(initialItem: provider.currentWeek - 1),
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick(); // 微振动
              provider.setCurrentWeek(index + 1);
            },
            children: List.generate(25, (index) => Center(child: Text('第 ${index + 1} 周', style: const TextStyle(color: Colors.white)))),
          ),
        ),
      ),
    );
  }
}
