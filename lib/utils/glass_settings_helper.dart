import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../main.dart';

/// [v2.2.8] 全局液态玻璃透明度系统
/// 统一管理所有玻璃效果，根据深色模式自动调整
/// 深色模式：半透明黑色玻璃（像晚上的玻璃窗）
/// 浅色模式：半透明白色玻璃
class GlassSettingsHelper {
  /// 获取标准玻璃设置（根据深色模式自动调整）
  static LiquidGlassSettings getStandardSettings({
    double? blur,
    double? thickness,
  }) {
    // 深色模式：黑色玻璃，中等透明度（像晚上的玻璃窗）
    // 浅色模式：白色玻璃，低透明度
    final glassColor = globalUseDarkMode
        ? Colors.black.withValues(alpha: 0.4) // [v2.2.9修复] 增加深色模式透明度
        : Colors.white.withValues(alpha: 0.08);

    return LiquidGlassSettings(
      glassColor: glassColor,
      blur: blur ?? 8.0, // [v2.5.9] 降低模糊度使玻璃更通透
      thickness: thickness ?? 1.0,
    );
  }

  /// 获取卡片玻璃设置
  static LiquidGlassSettings getCardSettings({double? alpha}) {
    // [v2.5.3] 极其通透的玻璃质感：大幅度降低遮罩颜色，提高模糊阻力，让背景透过来
    final glassColor = globalUseDarkMode
        ? Colors.black.withValues(alpha: alpha ?? 0.15)
        : Colors.white.withValues(alpha: alpha ?? 0.01);

    return LiquidGlassSettings(
      glassColor: glassColor,
      blur: 12.0, // [v2.5.9] 降低模糊度使玻璃更通透
      thickness: 0.8,
    );
  }

  /// 获取按钮玻璃设置
  static LiquidGlassSettings getButtonSettings({
    bool isSelected = false,
    Color? selectedColor,
  }) {
    Color glassColor;

    if (isSelected) {
      // 选中状态：使用主题色
      final baseColor = selectedColor ?? Colors.blue;
      glassColor = globalUseDarkMode
          ? baseColor.withValues(alpha: 0.45) // [v2.2.9修复] 增加深色模式透明度
          : baseColor.withValues(alpha: 0.3);
    } else {
      // 未选中状态
      glassColor = globalUseDarkMode
          ? Colors.white.withValues(alpha: 0.1) // [v2.2.9修复] 增加深色模式透明度
          : Colors.white.withValues(alpha: 0.05);
    }

    return LiquidGlassSettings(glassColor: glassColor, blur: 0, thickness: 10);
  }

  /// 获取对话框玻璃设置
  static LiquidGlassSettings getDialogSettings() {
    final glassColor = globalUseDarkMode
        ? Colors.black.withValues(alpha: 0.5) // [v2.2.9修复] 增加深色模式透明度
        : Colors.white.withValues(alpha: 0.15);

    return LiquidGlassSettings(
      glassColor: glassColor,
      blur: 15.0, // [v2.5.9] 降低模糊度使玻璃更通透
      thickness: 18.0,
    );
  }

  /// 获取输入框玻璃设置
  static LiquidGlassSettings getInputSettings() {
    final glassColor = globalUseDarkMode
        ? Colors.white.withValues(alpha: 0.12) // [v2.2.9修复] 增加深色模式透明度
        : Colors.white.withValues(alpha: 0.05);

    return LiquidGlassSettings(
      glassColor: glassColor,
      blur: 5.0, // [v2.5.9] 降低模糊度使玻璃更通透
      thickness: 0.6,
    );
  }

  /// 获取底部导航栏玻璃设置
  static LiquidGlassSettings getBottomBarSettings() {
    final glassColor = globalUseDarkMode
        ? Colors.black.withValues(alpha: 0.55) // [v2.2.9修复] 增加深色模式透明度
        : Colors.black.withValues(alpha: 0.4);

    return LiquidGlassSettings(
      glassColor: glassColor,
      blur: 12,
      thickness: 15,
    ); // [v2.5.9] 降低模糊度
  }

  /// 获取侧边栏玻璃设置
  static LiquidGlassSettings getSidebarSettings() {
    final glassColor = globalUseDarkMode
        ? Colors.black.withValues(alpha: 0.45) // [v2.2.9修复] 增加深色模式透明度
        : Colors.white.withValues(alpha: 0.05);

    return LiquidGlassSettings(
      glassColor: glassColor,
      blur: 10, // [v2.5.9] 降低模糊度使玻璃更通透
      thickness: 0.8,
    );
  }

  /// 获取文本颜色（根据深色模式）
  static Color getTextColor() {
    return globalUseDarkMode ? Colors.white : const Color(0xFF1A1A2E);
  }

  /// 获取次要文本颜色（根据深色模式）
  static Color getSecondaryTextColor() {
    return globalUseDarkMode ? Colors.white70 : const Color(0xFF666666);
  }

  /// 获取禁用文本颜色（根据深色模式）
  static Color getDisabledTextColor() {
    return globalUseDarkMode
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);
  }

  /// 获取背景叠加颜色（根据深色模式，用于降低背景亮度）
  static Color getBackgroundOverlay() {
    return globalUseDarkMode
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.15);
  }

  /// 获取分隔线颜色（根据深色模式）
  static Color getDividerColor() {
    return globalUseDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
  }
}
