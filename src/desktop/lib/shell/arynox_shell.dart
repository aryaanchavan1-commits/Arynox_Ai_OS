import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/shell_state.dart';
import '../core/design/app_colors.dart';
import '../core/widgets/glass_container.dart';
import 'taskbar/taskbar.dart';
import 'dock/dock.dart';
import 'launcher/launcher.dart';
import 'notifications/notification_center.dart';
import 'control_center/control_center.dart';
import 'workspaces/workspace_area.dart';
import 'widgets/desktop_widgets.dart';

class ArynoxShell extends ConsumerStatefulWidget {
  const ArynoxShell({super.key});

  @override
  ConsumerState<ArynoxShell> createState() => _ArynoxShellState();
}

class _ArynoxShellState extends ConsumerState<ArynoxShell>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLauncherOpen = ref.watch(isLauncherOpenProvider);
    final isNotifOpen = ref.watch(isNotificationCenterOpenProvider);
    final isControlOpen = ref.watch(isControlCenterOpenProvider);
    final isAssistantOpen = ref.watch(isAssistantOpenProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Desktop background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F1023),
                        const Color(0xFF1A1B2E),
                        const Color(0xFF151630),
                      ]
                    : [
                        const Color(0xFFE8E8F0),
                        const Color(0xFFF0F0F8),
                        const Color(0xFFE0E0EC),
                      ],
              ),
            ),
          ),

          // Wallpaper layer (handled by compositor/wallpaper daemon)
          // Placeholder wallpaper effect
          Positioned.fill(
            child: CustomPaint(
              painter: _WallpaperOverlayPainter(isDark),
            ),
          ),

          // Desktop widgets
          const Positioned.fill(
            child: DesktopWidgets(),
          ),

          // Workspace area (main content)
          const Positioned.fill(
            child: WorkspaceArea(),
          ),

          // Dock
          const Positioned(
            left: 0,
            right: 0,
            bottom: 56, // Above taskbar
            child: Dock(),
          ),

          // Taskbar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Taskbar(),
          ),

          // Launcher overlay
          if (isLauncherOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => ref.read(isLauncherOpenProvider.notifier).state = false,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
          if (isLauncherOpen)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: ApplicationLauncher(),
            ),

          // Notification center
          if (isNotifOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 56,
              child: NotificationCenter(
                onClose: () => ref.read(isNotificationCenterOpenProvider.notifier).state = false,
              ),
            ),

          // Control center
          if (isControlOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 56,
              child: ControlCenter(
                onClose: () => ref.read(isControlCenterOpenProvider.notifier).state = false,
              ),
            ),

          // AI Assistant overlay
          if (isAssistantOpen)
            Positioned.fill(
              child: _buildAssistantOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildAssistantOverlay() {
    return GestureDetector(
      onTap: () => ref.read(isAssistantOpenProvider.notifier).state = false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GlassContainer(
            width: 640,
            height: 480,
            borderRadius: 24,
            child: Column(
              children: [
                // Assistant header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ArynoxColors.aiGradientStart, ArynoxColors.aiGradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Arynox AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => ref.read(isAssistantOpenProvider.notifier).state = false,
                      ),
                    ],
                  ),
                ),
                // Chat area
                const Expanded(
                  child: Center(
                    child: Text('AI Assistant ready'),
                  ),
                ),
                // Input bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ask anything...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.mic, color: Colors.white70),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: ArynoxColors.primaryLight),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WallpaperOverlayPainter extends CustomPainter {
  final bool isDark;

  _WallpaperOverlayPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDark) return;

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.3),
        radius: 1.0,
        colors: [
          ArynoxColors.primary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _WallpaperOverlayPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
