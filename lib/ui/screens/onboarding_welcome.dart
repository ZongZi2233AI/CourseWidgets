import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_renderer/experimental.dart';
import 'dart:io' show Platform;
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
    // [v2.3.0修复] 使用 GlassContainer 获得真正的玻璃效果
    return GlassContainer(
      width: 280, // [v2.3.2修复] 增加宽度防止文字换行
      height: 240,
      shape: const LiquidRoundedSuperellipse(borderRadius: 48),
      settings: LiquidGlassSettings(
        glassColor: Colors.white.withValues(alpha: 0.15),
        blur: 20,
        thickness: 15,
      ),
      quality: GlassQuality.standard,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // [v2.3.0修复] 使用 assets 中的应用图标
            Image.asset(
              'assets/icon.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            
            // App Name - [v2.3.0修复] 缩小字号避免换行
            const Text(
              'CourseWidgets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible, // [v2.3.2修复] 允许溢出但不换行
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassifyText() {
    // [v2.2.9] 使用 Glassify 为文字添加玻璃效果
    // Windows 端降级为普通 Container (性能优化)
    // 参考: https://pub.dev/documentation/liquid_glass_renderer/latest/experimental/Glassify-class.html
    
    final isWindows = !kIsWeb && Platform.isWindows;
    
    if (isWindows) {
      // Windows 降级版本 - 使用简单的渐变背景
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Text(
          '欢迎使用',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 8.0,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      );
    }
    
    // Android/iOS - 使用 Glassify 效果
    return Glassify(
      settings: const LiquidGlassSettings(
        thickness: 8, // 保持在 20px 以下以获得最佳效果
        glassColor: Color(0x44FFFFFF), // 半透明白色
      ),
      child: const Text(
        '欢迎使用',
        style: TextStyle(
          fontSize: 72, // 大字体以展示玻璃效果
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8.0,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 4,
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
