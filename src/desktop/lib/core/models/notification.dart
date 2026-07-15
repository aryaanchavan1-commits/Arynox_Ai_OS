import 'package:flutter/material.dart';

enum NotificationPriority { low, normal, urgent, critical }

class ArynoxNotification {
  final String id;
  final String appId;
  final String title;
  final String body;
  final IconData? icon;
  final DateTime timestamp;
  final NotificationPriority priority;
  final String? actionLabel;
  final VoidCallback? action;
  final bool isDismissible;
  final bool isSilent;

  const ArynoxNotification({
    required this.id,
    required this.appId,
    required this.title,
    required this.body,
    this.icon,
    DateTime? timestamp,
    this.priority = NotificationPriority.normal,
    this.actionLabel,
    this.action,
    this.isDismissible = true,
    this.isSilent = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
