import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';

class DspToggleRow extends StatelessWidget {
  const DspToggleRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
        const SizedBox(width: 10),
        Expanded(
          child: _Toggle(
            label: 'Limiter',
            icon: Icons.compress,
            active: dsp.limiter,
            accent: limiterActive ? c.warning : null,
            badge: limiterActive ? 'ACT' : null,
            onTap: () => ctrl.setLimiter(!dsp.limiter),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Toggle(
            label: 'Mute',
            icon: Icons.volume_off,
            active: dsp.muted,
            accent: dsp.muted ? c.error : null,
            onTap: () => ctrl.setMute(!dsp.muted),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatefulWidget {
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
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = widget.accent ?? c.accent;
    final color = widget.active ? tint : c.textSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.active ? tint.withValues(alpha: 0.14) : c.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.badge!,
                    style: TextStyle(
                      color: tint,
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
      ),
    );
  }
}
