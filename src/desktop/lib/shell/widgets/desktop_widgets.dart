import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/widgets/glass_container.dart';

class DesktopWidgets extends StatelessWidget {
  const DesktopWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // Clock widget (top-right)
        Positioned(
          top: 16,
          right: 16,
          child: _ClockWidget(),
        ),
      ],
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() => _now = DateTime.now());
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final date = '${_now.day}/${_now.month}/${_now.year}';

    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = days[_now.weekday - 1];

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$hour:$minute',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            '$dayName, $date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
