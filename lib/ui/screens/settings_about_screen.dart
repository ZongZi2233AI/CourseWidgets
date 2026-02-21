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
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildPremiumGlassDemo() {
    // [v2.4.3修复] 移除 LiquidGlassScope.stack 避免由于透明图层在滚动列表下复合导致的 Impeller 渲染灰块问题
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
      },
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Center(
          child: GlassContainer(
            width: double.infinity,
            height: 120,
            useOwnLayer: false, // [v2.4.3修复] 必须关闭独立图层
            shape: const LiquidRoundedSuperellipse(borderRadius: 28),
            quality: GlassQuality.standard, // 使用标准质量的 BackdropFilter 是安全的
            settings: LiquidGlassSettings(
              glassColor: AppThemeColors.babyPink.withValues(alpha: 0.3),
              blur: 30,
              thickness: 25,
            ),
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
        ),
      ),
    );
  }
}
