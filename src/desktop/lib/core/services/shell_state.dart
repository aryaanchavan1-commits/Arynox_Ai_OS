import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_info.dart';
import '../models/notification.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final isTaskbarVisibleProvider = StateProvider<bool>((ref) => true);
final isDockVisibleProvider = StateProvider<bool>((ref) => true);
final isLauncherOpenProvider = StateProvider<bool>((ref) => false);
final isNotificationCenterOpenProvider = StateProvider<bool>((ref) => false);
final isControlCenterOpenProvider = StateProvider<bool>((ref) => false);
final isAssistantOpenProvider = StateProvider<bool>((ref) => false);

final currentWorkspaceProvider = StateProvider<int>((ref) => 0);
final workspaceCountProvider = StateProvider<int>((ref) => 4);

final searchQueryProvider = StateProvider<String>((ref) => '');

class AppRegistry extends StateNotifier<List<AppInfo>> {
  AppRegistry() : super(_defaultApps);

  static final List<AppInfo> _defaultApps = [
    AppInfo(
      id: 'com.arynox.files',
      name: 'Files',
      icon: Icons.folder_outlined,
      executable: '/usr/lib/arynox/arynox-files',
      categories: ['System', 'Utilities'],
      isFavorite: true,
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.settings',
      name: 'Settings',
      icon: Icons.settings_outlined,
      executable: '/usr/lib/arynox/arynox-settings',
      categories: ['System'],
      isFavorite: true,
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.software',
      name: 'Software Center',
      icon: Icons.store_outlined,
      executable: '/usr/lib/arynox/arynox-software',
      categories: ['System'],
      isFavorite: true,
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.terminal',
      name: 'Terminal',
      icon: Icons.terminal,
      executable: '/usr/bin/kgx',
      categories: ['Utilities', 'Development'],
      isFavorite: true,
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.browser',
      name: 'Browser',
      icon: Icons.language,
      executable: '/usr/bin/firefox',
      categories: ['Network', 'Internet'],
      isFavorite: true,
    ),
    AppInfo(
      id: 'com.arynox.music',
      name: 'Music',
      icon: Icons.music_note_outlined,
      executable: '/usr/lib/arynox/arynox-music',
      categories: ['Audio', 'Entertainment'],
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.video',
      name: 'Videos',
      icon: Icons.videocam_outlined,
      executable: '/usr/lib/arynox/arynox-video',
      categories: ['Video', 'Entertainment'],
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.camera',
      name: 'Camera',
      icon: Icons.camera_alt_outlined,
      executable: '/usr/lib/arynox/arynox-camera',
      categories: ['Multimedia'],
      isSystemApp: true,
    ),
    AppInfo(
      id: 'com.arynox.device-manager',
      name: 'Device Manager',
      icon: Icons.devices_outlined,
      executable: '/usr/lib/arynox/arynox-devices',
      categories: ['System'],
      isSystemApp: true,
    ),
  ];

  void toggleFavorite(String appId) {
    state = state.map((app) {
      if (app.id == appId) {
        return app.copyWith(isFavorite: !app.isFavorite);
      }
      return app;
    }).toList();
  }

  void setRunning(String appId, bool running) {
    state = state.map((app) {
      if (app.id == appId) {
        return app.copyWith(isRunning: running);
      }
      return app;
    }).toList();
  }
}

final appRegistryProvider = StateNotifierProvider<AppRegistry, List<AppInfo>>((ref) {
  return AppRegistry();
});

class NotificationManager extends StateNotifier<List<ArynoxNotification>> {
  NotificationManager() : super([]);

  void addNotification(ArynoxNotification notification) {
    state = [notification, ...state];
  }

  void dismissNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationManagerProvider =
    StateNotifierProvider<NotificationManager, List<ArynoxNotification>>((ref) {
  return NotificationManager();
});
