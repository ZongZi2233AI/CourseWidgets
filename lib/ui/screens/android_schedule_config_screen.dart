import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../models/schedule_config.dart';
import '../../providers/schedule_provider.dart';
import '../../constants/theme_constants.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/liquid_glass_pickers.dart';

class AndroidScheduleConfigScreen extends StatefulWidget {
  /// [v2.3.0] 是否显示导航元素（返回按钮、保存按钮）
  /// 在引导页面中嵌入时设为 false，独立使用时设为 true
  final bool showNavigation;
  
  const AndroidScheduleConfigScreen({
    super.key,
    this.showNavigation = true,
  });

  @override
  State<AndroidScheduleConfigScreen> createState() => _AndroidScheduleConfigScreenState();
}

class _AndroidScheduleConfigScreenState extends State<AndroidScheduleConfigScreen> {
  late ScheduleConfigModel _config;
  final _semesterDateController = TextEditingController();
  final _breakTimeController = TextEditingController();
  final List<TextEditingController> _startControllers = [];
  final List<TextEditingController> _durationControllers = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScheduleProvider>();
    _config = provider.currentConfig;
    
    _semesterDateController.text = 
      '${_config.semesterStartDate.year}-${_config.semesterStartDate.month.toString().padLeft(2, '0')}-${_config.semesterStartDate.day.toString().padLeft(2, '0')}';
    _breakTimeController.text = _config.breakTime.toString();
    
    for (int i = 1; i <= 11; i++) {
      _startControllers.add(TextEditingController(text: _formatMinutes(_config.sectionStartTimes[i] ?? 480)));
      _durationControllers.add(TextEditingController(text: (_config.sectionDurations[i] ?? 50).toString()));
    }
  }

  String _formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
    return _config.semesterStartDate;
  }

  void _pickSemesterDate() async {
    // 使用液态玻璃风格的日期选择器
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '选择开学日期',
        content: SizedBox(
          height: 300,
          child: LiquidGlassDatePicker(
            initialDate: _config.semesterStartDate,
            onDateChanged: (date) {
              setState(() {
                _semesterDateController.text = 
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              });
            },
          ),
        ),
        actions: [
          GlassDialogAction(
            label: '确定',
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _saveConfig() {
    try {
      // 构建新的配置对象
      final newConfig = ScheduleConfigModel(
        semesterStartDate: _parseDate(_semesterDateController.text),
        breakTime: int.tryParse(_breakTimeController.text) ?? _config.breakTime,
        sectionStartTimes: Map.from(_config.sectionStartTimes),
        sectionDurations: Map.from(_config.sectionDurations),
      );
      
      // 解析时间
      for (int i = 1; i <= 11; i++) {
        final timeStr = _startControllers[i-1].text;
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            newConfig.sectionStartTimes[i] = hour * 60 + minute;
          }
        }
        
        final duration = int.tryParse(_durationControllers[i-1].text);
        if (duration != null) {
          newConfig.sectionDurations[i] = duration;
        }
      }
      
      context.read<ScheduleProvider>().updateConfig(newConfig);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('配置已保存', style: TextStyle(color: Colors.white)),
          backgroundColor: AppThemeColors.babyPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _semesterDateController.dispose();
    _breakTimeController.dispose();
    for (var controller in _startControllers) {
      controller.dispose();
    }
    for (var controller in _durationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: 0.8,
          blur: 12.0,
          glassColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: Column(
          children: [
            // Custom Header - [v2.3.0] 根据 showNavigation 参数决定是否显示
            if (widget.showNavigation)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // 返回按钮
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CupertinoIcons.back, color: textColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('课时配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      const Spacer(),
                      liquid.LiquidButton(
                        text: '保存',
                        onTap: _saveConfig,
                        color: AppThemeColors.babyPink,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Content - 使用ListView优化滚动
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 基础设置
                  liquid.LiquidCard(
                    borderRadius: 24,
                    padding: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('基础设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        liquid.LiquidInput(
                          controller: _semesterDateController,
                          label: '开学日期',
                          icon: Icons.calendar_today_rounded,
                          isReadOnly: true,
                          onTap: _pickSemesterDate,
                        ),
                        const SizedBox(height: 16),
                        liquid.LiquidInput(
                          controller: _breakTimeController,
                          label: '课间休息 (分钟)',
                          icon: Icons.timer_rounded,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 课时设置
                  liquid.LiquidCard(
                    borderRadius: 24,
                    padding: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('课时设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        // 表头
                        Row(
                          children: [
                            Expanded(
                              child: Text('节次', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Expanded(
                              flex: 2, 
                              child: Text('开始时间', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Expanded(
                              child: Text('时长', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 课时列表
                        ...List.generate(11, (index) => _buildSectionRow(index)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32), // 底部留白
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionRow(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 节次
          Expanded(
            child: Text('第 ${index + 1} 节', style: TextStyle(color: textColor, fontSize: 13)),
          ),
          
          // 开始时间
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _startControllers[index],
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration.collapsed(
                  hintText: '',
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          
          // 时长
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _durationControllers[index],
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration.collapsed(
                  hintText: '',
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
