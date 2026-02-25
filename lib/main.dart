import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:ui'; // [v2.4.8] PointerDeviceKind for Windows scroll behavior
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
// 引入超椭圆库
import 'package:figma_squircle/figma_squircle.dart';
import 'providers/schedule_provider.dart';
import 'package:local_notifier/local_notifier.dart';
import 'services/theme_service.dart';
import 'services/onboarding_service.dart';
import 'services/windows_tray_service.dart';
import 'services/storage_service.dart';
import 'services/background_task_service.dart'; // [v2.2.9] 后台任务服务
import 'utils/glass_opacity_manager.dart'; // [v2.3.0] 玻璃透明度管理器
import 'ui/screens/schedule_screen.dart';
import 'ui/screens/android_liquid_glass_main.dart';
import 'ui/screens/windows_custom_window.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/transitions/smooth_slide_transitions.dart'; // [v2.4.8] 平滑过渡动画
import 'ui/transitions/custom_predictive_back_transitions.dart'; // [v2.5.6] 修正白屏预测返回
import 'dart:async';
import 'package:flutter_phoenix/flutter_phoenix.dart';

bool globalUseDarkMode = false;
final ValueNotifier<String?> globalBackgroundPath = ValueNotifier<String?>(
  null,
);

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

  // [v2.4.1] 初始化 Liquid Glass
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

    // [v2.5.1] 初始化本地桌面通知
    if (Platform.isWindows) {
      await localNotifier.setup(
        appName: 'CourseWidgets',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    }

    // [v2.4.8] 使用 TitleBarStyle.hidden 替代 setAsFrameless()
    // hidden 模式保留系统原生的 DWM 最大化/最小化动画
    // setAsFrameless() 则完全移除窗口边框导致无动画
    const WindowOptions windowOptions = WindowOptions(
      size: Size(1024, 768),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setHasShadow(true);
      await windowManager.show();
      await windowManager.focus();
    });

    // [v2.3.0] Windows 托盘服务初始化
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
    Phoenix(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
          ChangeNotifierProvider.value(value: ThemeService()),
        ],
        child: const MyApp(),
      ),
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
    final adaptiveMode =
        storage.getBool(StorageService.keyAdaptiveDarkMode) ?? false;

    if (adaptiveMode) {
      // 自适应模式：跟随系统
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
    // [v2.4.7] 引导完成后主动 reload ScheduleProvider 数据
    final provider = context.read<ScheduleProvider>();
    provider.loadSavedData().then((_) {
      if (mounted) {
        setState(() {
          _showOnboarding = false;
        });
      }
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
            child: material.CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: globalBackgroundPath,
      builder: (context, backgroundPath, _) {
        // [v2.2.8] 添加调试信息
        debugPrint('🎨 当前背景路径: $backgroundPath, 深色模式: $globalUseDarkMode');

        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return material.MaterialApp(
              key: ValueKey(themeService.primaryColor.value),
              debugShowCheckedModeBanner: false,
              theme: material.ThemeData(
                useMaterial3: true,
                colorScheme: material.ColorScheme.fromSeed(
                  seedColor: themeService.primaryColor,
                  brightness: material.Theme.of(context).brightness,
                ),
                // [v2.4.4] 全局字体统一使用萍方和SF Pro
                fontFamily: 'PingFangSC',
                fontFamilyFallback: const ['SFPro'],
                // [v2.4.4] 全局加粗标题
                textTheme: const material.TextTheme(
                  titleLarge: TextStyle(fontWeight: FontWeight.bold),
                  titleMedium: TextStyle(fontWeight: FontWeight.bold),
                ),
                // [v2.5.5修复] 采用拼接版预测性返回：进入使用Slide，拉手势触发Native缩放
                pageTransitionsTheme: const material.PageTransitionsTheme(
                  builders: {
                    material.TargetPlatform.android:
                        const CustomPredictiveBackPageTransitionsBuilder(),
                    material.TargetPlatform.iOS:
                        const SmoothSlideTransitionsBuilder(),
                    material.TargetPlatform.windows:
                        const SmoothSlideTransitionsBuilder(),
                  },
                ),
              ),
              // [v2.4.9] Windows 平滑滚动 — BouncingScrollPhysics + 鼠标拖拽
              scrollBehavior: Platform.isWindows
                  ? _SmoothWindowsScrollBehavior()
                  : null,
              builder: (context, child) {
                // 构建背景组件
                Widget backgroundWidget;

                // [v2.3.0] 根据深色模式调整背景亮度
                final darkenAlpha = globalUseDarkMode ? 0.6 : 0.2;

                if (backgroundPath != null && backgroundPath.isNotEmpty) {
                  // 检查是否是 asset 路径
                  if (backgroundPath.startsWith('asset:')) {
                    final assetPath = backgroundPath.substring(
                      6,
                    ); // 移除 'asset:' 前缀
                    debugPrint('🎨 使用 Asset 背景: $assetPath');
                    backgroundWidget = AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(assetPath),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
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
                            : [
                                const Color(0xFFE0C3FC),
                                const Color(0xFF8EC5FC),
                              ],
                      ),
                    ),
                  );
                }

                // 【核心修复】如果是 Windows，强制裁切背景为超椭圆
                if (Platform.isWindows) {
                  backgroundWidget = ClipSmoothRect(
                    radius: SmoothBorderRadius(
                      cornerRadius: 16,
                      cornerSmoothing: 1.0,
                    ),
                    child: backgroundWidget,
                  );
                }

                // [v2.4.1] 隔离背景层，防止二级页面切换时引发玻璃滤镜的重绘掉帧
                backgroundWidget = RepaintBoundary(child: backgroundWidget);

                final coreStack = LiquidGlassScope.stack(
                  background: backgroundWidget,
                  content: material.Material(
                    type: material.MaterialType.transparency,
                    child: child ?? const SizedBox(),
                  ),
                );

                // [v2.5.6修复] 修复 Windows 最小化时背景不随之缩放的问题，通过全局可观察量拉动背景
                if (Platform.isWindows) {
                  return ValueListenableBuilder<double>(
                    valueListenable: windowsGlobalScale,
                    builder: (context, scale, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: windowsGlobalOpacity,
                        builder: (context, opacity, _) {
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(opacity: opacity, child: coreStack),
                          );
                        },
                      );
                    },
                  );
                }

                return coreStack;
              },
              home: _showOnboarding
                  ? OnboardingScreen(onComplete: _completeOnboarding)
                  : _getHomeParams(),
            );
          },
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

/// [v2.4.9] Windows 平滑滚动行为
/// 使用 BouncingScrollPhysics（iOS 风格）替代默认的 ClampingScrollPhysics
/// 让鼠标滚轮滚动有惯性和弹性效果
class _SmoothWindowsScrollBehavior extends material.MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // 使用 BouncingScrollPhysics 让滚动有 iOS 风格的惯性和弹性
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.normal,
    );
  }
}
