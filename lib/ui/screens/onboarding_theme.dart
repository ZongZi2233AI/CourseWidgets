import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import '../../constants/theme_constants.dart';
import '../../main.dart';
import '../../services/storage_service.dart';
import '../../utils/glass_settings_helper.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/liquid_toast.dart';

/// [v2.2.8] 引导页面 - 主题设置
class OnboardingTheme extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;
  
  const OnboardingTheme({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<OnboardingTheme> createState() => _OnboardingThemeState();
}

class _OnboardingThemeState extends State<OnboardingTheme> {
  final StorageService _storage = StorageService();
  
  // 主题色选项
  final List<Color> _themeColors = [
    AppThemeColors.babyPink,
    AppThemeColors.softCoral,
    AppThemeColors.paleApricot,
    Colors.blue,
    Colors.purple,
    Colors.green,
  ];
  
  int _selectedColorIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: liquid.LiquidCard(
                borderRadius: 24,
                padding: 20,
                glassColor: GlassSettingsHelper.getCardSettings().glassColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '个性化',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: GlassSettingsHelper.getTextColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '选择你喜欢的主题色和背景',
                      style: TextStyle(
                        fontSize: 16,
                        color: GlassSettingsHelper.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                // 主题色选择
                liquid.LiquidCard(
                  borderRadius: 24,
                  padding: 20,
                  glassColor: GlassSettingsHelper.getCardSettings().glassColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主题色',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GlassSettingsHelper.getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_themeColors.length, (index) {
                          final color = _themeColors[index];
                          final isSelected = index == _selectedColorIndex;
                          
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedColorIndex = index);
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 背景图片
                liquid.LiquidCard(
                  borderRadius: 24,
                  padding: 20,
                  glassColor: GlassSettingsHelper.getCardSettings().glassColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '背景图片',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GlassSettingsHelper.getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      liquid.LiquidButton(
                        text: '选择背景图片',
                        onTap: _pickBackgroundImage,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '可以稍后在设置中更改',
                        style: TextStyle(
                          fontSize: 12,
                          color: GlassSettingsHelper.getSecondaryTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  liquid.LiquidButton(
                    text: '进入课程表',
                    onTap: _completeOnboarding,
                    color: _themeColors[_selectedColorIndex],
                  ),
                  const SizedBox(height: 12),
                  liquid.LiquidButton(
                    text: '上一步',
                    onTap: widget.onBack,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null && mounted) {
        // 保存背景路径
        await _storage.setString(StorageService.keyBackgroundPath, file.path);
        globalBackgroundPath.value = file.path;
        
        LiquidToast.success(context, '背景已更新');
      }
    } catch (e) {
      if (mounted) {
        LiquidToast.error(context, '选择图片失败: $e');
      }
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    
    // 保存主题色（TODO: 实现主题色系统）
    // await _storage.setInt('theme_color_index', _selectedColorIndex);
    
    // 完成引导
    widget.onComplete();
  }
}
