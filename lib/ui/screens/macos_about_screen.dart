import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import '../../constants/version.dart';

// 常量定义
const String appName = "CourseWidgets";
const String versionText = "v$appVersion";

/// macOS端的关于软件页面 - 使用原生macOS设计
class MacOSSAboutScreen extends StatelessWidget {
  const MacOSSAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('关于软件'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 应用图标和标题 - macOS风格
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: material.AssetImage('assets/icon.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey3.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "CourseWidgets",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '版本 v$appVersion',
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 开发者信息卡片
              _buildInfoCard('开发者', 'ZongZi', CupertinoIcons.person_solid),

              const SizedBox(height: 16),

              // 技术栈卡片
              _buildInfoCard(
                '技术栈',
                'Flutter 3.40.0\nDart 3.11.0\nImpeller 渲染引擎\nCupertino UI (macOS原生)',
                CupertinoIcons.book_solid,
              ),

              const SizedBox(height: 16),

              // 版权信息卡片
              _buildInfoCard('版权信息', copyright, CupertinoIcons.info_circle),

              const SizedBox(height: 32),

              // 底部构建信息
              Center(
                child: Text(
                  'Build $buildNumber | v$appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 通用信息卡片
  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey3.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: CupertinoColors.systemBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
