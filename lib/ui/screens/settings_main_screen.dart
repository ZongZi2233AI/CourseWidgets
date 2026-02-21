import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/theme_constants.dart';
import '../../utils/responsive_utils.dart';
import 'new_settings_screen.dart'; 
import 'settings_general_screen.dart'; 
import 'settings_about_screen.dart'; 
import 'settings_data_screen.dart';
import 'settings_notification_screen.dart';
import '../widgets/liquid_components.dart' as liquid;

/// [v2.2.8] 设置主界面 - 添加通知设置
class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({super.key});
  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
  Color get _textColor => Colors.white; 

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTabletMode(context);
    
    // [v2.2.8] 自适应顶部间距：平板16，手机8
    final topPadding = isTablet ? 16.0 : 8.0;
    
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSettingsEntry(
              title: '课程设置',
              subtitle: '添加课程、学期配置、课时配置',
              icon: Icons.school_rounded,
              color: AppThemeColors.babyPink,
              onTap: () => _navigateTo(const NewSettingsScreen()),
            ),
            const SizedBox(height: 16),
            _buildSettingsEntry(
              title: '课程通知',
              subtitle: '提醒时间、双次提醒、Live Activities',
              icon: Icons.notifications_rounded,
              color: AppThemeColors.softCoral,
              onTap: () => _navigateTo(const SettingsNotificationScreen()),
            ),
            const SizedBox(height: 16),
            _buildSettingsEntry(
              title: '通用设置',
              subtitle: '深色模式、历史记录、背景图片',
              icon: Icons.tune_rounded,
              color: AppThemeColors.paleApricot,
              onTap: () => _navigateTo(const SettingsGeneralScreen()),
            ),
            const SizedBox(height: 16),
            _buildSettingsEntry(
              title: '数据管理',
              subtitle: '导入导出、清理数据',
              icon: Icons.cloud_sync_rounded,
              color: Colors.blueAccent,
              onTap: () => _navigateTo(const SettingsDataScreen()),
            ),
            const SizedBox(height: 16),
            _buildSettingsEntry(
              title: '关于软件',
              subtitle: '版本信息、开发者信息',
              icon: Icons.info_outline_rounded,
              color: Colors.purpleAccent,
              onTap: () => _navigateTo(const SettingsAboutScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsEntry({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // [v2.4.0] 使用 Material + InkWell 实现水波纹和触控反馈
    return liquid.LiquidCard(
      borderRadius: 24,
      padding: 0, // 移除内边距，由内部的一级容器控制，以便水波纹填满
      glassColor: Colors.white.withValues(alpha: 0.04),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact(); // [v2.4.0] 添加触控震动
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color.withValues(alpha: 0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
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
                          fontWeight: FontWeight.w800,
                          color: _textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    // [v2.3.0修复] 使用 MaterialPageRoute 提供原生流畅动画
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }
}