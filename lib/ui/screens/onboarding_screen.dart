import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import '../../services/onboarding_service.dart';
import 'onboarding_welcome.dart';
import 'onboarding_config.dart';
import 'onboarding_import.dart';
import 'onboarding_theme.dart';

/// [v2.2.8] 首次启动引导主框架
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final OnboardingService _onboardingService = OnboardingService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      HapticFeedback.selectionClick();
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.selectionClick();
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await _onboardingService.completeOnboarding();

    if (mounted) {
      HapticFeedback.heavyImpact();

      // 直接调用 onComplete 回调
      widget.onComplete();

      // [v2.5.9] 引导结束后直接重启应用，确保所有 Provider 重新加载数据
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Phoenix.rebirth(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 禁用手势滑动
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          // 第一页：欢迎页
          OnboardingWelcome(onNext: _nextPage),

          // 第二页：课时配置
          OnboardingConfig(onNext: _nextPage, onBack: _previousPage),

          // 第三页：导入课表
          OnboardingImport(onNext: _nextPage, onBack: _previousPage),

          // 第四页：主题设置
          OnboardingTheme(
            onComplete: _completeOnboarding,
            onBack: _previousPage,
          ),
        ],
      ),
    );
  }
}
