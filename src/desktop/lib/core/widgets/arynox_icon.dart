import 'package:flutter/material.dart';
import '../design/app_colors.dart';

class ArynoxIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool hasGlow;

  const ArynoxIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : ArynoxColors.textPrimaryLight);

    if (!hasGlow) {
      return Icon(icon, size: size, color: effectiveColor);
    }

    return Container(
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.3),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.7, color: effectiveColor),
    );
  }
}
