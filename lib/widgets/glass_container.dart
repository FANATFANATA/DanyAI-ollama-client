import "dart:ui";
import "package:flutter/material.dart";

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.borderRadius,
    this.border,
    this.color,
    this.blur = 15,
    super.key,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final Color? color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? theme.colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: borderRadius,
            border: border ?? Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
