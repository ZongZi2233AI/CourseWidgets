import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../constants/theme_constants.dart';
import '../../constants/version.dart';
import '../widgets/liquid_components.dart' as liquid;

/// [修复7] iOS 26 液态玻璃风格关于软件页面
class SettingsAboutScreen extends StatefulWidget {
  const SettingsAboutScreen({super.key});
  @override
  State<SettingsAboutScreen> createState() => _SettingsAboutScreenState();
}

class _SettingsAboutScreenState extends State<SettingsAboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
      // [v2.4.8] LiquidGlassLayer 预热 shader，消除 Touch Me 白闪
      body: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: 20,
          blur: 8.0,
          lightIntensity: 0.6,
          saturation: 1.8,
        ),
        child: Column(
          children: [
            // Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const liquid.LiquidBackButton(),
                    const SizedBox(width: 12),
                    const Text(
                      '关于软件',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // App Icon & Name Card
                      liquid.LiquidCard(
                        borderRadius: 32,
                        padding: 32,
                        glassColor: Colors.white.withValues(alpha: 0.03),
                        quality: GlassQuality.standard,
                        child: Column(
                          children: [
                            // App Icon with glow effect
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppThemeColors.babyPink.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  'assets/icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // App Name
                            const Text(
                              'CourseWidgets',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Version Badge
                            liquid.LiquidCard(
                              borderRadius: 16,
                              padding: 8,
                              styleType: liquid.LiquidStyleType.micro,
                              glassColor: AppThemeColors.babyPink.withValues(
                                alpha: 0.2,
                              ),
                              quality: GlassQuality.standard,
                              child: Text(
                                'v$appVersion',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Premium Glass Demo Card
                      _buildPremiumGlassDemo(),

                      const SizedBox(height: 20),

                      // Copyright Card
                      liquid.LiquidCard(
                        borderRadius: 28,
                        padding: 20,
                        glassColor: Colors.white.withValues(alpha: 0.01),
                        quality: GlassQuality.standard,
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.heart_fill,
                              color: AppThemeColors.babyPink.withValues(
                                alpha: 0.6,
                              ),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            // [v2.1.8修复5] 修改copyright为开发者名称
                            const Text(
                              'Copyright © 2025-2026 ZongZi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // [v2.2.1] 修改为 Apache 2.0 License
                            const Text(
                              'Open Source under Apache 2.0 License',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Made with Flutter & Liquid Glass',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 100,
                      ), // Bottom padding for navigation bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGlassDemo() {
    // [v2.4.8] 使用 GlassButton.custom 获得完整的拉伸/按压/高光互动效果
    // 按 API 文档：GlassQuality.premium 用于静态布局，提供最高视觉质量
    // useOwnLayer: true 让 Touch Me 有自己的完整玻璃图层
    return GestureDetector(
      onTapDown: (_) {
        // [v2.5.6修复] 在最外层拦截 onTapDown，强制触发系统级别的触觉震动反馈，确保 Android 侧点按时有物理反馈
        HapticFeedback.lightImpact();
      },
      child: GlassButton.custom(
        onTap: () {
          HapticFeedback.heavyImpact();
        },
        width: double.infinity,
        height: 120,
        style: GlassButtonStyle.filled,
        // [v2.5.0修复] 关闭独立图层。使用 useOwnLayer=true 虽然能做shader预渲染，
        // 但在部分 Android 设备上初次绘制会白屏闪烁。关闭它即可解决闪烁。
        useOwnLayer: false,
        quality: GlassQuality.premium, // 最高质量 — 包括纹理捕获和色散
        // [v2.5.6修复] 将形变系数恢复到正常水平，解决 Windows 端拖拽失控乱飞的问题
        stretch: 0.8, // 适度的拉伸形变
        resistance: 0.05, // 保持一定的阻力感
        interactionScale: 0.9, // [v2.5.6修复] 恢复正常的按压回缩比例 (0.9)
        settings: LiquidGlassSettings(
          glassColor: Colors.transparent, // 完全无色透明
          blur: 1.0, // 仅保留边缘的一点点模糊，展现清晰的折射扭曲
          thickness: 500, // 极度夸张的厚度，让背后内容严重折射错位
          refractiveIndex: 2.5, // 极高折射率（钻石级别）
          lightIntensity: 1.5,
          chromaticAberration: 0.2, // 明显的色差
        ),
        shape: const LiquidRoundedSuperellipse(borderRadius: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.hand_point_right_fill,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'Touch me',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Premium Liquid Glass Demo',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
