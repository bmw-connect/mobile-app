import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';

class DspToggleRow extends StatelessWidget {
  const DspToggleRow({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final dsp = ctrl.dsp;
    final limiterActive = ctrl.stats?.limiterActive ?? false;

    return Row(
      children: [
        Expanded(
          child: _Toggle(
            label: 'Loudness',
            icon: Icons.hearing,
            active: dsp.loudness,
            onTap: () => ctrl.setLoudness(!dsp.loudness),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Toggle(
            label: 'Limiter',
            icon: Icons.compress,
            active: dsp.limiter,
            accent: limiterActive ? AppColors.warning : null,
            badge: limiterActive ? 'ACT' : null,
            onTap: () => ctrl.setLimiter(!dsp.limiter),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Toggle(
            label: 'Mute',
            icon: Icons.volume_off,
            active: dsp.muted,
            accent: dsp.muted ? AppColors.error : null,
            onTap: () => ctrl.setMute(!dsp.muted),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color? accent;
  final String? badge;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    required this.icon,
    required this.active,
    this.accent,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? (active ? AppColors.primary : AppColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.35) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: (accent ?? AppColors.warning).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: accent ?? AppColors.warning,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
