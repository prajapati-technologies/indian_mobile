import 'dart:ui';
import 'package:flutter/material.dart';

/// Drop-in replacement for `GlassContainer.clearGlass` from glass_kit.
/// Uses Flutter's native BackdropFilter — no third-party package needed.
/// Produces same frosted glass effect without deprecated shadow issues.
class FrostedContainer extends StatelessWidget {
  const FrostedContainer({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderWidth = 1.0,
    this.child,
  });

  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      height: height,
      width: width,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: radius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.5),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
