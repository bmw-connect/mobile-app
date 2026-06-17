import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final (color, icon, label) = _resolve(ctrl);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _resolve(AudioController ctrl) {
    return switch (ctrl.status) {
      ConnectionStatus.connected => ctrl.mode == ConnectionMode.ble
          ? (AppColors.bluetooth, Icons.bluetooth_connected, 'BLE')
          : (AppColors.success, Icons.wifi, ctrl.connectedLabel ?? 'WebSocket'),
      ConnectionStatus.connecting =>
        (AppColors.warning, Icons.sync, 'Connecting…'),
      ConnectionStatus.scanning =>
        (AppColors.bluetooth, Icons.bluetooth_searching, 'Scanning…'),
      ConnectionStatus.error => (AppColors.error, Icons.error_outline, 'Error'),
      ConnectionStatus.disconnected =>
        (AppColors.textMuted, Icons.link_off, 'Disconnected'),
    };
  }
}
