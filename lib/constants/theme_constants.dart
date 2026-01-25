/// 主题颜色配置

// 优先使用 Cupertino，但 ThemeData 类依赖 Material
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeData, ColorScheme;
import '../services/theme_service.dart';

/// 新主题色系统 - 支持动态主题
class AppThemeColors {
  // 动态主题色（从 ThemeService 获取）
  static Color get babyPink => ThemeService().primaryColor;
  static Color get softCoral => ThemeService().secondaryColor;
  
  // 默认主题色（用于初始化和回退）
  static const Color defaultBabyPink = Color(0xFFFF9A9E);
  static const Color defaultSoftCoral = Color(0xFFFAD0C4);
  
  // 固定颜色
  static const paleApricot = Color(0xFFFDE6D7);
  static const milkWhite = Color(0xFFFFFAF5);

  // 深色模式颜色
  static const darkBackground = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF16213E);
  static const darkCard = Color(0xFF0F3460);
  
  // 渐变
  static LinearGradient get defaultGradient => ThemeService().getGradient();
  
  // 半透明版本
  static Color babyPinkWithAlpha(double alpha) => ThemeService().getPrimaryWithAlpha(alpha);
  static Color softCoralWithAlpha(double alpha) => ThemeService().getSecondaryWithAlpha(alpha);
}

/// 主题配置 (Material - 用于 MaterialApp)
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    primaryColor: AppThemeColors.babyPink,
    scaffoldBackgroundColor: AppThemeColors.milkWhite,
    colorScheme: ColorScheme.light(
      primary: AppThemeColors.babyPink,
      secondary: AppThemeColors.softCoral,
      surface: AppThemeColors.paleApricot,
    ),
    useMaterial3: true,
    fontFamily: 'PingFangSC',
  );

  static ThemeData get darkTheme => ThemeData(
    primaryColor: AppThemeColors.babyPink,
    scaffoldBackgroundColor: AppThemeColors.darkBackground,
    colorScheme: ColorScheme.dark(
      primary: AppThemeColors.babyPink,
      secondary: AppThemeColors.softCoral,
      surface: AppThemeColors.darkSurface,
    ),
    useMaterial3: true,
    fontFamily: 'PingFangSC',
  );
}

/// iOS 主题配置 (Cupertino - 专为 iOS 优化)
class IOSTheme {
  static CupertinoThemeData get lightTheme => CupertinoThemeData(
    primaryColor: AppThemeColors.babyPink,
    barBackgroundColor: AppThemeColors.milkWhite.withValues(alpha: 0.5),
    scaffoldBackgroundColor: const Color(0x00000000),
    textTheme: const CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: 'PingFangSC', color: Color(0xFF1A1A2E)),
    ),
  );

  static CupertinoThemeData get darkTheme => CupertinoThemeData(
    primaryColor: AppThemeColors.babyPink,
    barBackgroundColor: AppThemeColors.darkBackground.withValues(alpha: 0.5),
    scaffoldBackgroundColor: const Color(0x00000000),
    textTheme: const CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: 'PingFangSC', color: CupertinoColors.white),
    ),
  );
}

/// 液态玻璃主题配置
class LiquidGlassTheme {
  // 圆角配置 - 增加所有圆角
  static const double smallRadius = 16.0;      // 增加：12 -> 16
  static const double mediumRadius = 20.0;     // 增加：16 -> 20
  static const double largeRadius = 24.0;      // 增加：20 -> 24
  static const double xLargeRadius = 28.0;     // 增加：24 -> 28
  static const double capsuleRadius = 32.0;    // 增加：28 -> 32

  // 间距配置
  static const double smallPadding = 8.0;
  static const double mediumPadding = 12.0;
  static const double largePadding = 16.0;
  static const double xLargePadding = 20.0;

  // 字体大小配置 - 修复课间休息时间字体
  static const double titleFontSize = 18.0;
  static const double subtitleFontSize = 14.0;
  static const double bodyFontSize = 12.0;
  static const double buttonFontSize = 15.0;
  static const double smallTextFontSize = 10.0; // 新增：用于小文字

  // 按钮高度
  static const double buttonHeight = 44.0;
  static const double smallButtonHeight = 36.0;

  // 导航栏配置 - 缩短
  static const double navBarHeight = 48.0;     // 缩短：56 -> 48
  static const double navBarPadding = 12.0;    // 缩短：16 -> 12
  static const double navButtonGap = 8.0;      // 缩短：12 -> 8
  static const double navBarWidth = 280.0;     // 新增：导航栏总宽度
}
