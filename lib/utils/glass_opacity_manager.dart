import 'package:flutter/material.dart';

/// [v2.3.0] 全局液态玻璃透明度管理器
/// 根据深色模式自动调整玻璃透明度和颜色
class GlassOpacityManager {
  static final GlassOpacityManager _instance = GlassOpacityManager._internal();
  factory GlassOpacityManager() => _instance;
  GlassOpacityManager._internal();

  // 当前是否为深色模式
  bool _isDarkMode = false;
  
  // 监听器
  final List<VoidCallback> _listeners = [];

  /// 获取当前深色模式状态
  bool get isDarkMode => _isDarkMode;

  /// 设置深色模式
  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _notifyListeners();
      debugPrint('🎨 玻璃透明度管理器: 深色模式 = $isDark');
    }
  }

  /// 添加监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // ==================== 玻璃颜色配置 ====================

  /// 获取玻璃基础颜色
  /// 深色模式：黑色系
  /// 浅色模式：白色系
  Color getGlassBaseColor({double alpha = 0.1}) {
    return _isDarkMode
        ? Colors.black.withValues(alpha: alpha)
        : Colors.white.withValues(alpha: alpha);
  }

  /// 获取玻璃卡片颜色
  Color getGlassCardColor() {
    return _isDarkMode
        ? Colors.white.withValues(alpha: 0.05) // 深色模式：更低透明度
        : Colors.white.withValues(alpha: 0.03); // 浅色模式：极低透明度
  }

  /// 获取玻璃按钮颜色（未选中）
  Color getGlassButtonColor() {
    return _isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.05);
  }

  /// 获取玻璃面板颜色
  Color getGlassPanelColor() {
    return _isDarkMode
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.03);
  }

  /// 获取玻璃导航栏颜色
  Color getGlassNavBarColor() {
    return _isDarkMode
        ? Colors.black.withValues(alpha: 0.5) // 深色模式：黑色半透明
        : Colors.black.withValues(alpha: 0.4); // 浅色模式：黑色半透明
  }

  /// 获取玻璃对话框颜色
  Color getGlassDialogColor() {
    return _isDarkMode
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.3);
  }

  /// 获取玻璃选择器颜色
  Color getGlassPickerColor() {
    return _isDarkMode
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.3);
  }

  // ==================== 文字颜色配置 ====================

  /// 获取主要文字颜色
  Color getPrimaryTextColor() {
    return _isDarkMode ? Colors.white : Colors.white;
  }

  /// 获取次要文字颜色
  Color getSecondaryTextColor() {
    return _isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.6);
  }

  /// 获取提示文字颜色
  Color getHintTextColor() {
    return _isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);
  }

  // ==================== 模糊度配置 ====================

  /// 获取标准模糊度
  double getStandardBlur() {
    return _isDarkMode ? 25.0 : 20.0; // 深色模式稍微增加模糊
  }

  /// 获取导航栏模糊度
  double getNavBarBlur() {
    return _isDarkMode ? 35.0 : 30.0;
  }

  /// 获取对话框模糊度
  double getDialogBlur() {
    return 20.0; // 对话框模糊度保持一致
  }

  // ==================== 厚度配置 ====================

  /// 获取标准厚度
  double getStandardThickness() {
    return _isDarkMode ? 12.0 : 10.0; // 深色模式稍微增加厚度
  }

  /// 获取导航栏厚度
  double getNavBarThickness() {
    return _isDarkMode ? 28.0 : 25.0;
  }

  // ==================== 便捷方法 ====================

  /// 根据深色模式选择颜色
  Color selectColor({
    required Color lightColor,
    required Color darkColor,
  }) {
    return _isDarkMode ? darkColor : lightColor;
  }

  /// 根据深色模式选择值
  T selectValue<T>({
    required T lightValue,
    required T darkValue,
  }) {
    return _isDarkMode ? darkValue : lightValue;
  }
}

