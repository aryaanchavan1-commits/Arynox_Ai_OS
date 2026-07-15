import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemPage extends ConsumerWidget {
  const SystemPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text('System', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        _Section(title: 'About', children: [
          _InfoRow(label: 'OS', value: 'Arynox OS 0.1.0'),
          _InfoRow(label: 'Kernel', value: 'Linux 6.6-arynox'),
          _InfoRow(label: 'Architecture', value: 'x86_64'),
          _InfoRow(label: 'Device Name', value: 'Arynox Desktop'),
          _InfoRow(label: 'Uptime', value: '2h 34m'),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Updates', children: [
          _InfoRow(label: 'Current Version', value: '0.1.0'),
          _InfoRow(label: 'Latest Version', value: '0.1.0'),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Check for Updates'),
          )),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Language & Input', children: [
          _DropdownTile(label: 'Language', value: 'English', items: ['English', 'Spanish', 'French', 'German', 'Japanese']),
          _DropdownTile(label: 'Input Method', value: 'System Keyboard', items: ['System Keyboard', 'IBus', 'Fcitx']),
          _SwitchTile(label: 'Spell Check', value: true),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Developer Mode', children: [
          _SwitchTile(label: 'Developer Mode', value: false),
          _SwitchTile(label: 'Enable SSH', value: false),
          _SwitchTile(label: 'ADB Debugging', value: false),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Power', children: [
          _DropdownTile(label: 'Power Profile', value: 'Balanced', items: ['Power Saver', 'Balanced', 'Performance']),
          _SwitchTile(label: 'Suspend on Lid Close', value: true),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label; final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.white60)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 14, color: Colors.white)),
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

class _DropdownTile extends StatelessWidget {
  final String label; final String value; final List<String> items;
  const _DropdownTile({required this.label, required this.value, required this.items});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFF0F1023), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: const Color(0xFF1A1B2E),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: (_) {},
        )),
      ),
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
