import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';
import '../widgets/glass_bubble.dart';

const double _kBarHeight = 220.0;
const double _kMaxDb = 12.0;
const double _kMinDb = -12.0;
const double _kDbRange = 24.0;

class EqScreen extends StatefulWidget {
  const EqScreen({super.key});

  @override
  State<EqScreen> createState() => _EqScreenState();
}

class _EqScreenState extends State<EqScreen> {
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final gains = ctrl.dsp.eqGains;
    final active = _activeIndex;
    final activeGain =
        active != null && gains.length > active ? gains[active] : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Equalizer',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ctrl.resetEq();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 16, 12),
              child: Text(
                'Drag bands to adjust  •  ±12 dB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _EqBars(
                      gains: gains,
                      activeIndex: _activeIndex,
                      onBandChanged: (i, db) {
                        HapticFeedback.selectionClick();
                        ctrl.setEqBand(i, db);
                      },
                      onActiveChanged: (i) =>
                          setState(() => _activeIndex = i),
                    ),
                    // Frosted readout while a band is being dragged.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: active != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 120),
                          child: Center(
                            child: GlassBubble(
                              text: active != null
                                  ? '${eqFreqLabel(eqFreqsHz[active])}Hz   '
                                      '${activeGain >= 0 ? '+' : ''}'
                                      '${activeGain.toStringAsFixed(1)} dB'
                                  : '',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PresetRow(
              onPreset: (values) {
                HapticFeedback.mediumImpact();
                for (int i = 0; i < eqBands; i++) {
                  ctrl.setEqBand(i, values[i]);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EqBars extends StatelessWidget {
  final List<double> gains;
  final int? activeIndex;
  final void Function(int, double) onBandChanged;
  final void Function(int?) onActiveChanged;

  const _EqBars({
    required this.gains,
    required this.activeIndex,
    required this.onBandChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight - 24 // 24 for freq labels row
            : _kBarHeight;

        return Column(
          children: [
            // Bars + left axis
            SizedBox(
              height: barHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left axis: grid lines + dB labels
                  SizedBox(
                    width: 30,
                    child: Stack(
                      // Stack bounded by the SizedBox(height: barHeight) parent
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPainter(
                              barHeight: barHeight,
                              color: c.separator,
                            ),
                          ),
                        ),
                        for (final db in [12.0, 6.0, 0.0, -6.0, -12.0])
                          Positioned(
                            top: ((_kMaxDb - db) / _kDbRange * (barHeight - 16)) +
                                1.5,
                            right: 4,
                            child: Text(
                              db >= 0 ? '+${db.toInt()}' : '${db.toInt()}',
                              style: TextStyle(
                                color: c.textTertiary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Bands
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(
                        eqBands,
                        (i) => Expanded(
                          child: _EqBand(
                            index: i,
                            gain: gains.length > i ? gains[i] : 0.0,
                            active: activeIndex == i,
                            barHeight: barHeight,
                            onChanged: (db) => onBandChanged(i, db),
                            onActiveChanged: (a) =>
                                onActiveChanged(a ? i : null),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Frequency labels
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Row(
                children: List.generate(
                  eqBands,
                  (i) => Expanded(
                    child: Text(
                      eqFreqLabel(eqFreqsHz[i]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: activeIndex == i ? c.accent : c.textSecondary,
                        fontSize: 10,
                        fontWeight: activeIndex == i
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EqBand extends StatefulWidget {
  final int index;
  final double gain;
  final bool active;
  final double barHeight;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onActiveChanged;

  const _EqBand({
    required this.index,
    required this.gain,
    required this.active,
    required this.barHeight,
    required this.onChanged,
    required this.onActiveChanged,
  });

  @override
  State<_EqBand> createState() => _EqBandState();
}

class _EqBandState extends State<_EqBand> {
  double _startGain = 0;
  double _startY = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => widget.onActiveChanged(true),
      onTapUp: (_) => widget.onActiveChanged(false),
      onTapCancel: () => widget.onActiveChanged(false),
      onVerticalDragStart: (d) {
        widget.onActiveChanged(true);
        _startGain = widget.gain;
        _startY = d.localPosition.dy;
      },
      onVerticalDragUpdate: (d) {
        final delta =
            (d.localPosition.dy - _startY) / widget.barHeight * _kDbRange;
        final newGain = (_startGain - delta).clamp(_kMinDb, _kMaxDb);
        widget.onChanged(newGain);
      },
      onVerticalDragEnd: (_) => widget.onActiveChanged(false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BandPainter(
                  gain: widget.gain,
                  active: widget.active,
                  barHeight: widget.barHeight,
                  trackColor: c.cardAlt,
                  barColor: c.accent,
                ),
              ),
            ),
            // Liquid Glass handle, only while the band is being dragged.
            Positioned(
              top: _gainY - 13,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: widget.active ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 120),
                  child: const Center(child: GlassKnob(size: 26)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _gainY =>
      ((_kMaxDb - widget.gain) / _kDbRange * widget.barHeight)
          .clamp(0.0, widget.barHeight);
}

class _BandPainter extends CustomPainter {
  final double gain;
  final bool active;
  final double barHeight;
  final Color trackColor;
  final Color barColor;

  const _BandPainter({
    required this.gain,
    required this.active,
    required this.barHeight,
    required this.trackColor,
    required this.barColor,
  });

  double get _zeroY => (_kMaxDb / _kDbRange * barHeight).clamp(0.0, barHeight);

  double get _gainY =>
      ((_kMaxDb - gain) / _kDbRange * barHeight).clamp(0.0, barHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final zeroY = _zeroY;
    final gainY = _gainY;

    // Track background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.3, size.height),
        Radius.circular(size.width * 0.15),
      ),
      Paint()..color = trackColor,
    );

    // Bar: a rounded pill from the zero line to the current gain. A minimum
    // height keeps a small nub visible at 0 dB — no floating knob dot.
    final barWidth = size.width * 0.4;
    double barTop = gain >= 0 ? gainY : zeroY;
    double barBottom = gain >= 0 ? zeroY : gainY;
    final minHeight = barWidth.clamp(8.0, 14.0);
    if (barBottom - barTop < minHeight) {
      final mid = (barTop + barBottom) / 2;
      barTop = (mid - minHeight / 2).clamp(0.0, size.height - minHeight);
      barBottom = barTop + minHeight;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.3,
          barTop,
          barWidth,
          barBottom - barTop,
        ),
        Radius.circular(barWidth / 2),
      ),
      Paint()..color = active ? barColor : barColor.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.gain != gain ||
      old.active != active ||
      old.barHeight != barHeight ||
      old.barColor != barColor ||
      old.trackColor != trackColor;
}

class _GridPainter extends CustomPainter {
  final double barHeight;
  final Color color;
  const _GridPainter({required this.barHeight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (final db in [12.0, 6.0, 0.0, -6.0, -12.0]) {
      final y = (_kMaxDb - db) / _kDbRange * barHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.barHeight != barHeight || old.color != color;
}

class _PresetRow extends StatelessWidget {
  final void Function(List<double>) onPreset;
  const _PresetRow({required this.onPreset});

  static const _presets = {
    'Bass': [7.0, 6.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Treble': [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 4.0],
    'V-Shape': [5.0, 3.0, 1.0, -1.0, -2.0, -2.0, -1.0, 1.0, 3.0, 5.0],
    'Rock': [3.0, 2.0, -1.0, -2.0, 0.0, 1.0, 2.0, 3.0, 3.0, 2.0],
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: _presets.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PresetChip(
              label: e.key,
              onTap: () => onPreset(List<double>.from(e.value)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Frosted glass preset pill that lights up (accent-tinted glass) and gently
/// shrinks while pressed.
class _PresetChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _pressed
                      ? [
                          c.accent.withValues(alpha: dark ? 0.45 : 0.30),
                          c.accent.withValues(alpha: dark ? 0.25 : 0.16),
                        ]
                      : dark
                          ? [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.07),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.55),
                            ],
                ),
                border: Border.all(
                  color: _pressed
                      ? c.accent.withValues(alpha: dark ? 0.6 : 0.4)
                      : Colors.white.withValues(alpha: dark ? 0.18 : 0.65),
                  width: 0.8,
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
