import 'package:flutter/material.dart';
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
    // [v2.3.0修复] 使用 GestureDetector 包裹整个卡片，确保点击区域覆盖整个卡片
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // 确保整个区域可点击
      child: liquid.LiquidCard(
        borderRadius: 24,
        padding: 20,
        glassColor: Colors.white.withValues(alpha: 0.04),
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
    );
  }

  void _navigateTo(Widget screen) {
    // [v2.3.0修复] 添加完整的进入和退出动画
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 进入动画：从右侧滑入
          const enterBegin = Offset(1.0, 0.0);
          const enterEnd = Offset.zero;
          final enterTween = Tween(begin: enterBegin, end: enterEnd).chain(
            CurveTween(curve: Curves.easeOutCubic),
          );
          final enterAnimation = animation.drive(enterTween);
          
          // 退出动画：向左侧滑出并淡出
          const exitBegin = Offset.zero;
          const exitEnd = Offset(-0.3, 0.0); // 轻微向左移动
          final exitTween = Tween(begin: exitBegin, end: exitEnd).chain(
            CurveTween(curve: Curves.easeInCubic),
          );
          final exitAnimation = secondaryAnimation.drive(exitTween);
          
          // 淡出动画
          final fadeOutTween = Tween<double>(begin: 1.0, end: 0.0).chain(
            CurveTween(curve: Curves.easeIn),
          );
          final fadeOutAnimation = secondaryAnimation.drive(fadeOutTween);
          
          return SlideTransition(
            position: enterAnimation,
            child: SlideTransition(
              position: exitAnimation,
              child: FadeTransition(
                opacity: fadeOutAnimation,
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350), // 进入动画时长
        reverseTransitionDuration: const Duration(milliseconds: 300), // 退出动画时长
      ),
    );
  }
}