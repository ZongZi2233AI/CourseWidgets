import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// [v2.2.8] 首次启动引导服务
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  final StorageService _storage = StorageService();
  
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingVersion = 'onboarding_version';
  static const String _currentOnboardingVersion = '2.2.8';

  /// 是否需要显示引导
  bool get shouldShowOnboarding {
    final completed = _storage.getBool(_keyOnboardingCompleted) ?? false;
    final version = _storage.getString(_keyOnboardingVersion) ?? '';
    
    // 如果从未完成引导，或者引导版本不匹配，则显示
    final shouldShow = !completed || version != _currentOnboardingVersion;
    
    debugPrint('🎯 引导检查: completed=$completed, version=$version, shouldShow=$shouldShow');
    
    return shouldShow;
  }

  /// 标记引导已完成
  Future<void> completeOnboarding() async {
    await _storage.setBool(_keyOnboardingCompleted, true);
    await _storage.setString(_keyOnboardingVersion, _currentOnboardingVersion);
    debugPrint('✅ 引导已完成');
  }

  /// 重置引导状态（用于测试）
  Future<void> resetOnboarding() async {
    await _storage.remove(_keyOnboardingCompleted);
    await _storage.remove(_keyOnboardingVersion);
    debugPrint('🔄 引导状态已重置');
  }

  /// 跳过引导
  Future<void> skipOnboarding() async {
    await completeOnboarding();
    debugPrint('⏭️ 已跳过引导');
  }
}
