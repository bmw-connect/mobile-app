import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';

/// Liquid Glass segmented control for the audio source — frosted pill
/// background with a floating glass thumb that slides between segments.
class SourceSwitcher extends StatelessWidget {
  const SourceSwitcher({super.key});

  static const _segments = [
    (AudioSource.airplay, Icons.airplay, 'AirPlay'),
    (AudioSource.bluetooth, CupertinoIcons.bluetooth, 'Bluetooth'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = context.watch<AudioController>();
    final source = ctrl.dsp.source;
    final selectedIndex =
        _segments.indexWhere((s) => s.$1 == source).clamp(0, 1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: dark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.40),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.12 : 0.55),
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 1 / _segments.length,
                  heightFactor: 1,
                  child: const _GlassThumb(),
                ),
              ),
              Row(
                children: [
                  for (final (value, icon, label) in _segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (value == source) return;
                          HapticFeedback.selectionClick();
                          ctrl.setSource(value);
                        },
                        child: _SegmentLabel(
                          icon: icon,
                          label: label,
                          selected: value == source,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sliding glass thumb: white gradient, specular top edge, soft shadow.
class _GlassThumb extends StatelessWidget {
  const _GlassThumb();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [
                  Colors.white.withValues(alpha: 0.26),
                  Colors.white.withValues(alpha: 0.12),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  Colors.white.withValues(alpha: 0.80),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.35 : 0.9),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.textPrimary : c.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
