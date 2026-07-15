import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/services/shell_state.dart';
import '../../core/widgets/glass_container.dart';

class ControlCenter extends ConsumerWidget {
  final VoidCallback onClose;

  const ControlCenter({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      width: 340,
      blur: 20,
      borderRadius: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Control Center',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick settings grid
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    _QuickSettingTile(
                      icon: Icons.wifi,
                      label: 'Wi-Fi',
                      active: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _QuickSettingTile(
                      icon: Icons.bluetooth,
                      label: 'Bluetooth',
                      active: false,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QuickSettingTile(
                      icon: Icons.dark_mode,
                      label: 'Dark Mode',
                      active: isDark,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).state =
                            isDark ? ThemeMode.light : ThemeMode.dark;
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickSettingTile(
                      icon: Icons.auto_awesome,
                      label: 'AI',
                      active: true,
                      onTap: () {
                        ref.read(isAssistantOpenProvider.notifier).state = true;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Brightness
                _buildSlider('Brightness', Icons.brightness_6, 0.8),
                const SizedBox(height: 12),

                // Volume
                _buildSlider('Volume', Icons.volume_up, 0.6),

                const SizedBox(height: 16),

                // Media player
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No media playing',
                              style: TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                            Text(
                              'Open a music app to start',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AI status footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ArynoxColors.aiGradientStart.withValues(alpha: 0.3),
                  ArynoxColors.aiGradientEnd.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: ArynoxColors.primaryLight, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'AI Ready',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ArynoxColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, IconData icon, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const Spacer(),
            Text('${(value * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: ArynoxColors.primaryLight,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
            thumbColor: Colors.white,
          ),
          child: Slider(value: value, onChanged: (_) {}),
        ),
      ],
    );
  }
}

class _QuickSettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _QuickSettingTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active
                ? ArynoxColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: active
                ? Border.all(
                    color: ArynoxColors.primaryLight.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: active ? ArynoxColors.primaryLight : Colors.white54,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
