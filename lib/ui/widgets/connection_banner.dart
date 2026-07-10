import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();
    final (color, icon, label) = _resolve(AppColors.of(context), ctrl);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
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
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _resolve(AppColors c, AudioController ctrl) {
    return switch (ctrl.status) {
      ConnectionStatus.connected => ctrl.mode == ConnectionMode.ble
          ? (c.bluetooth, Icons.bluetooth_connected, 'BLE')
          : (c.success, Icons.wifi, ctrl.connectedLabel ?? 'WebSocket'),
      ConnectionStatus.connecting => (c.warning, Icons.sync, 'Connecting…'),
      ConnectionStatus.scanning =>
        (c.bluetooth, Icons.bluetooth_searching, 'Scanning…'),
      ConnectionStatus.error => (c.error, Icons.error_outline, 'Error'),
      ConnectionStatus.disconnected =>
        (c.textSecondary, Icons.link_off, 'Disconnected'),
    };
  }
}
