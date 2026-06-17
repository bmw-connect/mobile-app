import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';

class VuMetersWidget extends StatelessWidget {
  const VuMetersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final stats = ctrl.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'VU METERS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (stats?.clipping == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.clip.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.clip.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'CLIP',
                      style: TextStyle(
                        color: AppColors.clip,
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

  Color _color(double linear) {
    final db = StatsSnapshot.toDbfs(linear);
    if (db >= -3) return AppColors.vuRed;
    if (db >= -12) return AppColors.vuYellow;
    return AppColors.vuGreen;
  }

  @override
  Widget build(BuildContext context) {
    final rmsPct = StatsSnapshot.toGaugePct(rms);
    final peakPct = StatsSnapshot.toGaugePct(peak);
    final db = StatsSnapshot.toDbfs(rms);

    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 20,
            child: CustomPaint(
              painter: _VuPainter(rms: rmsPct, peak: peakPct),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            '${db.toStringAsFixed(1)} dB',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _color(rms),
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

  const _VuPainter({required this.rms, required this.peak});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.border.withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    if (rms > 0) {
      final rmsPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.vuGreen, AppColors.vuGreen, AppColors.vuYellow, AppColors.vuRed],
          stops: [0.0, 0.6, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, (size.width * rms).clamp(0, size.width), size.height),
          const Radius.circular(4),
        ),
        rmsPaint,
      );
    }

    if (peak > 0) {
      final px = (size.width * peak).clamp(1.0, size.width - 1.0);
      canvas.drawLine(
        Offset(px, 2),
        Offset(px, size.height - 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_VuPainter old) => old.rms != rms || old.peak != peak;
}

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
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
            valueColor: stats?.clipping == true
                ? AppColors.clip
                : AppColors.textSecondary,
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
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 11,
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
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
