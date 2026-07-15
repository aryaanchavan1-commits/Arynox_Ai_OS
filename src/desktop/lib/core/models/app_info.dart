import 'package:flutter/material.dart';

class AppInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String executable;
  final List<String> categories;
  final bool isFavorite;
  final bool isRunning;
  final bool isSystemApp;

  const AppInfo({
    required this.id,
    required this.name,
    this.description = '',
    required this.icon,
    required this.executable,
    this.categories = const [],
    this.isFavorite = false,
    this.isRunning = false,
    this.isSystemApp = false,
  });

  AppInfo copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    String? executable,
    List<String>? categories,
    bool? isFavorite,
    bool? isRunning,
    bool? isSystemApp,
  }) {
    return AppInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      executable: executable ?? this.executable,
      categories: categories ?? this.categories,
      isFavorite: isFavorite ?? this.isFavorite,
      isRunning: isRunning ?? this.isRunning,
      isSystemApp: isSystemApp ?? this.isSystemApp,
    );
  }
}
