import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../constants/theme_constants.dart';

/// 平板模式侧边栏
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
    // [v2.2.2] 导航栏改为圆角矩形，四周留白
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16), // 四周留白
        child: GlassPanel(
          shape: const LiquidRoundedSuperellipse(borderRadius: 32), // 圆角矩形
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          settings: LiquidGlassSettings(
            glassColor: Colors.white.withValues(alpha: 0.05),
            blur: 20,
            thickness: 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 不占满全高
            children: [
              // Logo - 缩小尺寸
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
              
              // 版本信息
              Container(
                padding: const EdgeInsets.all(6),
                child: const Text(
                  'v2.2.2',
                  style: TextStyle(
                    color: Colors.white38,
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
        width: 50, // [v2.2.1] 从 56 减小到 50
        height: 50,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14), // [v2.2.1] 从 16 减小到 14
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
          settings: LiquidGlassSettings(
            glassColor: isSelected
                ? AppThemeColors.babyPink.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            blur: 0,
            thickness: 10,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 14), // [v2.2.1] 从 16 减小到 14
          child: Icon(
            isSelected && selectedIcon != null ? selectedIcon : icon,
            color: isSelected ? Colors.white : Colors.white60,
            size: 22, // [v2.2.1] 从 24 减小到 22
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
