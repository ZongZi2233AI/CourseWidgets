import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
// 引入超椭圆库
import 'package:figma_squircle/figma_squircle.dart';
import 'providers/schedule_provider.dart';
import 'services/windows_tray_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/onboarding_service.dart';
import 'services/background_task_service.dart'; // [v2.2.9] 后台任务服务
import 'utils/glass_opacity_manager.dart'; // [v2.3.0] 玻璃透明度管理器
import 'ui/screens/schedule_screen.dart';
import 'ui/screens/android_liquid_glass_main.dart';
import 'ui/screens/windows_custom_window.dart';
import 'ui/screens/onboarding_screen.dart';
import 'dart:async';

bool globalUseDarkMode = false; 
final ValueNotifier<String?> globalBackgroundPath = ValueNotifier<String?>(null);

Future<void> loadGlobalBackground() async {
  try {
    final storage = StorageService();
    final savedPath = storage.getString(StorageService.keyBackgroundPath);
    
    // 检查是否有用户自定义壁纸
    if (savedPath != null && savedPath.isNotEmpty) {
      // 如果是 asset 路径，直接使用
      if (savedPath.startsWith('asset:')) {
        globalBackgroundPath.value = savedPath;
        debugPrint('✅ 加载默认壁纸: $savedPath');
        return;
      }
      
      // 如果是文件路径，检查文件是否存在
      if (await File(savedPath).exists()) {
        globalBackgroundPath.value = savedPath;
        debugPrint('✅ 加载用户壁纸: $savedPath');
        return;
      }
    }
    
    // 没有保存的壁纸或文件不存在，使用默认壁纸
    String defaultWallpaper;
    if (Platform.isAndroid || Platform.isIOS) {
      // 手机端使用浅色壁纸
      defaultWallpaper = 'asset:assets/mobile wallpaper light.png';
    } else {
      // 平板和 Windows/macOS/Linux 使用 tahoe 壁纸
      defaultWallpaper = 'asset:assets/tahoe.jpg';
    }
    
    globalBackgroundPath.value = defaultWallpaper;
    debugPrint('✅ 使用默认壁纸: $defaultWallpaper');
  } catch (e) {
    debugPrint('❌ 加载壁纸错误: $e');
    // 出错时也使用默认壁纸
    String defaultWallpaper;
    if (Platform.isAndroid || Platform.isIOS) {
      defaultWallpaper = 'asset:assets/mobile wallpaper light.png';
    } else {
      defaultWallpaper = 'asset:assets/tahoe.jpg';
    }
    globalBackgroundPath.value = defaultWallpaper;
    debugPrint('✅ 使用默认壁纸 (fallback): $defaultWallpaper');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // [v2.1.10] 初始化 MMKV 存储服务
  await StorageService().initialize();
  
  // [v2.1.10] 初始化主题服务
  await ThemeService().initialize();
  
  await LiquidGlassWidgets.initialize();
  
  // [v2.2.9] 初始化后台任务服务（仅 Android）
  if (Platform.isAndroid) {
    try {
      await BackgroundTaskService.initialize();
      await BackgroundTaskService.registerPeriodicTask();
      debugPrint('✅ 后台任务服务已启动');
    } catch (e) {
      debugPrint('❌ 后台任务服务启动失败: $e');
    }
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    // [v2.1.8修复Windows1] 设置窗口选项，确保DPI正确
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false, // 隐藏默认窗口按钮
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    
    // [v2.3.0修复] Windows 托盘服务初始化
    if (Platform.isWindows) {
      // 设置窗口关闭时不退出应用，而是隐藏到托盘
      await windowManager.setPreventClose(true);
      
      final tray = WindowsTrayService();
      await tray.initialize();
      debugPrint('✅ Windows 托盘服务已在 main 中初始化');
    }
  }

  await loadGlobalBackground();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ScheduleProvider())],
      child: const MyApp(),
    ),
  );
  
  // [v2.1.7] Windows课程提醒将在WindowsCustomWindow中启动
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _showOnboarding = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // [v2.3.0] 初始化玻璃透明度管理器
    final storage = StorageService();
    final darkMode = storage.getBool(StorageService.keyDarkMode) ?? false;
    final adaptiveMode = storage.getBool(StorageService.keyAdaptiveDarkMode) ?? false;
    
    if (adaptiveMode) {
      // 自适应模式：跟随系统
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      GlassOpacityManager().setDarkMode(brightness == Brightness.dark);
      globalUseDarkMode = brightness == Brightness.dark;
    } else {
      // 手动模式
      GlassOpacityManager().setDarkMode(darkMode);
      globalUseDarkMode = darkMode;
    }
    
    setState(() {
      _showOnboarding = _onboardingService.shouldShowOnboarding;
      _isChecking = false;
    });
  }

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // 加载中
      return material.MaterialApp(
        debugShowCheckedModeBanner: false,
        home: material.Scaffold(
          backgroundColor: Colors.black,
          body: const Center(
            child: material.CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: globalBackgroundPath,
      builder: (context, backgroundPath, _) {
        // [v2.2.8修复] 添加调试信息
        debugPrint('🎨 当前背景路径: $backgroundPath, 深色模式: $globalUseDarkMode');
        
        return material.MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: material.ThemeData(
            useMaterial3: true,
            pageTransitionsTheme: const material.PageTransitionsTheme(
              builders: {
                material.TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
                material.TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
                material.TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
              },
            ),
          ),
          builder: (context, child) {
            // 构建背景组件
            Widget backgroundWidget;
            
            // [v2.3.0修复] 根据深色模式调整背景亮度
            final darkenAlpha = globalUseDarkMode ? 0.6 : 0.2;
            
            if (backgroundPath != null && backgroundPath.isNotEmpty) {
              // 检查是否是 asset 路径
              if (backgroundPath.startsWith('asset:')) {
                final assetPath = backgroundPath.substring(6); // 移除 'asset:' 前缀
                debugPrint('🎨 使用 Asset 背景: $assetPath');
                backgroundWidget = AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(assetPath),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        // [v2.3.0修复] 深色模式大幅降低背景亮度
                        Colors.black.withValues(alpha: darkenAlpha),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                );
              } else {
                // 用户自定义的文件路径
                debugPrint('🎨 使用文件背景: $backgroundPath');
                backgroundWidget = AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(backgroundPath)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        // [v2.3.0修复] 深色模式大幅降低背景亮度
                        Colors.black.withValues(alpha: darkenAlpha),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                );
              }
            } else {
              // 没有背景时使用渐变
              debugPrint('🎨 使用渐变背景 (fallback)');
              backgroundWidget = AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: globalUseDarkMode
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFE0C3FC), const Color(0xFF8EC5FC)],
                  ),
                ),
              );
            }

            // 【核心修复】如果是 Windows，强制裁切背景为超椭圆
            // 这样背景图就不会溢出到圆角之外，实现真正的窗口圆角效果
            if (Platform.isWindows) {
              backgroundWidget = ClipSmoothRect(
                radius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 1.0),
                child: backgroundWidget,
              );
            }

            return LiquidGlassScope.stack(
              background: backgroundWidget,
              content: child ?? const SizedBox(),
            );
          },
          home: _showOnboarding
              ? OnboardingScreen(onComplete: _completeOnboarding)
              : _getHomeParams(),
        );
      },
    );
  }

  Widget _getHomeParams() {
    if (Platform.isWindows) return const WindowsCustomWindow();
    if (Platform.isAndroid) return const AndroidLiquidGlassMain();
    return const ScheduleScreen();
  }
}

class FadeSlidePageTransitionsBuilder extends material.PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: secondaryAnimation, curve: const Interval(0.0, 0.3, curve: Curves.easeOut))),
      child: slideIn,
    );
  }
}