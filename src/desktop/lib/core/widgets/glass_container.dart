import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double blur;
  final double borderRadius;
  final Color? tintColor;
  final Color? strokeColor;
  final double strokeWidth;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.blur = 20,
    this.borderRadius = 16,
    this.tintColor,
    this.strokeColor,
    this.strokeWidth = 0.5,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTint = tintColor ?? (isDark ? ArynoxColors.glassDark : ArynoxColors.glassLight);
    final effectiveStroke = strokeColor ?? (isDark ? ArynoxColors.glassStrokeDark : ArynoxColors.glassStrokeLight);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: effectiveStroke,
                width: strokeWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
