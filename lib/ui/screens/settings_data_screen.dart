import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/schedule_provider.dart';
import '../../services/data_import_service.dart';
import '../../constants/theme_constants.dart';
import '../../services/theme_service.dart'; // Added this import
import '../../utils/glass_settings_helper.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/liquid_toast.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class SettingsDataScreen extends StatelessWidget {
  const SettingsDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScheduleProvider>();
    final dataImportService = DataImportService();
    final isDark = ThemeService().isDarkMode; // Added this line

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: 0.8,
          blur: 15.0, // 设置页背景模糊稍微高一点
          glassColor:
              GlassSettingsHelper.getStandardSettings().glassColor, // 极淡的底色
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '数据管理',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  liquid.LiquidCard(
                    padding: 20,
                    // [v2.5.3] 统一玻璃样式，去除发白遮罩
                    glassColor:
                        GlassSettingsHelper.getCardSettings().glassColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '数据操作',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          '导入 ICS 日历',
                          '',
                          Icons.calendar_month_rounded,
                          Colors.orangeAccent,
                          () async {
                            final success = await provider.importData();
                            if (success && context.mounted)
                              _showToast(context, 'ICS 导入成功');
                          },
                        ),
                        _buildActionCard(
                          '导入 HTML 课表',
                          '',
                          Icons.code_rounded,
                          Colors.deepPurpleAccent,
                          () async {
                            final success = await provider.importHtmlData();
                            if (success && context.mounted)
                              _showToast(context, 'HTML 导入成功');
                          },
                        ),
                        _buildActionCard(
                          '导入测试数据',
                          '',
                          Icons.data_exploration_rounded,
                          Colors.teal,
                          () async {
                            final success = await provider.importFromAssets();
                            if (success && context.mounted)
                              _showToast(context, '测试数据已导入');
                          },
                        ),

                        const SizedBox(height: 16),
                        _buildActionCard(
                          '导出为 ICS',
                          '',
                          Icons.ios_share_rounded,
                          Colors.green,
                          () async {
                            final activeSchedule = await dataImportService
                                .getActiveSchedule();
                            if (activeSchedule != null) {
                              final success = await dataImportService
                                  .exportHistoryToIcs(activeSchedule['id']);
                              if (success && context.mounted)
                                _showToast(context, 'ICS 导出成功');
                            } else {
                              if (context.mounted)
                                _showToast(context, '未找到当前课表');
                            }
                          },
                        ),
                        _buildActionCard(
                          '导出为 JSON',
                          '',
                          Icons.data_object_rounded,
                          Colors.blueAccent,
                          () async {
                            final success = await provider.exportData();
                            if (success && context.mounted)
                              _showToast(context, 'JSON 导出成功');
                          },
                        ),

                        const SizedBox(height: 16),
                        _buildActionCard(
                          '清除所有数据',
                          '',
                          Icons.delete_forever_rounded,
                          Colors.redAccent,
                          () => _confirmClear(context, provider),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // [v2.2.2] 历史记录管理移到数据管理
                  _buildActionCard(
                    '历史记录管理',
                    '',
                    CupertinoIcons.time,
                    Colors.purpleAccent,
                    () => _showHistoryDialog(
                      context,
                      dataImportService,
                      provider,
                      isDark, // Pass isDark
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [v2.2.2] 历史记录对话框
  void _showHistoryDialog(
    BuildContext context,
    DataImportService dataImportService,
    ScheduleProvider provider,
    bool isDark, // isDark is now a parameter
  ) {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '历史记录',
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: dataImportService.getAllHistory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CupertinoActivityIndicator(color: Colors.white),
                );
              }
              final history = snapshot.data!;
              if (history.isEmpty) {
                return const Center(
                  child: Text('暂无历史记录', style: TextStyle(color: Colors.white)),
                );
              }

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isActive = item['is_active'] == 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: liquid.LiquidCard(
                      glassColor: isActive
                          ? AppThemeColors.babyPink.withValues(alpha: 0.2)
                          : GlassSettingsHelper.getCardSettings().glassColor,
                      padding: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['semester']} | ${item['source_type']}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(
                                      0.6,
                                    ), // Fixed withValues to withOpacity
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: AppThemeColors.babyPink,
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                CupertinoIcons.time,
                                color: Colors.white70,
                              ),
                              onPressed: () async {
                                await dataImportService.switchToHistory(
                                  item['id'],
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  await provider.loadSavedData();
                                  _showToast(context, '已切换到该课表');
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
          GlassDialogAction(
            label: '关闭',
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // [v2.3.0修复] 使用 GestureDetector 确保整个卡片可点击
    final isDark = ThemeService().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: liquid.LiquidCard(
          padding: 16,
          // [v2.5.3] 统一列表项卡片的玻璃质感
          glassColor: GlassSettingsHelper.getCardSettings().glassColor,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [v2.3.0修复] 使用 LiquidToast 替代 SnackBar
  void _showToast(BuildContext context, String message) {
    LiquidToast.success(context, message);
  }

  void _confirmClear(BuildContext context, ScheduleProvider provider) {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '确认清除',
        content: const Text('确定要删除所有数据吗？此操作无法撤销。'),
        actions: [
          GlassDialogAction(
            label: '取消',
            onPressed: () => Navigator.pop(context),
          ),
          GlassDialogAction(
            label: '删除',
            isPrimary: true,
            onPressed: () async {
              await provider.clearData();
              if (context.mounted) {
                // [v2.5.6修复] 清除数据后，重新显示系统启动图动画和重置教程，解决 Windows 端看不到引导页的问题
                Phoenix.rebirth(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
