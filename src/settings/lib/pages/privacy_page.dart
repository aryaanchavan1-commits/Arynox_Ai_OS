import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text('Privacy', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        _Section(title: 'Permissions', children: [
          _PermTile(label: 'Camera', enabled: false),
          _PermTile(label: 'Microphone', enabled: true),
          _PermTile(label: 'Location', enabled: false),
          _PermTile(label: 'Notifications', enabled: true),
          _PermTile(label: 'USB Devices', enabled: true),
          _PermTile(label: 'File System', enabled: true),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Telemetry', children: [
          _SwitchTile(label: 'Send Anonymous Usage Data', value: false),
          _SwitchTile(label: 'Send Crash Reports', value: true),
          _SwitchTile(label: 'AI Usage Collection', value: false),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Data & Storage', children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Clear AI Conversation History', style: TextStyle(color: Colors.white70, fontSize: 14)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            title: const Text('Reset All Permissions', style: TextStyle(color: Colors.white70, fontSize: 14)),
            onTap: () {},
          ),
        ]),
      ],
    );
  }
}

class _PermTile extends StatelessWidget {
  final String label; final bool enabled;
  const _PermTile({required this.label, required this.enabled});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: enabled ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6)),
        child: Text(enabled ? 'Allowed' : 'Denied',
          style: TextStyle(fontSize: 12, color: enabled ? Colors.green : Colors.redAccent)),
      ),
    ]),
  );
}

class _SwitchTile extends StatelessWidget {
  final String label; final bool value;
  const _SwitchTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70))),
      Switch(value: value, onChanged: (_) {}, activeColor: const Color(0xFF6C5CE7)),
    ]),
  );
}

class _Section extends StatelessWidget {
  final String title; final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
    const SizedBox(height: 12),
    Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1B2E), borderRadius: BorderRadius.circular(16)),
      child: Column(children: children)),
  ]);
}
