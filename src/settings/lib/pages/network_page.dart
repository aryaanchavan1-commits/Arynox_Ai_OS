import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkPage extends ConsumerWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text('Network', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        _Section(title: 'Wi-Fi', children: [
          _SwitchTile(label: 'Wi-Fi', value: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F1023), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _NetworkItem(name: 'Home Network', secured: true, signal: 4),
              _NetworkItem(name: 'Neighbor WiFi', secured: true, signal: 2),
              _NetworkItem(name: 'Public Hotspot', secured: false, signal: 3),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Bluetooth', children: [
          _SwitchTile(label: 'Bluetooth', value: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F1023), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _BTItem(name: 'Keyboard K380', connected: true),
              _BTItem(name: 'AirPods Pro', connected: false),
              _BTItem(name: 'MX Master 3', connected: true),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'VPN', children: [
          _SwitchTile(label: 'VPN', value: false),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, child: const Text('Add VPN Connection'))),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Proxy', children: [
          _SwitchTile(label: 'System Proxy', value: false),
        ]),
      ],
    );
  }
}

class _NetworkItem extends StatelessWidget {
  final String name; final bool secured; final int signal;
  const _NetworkItem({required this.name, required this.secured, required this.signal});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(Icons.wifi, size: 20, color: Colors.white54),
      const SizedBox(width: 12),
      Expanded(child: Text(name, style: const TextStyle(fontSize: 14, color: Colors.white70))),
      if (secured) const Icon(Icons.lock_outline, size: 14, color: Colors.white38),
      const SizedBox(width: 8),
      Row(children: List.generate(4, (i) => Container(
        width: 6, height: 10, margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: i < signal ? Colors.white54 : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(1),
        ),
      ))),
    ]),
  );
}

class _BTItem extends StatelessWidget {
  final String name; final bool connected;
  const _BTItem({required this.name, required this.connected});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(Icons.bluetooth, size: 20, color: connected ? Colors.white54 : Colors.white24),
      const SizedBox(width: 12),
      Expanded(child: Text(name, style: const TextStyle(fontSize: 14, color: Colors.white70))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: connected ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6)),
        child: Text(connected ? 'Connected' : 'Not Connected',
          style: TextStyle(fontSize: 12, color: connected ? Colors.green : Colors.white38)),
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
