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
import 'ui/screens/schedule_screen.dart';
import 'ui/screens/android_liquid_glass_main.dart';
import 'ui/screens/windows_custom_window.dart';
import 'dart:async';

bool globalUseDarkMode = false; 
final ValueNotifier<String?> globalBackgroundPath = ValueNotifier<String?>(null);

Future<void> loadGlobalBackground() async {
  try {
    final storage = StorageService();
    final savedPath = storage.getString(StorageService.keyBackgroundPath);
    if (savedPath != null && await File(savedPath).exists()) {
      globalBackgroundPath.value = savedPath;
    }
  } catch (e) {
    debugPrint('Bg Error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // [v2.1.10] 初始化 MMKV 存储服务
  await StorageService().initialize();
  
  // [v2.1.10] 初始化主题服务
  await ThemeService().initialize();
  
  await LiquidGlassWidgets.initialize();

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
    if (Platform.isWindows) {
      final tray = WindowsTrayService();
      await tray.initialize();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: globalBackgroundPath,
      builder: (context, backgroundPath, _) {
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
            Widget backgroundWidget = AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                image: backgroundPath != null
                    ? DecorationImage(image: FileImage(File(backgroundPath)), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken))
                    : null,
                gradient: backgroundPath == null ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)]) : null,
              ),
            );

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
          home: _getHomeParams(),
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