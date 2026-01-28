import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/schedule_provider.dart';
import '../../constants/version.dart';
import '../../constants/theme_constants.dart';
import '../../services/live_notification_service_v2.dart';
import '../../services/data_import_service.dart';
import '../../utils/responsive_utils.dart';
import 'course_edit_screen.dart';
import 'calendar_view_screen.dart';
import 'settings_main_screen.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/glass_context_menu.dart';
import '../widgets/tablet_sidebar.dart';
import '../widgets/weekly_schedule_grid.dart';

class AndroidLiquidGlassMain extends StatefulWidget {
  const AndroidLiquidGlassMain({super.key});
  @override
  State<AndroidLiquidGlassMain> createState() => _AndroidLiquidGlassMainState();
}

class _AndroidLiquidGlassMainState extends State<AndroidLiquidGlassMain> {
  int _currentIndex = 0;
  bool _isLoading = true; // 添加加载状态
  final DataImportService _importService = DataImportService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final provider = context.read<ScheduleProvider>();
      await provider.loadSavedData();
      
      // 初始化 Android 16 Live Updates 通知服务
      final liveService = LiveNotificationServiceV2();
      await liveService.initialize();
      
      // 设置通知点击回调 - 跳转到课程详情
      liveService.setOnNotificationTapCallback((course) {
        // 切换到课程页面
        if (mounted) {
          setState(() => _currentIndex = 0);
        }
      });
      
      // 获取下一节课并启动实时通知
      final nextCourse = provider.getNextCourse();
      await liveService.startLiveUpdate(nextCourse);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ 加载数据失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  void dispose() {
    // 停止通知服务
    LiveNotificationServiceV2().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [v2.2.8修复] 显示加载状态
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    final isTablet = ResponsiveUtils.isTabletMode(context);
    
    if (isTablet) {
      // 平板模式：左侧导航栏 + 右侧内容
      return _buildTabletLayout(context);
    } else {
      // 手机模式：底部导航栏
      return _buildPhoneLayout(context);
    }
  }
  
  /// 平板布局
  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // 左侧导航栏
          TabletSideBar(
            selectedIndex: _currentIndex,
            onTabSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            items: const [
              TabletSideBarItem(
                icon: CupertinoIcons.square_grid_2x2,
                selectedIcon: CupertinoIcons.square_grid_2x2_fill,
                label: '课程',
              ),
              TabletSideBarItem(
                icon: CupertinoIcons.calendar,
                selectedIcon: CupertinoIcons.calendar,
                label: '日历',
              ),
              TabletSideBarItem(
                icon: CupertinoIcons.settings,
                selectedIcon: CupertinoIcons.settings_solid,
                label: '设置',
              ),
            ],
          ),
          
          // 右侧内容区
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: IndexedStack(
                key: ValueKey(_currentIndex),
                index: _currentIndex,
                children: [
                  _buildTabletSchedulePage(),
                  const CalendarViewScreen(),
                  const SettingsMainScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 手机布局
  Widget _buildPhoneLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: IndexedStack(
              key: ValueKey(_currentIndex),
              index: _currentIndex,
              children: [
                _buildPageWithHeader(0, _buildSchedulePage()),
                _buildPageWithHeader(1, const CalendarViewScreen()),
                _buildPageWithHeader(2, const SettingsMainScreen()),
              ],
            ),
          ),
        ],
      ),
      // 导航栏
      bottomNavigationBar: GlassBottomBar(
        selectedIndex: _currentIndex,
        onTabSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        glassSettings: LiquidGlassSettings(
          glassColor: Colors.black.withValues(alpha: 0.4),
          blur: 30, // [v2.2.9] 增加模糊度提升质量
          thickness: 25, // [v2.2.9] 增加厚度提升质量
          refractiveIndex: 2.0, // [v2.2.9] 增加折射率
        ),
        quality: GlassQuality.premium, // [v2.2.9] 使用 premium 质量提升刷新率
        indicatorColor: AppThemeColors.babyPink.withValues(alpha: 0.3),
        tabs: [
          GlassBottomBarTab(
            icon: CupertinoIcons.square_grid_2x2_fill,
            label: '课程',
          ),
          GlassBottomBarTab(
            icon: CupertinoIcons.calendar,
            label: '日历',
          ),
          GlassBottomBarTab(
            icon: CupertinoIcons.settings_solid,
            label: '设置',
          ),
        ],
      ),
    );
  }
  
  /// 平板模式的课程页面（本周网格视图）
  Widget _buildTabletSchedulePage() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: WeeklyScheduleGrid(), // [v2.2.2] 移除顶部标题横条
      ),
    );
  }

  // [修复4] 周次和星期选择器移到底部（导航栏上方）
  Widget _buildWeekAndDaySelectorWrapper() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 周次选择 - 横向滚动
            SizedBox(
              height: 44,
              child: FutureBuilder<List<int>>(
                future: provider.getAvailableWeeks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final week = snapshot.data![index];
                      final isSelected = week == provider.currentWeek;
                      // [v2.1.8修复3] 使用 Container + BoxShadow 实现圆形光晕
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          decoration: isSelected ? BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeColors.babyPink.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ) : null,
                          child: GlassButton.custom(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              provider.setCurrentWeek(week);
                            },
                            width: 80,
                            height: 44,
                            style: GlassButtonStyle.filled,
                            settings: LiquidGlassSettings(
                              glassColor: isSelected 
                                  ? AppThemeColors.babyPink.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                              blur: 0,
                              thickness: 10,
                            ),
                            shape: LiquidRoundedSuperellipse(borderRadius: 100), // 超椭圆确保圆形光晕
                            child: Center(
                              child: Text(
                                '第$week周',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // [v2.1.8修复6] 星期选择 - 添加模糊效果
            GlassPanel(
              shape: LiquidRoundedSuperellipse(borderRadius: 24), // [v2.1.8] 使用shape设置圆角
              padding: const EdgeInsets.all(8),
              settings: LiquidGlassSettings(
                glassColor: Colors.white.withValues(alpha: 0.03),
                blur: 12, // 添加背景模糊
                thickness: 0.6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = day == provider.currentDay;
                  return Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        decoration: isSelected ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppThemeColors.softCoral.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ) : null,
                        child: GlassButton.custom(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider.setCurrentDay(day);
                          },
                          width: double.infinity,
                          height: 48,
                          style: GlassButtonStyle.filled,
                          settings: LiquidGlassSettings(
                            glassColor: isSelected
                                ? AppThemeColors.softCoral.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            blur: 0,
                            thickness: 10,
                          ),
                          shape: LiquidRoundedSuperellipse(borderRadius: 18),
                          child: Center(
                            child: Text(
                              ['一', '二', '三', '四', '五', '六', '日'][index],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? Colors.white : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageWithHeader(int index, Widget child) {
    return Column(
      children: [
        // 顶部标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 10),
          child: liquid.LiquidCard(
            borderRadius: 24,
            padding: 16,
            glassColor: Colors.white.withValues(alpha: 0.02),
            quality: GlassQuality.standard,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.book_fill,
                  color: AppThemeColors.babyPink,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "CourseWidgets",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                liquid.LiquidCard(
                  borderRadius: 12,
                  padding: 6,
                  styleType: liquid.LiquidStyleType.micro,
                  glassColor: Colors.white.withValues(alpha: 0.1),
                  quality: GlassQuality.standard,
                  child: Text(
                    'v$appVersion',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
        // [修复4] 周次和星期选择器放在底部（导航栏上方）
        if (index == 0) _buildWeekAndDaySelectorWrapper(),
        const SizedBox(height: 80), // 为导航栏留出空间
      ],
    );
  }

  Widget _buildSchedulePage() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final courses = provider.getCurrentDayCourses();
        if (courses.isEmpty) {
          return Center(
            child: Text(
              '今天没有课',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // [v2.2.8修复] 始终启用滚动，移除禁用逻辑
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          physics: const BouncingScrollPhysics(),
          // [v2.2.8修复] 增加缓存范围，防止滚动时降级渲染
          cacheExtent: 200,
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            // [v2.2.8修复] 使用 RepaintBoundary 隔离重绘，防止滚动时玻璃效果消失
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: liquid.LiquidCard(
                  borderRadius: 28,
                  padding: 20,
                  glassColor: Colors.white.withValues(alpha: 0.03),
                  quality: GlassQuality.standard,
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppThemeColors.babyPink.withValues(alpha: 0.8),
                              AppThemeColors.softCoral.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Center(
                          child: Text(
                            course.timeStr.split('-')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              course.location,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            if (course.teacher.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                course.teacher,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // [v2.2.9] 使用自定义 GlassContextMenu
                      GlassContextMenu(
                        items: [
                          GlassContextMenuItem(
                            title: '编辑课程',
                            icon: CupertinoIcons.pencil,
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => CourseEditScreen(course: course),
                                ),
                              );
                            },
                          ),
                          GlassContextMenuItem(
                            title: '删除本节课程',
                            icon: CupertinoIcons.delete,
                            isDestructive: true,
                            onTap: () async {
                              final provider = Provider.of<ScheduleProvider>(context, listen: false);
                              await _importService.deleteCourse(course);
                              await provider.loadSavedData();
                              if (mounted) liquid.showLiquidToast(context, '已删除本节课程');
                            },
                          ),
                          GlassContextMenuItem(
                            title: '删除所有本课程',
                            icon: CupertinoIcons.trash,
                            isDestructive: true,
                            onTap: () async {
                              final provider = Provider.of<ScheduleProvider>(context, listen: false);
                              await _importService.deleteAllCoursesWithName(course.name);
                              await provider.loadSavedData();
                              if (mounted) liquid.showLiquidToast(context, '已删除所有${course.name}课程');
                            },
                          ),
                        ],
                        trigger: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis_vertical,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
