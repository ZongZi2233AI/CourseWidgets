import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import '../../constants/theme_constants.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart' as theme;
import '../../main.dart'; 
import '../widgets/liquid_components.dart' as liquid;

class SettingsGeneralScreen extends StatefulWidget {
  const SettingsGeneralScreen({super.key});
  @override
  State<SettingsGeneralScreen> createState() => _SettingsGeneralScreenState();
}

class _SettingsGeneralScreenState extends State<SettingsGeneralScreen> {
  final StorageService _storage = StorageService();
  final theme.ThemeService _themeService = theme.ThemeService();
  
  bool _adaptiveDarkMode = false;
  theme.ThemeMode _currentThemeMode = theme.ThemeMode.defaultMode;

  bool get _isDarkMode {
    if (_adaptiveDarkMode) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return globalUseDarkMode;
  }
  
  Color get _textColor => _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
  Color get _textSecondaryColor => _isDarkMode ? Colors.white70 : const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final darkMode = _storage.getBool(StorageService.keyDarkMode) ?? false;
    final adaptiveMode = _storage.getBool(StorageService.keyAdaptiveDarkMode) ?? false;
    
    setState(() {
      globalUseDarkMode = darkMode;
      _adaptiveDarkMode = adaptiveMode;
      _currentThemeMode = _themeService.themeMode;
    });
  }

  void _toggleDarkMode(bool value) async {
    setState(() {
      globalUseDarkMode = value;
      if (value) _adaptiveDarkMode = false; 
    });
    await _storage.setBool(StorageService.keyDarkMode, value);
    if (value) {
      await _storage.setBool(StorageService.keyAdaptiveDarkMode, false);
    }
  }

  void _toggleAdaptiveMode(bool value) async {
    setState(() {
      _adaptiveDarkMode = value;
      if (value) globalUseDarkMode = false; 
    });
    await _storage.setBool(StorageService.keyAdaptiveDarkMode, value);
    if (value) {
      await _storage.setBool(StorageService.keyDarkMode, false);
    }
  }

  Future<void> _pickBackgroundImage() async {
    try {
      if (Platform.isAndroid) {
        // Android 14+ Photo Picker（不需要权限）
        const platform = MethodChannel('com.zongzi.schedule/image_picker');
        final String? imagePath = await platform.invokeMethod('pickImage');
        
        if (imagePath != null) {
          globalBackgroundPath.value = imagePath;
          await _storage.setString(StorageService.keyBackgroundPath, imagePath);
          
          // 如果是莫奈取色模式，立即提取颜色
          if (_currentThemeMode == theme.ThemeMode.monet) {
            await _themeService.extractColorsFromImage(imagePath);
            setState(() {});
          }
          
          if (mounted) _showToast('背景设置成功');
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Windows/macOS/Linux 使用 file_selector
        final XFile? file = await openFile(
          acceptedTypeGroups: [
            const XTypeGroup(
              label: '图片',
              extensions: ['jpg', 'jpeg', 'png', 'bmp', 'webp'],
            ),
          ],
        );
        
        if (file != null) {
          globalBackgroundPath.value = file.path;
          await _storage.setString(StorageService.keyBackgroundPath, file.path);
          
          // 如果是莫奈取色模式，立即提取颜色
          if (_currentThemeMode == theme.ThemeMode.monet) {
            await _themeService.extractColorsFromImage(file.path);
            setState(() {});
          }
          
          if (mounted) _showToast('背景设置成功');
        }
      } else {
        _showToast('当前平台不支持');
      }
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED') {
        if (mounted) _showToast('需要 Android 14+');
      } else if (e.code == 'CANCELLED') {
        // 用户取消，不显示错误
      } else {
        if (mounted) _showToast('选择图片失败: ${e.message}');
      }
    } catch (e) {
      if (mounted) _showToast('选择图片失败: $e');
    }
  }

  void _showThemeModeDialog() {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(
        title: '主题色设置',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeModeOption(
              theme.ThemeMode.defaultMode,
              '默认主题',
              '使用应用默认的嫩粉色主题',
              CupertinoIcons.paintbrush,
            ),
            const SizedBox(height: 12),
            if (Platform.isAndroid) ...[
              _buildThemeModeOption(
                theme.ThemeMode.system,
                '系统主题',
                'Android 12+ Material You 动态颜色',
                CupertinoIcons.device_phone_portrait,
              ),
              const SizedBox(height: 12),
            ],
            _buildThemeModeOption(
              theme.ThemeMode.monet,
              '莫奈取色',
              '从背景图片提取主题色',
              CupertinoIcons.photo,
            ),
          ],
        ),
        actions: [
          GlassDialogAction(
            label: '关闭',
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeOption(theme.ThemeMode mode, String title, String subtitle, IconData icon) {
    final isSelected = _currentThemeMode == mode;
    
    return GestureDetector(
      onTap: () async {
        setState(() => _currentThemeMode = mode);
        await _themeService.setThemeMode(mode);
        
        if (mode == theme.ThemeMode.system && Platform.isAndroid && mounted) {
          await _themeService.applySystemTheme(context);
        } else if (mode == theme.ThemeMode.monet && globalBackgroundPath.value != null) {
          await _themeService.extractColorsFromImage(globalBackgroundPath.value!);
        }
        
        setState(() {});
        if (mounted) Navigator.pop(context);
        _showToast('主题已切换');
      },
      child: liquid.LiquidCard(
        borderRadius: 16,
        padding: 12,
        glassColor: isSelected 
            ? AppThemeColors.babyPink.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeColors.babyPink.withValues(alpha: 0.3),
                    AppThemeColors.softCoral.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: AppThemeColors.babyPink,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg) {
    if (mounted) liquid.showLiquidToast(context, msg);
  }

  void _showAlert(String title, String content) {
    liquid.showLiquidDialog(
      context: context,
      builder: liquid.LiquidGlassDialog(title: title, content: Text(content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('通用设置', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(CupertinoIcons.back, color: _textColor), onPressed: () => Navigator.pop(context)),
      ),
      body: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          thickness: 0.8,
          blur: 12.0,
          glassColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('外观'),
              _buildSwitchCard('自适应深色模式', '跟随系统设置', _adaptiveDarkMode, _toggleAdaptiveMode),
              const SizedBox(height: 12),
              
              IgnorePointer(
                ignoring: _adaptiveDarkMode,
                child: _buildSwitchCard(
                  '强制深色模式', 
                  '手动覆盖系统设置', 
                  globalUseDarkMode, 
                  _toggleDarkMode,
                  disabled: _adaptiveDarkMode,
                ),
              ),
              
              const SizedBox(height: 20),
              _buildSection('主题色'),
              _buildActionCard(
                '主题色设置', 
                CupertinoIcons.color_filter, 
                _showThemeModeDialog,
                subtitle: _getThemeModeText(),
              ),
              
              const SizedBox(height: 20),
              _buildSection('个性化'),
              _buildActionCard('更换背景图片', CupertinoIcons.photo, _pickBackgroundImage),
              const SizedBox(height: 10),
              _buildActionCard('恢复默认背景', CupertinoIcons.arrow_counterclockwise, () async {
                globalBackgroundPath.value = null;
                await _storage.remove(StorageService.keyBackgroundPath);
                _showAlert('已恢复', '背景已恢复默认渐变');
              }),
              
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeModeText() {
    switch (_currentThemeMode) {
      case theme.ThemeMode.defaultMode:
        return '默认主题';
      case theme.ThemeMode.system:
        return '系统主题';
      case theme.ThemeMode.monet:
        return '莫奈取色';
    }
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: TextStyle(color: _textSecondaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchCard(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: liquid.LiquidCard(
        onTap: () => onChanged(!value),
        glassColor: Colors.white.withValues(alpha: 0.04),
        padding: 16,
        borderRadius: 20,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _textColor.withValues(alpha: disabled ? 0.5 : 1.0), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: _textSecondaryColor.withValues(alpha: disabled ? 0.5 : 1.0), fontSize: 12)),
                ],
              ),
            ),
            liquid.LiquidSwitch(value: value, onChanged: disabled ? (v){} : onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap, {String? subtitle}) {
    return liquid.LiquidCard(
      onTap: onTap,
      glassColor: Colors.white.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppThemeColors.babyPink),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: _textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(CupertinoIcons.right_chevron, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
