import 'package:flutter/material.dart';
import '../theme.dart';

/// Subtle blue ambient gradient behind every screen, so the background is
/// never flat white or flat black. A faint accent glow at the top gives the
/// instrument-cluster backlight feel.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [
                  Color(0xFF0C1626),
                  Color(0xFF080D16),
                  Color(0xFF05070C),
                ]
              : const [
                  Color(0xFFE1EBFA),
                  Color(0xFFECF1F9),
                  Color(0xFFF2F4F8),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -160,
            left: -80,
            right: -80,
            height: 400,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      c.accent.withValues(alpha: dark ? 0.14 : 0.09),
                      c.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
