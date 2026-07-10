import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';
import 'glass_bubble.dart';

class VolumeControl extends StatefulWidget {
  const VolumeControl({super.key});

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  double? _localVolume;
  bool _dragging = false;

  double _volToDb(double v) {
    if (v < 1e-9) return -90.0;
    return 20.0 * math.log(v) / math.ln10;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ctrl = context.watch<AudioController>();
    final volume =
        _dragging ? (_localVolume ?? ctrl.dsp.volume) : ctrl.dsp.volume;
    final muted = ctrl.dsp.muted;
    final db = _volToDb(volume);
    final pct = (volume * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.setMute(!muted);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      muted ? Icons.volume_off : Icons.volume_up_rounded,
                      key: ValueKey(muted),
                      size: 20,
                      color: muted ? c.error : c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Volume', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (muted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'MUTED',
                      style: TextStyle(
                        color: c.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$pct',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextSpan(
                          text: ' %',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _CapsuleSlider(
              value: volume,
              dragging: _dragging,
              label: '$pct %',
              onChangeStart: () => setState(() => _dragging = true),
              onChanged: (v) {
                setState(() => _localVolume = v);
                ctrl.setVolume(v);
              },
              onChangeEnd: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _dragging = false;
                  _localVolume = null;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(
              db > -90 ? '${db.toStringAsFixed(1)} dB' : '−∞ dB',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple-Settings-style volume slider: a frosted glass capsule that fills
/// with the accent color, with a round white knob riding the fill edge.
/// While dragging, a frosted glass bubble with the live value floats above
/// the finger.
class _CapsuleSlider extends StatelessWidget {
  const _CapsuleSlider({
    required this.value,
    required this.dragging,
    required this.label,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final bool dragging;
  final String label;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  static const double _trackHeight = 36;
  static const double _bubbleWidth = 64;
  static const double _knobSize = 28;
  static const double _knobInset = (_trackHeight - _knobSize) / 2;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The knob travels between the capsule's rounded ends.
        final travel = width - _knobSize - 2 * _knobInset;
        final knobCenterX = _knobInset + _knobSize / 2 + value * travel;
        final fillWidth =
            (knobCenterX + _knobSize / 2 + _knobInset).clamp(0.0, width);

        void update(Offset local) {
          onChanged(
            ((local.dx - _knobInset - _knobSize / 2) / travel).clamp(0.0, 1.0),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            onChangeStart();
            update(d.localPosition);
          },
          onHorizontalDragUpdate: (d) => update(d.localPosition),
          onHorizontalDragEnd: (_) => onChangeEnd(),
          onHorizontalDragCancel: onChangeEnd,
          onTapDown: (d) {
            onChangeStart();
            update(d.localPosition);
          },
          onTapUp: (_) => onChangeEnd(),
          child: SizedBox(
            height: _trackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Frosted glass track with the accent fill inside.
                AnimatedScale(
                  scale: dragging ? 1.02 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Stack(
                        children: [
                          Container(
                            width: width,
                            height: _trackHeight,
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.38),
                              borderRadius:
                                  BorderRadius.circular(_trackHeight / 2),
                              border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: dark ? 0.12 : 0.55),
                                width: 0.8,
                              ),
                            ),
                          ),
                          Container(
                            width: fillWidth,
                            height: _trackHeight,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(_trackHeight / 2),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  c.accent.withValues(alpha: 0.92),
                                  c.accent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // White knob riding the fill edge, like an iOS settings
                // slider thumb.
                Positioned(
                  left: knobCenterX - _knobSize / 2,
                  top: _knobInset,
                  child: IgnorePointer(
                    child: AnimatedScale(
                      scale: dragging ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: _knobSize,
                        height: _knobSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFF0F0F5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: dark ? 0.45 : 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Glass value bubble above the finger while dragging.
                Positioned(
                  left: (knobCenterX - _bubbleWidth / 2)
                      .clamp(0.0, math.max(0.0, width - _bubbleWidth)),
                  top: -46,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: dragging ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 120),
                      child: SizedBox(
                        width: _bubbleWidth,
                        child: Center(child: GlassBubble(text: label)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
