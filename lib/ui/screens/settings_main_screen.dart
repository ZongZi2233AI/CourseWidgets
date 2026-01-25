import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/theme_constants.dart';
import '../../main.dart'; 
import 'new_settings_screen.dart'; 
import 'settings_general_screen.dart'; 
import 'settings_about_screen.dart'; 
import 'settings_data_screen.dart';
import '../widgets/liquid_components.dart' as liquid;

class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({super.key});
  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
  Color get _textColor => Colors.white; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea( // [v2.2.1修复] 添加 SafeArea 避免顶出屏幕
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // [v2.2.1] 添加顶部padding
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
              title: '通用设置',
              subtitle: '深色模式、历史记录、背景图片',
              icon: Icons.tune_rounded,
              color: AppThemeColors.softCoral,
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
              color: AppThemeColors.paleApricot,
              onTap: () => _navigateTo(const SettingsAboutScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsEntry({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return liquid.LiquidCard(
      borderRadius: 24,
      onTap: onTap,
      padding: 20,
      glassColor: Colors.white.withOpacity(0.04),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.8), color.withOpacity(0.4)]), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textColor)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60))])),
          const Icon(Icons.chevron_right_rounded, color: Colors.white30),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    // [核心修复] 使用 MaterialPageRoute 以启用 main.dart 中定义的自定义转场动画
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}