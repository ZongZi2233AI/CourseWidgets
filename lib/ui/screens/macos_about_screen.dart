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
              _buildInfoCard(
                '开发者',
                'ZongZi',
                CupertinoIcons.person_solid,
              ),
              
              const SizedBox(height: 16),
              
              // 技术栈卡片
              _buildInfoCard(
                '技术栈',
                'Flutter 3.40.0\nDart 3.11.0\nImpeller 渲染引擎\nCupertino UI (macOS原生)',
                CupertinoIcons.book_solid,
              ),
              
              const SizedBox(height: 16),
              
              
              
              
              // 版权信息卡片
              _buildInfoCard(
                '版权信息',
                copyright,
                CupertinoIcons.info_circle,
              ),
              
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
            child: Icon(
              icon,
              size: 20,
              color: CupertinoColors.systemBlue,
            ),
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

  /// 功能特性卡片
  Widget _buildFeatureCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.star_circle,
                  size: 20,
                  color: CupertinoColors.systemOrange,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '功能特性',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureItem('跨平台支持', 'Windows / Android / macOS / Web'),
          const SizedBox(height: 8),
          _buildFeatureItem('智能课表管理', '周次选择 / 星期切换 / 自动跳转'),
          const SizedBox(height: 8),
          _buildFeatureItem('数据导入导出', 'ICS / HTML / JSON 格式支持'),
          const SizedBox(height: 8),
          _buildFeatureItem('本地课程编辑', '添加 / 编辑 / 删除课程'),
          const SizedBox(height: 8),
          _buildFeatureItem('历史记录管理', '多版本保存 / 切换 / 导出'),
          const SizedBox(height: 8),
          _buildFeatureItem('课时配置', '自定义时间 / 预设模板 / 自动保存'),
          const SizedBox(height: 8),
          _buildFeatureItem('macOS原生体验', 'Cupertino UI / 原生设计规范'),
        ],
      ),
    );
  }

  /// 功能特性项
  Widget _buildFeatureItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 56),
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
