import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../../core/protocol.dart';
import '../theme.dart';

class SourceSwitcher extends StatelessWidget {
  const SourceSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final source = ctrl.dsp.source;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _SourceTab(
              label: 'AirPlay',
              icon: Icons.airplay,
              color: AppColors.airplay,
              selected: source == AudioSource.airplay,
              onTap: () => ctrl.setSource(AudioSource.airplay),
            ),
            _SourceTab(
              label: 'Bluetooth',
              icon: Icons.bluetooth_audio,
              color: AppColors.bluetooth,
              selected: source == AudioSource.bluetooth,
              onTap: () => ctrl.setSource(AudioSource.bluetooth),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SourceTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
