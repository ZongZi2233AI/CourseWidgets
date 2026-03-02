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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppThemeColors.babyPink, AppThemeColors.softCoral],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.book_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 32),

            // 导航项
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
                  fontSize: 10,
                ),
              ),
            ),
          ],
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
    return Tooltip(
      message: '', // 可选添加Tooltip
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppThemeColors.babyPink.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: GlassButton.custom(
          onTap: onTap,
          width: 50,
          height: 50,
          style: GlassButtonStyle.filled,
          settings: LiquidGlassSettings(
            glassColor: isSelected
                ? AppThemeColors.babyPink.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            blur: 15,
            thickness: 20.0,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 16),
          child: Icon(
            isSelected && selectedIcon != null ? selectedIcon : icon,
            color: isSelected ? Colors.white : Colors.white60,
            size: 24,
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
