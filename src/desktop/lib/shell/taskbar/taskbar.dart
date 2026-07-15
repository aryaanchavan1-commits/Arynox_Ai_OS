import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/shell_state.dart';

class Taskbar extends ConsumerWidget {
  const Taskbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVisible = ref.watch(isTaskbarVisibleProvider);
    final time = _formatTime(DateTime.now());

    if (!isVisible) return const SizedBox.shrink();

    return GlassContainer(
      height: 48,
      borderRadius: 0,
      blur: 20,
      child: Row(
        children: [
          // Launcher button
          _TaskbarButton(
            icon: Icons.grid_view_rounded,
            onTap: () => ref.read(isLauncherOpenProvider.notifier).state =
                !ref.read(isLauncherOpenProvider.notifier).state,
          ),

          // Workspace indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // Running apps
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final apps = ref.watch(appRegistryProvider);
                final running = apps.where((a) => a.isRunning).toList();
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: running.length,
                  itemBuilder: (context, index) {
                    final app = running[index];
                    return _TaskbarAppItem(
                      icon: app.icon,
                      name: app.name,
                      active: index == 0,
                    );
                  },
                );
              },
            ),
          ),

          // System tray
          Row(
            children: [
              _TaskbarButton(
                icon: Icons.wifi,
                size: 16,
                onTap: () => ref.read(isControlCenterOpenProvider.notifier).state =
                    !ref.read(isControlCenterOpenProvider.notifier).state,
              ),
              _TaskbarButton(
                icon: Icons.volume_up_outlined,
                size: 16,
                onTap: () {},
              ),
              _TaskbarButton(
                icon: Icons.bluetooth_outlined,
                size: 16,
                onTap: () {},
              ),
            ],
          ),

          // AI Quick Access
          _TaskbarButton(
            icon: Icons.auto_awesome,
            color: ArynoxColors.primaryLight,
            hasGlow: true,
            onTap: () => ref.read(isAssistantOpenProvider.notifier).state =
                !ref.read(isAssistantOpenProvider.notifier).state,
          ),

          // Notification bell
          Stack(
            children: [
              _TaskbarButton(
                icon: Icons.notifications_outlined,
                onTap: () => ref.read(isNotificationCenterOpenProvider.notifier).state =
                    !ref.read(isNotificationCenterOpenProvider.notifier).state,
              ),
              Consumer(
                builder: (context, ref, _) {
                  final count = ref.watch(notificationManagerProvider).length;
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: ArynoxColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Clock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : ArynoxColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : ArynoxColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TaskbarButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool hasGlow;
  final VoidCallback onTap;

  const _TaskbarButton({
    required this.icon,
    this.size = 20,
    this.color,
    this.hasGlow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: size,
              color: color ?? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : ArynoxColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskbarAppItem extends StatefulWidget {
  final IconData icon;
  final String name;
  final bool active;

  const _TaskbarAppItem({
    required this.icon,
    required this.name,
    this.active = false,
  });

  @override
  State<_TaskbarAppItem> createState() => _TaskbarAppItemState();
}

class _TaskbarAppItemState extends State<_TaskbarAppItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          onEnter: (_) {},
          onExit: (_) {},
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                bottom: BorderSide(
                  color: widget.active ? ArynoxColors.primaryLight : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : ArynoxColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
