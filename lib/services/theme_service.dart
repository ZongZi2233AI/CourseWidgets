import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:material_color_utilities/material_color_utilities.dart';
import 'storage_service.dart';

/// 主题模式
enum ThemeMode {
  defaultMode, // 默认主题色（嫩粉色+柔珊瑚）
  system,      // 系统主题色（Android 12+ Material You）
  monet,       // 莫奈取色（从背景图片提取）
}

/// 主题服务 - 管理应用主题色
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final StorageService _storage = StorageService();
  
  // 默认主题色
  static const Color defaultPrimaryColor = Color(0xFFFF9A9E); // 嫩粉色
  static const Color defaultSecondaryColor = Color(0xFFFAD0C4); // 柔珊瑚
  
  // 当前主题色
  Color _primaryColor = defaultPrimaryColor;
  Color _secondaryColor = defaultSecondaryColor;
  ThemeMode _themeMode = ThemeMode.defaultMode;

  // Getters
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  ThemeMode get themeMode => _themeMode;

  /// 初始化主题服务
  Future<void> initialize() async {
    // 加载保存的主题模式
    final savedMode = _storage.getString(StorageService.keyThemeMode);
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => ThemeMode.defaultMode,
      );
    }

    // [v2.2.9修复] 根据保存的模式恢复颜色
    if (_themeMode == ThemeMode.monet) {
      final savedColor = _storage.getInt(StorageService.keyCustomThemeColor);
      if (savedColor != null) {
        _primaryColor = Color(savedColor);
        _secondaryColor = _generateSecondaryColor(_primaryColor);
        debugPrint('✅ 恢复莫奈取色: $_primaryColor');
      }
    } else if (_themeMode == ThemeMode.defaultMode) {
      _primaryColor = defaultPrimaryColor;
      _secondaryColor = defaultSecondaryColor;
    }

    debugPrint('主题服务初始化完成: $_themeMode');
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setString(StorageService.keyThemeMode, mode.name);
    
    switch (mode) {
      case ThemeMode.defaultMode:
        _primaryColor = defaultPrimaryColor;
        _secondaryColor = defaultSecondaryColor;
        break;
      case ThemeMode.system:
        // 系统主题色将在 applySystemTheme 中设置
        break;
      case ThemeMode.monet:
        // 莫奈取色将在 extractColorsFromImage 中设置
        break;
    }
    
    debugPrint('主题模式已切换: $mode');
  }

  /// 应用系统主题色（Android 12+ Material You）
  Future<void> applySystemTheme(BuildContext context) async {
    if (!Platform.isAndroid) {
      debugPrint('系统主题色仅支持 Android 12+');
      return;
    }

    try {
      // 使用 MethodChannel 获取系统主题色
      const platform = MethodChannel('com.zongzi.schedule/theme');
      final int? systemColor = await platform.invokeMethod('getSystemAccentColor');
      
      if (systemColor != null) {
        // 使用系统主色调生成调色板
        final corePalette = CorePalette.of(systemColor);
        _primaryColor = Color(corePalette.primary.get(40));
        _secondaryColor = Color(corePalette.secondary.get(40));
        
        await _storage.setInt(StorageService.keyCustomThemeColor, _primaryColor.toARGB32());
        debugPrint('系统主题色已应用: $_primaryColor');
      } else {
        debugPrint('无法获取系统主题色，使用默认主题');
        _primaryColor = defaultPrimaryColor;
        _secondaryColor = defaultSecondaryColor;
      }
    } catch (e) {
      debugPrint('获取系统主题色失败: $e，使用默认主题');
      _primaryColor = defaultPrimaryColor;
      _secondaryColor = defaultSecondaryColor;
    }
  }

  /// 从图片提取莫奈颜色（背景图片取色）
  Future<void> extractColorsFromImage(String imagePath) async {
    try {
      // 读取图片文件
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('图片文件不存在: $imagePath');
        return;
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('无法解码图片');
        return;
      }

      // 缩小图片以提高性能（最大 128x128）
      final resized = img.copyResize(
        image,
        width: image.width > 128 ? 128 : image.width,
        height: image.height > 128 ? 128 : image.height,
      );

      // 提取主色调
      final pixels = <int>[];
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          // 转换为 ARGB 格式
          final a = pixel.a.toInt();
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final argb = (a << 24) | (r << 16) | (g << 8) | b;
          pixels.add(argb);
        }
      }

      // 使用 Material Color Utilities 生成调色板
      final result = await QuantizerCelebi().quantize(pixels, 128);
      final ranked = Score.score(result.colorToCount, desired: 1);
      
      if (ranked.isNotEmpty) {
        final dominantColor = Color(ranked.first);
        
        // 生成 Material You 风格的调色板
        final corePalette = CorePalette.of(dominantColor.toARGB32());
        
        _primaryColor = Color(corePalette.primary.get(40));
        _secondaryColor = Color(corePalette.secondary.get(40));
        
        await _storage.setInt(StorageService.keyCustomThemeColor, _primaryColor.toARGB32());
        debugPrint('莫奈取色完成: $_primaryColor');
      }
    } catch (e) {
      debugPrint('莫奈取色失败: $e');
      _primaryColor = defaultPrimaryColor;
      _secondaryColor = defaultSecondaryColor;
    }
  }

  /// 生成次要颜色（基于主色调）
  Color _generateSecondaryColor(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    return hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }

  /// 重置为默认主题
  Future<void> resetToDefault() async {
    await setThemeMode(ThemeMode.defaultMode);
    _primaryColor = defaultPrimaryColor;
    _secondaryColor = defaultSecondaryColor;
    await _storage.remove(StorageService.keyCustomThemeColor);
    debugPrint('主题已重置为默认');
  }

  /// 获取主题色的渐变
  LinearGradient getGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_primaryColor, _secondaryColor],
    );
  }

  /// 获取主题色的半透明版本
  Color getPrimaryWithAlpha(double alpha) {
    return _primaryColor.withValues(alpha: alpha);
  }

  Color getSecondaryWithAlpha(double alpha) {
    return _secondaryColor.withValues(alpha: alpha);
  }
}
