import 'dart:io';
import 'package:flutter/material.dart';

/// 当前版本：[v2.6.0.beta27] 完美解决安卓侧滑返回双弹及缺失模糊与进入动画问题，解决移动端教务导入卡加载循环问题
const String appVersion = '2.6.0.beta27';
const int buildNumber = 10008027;
const String copyright = '© 2025-2026 CourseWidgets. All rights reserved.';

// 全局状态
bool globalUseDarkMode = false;
ValueNotifier<String?> globalBackgroundPath = ValueNotifier<String?>(null);

// 全局背景加载
Future<void> loadGlobalBackground() async {
  try {
    final appDir = Directory(
      '/data/data/com.zongzi.schedule/app_flutter/backgrounds',
    );
    if (await appDir.exists()) {
      final files = await appDir.list().toList();
      for (var file in files) {
        if (file.path.endsWith('.png')) {
          globalBackgroundPath.value = file.path;
          break;
        }
      }
    }
  } catch (_) {}
}
