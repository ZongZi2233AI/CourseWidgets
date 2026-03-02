import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      // [v2.6.0] 引导结束后直接彻底关闭应用
      Future.delayed(const Duration(milliseconds: 300), () {
        SystemNavigator.pop(); // 完全关闭 App
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

          // 第二页：主题设置 (改版调至第二)
          OnboardingTheme(
            onComplete: _nextPage,
            onBack: _previousPage,
            isLastPage:
                false, // [v2.6.0] 增设一个非最后一页的状态参数（需要在onboarding_theme里处理一下，这里若未实现就保持UI原样，只换逻辑）
          ),

          // 第三页：课时配置
          OnboardingConfig(onNext: _nextPage, onBack: _previousPage),

          // 第四页：导入课表
          OnboardingImport(
            onNext: _completeOnboarding, // [v2.6.0] 改为完成引导
            onBack: _previousPage,
            isLastPage: true, // [v2.6.0] 告诉导入页它是最后一页
          ),
        ],
      ),
    );
  }
}
