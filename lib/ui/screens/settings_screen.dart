import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../core/audio_controller.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AudioController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: _Label('CONNECTION'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _ConnectionCard(ctrl: ctrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                child: _Label('BLUETOOTH (BLE)'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _BleSection(ctrl: ctrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                child: _Label('WEBSOCKET (Wi-Fi)'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _WsSection(ctrl: ctrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 16, 0),
                child: _Label('ABOUT'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: _AboutCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}

class _ConnectionCard extends StatelessWidget {
  final AudioController ctrl;
  const _ConnectionCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (statusColor, statusLabel) = _statusInfo(c, ctrl.status);

    return Card(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(_modeIcon(ctrl.mode), color: statusColor, size: 20),
            title: Text(
              ctrl.connectedLabel ?? _modeLabel(ctrl.mode),
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
            trailing: ctrl.isConnected
                ? TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ctrl.disconnect();
                    },
                    style: TextButton.styleFrom(foregroundColor: c.error),
                    child: const Text('Disconnect'),
                  )
                : null,
          ),
          if (ctrl.errorMsg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ctrl.errorMsg!,
                  style: TextStyle(color: c.error, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  (Color, String) _statusInfo(AppColors c, ConnectionStatus s) => switch (s) {
        ConnectionStatus.connected => (c.success, 'Connected'),
        ConnectionStatus.connecting => (c.warning, 'Connecting…'),
        ConnectionStatus.scanning => (c.bluetooth, 'Scanning…'),
        ConnectionStatus.error => (c.error, 'Error'),
        ConnectionStatus.disconnected => (c.textSecondary, 'Not connected'),
      };

  IconData _modeIcon(ConnectionMode m) => switch (m) {
        ConnectionMode.ble => Icons.bluetooth_connected,
        ConnectionMode.websocket => Icons.wifi,
        ConnectionMode.none => Icons.link_off,
      };

  String _modeLabel(ConnectionMode m) => switch (m) {
        ConnectionMode.ble => 'Bluetooth',
        ConnectionMode.websocket => 'WebSocket',
        ConnectionMode.none => 'Not connected',
      };
}

class _BleSection extends StatelessWidget {
  final AudioController ctrl;
  const _BleSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Auto-discover devices advertising the service.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                _ScanButton(ctrl: ctrl),
              ],
            ),
            if (ctrl.isScanning || ctrl.scanResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (ctrl.isScanning && ctrl.scanResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.bluetooth,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Looking for device…',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ...ctrl.scanResults.map((r) => _BleDevice(
                    result: r,
                    onConnect: () {
                      HapticFeedback.mediumImpact();
                      ctrl.connectBle(r.device);
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final AudioController ctrl;
  const _ScanButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (ctrl.isScanning) {
      return OutlinedButton.icon(
        onPressed: ctrl.stopBleScan,
        icon: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: c.accent,
          ),
        ),
        label: const Text('Stop'),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        ctrl.startBleScan();
      },
      icon: const Icon(Icons.bluetooth_searching, size: 16),
      label: const Text('Scan'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BleDevice extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;

  const _BleDevice({required this.result, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName.isNotEmpty
            ? result.advertisementData.advName
            : result.device.remoteId.str;
    final rssi = result.rssi;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(_rssiIcon(rssi), size: 16, color: c.bluetooth),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$rssi dBm',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onConnect,
            style: FilledButton.styleFrom(
              minimumSize: const Size(76, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  IconData _rssiIcon(int rssi) {
    if (rssi > -60) return Icons.signal_cellular_alt;
    if (rssi > -75) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }
}

class _WsSection extends StatefulWidget {
  final AudioController ctrl;
  const _WsSection({required this.ctrl});

  @override
  State<_WsSection> createState() => _WsSectionState();
}

class _WsSectionState extends State<_WsSection> {
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textCtrl.text = widget.ctrl.wsHost ?? '';
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the IP. The app connects to port 9000.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: '192.168.50.1',
                prefixIcon: Icon(
                  Icons.dns_outlined,
                  size: 18,
                  color: c.textSecondary,
                ),
                prefixText: 'ws://',
                prefixStyle: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final host = _textCtrl.text.trim();
                  if (host.isEmpty) return;
                  HapticFeedback.mediumImpact();
                  FocusScope.of(context).unfocus();
                  widget.ctrl.connectWebSocket(host);
                },
                icon: const Icon(Icons.wifi, size: 16),
                label: const Text('Connect via Wi-Fi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMW Connect',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Remote controller for the BMW Connect Rust daemon.\n'
              'Connects via BLE GATT or WebSocket on port 9000.',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
                Text(
                  '1.0.0',
                  style: TextStyle(color: c.textPrimary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
