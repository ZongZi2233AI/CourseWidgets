import 'package:mmkv/mmkv.dart';
import 'package:flutter/foundation.dart';

/// MMKV 存储服务 - 替代 SharedPreferences
/// 性能更高，支持 AGP 9.0
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  MMKV? _mmkv;
  bool _isInitialized = false;

  /// 初始化 MMKV
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 初始化 MMKV
      final rootDir = await MMKV.initialize();
      debugPrint('MMKV 初始化成功: $rootDir');
      
      _mmkv = MMKV.defaultMMKV();
      _isInitialized = true;
    } catch (e) {
      debugPrint('MMKV 初始化失败: $e');
    }
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_isInitialized || _mmkv == null) {
      throw Exception('StorageService 未初始化，请先调用 initialize()');
    }
  }

  // ==================== String ====================
  
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return _mmkv!.encodeString(key, value);
  }

  String? getString(String key, {String? defaultValue}) {
    _ensureInitialized();
    final value = _mmkv!.decodeString(key);
    return value ?? defaultValue;
  }

  // ==================== Int ====================
  
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return _mmkv!.encodeInt(key, value);
  }

  int? getInt(String key, {int? defaultValue}) {
    _ensureInitialized();
    final value = _mmkv!.decodeInt(key);
    return value == 0 && !_mmkv!.containsKey(key) ? defaultValue : value;
  }

  // ==================== Bool ====================
  
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return _mmkv!.encodeBool(key, value);
  }

  bool? getBool(String key, {bool? defaultValue}) {
    _ensureInitialized();
    if (!_mmkv!.containsKey(key)) return defaultValue;
    return _mmkv!.decodeBool(key);
  }

  // ==================== Double ====================
  
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();
    return _mmkv!.encodeDouble(key, value);
  }

  double? getDouble(String key, {double? defaultValue}) {
    _ensureInitialized();
    if (!_mmkv!.containsKey(key)) return defaultValue;
    return _mmkv!.decodeDouble(key);
  }

  // ==================== 删除和清空 ====================
  
  Future<bool> remove(String key) async {
    _ensureInitialized();
    _mmkv!.removeValue(key);
    return true;
  }

  Future<bool> clear() async {
    _ensureInitialized();
    _mmkv!.clearAll();
    return true;
  }

  // ==================== 检查键是否存在 ====================
  
  bool containsKey(String key) {
    _ensureInitialized();
    return _mmkv!.containsKey(key);
  }

  // ==================== 获取所有键 ====================
  
  List<String> getAllKeys() {
    _ensureInitialized();
    return _mmkv!.allKeys;
  }

  // ==================== 常用键定义 ====================
  
  static const String keyDarkMode = 'dark_mode';
  static const String keyAdaptiveDarkMode = 'adaptive_dark_mode';
  static const String keyBackgroundPath = 'background_path';
  static const String keyThemeMode = 'theme_mode'; // 'default', 'system', 'monet'
  static const String keyCustomThemeColor = 'custom_theme_color';
}
