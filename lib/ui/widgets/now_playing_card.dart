import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';

class NowPlayingCard extends StatefulWidget {
  const NowPlayingCard({super.key});

  @override
  State<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick every second to update progress bar interpolation
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final track = ctrl.track;
    final source = ctrl.dsp.source;
    final sourceColor =
        source == AudioSource.airplay ? AppColors.airplay : AppColors.bluetooth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  source == AudioSource.airplay
                      ? Icons.airplay
                      : Icons.bluetooth_audio,
                  size: 13,
                  color: sourceColor,
                ),
                const SizedBox(width: 6),
                Text(
                  source.displayName.toUpperCase(),
                  style: TextStyle(
                    color: sourceColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                _SignalDot(active: ctrl.stats?.signalActive ?? false),
              ],
            ),
            const SizedBox(height: 12),
            if (track == null) ...[
              Text(
                '—',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: 2),
              Text('No media playing',
                  style: Theme.of(context).textTheme.bodySmall),
            ] else ...[
              Text(
                track.title ?? 'Unknown Track',
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (track.subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  track.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (track.durationMs != null && track.durationMs! > 0) ...[
                const SizedBox(height: 12),
                _ProgressBar(track: track),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final TrackInfo track;
  const _ProgressBar({required this.track});

  @override
  Widget build(BuildContext context) {
    final pos = track.currentPositionMs ?? 0;
    final dur = track.durationMs ?? 1;
    final ratio = (pos / dur).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
            minHeight: 2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmtMs(pos), style: Theme.of(context).textTheme.labelSmall),
            Text(_fmtMs(dur), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  String _fmtMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '$m:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _SignalDot extends StatefulWidget {
  final bool active;
  const _SignalDot({required this.active});

  @override
  State<_SignalDot> createState() => _SignalDotState();
}

class _SignalDotState extends State<_SignalDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
