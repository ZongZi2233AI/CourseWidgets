import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../utils/glass_settings_helper.dart';

/// 自定义玻璃上下文菜单
/// 点击触发器显示菜单，点击空白关闭
class GlassContextMenu extends StatelessWidget {
  final List<GlassContextMenuItem> items;
  final Widget trigger;

  const GlassContextMenu({
    super.key,
    required this.items,
    required this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => _showMenu(context), child: trigger);
  }

  void _showMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) => _GlassContextMenuContent(items: items),
    );
  }
}

class _GlassContextMenuContent extends StatelessWidget {
  final List<GlassContextMenuItem> items;

  const _GlassContextMenuContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassContainer(
              shape: const LiquidRoundedSuperellipse(borderRadius: 20),
              settings: GlassSettingsHelper.getDialogSettings(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      _buildMenuItem(context, item),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, GlassContextMenuItem item) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onPressed: () {
        Navigator.pop(context);
        item.onTap();
      },
      child: Row(
        children: [
          Icon(
            item.icon,
            color: item.isDestructive ? Colors.red : Colors.white,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                color: item.isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassContextMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const GlassContextMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}
