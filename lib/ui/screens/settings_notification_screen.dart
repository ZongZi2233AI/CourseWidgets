import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../constants/theme_constants.dart';
import '../../services/notification_manager.dart';
import '../../utils/glass_settings_helper.dart';
import '../widgets/liquid_components.dart' as liquid;

/// [v2.2.8] 课程通知设置页面
class SettingsNotificationScreen extends StatefulWidget {
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() => _SettingsNotificationScreenState();
}

class _SettingsNotificationScreenState extends State<SettingsNotificationScreen> {
  final NotificationManager _notificationManager = NotificationManager();
  
  bool _notificationEnabled = true;
  int _advanceMinutes = 15;
  bool _doubleReminder = true;
  
  final List<int> _advanceOptions = [5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _notificationEnabled = _notificationManager.isNotificationEnabled;
      _advanceMinutes = _notificationManager.getAdvanceMinutes();
      _doubleReminder = _notificationManager.isDoubleReminderEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const liquid.LiquidBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    '课程通知',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GlassSettingsHelper.getTextColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                // 启用通知
                _buildSwitchCard(
                  title: '启用课程通知',
                  subtitle: '在课程开始前提醒你',
                  icon: CupertinoIcons.bell_fill,
                  value: _notificationEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationEnabled = value);
                    await _notificationManager.setNotificationEnabled(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 提前通知时间
                _buildAdvanceTimeCard(),
                
                const SizedBox(height: 16),
                
                // 双次提醒
                _buildSwitchCard(
                  title: '双次提醒',
                  subtitle: '在上课前 5 分钟再次提醒\n(Android API < 34 和 Windows)',
                  icon: CupertinoIcons.bell_circle_fill,
                  value: _doubleReminder,
                  onChanged: (value) async {
                    setState(() => _doubleReminder = value);
                    await _notificationManager.setDoubleReminder(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Live Activities 说明
                _buildInfoCard(),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return liquid.LiquidCard(
      borderRadius: 24,
      padding: 20,
      glassColor: GlassSettingsHelper.getCardSettings().glassColor,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.babyPink.withValues(alpha: 0.8),
                  AppThemeColors.softCoral.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlassSettingsHelper.getTextColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassSettingsHelper.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppThemeColors.babyPink,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceTimeCard() {
    return liquid.LiquidCard(
      borderRadius: 24,
      padding: 20,
      glassColor: GlassSettingsHelper.getCardSettings().glassColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemeColors.softCoral.withValues(alpha: 0.8),
                      AppThemeColors.paleApricot.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.clock_fill, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '提前通知时间',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GlassSettingsHelper.getTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '在课程开始前多久提醒',
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassSettingsHelper.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _advanceOptions.map((minutes) {
              final isSelected = minutes == _advanceMinutes;
              return GlassButton.custom(
                onTap: () async {
                  setState(() => _advanceMinutes = minutes);
                  await _notificationManager.setAdvanceMinutes(minutes);
                },
                width: 70,
                height: 40,
                style: GlassButtonStyle.filled,
                settings: GlassSettingsHelper.getButtonSettings(
                  isSelected: isSelected,
                  selectedColor: AppThemeColors.softCoral,
                ),
                shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                child: Center(
                  child: Text(
                    '$minutes 分钟',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return liquid.LiquidCard(
      borderRadius: 24,
      padding: 20,
      glassColor: Colors.blue.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle_fill,
                color: Colors.blue.withValues(alpha: 0.8),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Live Activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GlassSettingsHelper.getTextColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Android 14+ 和 iOS/iPadOS/macOS 设备支持 Live Activities 功能，可以在通知栏实时显示课程倒计时。\n\n'
            '• 上课前：显示距离上课的倒计时\n'
            '• 上课中：自动切换为下课倒计时\n'
            '• 实时更新：每分钟自动刷新',
            style: TextStyle(
              fontSize: 13,
              color: GlassSettingsHelper.getSecondaryTextColor(),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
