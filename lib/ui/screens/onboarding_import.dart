import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/schedule_provider.dart';
import '../../services/test_data_generator.dart';
import '../../services/database_helper.dart';
import '../../utils/glass_settings_helper.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/liquid_toast.dart';

/// [v2.2.8] 引导页面 - 导入课表
class OnboardingImport extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const OnboardingImport({
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
              child: liquid.LiquidCard(
                borderRadius: 24,
                padding: 20,
                glassColor: Colors.white.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导入课表',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: GlassSettingsHelper.getTextColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '选择一种方式导入你的课程数据',
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
                _buildImportOption(
                  context,
                  icon: Icons.insert_drive_file_rounded,
                  title: '从 ICS 文件导入',
                  subtitle: '日程/其他课表软件导出的文件',
                  color: AppThemeColors.babyPink,
                  onTap: () => _importFromICS(context),
                ),
                const SizedBox(height: 16),
                
                _buildImportOption(
                  context,
                  icon: Icons.code_rounded,
                  title: '从 HTML 文件导入',
                  subtitle: '使用脚本导出的教务系统文件',
                  color: AppThemeColors.softCoral,
                  onTap: () => _importFromHTML(context),
                ),
                const SizedBox(height: 16),
                
                _buildImportOption(
                  context,
                  icon: Icons.data_object_rounded,
                  title: '从 JSON 数据导入',
                  subtitle: '本软件导出的 JSON 数据文件',
                  color: AppThemeColors.paleApricot,
                  onTap: () => _importFromJSON(context),
                ),
                const SizedBox(height: 16),
                
                _buildImportOption(
                  context,
                  icon: Icons.science_rounded,
                  title: '导入测试数据',
                  subtitle: '生成模拟课表用于体验',
                  color: Colors.purpleAccent,
                  onTap: () => _importTestData(context),
                ),
                const SizedBox(height: 16),
                
                _buildImportOption(
                  context,
                  icon: Icons.skip_next_rounded,
                  title: '暂时不导入',
                  subtitle: '稍后可在设置中导入',
                  color: Colors.grey,
                  onTap: onNext,
                ),
              ],
            ),
          ),
          
          // Navigation
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: liquid.LiquidButton(
                text: '上一步',
                onTap: onBack,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return liquid.LiquidCard(
      borderRadius: 24,
      padding: 20,
      onTap: onTap,
      glassColor: GlassSettingsHelper.getCardSettings().glassColor,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: GlassSettingsHelper.getTextColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: GlassSettingsHelper.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: GlassSettingsHelper.getDisabledTextColor(),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromICS(BuildContext context) async {
    try {
      HapticFeedback.mediumImpact();
      
      final provider = context.read<ScheduleProvider>();
      final success = await provider.importData();
      
      if (context.mounted) {
        if (success) {
          LiquidToast.success(context, 'ICS 导入成功');
          
          // 延迟后进入下一页
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              onNext();
            }
          });
        } else {
          LiquidToast.error(context, 'ICS 导入失败或已取消');
        }
      }
    } catch (e) {
      if (context.mounted) {
        LiquidToast.error(context, '导入失败: $e');
      }
    }
  }

  Future<void> _importFromHTML(BuildContext context) async {
    try {
      HapticFeedback.mediumImpact();
      
      final provider = context.read<ScheduleProvider>();
      final success = await provider.importHtmlData();
      
      if (context.mounted) {
        if (success) {
          LiquidToast.success(context, 'HTML 导入成功');
          
          // 延迟后进入下一页
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              onNext();
            }
          });
        } else {
          LiquidToast.error(context, 'HTML 导入失败或已取消');
        }
      }
    } catch (e) {
      if (context.mounted) {
        LiquidToast.error(context, '导入失败: $e');
      }
    }
  }

  Future<void> _importFromJSON(BuildContext context) async {
    try {
      HapticFeedback.mediumImpact();
      
      final provider = context.read<ScheduleProvider>();
      final success = await provider.importFromAssets(); // 使用 importFromAssets 作为 JSON 导入
      
      if (context.mounted) {
        if (success) {
          LiquidToast.success(context, 'JSON 导入成功');
          
          // 延迟后进入下一页
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              onNext();
            }
          });
        } else {
          LiquidToast.error(context, 'JSON 导入失败或已取消');
        }
      }
    } catch (e) {
      if (context.mounted) {
        LiquidToast.error(context, '导入失败: $e');
      }
    }
  }

  Future<void> _importTestData(BuildContext context) async {
    try {
      HapticFeedback.mediumImpact();
      
      // 生成测试数据
      final testCourses = TestDataGenerator.generateTestData();
      
      // 保存到数据库
      final db = DatabaseHelper.instance;
      await db.insertCourses(testCourses);
      
      // 重新加载数据
      if (context.mounted) {
        await context.read<ScheduleProvider>().loadSavedData();
        
        LiquidToast.success(context, '已导入 ${testCourses.length} 节测试课程');
        
        // 延迟后进入下一页
        Future.delayed(const Duration(milliseconds: 800), () {
          if (context.mounted) {
            onNext();
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        LiquidToast.error(context, '导入失败: $e');
      }
    }
  }
}
