import 'package:flutter/material.dart';

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'System Settings',
            style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a category from the sidebar',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }
}
