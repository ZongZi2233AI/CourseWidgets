import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../services/windows_tray_service.dart';
import '../../providers/schedule_provider.dart';
import 'windows_schedule_screen.dart';
import 'settings_main_screen.dart';
import 'calendar_view_screen.dart';

/// [v2.2.0] 完全重构的Windows自定义窗口
/// 修复：DPI缩放、窗口动画、托盘功能、窗口调整大小
class WindowsCustomWindow extends StatefulWidget {
  const WindowsCustomWindow({super.key});
  @override
  State<WindowsCustomWindow> createState() => _WindowsCustomWindowState();
}

class _WindowsCustomWindowState extends State<WindowsCustomWindow>
    with WindowListener, TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isMaximized = false;
  final GlobalKey<NavigatorState> _localNavigatorKey =
      GlobalKey<NavigatorState>();

  // [v2.5.1反馈] 恢复真·自定义窗口最大最小化动画
  late AnimationController _windowAnimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // [v2.5.1] 初始化窗口动画
    _windowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _windowAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _windowAnimController, curve: Curves.easeInCubic),
    );

    _initWindow();

    // [v2.3.0修复] 初始化托盘服务并启动课程提醒
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final tray = WindowsTrayService();
        await tray.initialize();

        // 启动课程提醒
        if (mounted) {
          final provider = context.read<ScheduleProvider>();
          tray.startCourseReminder(provider);
        }

        // [v2.5.0] 监听托盘菜单的页面切换事件
        tray.navigationStream.listen((index) {
          if (mounted) {
            setState(() {
              _selectedIndex = index;
            });
          }
        });

        debugPrint('✅ Windows 托盘服务已初始化并启动课程提醒');
      } catch (e) {
        debugPrint('❌ 托盘服务初始化失败: $e');
      }
    });
  }

  /// [v2.2.0修复1+2] 修复DPI缩放问题 + 启用窗口调整大小
  void _initWindow() async {
    // 等待窗口完全初始化
    await Future.delayed(const Duration(milliseconds: 150));

    // [修复2] 启用窗口调整大小
    await windowManager.setResizable(true);

    // 设置最小窗口大小
    await windowManager.setMinimumSize(const Size(800, 600));

    // [v2.4.8] 确保使用 TitleBarStyle.hidden 而非 setAsFrameless
    // hidden 保留系统 DWM 窗口动画（最大化/最小化/还原）
    // setAsFrameless 完全移除窗口边框，导致 DWM 无法触发动画
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setHasShadow(true);

    // [v2.4.8] 使用不透明黑色背景，让 DWM 有足够内容来渲染动画
    // alpha: 0.01 太透明会导致 DWM 动画看不到效果
    await windowManager.setBackgroundColor(Colors.black);

    // 强制设置窗口大小和位置
    await windowManager.setSize(const Size(1024, 768));
    await windowManager.center();

    // 检查最大化状态
    _isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {});
    }

    debugPrint('✅ 窗口初始化完成: 1024x768, 可调整大小, 启用动画');
  }

  @override
  void dispose() {
    _windowAnimController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  /// [v2.2.0修复3] 窗口最大化
  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
    debugPrint('窗口已最大化');
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
    debugPrint('窗口已还原');
  }

  /// [v2.3.0修复] 窗口关闭 - 最小化到托盘而不退出进程
  @override
  Future<void> onWindowClose() async {
    // 阻止窗口关闭，改为隐藏到托盘
    // [v2.5.3] 添加恢复窗口时的放大淡入动画，完成自定义最小化/恢复闭环
    await _windowAnimController.forward();
    await windowManager.hide();

    // 进入后台模式
    final tray = WindowsTrayService();
    await tray.enterBackgroundMode();

    debugPrint('🌙 窗口已最小化到托盘，进程继续运行');
  }

  // [v2.5.5修复] 直接调用系统级别的最小化，去除多余的 _windowAnimController 层面的缩放，使得背景和窗口组件同步缩小
  void _handleMinimize() async {
    await windowManager.minimize();
  }

  // [v2.5.3] 监听窗口从托盘或任务栏恢复
  @override
  void onWindowRestore() {
    setState(() {});
    debugPrint('🌟 窗口已恢复(DWM原生重绘)');
  }

  @override
  void onWindowFocus() {
    // nothing
  }

  void _handleMaximize() async {
    // 移除花哨但冲突的缩放，直接交由原生 DWM 处理以避免冲突和闪烁
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // [v2.2.1修复] 根据最大化状态调整圆角
    // [v2.5.4紧急修复] 如果 radius 为 0，必须将 smoothing 也置为 0，否则底层的 figma_squircle 会在绘制路径时产生 NaN/除零错误，
    // 导致 Debug 红屏，以及 Release 混淆模式下的 GPU 线程直接死锁（黑屏崩盘无响应）。
    final borderRadius = _isMaximized ? 0.0 : 16.0;
    final smoothing = _isMaximized ? 0.0 : 1.0;

    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: borderRadius,
        cornerSmoothing: smoothing,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _windowAnimController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(opacity: _opacityAnim.value, child: child),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Column(
              children: [
                _buildTitleBar(),
                Expanded(
                  child: Navigator(
                    key: _localNavigatorKey,
                    initialRoute: '/',
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        builder: (context) => Scaffold(
                          backgroundColor: Colors.transparent, // 继承外层透明
                          body: Row(
                            children: [
                              _buildSidebar(),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildContent(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标题栏
  Widget _buildTitleBar() {
    return DragToMoveArea(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.school, color: AppThemeColors.babyPink, size: 16),
            const SizedBox(width: 8),
            const Text(
              "CourseWidgets",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // 自定义窗口按钮
            _buildWindowButton(
              Icons.remove,
              _handleMinimize,
            ), // [v2.5.0] 使用原生最小化
            _buildWindowButton(
              _isMaximized ? Icons.filter_none : Icons.crop_square,
              _handleMaximize,
            ),
            _buildWindowButton(
              Icons.close,
              () => windowManager.close(), // 触发 onWindowClose 隐藏到托盘
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowButton(
    IconData icon,
    VoidCallback onTap, {
    bool isClose = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 40,
          color: Colors.transparent, // 可以改为 hover 时有浅色背景
          child: Icon(
            icon,
            size: 16,
            color: isClose ? Colors.redAccent : Colors.white70,
          ),
        ),
      ),
    );
  }

  /// 侧边栏
  Widget _buildSidebar() {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        settings: LiquidGlassSettings(
          glassColor: Colors.white.withValues(alpha: 0.05),
          blur: 10,
        ),
        quality: GlassQuality.standard,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildNavItem(0, Icons.grid_view, "课程"),
              const SizedBox(height: 8),
              _buildNavItem(1, Icons.calendar_today, "日历"),
              const SizedBox(height: 8),
              _buildNavItem(2, Icons.settings, "设置"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return GlassButton.custom(
      onTap: () => setState(() => _selectedIndex = index),
      width: double.infinity,
      height: 48,
      style: GlassButtonStyle.filled,
      settings: LiquidGlassSettings(
        glassColor: isSelected
            ? AppThemeColors.babyPink.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.05),
        blur: 0,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 12),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 内容区域
  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        WindowsScheduleScreen(),
        CalendarViewScreen(),
        SettingsMainScreen(),
      ],
    );
  }
}
