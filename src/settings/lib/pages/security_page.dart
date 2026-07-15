import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text('Security', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        _Section(title: 'Encryption', children: [
          _StatusTile(label: 'Disk Encryption', status: 'Active', color: Colors.green),
          _StatusTile(label: 'Secure Boot', status: 'Enabled', color: Colors.green),
          _StatusTile(label: 'TPM', status: 'Available', color: Colors.green),
          _SwitchTile(label: 'Encrypt API Keys', value: true),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Authentication', children: [
          _SwitchTile(label: 'Password on Wake', value: true),
          _SwitchTile(label: 'Fingerprint Login', value: true),
          _SwitchTile(label: 'Automatic Lock', value: true),
          _DropdownTile(label: 'Lock After', value: '5 Minutes', items: ['1 Minute', '5 Minutes', '15 Minutes', '30 Minutes', '1 Hour']),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Firewall', children: [
          _StatusTile(label: 'Firewall', status: 'Active', color: Colors.green),
          _SwitchTile(label: 'Block Inbound Connections', value: true),
          _SwitchTile(label: 'Allow Ping', value: false),
        ]),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label; final String status; final Color color;
  const _StatusTile({required this.label, required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(fontSize: 12, color: color)),
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
