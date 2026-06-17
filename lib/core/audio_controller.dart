import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'protocol.dart';

enum ConnectionMode { none, websocket, ble }

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class AudioController extends ChangeNotifier {
  // ─── DSP state ───────────────────────────────────────────────────────────────

  DspState _dsp = DspState.initial();
  StatsSnapshot? _stats;
  TrackInfo? _track;

  DspState get dsp => _dsp;
  StatsSnapshot? get stats => _stats;
  TrackInfo? get track => _track;

  // ─── Connection ───────────────────────────────────────────────────────────────

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionMode _mode = ConnectionMode.none;
  String? _errorMsg;
  String? _connectedLabel;

  ConnectionStatus get status => _status;
  ConnectionMode get mode => _mode;
  String? get errorMsg => _errorMsg;
  String? get connectedLabel => _connectedLabel;
  bool get isConnected => _status == ConnectionStatus.connected;

  // ─── WebSocket ───────────────────────────────────────────────────────────────

  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  String? _wsHost;
  Timer? _wsReconnectTimer;

  String? get wsHost => _wsHost;

  // ─── BLE ─────────────────────────────────────────────────────────────────────

  BluetoothDevice? _bleDevice;
  BluetoothCharacteristic? _bleCmdChar;
  StreamSubscription? _bleNotifySub;
  StreamSubscription? _bleConnStateSub;

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription? _scanResultSub;
  StreamSubscription? _scanStatusSub;

  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  bool get isScanning => _isScanning;

  // ─── Saved preferences ───────────────────────────────────────────────────────

  static const _kWsHost = 'ws_host';
  static const _kMode = 'connection_mode';

  // ─── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _wsHost = prefs.getString(_kWsHost);
    final savedMode = prefs.getString(_kMode);
    if (savedMode == 'websocket' && _wsHost != null) {
      connectWebSocket(_wsHost!);
    }
  }

  // ─── WebSocket ───────────────────────────────────────────────────────────────

  Future<void> connectWebSocket(String host) async {
    await _disconnectAll();
    _wsHost = host.trim();
    _mode = ConnectionMode.websocket;
    _setStatus(ConnectionStatus.connecting);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWsHost, _wsHost!);
    await prefs.setString(_kMode, 'websocket');

    _openWs();
  }

  void _openWs() {
    if (_mode != ConnectionMode.websocket || _wsHost == null) return;
    try {
      _ws = WebSocketChannel.connect(Uri.parse('ws://$_wsHost:9000/ws'));
      _connectedLabel = _wsHost;
      _wsSub = _ws!.stream.listen(
        (data) {
          if (_status != ConnectionStatus.connected) {
            _errorMsg = null;
            _setStatus(ConnectionStatus.connected);
          }
          final raw = data is String ? data : utf8.decode(data as List<int>);
          final msg = parseMessage(raw);
          if (msg != null) _applyMessage(msg);
        },
        onError: (_) {
          _setStatus(ConnectionStatus.error);
          _errorMsg = 'Connection lost — retrying…';
          _scheduleWsReconnect();
        },
        onDone: () {
          if (_mode == ConnectionMode.websocket) {
            _setStatus(ConnectionStatus.disconnected);
            _scheduleWsReconnect();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      _errorMsg = 'Cannot reach $_wsHost';
      _scheduleWsReconnect();
    }
  }

  void _scheduleWsReconnect() {
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_mode == ConnectionMode.websocket &&
          _status != ConnectionStatus.connected) {
        _setStatus(ConnectionStatus.connecting);
        _openWs();
      }
    });
  }

  // ─── BLE ─────────────────────────────────────────────────────────────────────

  Future<void> startBleScan() async {
    await _disconnectAll();
    _scanResults = [];
    _mode = ConnectionMode.none;
    _setStatus(ConnectionStatus.scanning);

    _scanStatusSub?.cancel();
    _scanStatusSub = FlutterBluePlus.isScanning.listen((v) {
      _isScanning = v;
      notifyListeners();
    });

    _scanResultSub?.cancel();
    _scanResultSub = FlutterBluePlus.onScanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(bleServiceUuid)],
        timeout: const Duration(seconds: 20),
      );
    } catch (e) {
      _isScanning = false;
      _setStatus(ConnectionStatus.error);
      _errorMsg = 'BLE not available: $e';
    }
  }

  Future<void> stopBleScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _isScanning = false;
    if (_status == ConnectionStatus.scanning) {
      _setStatus(ConnectionStatus.disconnected);
    }
  }

  Future<void> connectBle(BluetoothDevice device) async {
    await stopBleScan();
    await _disconnectAll();

    _bleDevice = device;
    _mode = ConnectionMode.ble;
    _connectedLabel = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.str;
    _setStatus(ConnectionStatus.connecting);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode, 'ble');

    try {
      await device.connect(timeout: const Duration(seconds: 15));

      _bleConnStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            _mode == ConnectionMode.ble) {
          _bleCmdChar = null;
          _setStatus(ConnectionStatus.disconnected);
        }
      });

      final services = await device.discoverServices();
      final svc = services.firstWhere(
        (s) => s.uuid == Guid(bleServiceUuid),
      );

      _bleCmdChar = svc.characteristics.firstWhere(
        (c) => c.uuid == Guid(bleCmdCharUuid),
      );

      final notifyChar = svc.characteristics.firstWhere(
        (c) => c.uuid == Guid(bleStatsCharUuid),
      );

      await notifyChar.setNotifyValue(true);

      _bleNotifySub = notifyChar.onValueReceived.listen((value) {
        if (_status != ConnectionStatus.connected) {
          _errorMsg = null;
          _setStatus(ConnectionStatus.connected);
        }
        final msg = parseMessage(utf8.decode(value));
        if (msg != null) _applyMessage(msg);
      });

      _setStatus(ConnectionStatus.connected);
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      _errorMsg = 'BLE failed: $e';
    }
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────────

  Future<void> _disconnectAll() async {
    _wsReconnectTimer?.cancel();
    _wsSub?.cancel();
    _ws?.sink.close(ws_status.goingAway);
    _ws = null;
    _wsSub = null;

    _bleNotifySub?.cancel();
    _bleConnStateSub?.cancel();
    _bleNotifySub = null;
    _bleConnStateSub = null;
    _bleCmdChar = null;

    _scanResultSub?.cancel();
    _scanStatusSub?.cancel();
    _scanResultSub = null;
    _scanStatusSub = null;

    if (_bleDevice != null) {
      try {
        await _bleDevice!.disconnect();
      } catch (_) {}
      _bleDevice = null;
    }
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    _isScanning = false;
    _mode = ConnectionMode.none;
    _setStatus(ConnectionStatus.disconnected);
  }

  Future<void> disconnect() async {
    await _disconnectAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMode);
  }

  // ─── Message handling ─────────────────────────────────────────────────────────

  void _applyMessage(ServiceMessage msg) {
    switch (msg) {
      case StateMessage(:final state):
        _dsp = state;
      case StatsMessage(:final stats):
        _stats = stats;
      case NowPlayingMessage(:final track):
        _track = track.isEmpty ? null : track;
    }
    notifyListeners();
  }

  // ─── Commands ─────────────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> cmd) {
    final json = encodeCmd(cmd);
    try {
      if (_ws != null) {
        _ws!.sink.add(json);
      } else if (_bleCmdChar != null) {
        _bleCmdChar!.write(utf8.encode(json), withoutResponse: true);
      }
    } catch (_) {}
  }

  void setVolume(double value) {
    _dsp = _dsp.copyWith(volume: value);
    notifyListeners();
    _send(cmdVolume(value));
  }

  void setEqBand(int band, double gainDb) {
    final gains = List<double>.from(_dsp.eqGains);
    if (band >= 0 && band < gains.length) gains[band] = gainDb;
    _dsp = _dsp.copyWith(eqGains: gains);
    notifyListeners();
    _send(cmdEqBand(band, gainDb));
  }

  void setLoudness(bool value) {
    _dsp = _dsp.copyWith(loudness: value);
    notifyListeners();
    _send(cmdLoudness(value));
  }

  void setLimiter(bool value) {
    _dsp = _dsp.copyWith(limiter: value);
    notifyListeners();
    _send(cmdLimiter(value));
  }

  void setMute(bool value) {
    _dsp = _dsp.copyWith(muted: value);
    notifyListeners();
    _send(cmdMute(value));
  }

  void setSource(AudioSource source) {
    _dsp = _dsp.copyWith(source: source);
    notifyListeners();
    _send(cmdSource(source));
  }

  void resetEq() {
    final gains = List<double>.filled(eqBands, 0.0);
    _dsp = _dsp.copyWith(eqGains: gains);
    notifyListeners();
    for (int i = 0; i < eqBands; i++) {
      _send(cmdEqBand(i, 0.0));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void _setStatus(ConnectionStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disconnectAll();
    super.dispose();
  }
}
