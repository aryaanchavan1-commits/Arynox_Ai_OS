import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text(
          'Appearance',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 24),
        _Section(title: 'Theme', children: [
          _SwitchTile(label: 'Dark Mode', value: true, onChanged: (_) {}),
          _SwitchTile(label: 'Reduce Motion', value: false, onChanged: (_) {}),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Accent Color', children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ColorSwatch(color: const Color(0xFF6C5CE7), selected: true),
              _ColorSwatch(color: const Color(0xFF00CEC9), selected: false),
              _ColorSwatch(color: const Color(0xFFE17055), selected: false),
              _ColorSwatch(color: const Color(0xFF74B9FF), selected: false),
              _ColorSwatch(color: const Color(0xFF00B894), selected: false),
              _ColorSwatch(color: const Color(0xFFFDCB6E), selected: false),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Wallpaper', children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
              ),
            ),
            child: const Center(
              child: Text('Wallpaper Picker', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'Font Size', children: [
          _SliderTile(label: 'Text Scale', value: 1.0, min: 0.5, max: 2.0, onChanged: (_) {}),
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
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70))),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF6C5CE7)),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _SliderTile({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const Spacer(),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  const _ColorSwatch({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
