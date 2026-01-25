# Android 16 Live Updates 实时通知实现文档

## 版本信息
- **版本号**: 2.1.11 (10002111)
- **实现日期**: 2025-01-23
- **目标平台**: Android 14+

## 功能概述

实现了类似 iOS 灵动岛的 Android 16 Live Updates 实时通知功能，提供课程倒计时和实时提醒。

## 核心特性

### 1. 实时更新机制
- ✅ 每分钟自动更新通知内容
- ✅ 常驻通知栏（ongoing notification）
- ✅ 无法通过滑动关闭
- ✅ 进度条显示课程进度/倒计时

### 2. 四种通知状态

#### 状态 1: 即将上课（> 60分钟）
```
标题: ⏰ 下节课
内容: [课程名称]
详情: [地点] · [开始时间]
进度: 0%
```

#### 状态 2: 即将开始（20-60分钟）
```
标题: ⏰ 即将开始
内容: [课程名称]
详情: [地点] · 还有 X 分钟
进度: (60-X)/60 * 100%
```

#### 状态 3: 马上开始（0-20分钟）
```
标题: 🔔 马上开始
内容: [课程名称]
详情: [地点] · 还有 X 分钟！
进度: (20-X)/20 * 100%
```

#### 状态 4: 正在上课
```
标题: 📚 正在上课
内容: [课程名称]
详情: [地点] · 还有 X 分钟下课
进度: 已上课时间/总时长 * 100%
```

### 3. 交互功能

#### 通知点击
- 点击通知本体 → 跳转到课程详情页面
- 自动切换到课程页面
- 显示课程详情对话框

#### 操作按钮
1. **查看详情** - 跳转到课程详情
2. **关闭** - 停止实时通知服务

### 4. 视觉设计

#### 颜色主题
- 主色调: 嫩粉色 (#FF9A9E)
- 通知着色: colorized = true
- LED 灯光: 嫩粉色

#### 通知样式
- BigTextStyle: 支持多行文本
- 进度条: 实时显示课程进度
- 图标: 使用应用图标

## 技术实现

### 文件结构
```
lib/services/
  └── live_notification_service_v2.dart  # 核心服务实现

lib/ui/screens/
  └── android_liquid_glass_main.dart     # 主界面集成
```

### 核心代码

#### 1. 服务初始化
```dart
final liveService = LiveNotificationServiceV2();
await liveService.initialize();
```

#### 2. 设置点击回调
```dart
liveService.setOnNotificationTapCallback((course) {
  // 处理通知点击事件
  setState(() => _currentIndex = 0);
  _showCourseDetailDialog(course);
});
```

#### 3. 启动实时更新
```dart
final nextCourse = provider.getNextCourse();
await liveService.startLiveUpdate(nextCourse);
```

#### 4. 停止服务
```dart
await liveService.dispose();
```

### 通知通道配置
```dart
AndroidNotificationChannel(
  'live_course_updates',
  '课程实时提醒',
  description: 'Android 16 实时课程倒计时和提醒',
  importance: Importance.high,
  playSound: false,
  enableVibration: false,
  showBadge: true,
  enableLights: true,
  ledColor: Color(0xFFFF9A9E),
)
```

### 通知详情配置
```dart
AndroidNotificationDetails(
  ongoing: true,              // 常驻通知
  autoCancel: false,          // 不自动取消
  onlyAlertOnce: true,        // 只提醒一次
  showProgress: true,         // 显示进度条
  visibility: NotificationVisibility.public,
  color: Color(0xFFFF9A9E),   // 嫩粉色
  colorized: true,            // 着色
  styleInformation: BigTextStyleInformation(...),
  actions: [
    AndroidNotificationAction('view_details', '查看详情'),
    AndroidNotificationAction('dismiss', '关闭'),
  ],
)
```

## 权限要求

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

### 运行时权限
```dart
final status = await Permission.notification.request();
if (status.isDenied) {
  debugPrint('❌ 通知权限被拒绝');
  return;
}
```

## 依赖包

```yaml
dependencies:
  flutter_local_notifications: ^17.2.3
  permission_handler: ^11.3.1
```

## 测试清单

### 功能测试
- [ ] 通知正常显示
- [ ] 每分钟自动更新
- [ ] 进度条正确显示
- [ ] 四种状态切换正常
- [ ] 点击通知跳转正确
- [ ] 查看详情按钮工作
- [ ] 关闭按钮工作
- [ ] 常驻通知无法滑动关闭

### 边界测试
- [ ] 无课程时不显示通知
- [ ] 课程结束后自动取消
- [ ] 应用退出后通知保持
- [ ] 应用重启后通知恢复
- [ ] 权限被拒绝时的处理

### 性能测试
- [ ] 定时器不泄漏
- [ ] 内存占用正常
- [ ] 电池消耗可接受
- [ ] 通知更新流畅

## 已知问题

### 1. 通知权限
- Android 13+ 需要运行时请求通知权限
- 用户拒绝后需要引导到设置页面

### 2. 精确闹钟权限
- Android 14+ 可能需要 SCHEDULE_EXACT_ALARM 权限
- 部分设备可能限制后台定时器

### 3. 电池优化
- 部分设备的电池优化可能影响定时器
- 需要引导用户关闭电池优化

## 优化建议

### 短期优化
1. 添加通知音效（可选）
2. 添加震动反馈（可选）
3. 支持自定义通知颜色
4. 支持自定义更新频率

### 长期优化
1. 使用 WorkManager 替代 Timer（更省电）
2. 支持多课程同时提醒
3. 添加课程提前提醒功能
4. 支持通知样式自定义

## 调试日志

### 关键日志标记
```dart
✅ Android 16 Live Updates 通知服务初始化完成
🚀 实时通知已启动: [课程名称]
📱 通知被点击: [payload]
📖 跳转到课程详情: [payload]
🛑 实时通知已取消
🛑 用户手动关闭通知
❌ 通知权限被拒绝
```

### 调试命令
```bash
# 查看通知日志
adb logcat | grep "LiveNotification"

# 查看通知通道
adb shell dumpsys notification

# 测试通知权限
adb shell pm grant com.example.schedule_app android.permission.POST_NOTIFICATIONS
```

## 参考资料

- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Android Notifications Guide](https://developer.android.com/develop/ui/views/notifications)
- [Android 16 Live Updates](https://developer.android.com/about/versions/16/features#live-updates)
- [Permission Handler](https://pub.dev/packages/permission_handler)

## 更新日志

### v2.1.11 (2025-01-23)
- ✅ 实现 Android 16 Live Updates 基础功能
- ✅ 实现四种通知状态
- ✅ 实现通知点击跳转
- ✅ 实现操作按钮功能
- ✅ 实现每分钟自动更新
- ✅ 实现常驻通知
- ✅ 实现进度条显示
- ✅ 集成到主界面

---

**文档版本**: 1.0  
**最后更新**: 2025-01-23  
**维护者**: CourseWidgets Team
