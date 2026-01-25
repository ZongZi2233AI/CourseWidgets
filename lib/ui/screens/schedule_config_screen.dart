import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../models/schedule_config.dart';
import '../../providers/schedule_provider.dart';
import '../../constants/theme_constants.dart';
import '../widgets/liquid_glass_pickers.dart';
import '../widgets/liquid_components.dart' as liquid;

/// 课时配置界面 - 液态玻璃版本
class ScheduleConfigScreen extends StatefulWidget {
  const ScheduleConfigScreen({super.key});

  @override
  State<ScheduleConfigScreen> createState() => _ScheduleConfigScreenState();
}

class _ScheduleConfigScreenState extends State<ScheduleConfigScreen> {
  late ScheduleConfigModel _config;
  final _formKey = GlobalKey<FormState>();

  // 控制器
  final _semesterDateController = TextEditingController();
  final _breakTimeController = TextEditingController();
  final List<TextEditingController> _startControllers = [];
  final List<TextEditingController> _durationControllers = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScheduleProvider>();
    _config = provider.currentConfig;
    
    // 初始化控制器
    _semesterDateController.text = 
      '${_config.semesterStartDate.year}-${_config.semesterStartDate.month.toString().padLeft(2, '0')}-${_config.semesterStartDate.day.toString().padLeft(2, '0')}';
    _breakTimeController.text = _config.breakTime.toString();
    
    for (int i = 1; i <= 11; i++) {
      _startControllers.add(TextEditingController(
        text: _formatMinutes(_config.sectionStartTimes[i] ?? 480)
      ));
      _durationControllers.add(TextEditingController(
        text: (_config.sectionDurations[i] ?? 50).toString()
      ));
    }
  }

  bool get _isDarkMode {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark;
  }

  Color get _glassOverlayColor {
    return _isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.05);
  }

  Color get _textColor {
    return _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
  }

  Color get _textSecondaryColor {
    return _isDarkMode ? Colors.white70 : const Color(0xFF666666);
  }

  String _formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 480;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode 
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                : [const Color(0xFFF5F5F5), const Color(0xFFE8E8E8), const Color(0xFFDADADA)],
          ),
        ),
        child: LiquidGlassLayer(
          settings: LiquidGlassSettings(
            thickness: 20,
            blur: 4,
            glassColor: _glassOverlayColor,
            lightIntensity: 1.5,
            ambientStrength: 0.8,
            saturation: 1.2,
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 顶部标题栏
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _glassOverlayColor,
                      borderRadius: BorderRadius.circular(LiquidGlassTheme.largeRadius),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: _textColor, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '课时配置',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: LiquidGlassTheme.titleFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          onPressed: _saveConfig,
                          child: Text(
                            '保存',
                            style: TextStyle(
                              color: AppThemeColors.babyPink,
                              fontWeight: FontWeight.w700,
                              fontSize: LiquidGlassTheme.buttonFontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('基础设置'),
                          const SizedBox(height: 8),
                          _buildGeneralSettings(),
                          
                          const SizedBox(height: 20),
                          _buildSectionTitle('课时设置'),
                          const SizedBox(height: 8),
                          _buildSectionSettings(),
                          
                          const SizedBox(height: 20),
                          _buildSectionTitle('快速配置'),
                          const SizedBox(height: 8),
                          _buildPresetButtons(),
                        ],
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _textColor,
        fontSize: LiquidGlassTheme.titleFontSize,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: LiquidGlassTheme.largeRadius),
      settings: LiquidGlassSettings(
        blur: 4,
        glassColor: _glassOverlayColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _glassOverlayColor,
          borderRadius: BorderRadius.circular(LiquidGlassTheme.largeRadius),
        ),
        padding: const EdgeInsets.all(LiquidGlassTheme.mediumPadding),
        child: Column(
          children: [
            // 学期日期
            _buildTextField(
              controller: _semesterDateController,
              label: '学期开始日期',
              hint: '2025-09-08',
              suffixIcon: Icons.calendar_today,
              onTap: () async {
                final date = await showLiquidGlassCalendarPicker(
                  context: context,
                  initialDate: _config.semesterStartDate,
                );
                if (date != null) {
                  _semesterDateController.text = 
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              },
            ),
            
            const SizedBox(height: 12),
            
            // 课间休息时间 - 修复字体大小
            _buildTextField(
              controller: _breakTimeController,
              label: '课间休息时间',
              hint: '10',
              suffixText: '分钟',
              keyboardType: TextInputType.number,
              fontSize: LiquidGlassTheme.bodyFontSize, // 使用body字体大小
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffixText,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    double fontSize = LiquidGlassTheme.subtitleFontSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(LiquidGlassTheme.mediumRadius),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: LiquidGlassTheme.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: _textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textSecondaryColor.withOpacity(0.6)),
              border: InputBorder.none,
              isDense: true,
              suffixText: suffixText,
              suffixStyle: TextStyle(
                color: _textSecondaryColor,
                fontSize: LiquidGlassTheme.bodyFontSize,
              ),
              suffixIcon: suffixIcon != null 
                ? Icon(suffixIcon, size: 18, color: AppThemeColors.babyPink)
                : null,
            ),
            keyboardType: keyboardType,
            style: TextStyle(
              color: _textColor,
              fontSize: LiquidGlassTheme.subtitleFontSize,
              fontWeight: FontWeight.w600,
            ),
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSettings() {
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: LiquidGlassTheme.largeRadius),
      settings: LiquidGlassSettings(
        blur: 4,
        glassColor: _glassOverlayColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _glassOverlayColor,
          borderRadius: BorderRadius.circular(LiquidGlassTheme.largeRadius),
        ),
        padding: const EdgeInsets.all(LiquidGlassTheme.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置每节课的开始时间和时长',
              style: TextStyle(
                fontSize: LiquidGlassTheme.bodyFontSize,
                color: _textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(11, (index) => _buildSectionRow(index + 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionRow(int section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(LiquidGlassTheme.smallRadius),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // 第X节
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              '第$section节',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppThemeColors.softCoral,
                fontSize: LiquidGlassTheme.bodyFontSize,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 开始时间
          Expanded(
            flex: 2,
            child: _buildSmallTextField(
              controller: _startControllers[section - 1],
              hint: '08:00',
              label: '开始',
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 时长
          Expanded(
            flex: 1,
            child: _buildSmallTextField(
              controller: _durationControllers[section - 1],
              hint: '50',
              label: '时长',
              suffixText: '分',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _textSecondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textSecondaryColor.withOpacity(0.6),
                fontSize: 12,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              suffixText: suffixText,
              suffixStyle: TextStyle(
                color: _textSecondaryColor,
                fontSize: 10,
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButtons() {
    return FakeGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: LiquidGlassTheme.largeRadius),
      settings: LiquidGlassSettings(
        blur: 4,
        glassColor: _glassOverlayColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _glassOverlayColor,
          borderRadius: BorderRadius.circular(LiquidGlassTheme.largeRadius),
        ),
        padding: const EdgeInsets.all(LiquidGlassTheme.mediumPadding),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton('默认配置', _loadDefaultConfig, AppThemeColors.babyPink),
            _buildPresetButton('早课配置', _loadEarlyConfig, AppThemeColors.softCoral),
            _buildPresetButton('长课时配置', _loadLongConfig, AppThemeColors.paleApricot),
            _buildPresetButton('短课时配置', _loadShortConfig, AppThemeColors.babyPink),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed, Color color) {
    return LiquidGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: LiquidGlassTheme.mediumRadius),
      child: CupertinoButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(LiquidGlassTheme.mediumRadius),
        child: Text(
          label,
          style: TextStyle(
            color: _textColor,
            fontSize: LiquidGlassTheme.bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _loadDefaultConfig() {
    final defaultConfig = ScheduleConfigModel.defaultConfig();
    _updateUIFromConfig(defaultConfig);
  }

  void _loadEarlyConfig() {
    // 早课配置：7:30开始，每节课45分钟，休息5分钟
    final config = ScheduleConfigModel(
      semesterStartDate: DateTime(2025, 9, 8),
      sectionStartTimes: {
        1: 450, 2: 495, 3: 540, 4: 585, 5: 630,
        6: 705, 7: 750, 8: 795, 9: 870, 10: 915, 11: 960
      },
      sectionDurations: {
        1: 45, 2: 45, 3: 45, 4: 45, 5: 45, 6: 45, 7: 45, 8: 45, 9: 45, 10: 45, 11: 45
      },
      breakTime: 5,
    );
    _updateUIFromConfig(config);
  }

  void _loadLongConfig() {
    // 长课时配置：8:00开始，每节课90分钟，休息10分钟
    final config = ScheduleConfigModel(
      semesterStartDate: DateTime(2025, 9, 8),
      sectionStartTimes: {
        1: 480, 2: 570, 3: 660, 4: 750, 5: 840,
        6: 930, 7: 1020, 8: 1110, 9: 1200, 10: 1290, 11: 1380
      },
      sectionDurations: {
        1: 90, 2: 90, 3: 90, 4: 90, 5: 90, 6: 90, 7: 90, 8: 90, 9: 90, 10: 90, 11: 90
      },
      breakTime: 10,
    );
    _updateUIFromConfig(config);
  }

  void _loadShortConfig() {
    // 短课时配置：8:00开始，每节课40分钟，休息5分钟
    final config = ScheduleConfigModel(
      semesterStartDate: DateTime(2025, 9, 8),
      sectionStartTimes: {
        1: 480, 2: 525, 3: 570, 4: 615, 5: 660,
        6: 705, 7: 750, 8: 795, 9: 840, 10: 885, 11: 930
      },
      sectionDurations: {
        1: 40, 2: 40, 3: 40, 4: 40, 5: 40, 6: 40, 7: 40, 8: 40, 9: 40, 10: 40, 11: 40
      },
      breakTime: 5,
    );
    _updateUIFromConfig(config);
  }

  void _updateUIFromConfig(ScheduleConfigModel config) {
    setState(() {
      _config = config;
      _semesterDateController.text = 
        '${config.semesterStartDate.year}-${config.semesterStartDate.month.toString().padLeft(2, '0')}-${config.semesterStartDate.day.toString().padLeft(2, '0')}';
      _breakTimeController.text = config.breakTime.toString();
      
      for (int i = 1; i <= 11; i++) {
        _startControllers[i - 1].text = _formatMinutes(config.sectionStartTimes[i] ?? 480);
        _durationControllers[i - 1].text = (config.sectionDurations[i] ?? 50).toString();
      }
    });
  }

  void _saveConfig() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // 解析日期
      final dateParts = _semesterDateController.text.split('-');
      if (dateParts.length != 3) {
        throw Exception('日期格式错误');
      }
      final semesterStartDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      // 解析休息时间
      final breakTime = int.tryParse(_breakTimeController.text) ?? 10;

      // 解析课时设置
      final sectionStartTimes = <int, int>{};
      final sectionDurations = <int, int>{};

      for (int i = 1; i <= 11; i++) {
        final startTime = _parseTimeToMinutes(_startControllers[i - 1].text);
        final duration = int.tryParse(_durationControllers[i - 1].text) ?? 50;
        
        sectionStartTimes[i] = startTime;
        sectionDurations[i] = duration;
      }

      // 创建新配置
      final newConfig = ScheduleConfigModel(
        semesterStartDate: semesterStartDate,
        sectionStartTimes: sectionStartTimes,
        sectionDurations: sectionDurations,
        breakTime: breakTime,
        useCustomConfig: true,
      );

      // 验证配置
      if (!newConfig.isValid()) {
        throw Exception('配置无效，请检查输入');
      }

      // 保存到Provider
      context.read<ScheduleProvider>().updateConfig(newConfig);

      // 显示成功消息
      _showCupertinoAlert('配置已保存', '课时配置已成功保存');

      // 返回上一页
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      _showCupertinoAlert('保存失败', e.toString());
    }
  }

  void _showCupertinoAlert(String title, String content) {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: title,
        content: Text(content),
        actions: [
          GlassDialogAction(
            label: '确定',
            onPressed: () => Navigator.pop(context),
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}
