import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../constants/theme_constants.dart';
import '../../constants/version.dart';
import '../../utils/glass_settings_helper.dart';

/// [v2.2.8] 平板模式侧边栏 - 使用全局玻璃设置系统
class TabletSideBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final List<TabletSideBarItem> items;
  
  const TabletSideBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          shape: const LiquidRoundedSuperellipse(borderRadius: 32),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          settings: GlassSettingsHelper.getSidebarSettings(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeColors.babyPink,
                      AppThemeColors.softCoral,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 24),
              
              // 导航项
              ...List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == selectedIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNavItem(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    isSelected: isSelected,
                    onTap: () => onTabSelected(index),
                  ),
                );
              }),
              
              const Spacer(),
              
              // [v2.2.8] 版本信息 - 使用常量
              Container(
                padding: const EdgeInsets.all(6),
                child: Text(
                  'v$appVersion',
                  style: TextStyle(
                    color: GlassSettingsHelper.getDisabledTextColor(),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    IconData? selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppThemeColors.babyPink.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: GlassButton.custom(
          onTap: onTap,
          width: 50,
          height: 50,
          style: GlassButtonStyle.filled,
          settings: GlassSettingsHelper.getButtonSettings(
            isSelected: isSelected,
            selectedColor: AppThemeColors.babyPink,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 14),
          child: Icon(
            isSelected && selectedIcon != null ? selectedIcon : icon,
            color: isSelected ? Colors.white : Colors.white60,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// 侧边栏项目
class TabletSideBarItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  
  const TabletSideBarItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
