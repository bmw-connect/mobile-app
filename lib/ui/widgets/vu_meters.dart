import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';

class VuMetersWidget extends StatelessWidget {
  const VuMetersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ctrl = context.watch<AudioController>();
    final stats = ctrl.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LEVELS',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                if (stats?.clipping == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CLIP',
                      style: TextStyle(
                        color: c.error,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _VuChannel(
              label: 'L',
              rms: stats?.rmsL ?? 0,
              peak: stats?.peakL ?? 0,
            ),
            const SizedBox(height: 8),
            _VuChannel(
              label: 'R',
              rms: stats?.rmsR ?? 0,
              peak: stats?.peakR ?? 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _VuChannel extends StatelessWidget {
  final String label;
  final double rms;
  final double peak;

  const _VuChannel({
    required this.label,
    required this.rms,
    required this.peak,
  });

  Color _color(AppColors c, double linear) {
    final db = StatsSnapshot.toDbfs(linear);
    if (db >= -3) return c.vuRed;
    if (db >= -12) return c.vuYellow;
    return c.vuGreen;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rmsPct = StatsSnapshot.toGaugePct(rms);
    final peakPct = StatsSnapshot.toGaugePct(peak);
    final db = StatsSnapshot.toDbfs(rms);

    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 18,
            child: CustomPaint(
              painter: _VuPainter(
                rms: rmsPct,
                peak: peakPct,
                trackColor: c.cardAlt,
                green: c.vuGreen,
                yellow: c.vuYellow,
                red: c.vuRed,
                peakColor: c.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          child: Text(
            '${db.toStringAsFixed(1)} dB',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _color(c, rms),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _VuPainter extends CustomPainter {
  final double rms;
  final double peak;
  final Color trackColor;
  final Color green;
  final Color yellow;
  final Color red;
  final Color peakColor;

  const _VuPainter({
    required this.rms,
    required this.peak,
    required this.trackColor,
    required this.green,
    required this.yellow,
    required this.red,
    required this.peakColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height / 2),
      ),
      Paint()..color = trackColor,
    );

    if (rms > 0) {
      final rmsPaint = Paint()
        ..shader = LinearGradient(
          colors: [green, green, yellow, red],
          stops: const [0.0, 0.6, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              0, 0, (size.width * rms).clamp(0, size.width), size.height),
          Radius.circular(size.height / 2),
        ),
        rmsPaint,
      );
    }

    if (peak > 0) {
      final px = (size.width * peak).clamp(1.0, size.width - 1.0);
      canvas.drawLine(
        Offset(px, 3),
        Offset(px, size.height - 3),
        Paint()
          ..color = peakColor.withValues(alpha: 0.8)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_VuPainter old) =>
      old.rms != rms ||
      old.peak != peak ||
      old.trackColor != trackColor ||
      old.peakColor != peakColor;
}

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ctrl = context.watch<AudioController>();
    final stats = ctrl.stats;
    final sr = ctrl.dsp.source.sampleRate;
    final latMs = (2048 / sr * 1000);
    final kbps = stats != null
        ? (stats.framesPerSec * 4 * 2 / 1024).toStringAsFixed(0)
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _Stat(
            label: 'FORMAT',
            value: '${(sr / 1000).toStringAsFixed(sr % 1000 == 0 ? 0 : 1)}kHz',
          ),
          const _Sep(),
          _Stat(label: 'LATENCY', value: '${latMs.toStringAsFixed(2)} ms'),
          const _Sep(),
          _Stat(label: 'RATE', value: '$kbps KB/s'),
          const _Sep(),
          _Stat(
            label: 'CLIP',
            value: stats?.clipping == true ? 'YES' : 'no',
            valueColor:
                stats?.clipping == true ? c.error : c.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? c.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: AppColors.of(context).separator,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
