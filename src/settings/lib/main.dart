import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_providers.dart';
import 'pages/settings_home.dart';
import 'pages/appearance_page.dart';
import 'pages/ai_settings_page.dart';
import 'pages/security_page.dart';
import 'pages/network_page.dart';
import 'pages/display_page.dart';
import 'pages/system_page.dart';
import 'pages/privacy_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ArynoxSettingsApp(),
    ),
  );
}

class ArynoxSettingsApp extends StatelessWidget {
  const ArynoxSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      home: const SettingsShell(),
    );
  }
}

class SettingsShell extends ConsumerWidget {
  const SettingsShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentSettingsPageProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: const Color(0xFF1A1B2E),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _SettingsNavItem(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        selected: currentPage == 'appearance',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'appearance',
                      ),
                      _SettingsNavItem(
                        icon: Icons.display_settings_outlined,
                        label: 'Display',
                        selected: currentPage == 'display',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'display',
                      ),
                      _SettingsNavItem(
                        icon: Icons.wifi_outlined,
                        label: 'Network',
                        selected: currentPage == 'network',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'network',
                      ),
                      _SettingsNavItem(
                        icon: Icons.auto_awesome,
                        label: 'AI',
                        selected: currentPage == 'ai',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'ai',
                      ),
                      _SettingsNavItem(
                        icon: Icons.lock_outlined,
                        label: 'Security',
                        selected: currentPage == 'security',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'security',
                      ),
                      _SettingsNavItem(
                        icon: Icons.visibility_outlined,
                        label: 'Privacy',
                        selected: currentPage == 'privacy',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'privacy',
                      ),
                      _SettingsNavItem(
                        icon: Icons.settings_outlined,
                        label: 'System',
                        selected: currentPage == 'system',
                        onTap: () => ref.read(currentSettingsPageProvider.notifier).state = 'system',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: const Color(0xFF0F1023),
              child: _buildPage(currentPage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(String page) {
    switch (page) {
      case 'appearance':
        return const AppearancePage();
      case 'display':
        return const DisplayPage();
      case 'network':
        return const NetworkPage();
      case 'ai':
        return const AiSettingsPage();
      case 'security':
        return const SecurityPage();
      case 'privacy':
        return const PrivacyPage();
      case 'system':
        return const SystemPage();
      default:
        return const SettingsHomePage();
    }
  }
}

class _SettingsNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF6C5CE7).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? const Color(0xFFA29BFE)
                      : Colors.white54,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
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
