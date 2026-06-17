import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Equalizer',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 22),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ctrl.resetEq();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
              child: Text(
                'Drag bands to adjust  •  ±12 dB range',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _EqBars(
                  gains: gains,
                  activeIndex: _activeIndex,
                  onBandChanged: (i, db) {
                    HapticFeedback.selectionClick();
                    ctrl.setEqBand(i, db);
                  },
                  onActiveChanged: (i) => setState(() => _activeIndex = i),
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
                            painter: _GridPainter(barHeight: barHeight),
                          ),
                        ),
                        for (final db in [12.0, 6.0, 0.0, -6.0, -12.0])
                          Positioned(
                            top: ((_kMaxDb - db) / _kDbRange * barHeight) - 7,
                            right: 4,
                            child: Text(
                              db >= 0 ? '+${db.toInt()}' : '${db.toInt()}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
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
                        color: activeIndex == i
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 9,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => widget.onActiveChanged(true),
      onVerticalDragStart: (d) {
        widget.onActiveChanged(true);
        _startGain = widget.gain;
        _startY = d.localPosition.dy;
      },
      onVerticalDragUpdate: (d) {
        final delta =
            (d.localPosition.dy - _startY) / widget.barHeight * _kDbRange;
        final newGain = (_startGain - delta).clamp(_kMinDb, _kMaxDb);
        // Snap to 0.5 dB steps
        widget.onChanged((newGain * 2).round() / 2.0);
      },
      onVerticalDragEnd: (_) => widget.onActiveChanged(false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: CustomPaint(
          painter: _BandPainter(
            gain: widget.gain,
            active: widget.active,
            barHeight: widget.barHeight,
          ),
        ),
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  final double gain;
  final bool active;
  final double barHeight;

  const _BandPainter({
    required this.gain,
    required this.active,
    required this.barHeight,
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
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.border.withValues(alpha: 0.4),
    );

    // Bar
    final barTop = gain >= 0 ? gainY : zeroY;
    final barBottom = gain >= 0 ? zeroY : gainY;
    if (barBottom - barTop > 0.5) {
      final barColor =
          gain > 0 ? AppColors.primaryLight : AppColors.airplay;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.3,
            barTop,
            size.width * 0.4,
            barBottom - barTop,
          ),
          const Radius.circular(4),
        ),
        Paint()
          ..color = active ? barColor : barColor.withValues(alpha: 0.65),
      );
    }

    // Knob
    final knobColor = active ? Colors.white : AppColors.primaryLight;
    canvas.drawCircle(
      Offset(size.width / 2, gainY),
      active ? 7 : 5,
      Paint()..color = knobColor,
    );

    if (active) {
      canvas.drawCircle(
        Offset(size.width / 2, gainY),
        12,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Gain label
    if (gain.abs() > 0.4 || active) {
      final label = gain >= 0
          ? '+${gain % 1 == 0 ? gain.toInt() : gain.toStringAsFixed(1)}'
          : '${gain % 1 == 0 ? gain.toInt() : gain.toStringAsFixed(1)}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          size.width / 2 - tp.width / 2,
          gainY + (gain < 0 ? 10 : -tp.height - 4),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.gain != gain || old.active != active || old.barHeight != barHeight;
}

class _GridPainter extends CustomPainter {
  final double barHeight;
  const _GridPainter({required this.barHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (final db in [12.0, 6.0, 0.0, -6.0, -12.0]) {
      final y = (_kMaxDb - db) / _kDbRange * barHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.barHeight != barHeight;
}

class _PresetRow extends StatelessWidget {
  final void Function(List<double>) onPreset;
  const _PresetRow({required this.onPreset});

  static const _presets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass': [4.0, 4.0, 3.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Treble': [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 4.0],
    'V-Shape': [5.0, 3.0, 1.0, -1.0, -2.0, -2.0, -1.0, 1.0, 3.0, 5.0],
    'Rock': [3.0, 2.0, -1.0, -2.0, 0.0, 1.0, 2.0, 3.0, 3.0, 2.0],
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: _presets.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => onPreset(List<double>.from(e.value)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border, width: 0.5),
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
