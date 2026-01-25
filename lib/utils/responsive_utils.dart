import 'package:flutter/material.dart';

/// 响应式布局工具类
class ResponsiveUtils {
  /// 平板模式阈值（宽度 > 600dp）
  static const double tabletBreakpoint = 600.0;
  
  /// 检测是否为平板模式（横屏且宽度 > 600dp）
  static bool isTabletMode(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    
    // 平板模式：横屏且宽度 > 600dp
    return size.width > tabletBreakpoint && 
           orientation == Orientation.landscape;
  }
  
  /// 检测是否为横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// 检测是否为竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// 获取安全区域内边距
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// 侧边栏宽度（平板模式）
  static const double sideBarWidth = 80.0;
  
  /// 侧边栏宽度（展开模式，带文字）
  static const double sideBarExpandedWidth = 200.0;
}
