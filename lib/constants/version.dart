import 'dart:io';
import 'package:flutter/material.dart';

/// 当前版本：[v2.5.3] Full Slide Transitions, Windows UX, Live Update
const String appVersion = '2.5.6';
const int buildNumber = 10005003;
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
