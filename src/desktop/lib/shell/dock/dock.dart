import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/shell_state.dart';
import '../../core/models/app_info.dart';

class Dock extends ConsumerWidget {
  const Dock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVisible = ref.watch(isDockVisibleProvider);
    final apps = ref.watch(appRegistryProvider);
    final favorites = apps.where((a) => a.isFavorite).toList();

    if (!isVisible || favorites.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final app in favorites) ...[
                _DockItem(app: app),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatefulWidget {
  final AppInfo app;

  const _DockItem({required this.app});

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _isHovered ? 52 : 44,
          height: _isHovered ? 52 : 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(_isHovered ? 14 : 12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.app.icon,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : ArynoxColors.textPrimaryLight,
              ),
              if (widget.app.isRunning)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: ArynoxColors.primaryLight,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
