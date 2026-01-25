import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../providers/schedule_provider.dart';
import '../../models/course_event.dart';
import '../../constants/version.dart';
import '../../constants/theme_constants.dart';
import '../../services/live_notification_service_v2.dart';
import '../../utils/responsive_utils.dart';
import 'course_edit_screen.dart';
import 'calendar_view_screen.dart';
import 'settings_main_screen.dart';
import '../widgets/liquid_components.dart' as liquid;
import '../widgets/tablet_sidebar.dart';
import '../widgets/weekly_schedule_grid.dart';

class AndroidLiquidGlassMain extends StatefulWidget {
  const AndroidLiquidGlassMain({super.key});
  @override
  State<AndroidLiquidGlassMain> createState() => _AndroidLiquidGlassMainState();
}

class _AndroidLiquidGlassMainState extends State<AndroidLiquidGlassMain> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
          // 显示课程详情对话框
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showCourseDetailDialog(course);
            }
          });
        }
      });
      
      // 获取下一节课并启动实时通知
      final nextCourse = provider.getNextCourse();
      await liveService.startLiveUpdate(nextCourse);
    });
  }
  
  @override
  void dispose() {
    // 停止通知服务
    LiveNotificationServiceV2().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          blur: 20,
          thickness: 15,
        ),
        quality: GlassQuality.standard,
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
                const Text(
                  "CourseWidgets",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
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

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: liquid.LiquidCard(
                borderRadius: 28,
                padding: 20,
                glassColor: Colors.white.withValues(alpha: 0.03),
                quality: GlassQuality.standard,
                onTap: () => _showCourseDetailDialog(course),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // [修复2] Dialog 使用更大的圆角
  void _showCourseDetailDialog(CourseEvent course) {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '课程详情',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('课程', course.name),
            const SizedBox(height: 8),
            _buildDetailRow('地点', course.location),
            const SizedBox(height: 8),
            _buildDetailRow('时间', course.timeStr),
          ],
        ),
        actions: [
          GlassDialogAction(
            label: '编辑',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseEditScreen(course: course),
                ),
              );
            },
          ),
          GlassDialogAction(
            label: '关闭',
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
