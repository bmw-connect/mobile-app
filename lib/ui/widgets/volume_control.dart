import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';

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
    final ctrl = context.watch<AudioController>();
    final volume = _dragging ? (_localVolume ?? ctrl.dsp.volume) : ctrl.dsp.volume;
    final muted = ctrl.dsp.muted;
    final db = _volToDb(volume);
    final pct = (volume * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => ctrl.setMute(!muted),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      muted ? Icons.volume_off : Icons.volume_up_rounded,
                      key: ValueKey(muted),
                      size: 20,
                      color: muted ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Volume', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (muted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'MUTED',
                      style: TextStyle(
                        color: AppColors.error,
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const TextSpan(
                          text: ' %',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Slider(
              value: volume,
              min: 0,
              max: 1,
              onChangeStart: (_) => setState(() => _dragging = true),
              onChanged: (v) {
                setState(() => _localVolume = v);
                ctrl.setVolume(v);
              },
              onChangeEnd: (v) {
                setState(() {
                  _dragging = false;
                  _localVolume = null;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%', style: Theme.of(context).textTheme.labelSmall),
                Text(
                  db > -90 ? '${db.toStringAsFixed(1)} dB' : '—∞ dB',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text('100%', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
