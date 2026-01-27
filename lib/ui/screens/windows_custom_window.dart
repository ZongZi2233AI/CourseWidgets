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
    with WindowListener {
  int _selectedIndex = 0;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
    
    // [v2.2.0修复5] 初始化托盘服务
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final tray = WindowsTrayService();
      await tray.initialize();
      
      // 启动课程提醒
      final provider = context.read<ScheduleProvider>();
      tray.startCourseReminder(provider);
      
      debugPrint('✅ 托盘服务已初始化');
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
    
    // [v2.2.8修复] 启用窗口动画 - 设置窗口属性
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(true);
    
    // [v2.2.8修复] 尝试启用窗口动画效果
    // 注意：window_manager 本身不提供动画API，动画由系统DWM控制
    // 确保窗口不是完全透明，这样系统才能正确渲染动画
    await windowManager.setBackgroundColor(Colors.black.withValues(alpha: 0.01));
    
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

  /// [v2.2.0修复5] 窗口关闭 - 最小化到托盘
  @override
  Future<void> onWindowClose() async {
    // 隐藏到托盘
    await windowManager.hide();
    debugPrint('窗口已最小化到托盘');
  }

  @override
  Widget build(BuildContext context) {
    // [v2.2.1修复] 根据最大化状态调整圆角
    final borderRadius = _isMaximized ? 0.0 : 16.0;
    
    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: borderRadius,
        cornerSmoothing: 1.0,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          // [v2.2.8修复] 添加动画过渡，平滑最大化/还原效果
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            // [v2.2.8修复] 确保窗口有可见的背景色
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            children: [
              _buildTitleBar(),
              Expanded(
                child: Row(
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
            ],
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
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.school,
              color: AppThemeColors.babyPink,
              size: 16,
            ),
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
            _buildWindowButton(
              Icons.remove,
              () => windowManager.minimize(),
            ),
            _buildWindowButton(
              _isMaximized ? Icons.fullscreen_exit : Icons.crop_square,
              () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _buildWindowButton(
              Icons.close,
              () => windowManager.close(),
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
          color: Colors.transparent,
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
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
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
