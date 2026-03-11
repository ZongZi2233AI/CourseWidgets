import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../services/windows_tray_service.dart';
import '../../providers/schedule_provider.dart';
import 'windows_schedule_screen.dart';
import 'settings_main_screen.dart';
import 'calendar_view_screen.dart';

/// 全局注入，使得背景跟随自定义窗口同步缩放
final ValueNotifier<double> windowsGlobalScale = ValueNotifier(1.0);
final ValueNotifier<double> windowsGlobalOpacity = ValueNotifier(1.0);
final ValueNotifier<bool> windowsGlobalIsMaximized = ValueNotifier(false);

/// 用于给由于 setAsFrameless 移除边框的窗体重新加上缩放手柄
class WindowResizer extends StatelessWidget {
  final Widget child;
  const WindowResizer({super.key, required this.child});

  Widget _buildEdge({
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
    required MouseCursor cursor,
    required ResizeEdge edge,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startResizing(edge),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        _buildEdge(
          top: 0,
          left: 8,
          right: 8,
          height: 6,
          cursor: SystemMouseCursors.resizeUpDown,
          edge: ResizeEdge.top,
        ),
        _buildEdge(
          bottom: 0,
          left: 8,
          right: 8,
          height: 6,
          cursor: SystemMouseCursors.resizeUpDown,
          edge: ResizeEdge.bottom,
        ),
        _buildEdge(
          left: 0,
          top: 8,
          bottom: 8,
          width: 6,
          cursor: SystemMouseCursors.resizeLeftRight,
          edge: ResizeEdge.left,
        ),
        _buildEdge(
          right: 0,
          top: 8,
          bottom: 8,
          width: 6,
          cursor: SystemMouseCursors.resizeLeftRight,
          edge: ResizeEdge.right,
        ),
        _buildEdge(
          top: 0,
          left: 0,
          width: 8,
          height: 8,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          edge: ResizeEdge.topLeft,
        ),
        _buildEdge(
          top: 0,
          right: 0,
          width: 8,
          height: 8,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
          edge: ResizeEdge.topRight,
        ),
        _buildEdge(
          bottom: 0,
          left: 0,
          width: 8,
          height: 8,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
          edge: ResizeEdge.bottomLeft,
        ),
        _buildEdge(
          bottom: 0,
          right: 0,
          width: 8,
          height: 8,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          edge: ResizeEdge.bottomRight,
        ),
      ],
    );
  }
}

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

    _windowAnimController.addListener(() {
      windowsGlobalScale.value = _scaleAnim.value;
      windowsGlobalOpacity.value = _opacityAnim.value;
    });

    _initWindow();

    // [v2.3.0修复] 初始化托盘服务并启动课程提醒
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // [v2.7.0修复] 确保桌面端在启动时强制加载SQLite与配置内容
      try {
        await context.read<ScheduleProvider>().loadSavedData();
      } catch (e) {
        debugPrint('桌面端启动加载数据失败: $e');
      }

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

    // [v2.7.1] 应用户要求，移除 Windows 自带的主题色边框。
    // 使用 setAsFrameless 可以完全移除系统边框且我们自制的窗体缩放和透明动画依旧可以运作！
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false); // 关闭系统阴影，我们将使用 Flutter 原生绘制悬浮散发阴影

    // [v2.7.0] 彻底解耦背景层。不强制塞入 Colors.black。
    // 这可以让 Windows 透出底层实现真彩色透明窗口与自定义壁纸容器交互。
    await windowManager.setBackgroundColor(Colors.transparent);

    // 强制设置窗口大小和位置
    await windowManager.setSize(const Size(1024, 768));
    await windowManager.center();

    // 检查最大化状态
    _isMaximized = await windowManager.isMaximized();
    windowsGlobalIsMaximized.value = _isMaximized;
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
    windowsGlobalIsMaximized.value = true;
    setState(() => _isMaximized = true);
    debugPrint('窗口已最大化');
  }

  @override
  void onWindowUnmaximize() {
    windowsGlobalIsMaximized.value = false;
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
    // [v2.8.0] 传入课程列表以便发送后台通知
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    await tray.enterBackgroundMode(courses: provider.courses);

    debugPrint('🌙 窗口已最小化到托盘，进程继续运行');
  }

  // [v2.5.9修复] 恢复手动实现的最小化动画
  void _handleMinimize() async {
    await _windowAnimController.forward();
    await windowManager.minimize();
  }

  // [v2.5.3] 监听窗口从托盘或任务栏恢复
  @override
  void onWindowRestore() async {
    setState(() {});
    await _windowAnimController.reverse();
    debugPrint('🌟 窗口已恢复(DWM原生重绘)');
  }

  @override
  void onWindowFocus() {
    setState(() {});
    _windowAnimController.reverse();
  }

  // [v2.5.9修复] 恢复手动实现的最大化过渡动画
  void _handleMaximize() async {
    await _windowAnimController.forward();
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    await _windowAnimController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 阴影和圆角现已整体被 main.dart 接管以覆盖壁纸，此处直接返回无背景色 Scaffold 即可
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildTitleBar(),
          Expanded(
            child: Navigator(
              key: _localNavigatorKey,
              initialRoute: '/',
              onGenerateRoute: (settings) {
                // [v2.5.9修复] 使用 PageRouteBuilder + opaque:false
                // MaterialPageRoute 默认包裹一个 MaterialType.canvas (纯白) Material，
                // 会遮挡透明的 Scaffold 和玻璃背景层，形成 "白色遮罩"。
                return PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Row(
                        children: [
                          // [v2.9.2] 彻底拔除侧边栏的滚动条与滚动能力
                          // 即使加了 NeverScrollableScrollPhysics，桌面端默认注入的 Scrollbar
                          // 的滑块依然可能被鼠标强行拖动。使用 ScrollConfiguration 彻底隐藏。
                          ScrollConfiguration(
                            behavior: ScrollConfiguration.of(
                              context,
                            ).copyWith(scrollbars: false),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.of(context).size.height - 40,
                                ),
                                child: IntrinsicHeight(child: _buildSidebar()),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildContent(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
            Icon(Icons.school, color: Theme.of(context).primaryColor, size: 16),
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
      width: 80,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavItem(0, Icons.grid_view, "课程"),
          const SizedBox(height: 24),
          _buildNavItem(1, Icons.calendar_today, "日历"),
          const Spacer(),
          _buildNavItem(2, Icons.settings, "设置"),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String tooltip) {
    final isSelected = _selectedIndex == index;
    // [v2.5.8 优化] Windows侧边栏：不要底板，只保留按钮，并加上悬浮阴影
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: GlassButton.custom(
          onTap: () => setState(() => _selectedIndex = index),
          width: 48,
          height: 48,
          style: GlassButtonStyle.filled,
          settings: LiquidGlassSettings(
            glassColor: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            blur: 15,
            thickness: 20.0,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 16),
          child: Center(
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ),
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
