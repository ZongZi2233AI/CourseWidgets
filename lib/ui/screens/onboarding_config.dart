import 'package:flutter/material.dart';
import '../../utils/glass_settings_helper.dart';
import '../widgets/liquid_components.dart' as liquid;
import 'android_schedule_config_screen.dart';

/// [v2.2.8] 引导页面 - 课时配置
/// 复用现有的课时配置页面
class OnboardingConfig extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const OnboardingConfig({
    super.key,
    required this.onNext,
    required this.onBack,
  });

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
              child: Center( // 居中标题
                child: liquid.LiquidCard(
                  borderRadius: 24,
                  padding: 20,
                  glassColor: GlassSettingsHelper.getCardSettings().glassColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
                    children: [
                      Text(
                        '课时配置',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: GlassSettingsHelper.getTextColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '设置开学日期和课程时间',
                        style: TextStyle(
                          fontSize: 16,
                          color: GlassSettingsHelper.getSecondaryTextColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 嵌入课时配置页面内容
          // [v2.3.0修复] 引导页面中不显示返回按钮和保存按钮
          Expanded(
            child: const AndroidScheduleConfigScreen(showNavigation: false),
          ),
          
          // Navigation
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: liquid.LiquidButton(
                      text: '上一步',
                      onTap: onBack,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: liquid.LiquidButton(
                      text: '下一步',
                      onTap: () {
                        // 配置会自动保存，直接进入下一步
                        onNext();
                      },
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
