import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisplayPage extends ConsumerWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text('Display', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        _Section(title: 'Resolution', children: [
          _DropdownTile(label: 'Resolution', value: '1920×1080', items: const ['1920×1080', '2560×1440', '3840×2160']),
          _DropdownTile(label: 'Refresh Rate', value: '60 Hz', items: const ['60 Hz', '120 Hz', '144 Hz', '240 Hz']),
          _SwitchTile(label: 'Auto-rotate', value: false),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Scaling', children: [
          _SliderTile(label: 'Scale', value: 1.0, min: 0.5, max: 3.0),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Night Light', children: [
          _SwitchTile(label: 'Night Light', value: false),
          _SliderTile(label: 'Color Temperature', value: 0.5, min: 0.0, max: 1.0),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Multi-Monitor', children: [
          const Text('Connected Displays: 1', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF0F1023),
            ),
            child: const Center(child: Text('Display Layout', style: TextStyle(color: Colors.white24))),
          ),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1A1B2E), borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
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

class _SliderTile extends StatelessWidget {
  final String label; final double value; final double min; final double max;
  const _SliderTile({required this.label, required this.value, required this.min, required this.max});
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const Spacer(),
      Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 14, color: Colors.white)),
    ]),
    Slider(value: value, min: min, max: max, onChanged: (_) {}),
  ]);
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
