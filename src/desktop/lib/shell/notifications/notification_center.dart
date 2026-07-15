import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/models/notification.dart';
import '../../core/services/shell_state.dart';
import '../../core/widgets/glass_container.dart';

class NotificationCenter extends ConsumerWidget {
  final VoidCallback onClose;

  const NotificationCenter({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = ref.watch(notificationManagerProvider);

    return GlassContainer(
      width: 360,
      blur: 20,
      borderRadius: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(notificationManagerProvider.notifier).clearAll(),
                  child: const Text('Clear All'),
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Do Not Disturb toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.do_not_disturb_alt_outlined, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                const Text('Do Not Disturb', style: TextStyle(fontSize: 13)),
                const Spacer(),
                Switch(value: false, onChanged: (_) {}),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notification list
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _NotificationItem(
                        notification: notif,
                        onDismiss: () =>
                            ref.read(notificationManagerProvider.notifier).dismissNotification(notif.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final ArynoxNotification notification;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onDismiss,
  });

  Color _priorityColor() {
    switch (notification.priority) {
      case NotificationPriority.low:
        return ArynoxColors.notificationLow;
      case NotificationPriority.normal:
        return ArynoxColors.notificationNormal;
      case NotificationPriority.urgent:
        return ArynoxColors.notificationUrgent;
      case NotificationPriority.critical:
        return ArynoxColors.notificationCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _priorityColor(),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.icon != null)
            Icon(
              notification.icon,
              size: 20,
              color: Colors.white70,
            ),
          if (notification.icon != null) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.actionLabel != null) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: notification.action,
                    child: Text(
                      notification.actionLabel!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (notification.isDismissible)
            IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: onDismiss,
              color: Colors.white38,
            ),
        ],
      ),
    );
  }
}
