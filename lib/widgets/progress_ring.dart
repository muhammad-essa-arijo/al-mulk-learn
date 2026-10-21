import 'package:flutter/material.dart';

/// A circle that fills up smoothly. [value] is between 0 and 1.
class ProgressRing extends StatelessWidget {
  final double value;
  final Widget child;
  final double size;
  const ProgressRing(
      {super.key, required this.value, required this.child, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: color.primary.withValues(alpha: 0.12),
              color: color.primary,
            ),
          ),
          child,
        ]),
      ),
    );
  }
}
