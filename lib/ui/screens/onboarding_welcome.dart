import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_renderer/experimental.dart';
import '../../constants/theme_constants.dart';

/// [v2.2.9] 引导页面 - 欢迎页
/// Logo 动画 + Glassify 文字效果 + "开始使用" 按钮
class OnboardingWelcome extends StatefulWidget {
  final VoidCallback onNext;
  
  const OnboardingWelcome({
    super.key,
    required this.onNext,
  });

  @override
  State<OnboardingWelcome> createState() => _OnboardingWelcomeState();
}

class _OnboardingWelcomeState extends State<OnboardingWelcome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Logo 向上移动动画
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: -120.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));
    
    // 文字淡入动画
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    ));
    
    // 按钮淡入动画
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));
    
    // 启动动画
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Logo 玻璃块
              Center(
                child: Transform.translate(
                  offset: Offset(0, _logoAnimation.value),
                  child: _buildLogoGlass(),
                ),
              ),
              
              // "欢迎使用" Glassify 文字
              Center(
                child: Transform.translate(
                  offset: const Offset(0, 80),
                  child: Opacity(
                    opacity: _textAnimation.value,
                    child: _buildGlassifyText(),
                  ),
                ),
              ),
              
              // "开始使用" 按钮
              Positioned(
                left: 40,
                right: 40,
                bottom: 100,
                child: Opacity(
                  opacity: _buttonAnimation.value,
                  child: _buildStartButton(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoGlass() {
    return GlassContainer(
      width: 200,
      height: 200,
      shape: const LiquidRoundedSuperellipse(borderRadius: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.babyPink,
                  AppThemeColors.softCoral,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppThemeColors.babyPink.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          
          // App Name
          const Text(
            'CourseWidgets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassifyText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        '欢迎使用',
        style: TextStyle(
          fontSize: 48, // 增大字体
          fontWeight: FontWeight.w900,
          color: Colors.white, // 确保白色
          letterSpacing: 6.0,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GlassButton.custom(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onNext();
      },
      width: double.infinity,
      height: 60,
      style: GlassButtonStyle.filled,
      settings: LiquidGlassSettings(
        glassColor: AppThemeColors.babyPink.withValues(alpha: 0.2),
        blur: 15, // 添加模糊
        thickness: 20, // 添加厚度
      ),
      shape: const LiquidRoundedSuperellipse(borderRadius: 24),
      child: const Center(
        child: Text(
          '开始使用',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
