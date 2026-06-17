import 'dart:convert';
import 'dart:math' as math;

const int eqBands = 10;

const String bleServiceUuid = 'cafecafe-cafe-cafe-cafe-cafecafe0001';
const String bleCmdCharUuid = 'cafecafe-cafe-cafe-cafe-cafecafe0002';
const String bleStatsCharUuid = 'cafecafe-cafe-cafe-cafe-cafecafe0003';

const List<double> eqFreqsHz = [
  31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
];

String eqFreqLabel(double hz) =>
    hz >= 1000 ? '${(hz / 1000).toStringAsFixed(0)}k' : hz.toStringAsFixed(0);

// ─── Source ───────────────────────────────────────────────────────────────────

enum AudioSource { airplay, bluetooth }

extension AudioSourceX on AudioSource {
  String get jsonValue => name;
  String get displayName => this == AudioSource.airplay ? 'AirPlay' : 'Bluetooth';
  int get sampleRate => this == AudioSource.airplay ? 352800 : 48000;
  AudioSource get toggled =>
      this == AudioSource.airplay ? AudioSource.bluetooth : AudioSource.airplay;
}

// ─── DSP state ────────────────────────────────────────────────────────────────

class DspState {
  final double volume;
  final List<double> eqGains;
  final bool loudness;
  final bool limiter;
  final bool muted;
  final AudioSource source;

  const DspState({
    required this.volume,
    required this.eqGains,
    required this.loudness,
    required this.limiter,
    required this.muted,
    required this.source,
  });

  factory DspState.initial() => DspState(
        volume: 0.8,
        eqGains: List.filled(eqBands, 0.0),
        loudness: true,
        limiter: true,
        muted: false,
        source: AudioSource.airplay,
      );

  factory DspState.fromJson(Map<String, dynamic> j) => DspState(
        volume: (j['volume'] as num).toDouble(),
        eqGains: (j['eq_gains'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
        loudness: j['loudness'] as bool,
        limiter: j['limiter'] as bool,
        muted: j['muted'] as bool,
        source: j['source'] == 'bluetooth'
            ? AudioSource.bluetooth
            : AudioSource.airplay,
      );

  DspState copyWith({
    double? volume,
    List<double>? eqGains,
    bool? loudness,
    bool? limiter,
    bool? muted,
    AudioSource? source,
  }) =>
      DspState(
        volume: volume ?? this.volume,
        eqGains: eqGains ?? this.eqGains,
        loudness: loudness ?? this.loudness,
        limiter: limiter ?? this.limiter,
        muted: muted ?? this.muted,
        source: source ?? this.source,
      );
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class StatsSnapshot {
  final double rmsL, rmsR, peakL, peakR;
  final bool clipping, limiterActive, signalActive;
  final int framesPerSec;

  const StatsSnapshot({
    required this.rmsL,
    required this.rmsR,
    required this.peakL,
    required this.peakR,
    required this.clipping,
    required this.limiterActive,
    required this.signalActive,
    required this.framesPerSec,
  });

  factory StatsSnapshot.fromJson(Map<String, dynamic> j) => StatsSnapshot(
        rmsL: (j['rms_l'] as num).toDouble(),
        rmsR: (j['rms_r'] as num).toDouble(),
        peakL: (j['peak_l'] as num).toDouble(),
        peakR: (j['peak_r'] as num).toDouble(),
        clipping: j['clipping'] as bool,
        limiterActive: j['limiter_active'] as bool,
        signalActive: j['signal_active'] as bool,
        framesPerSec: (j['frames_per_sec'] as num).toInt(),
      );

  static double toDbfs(double linear) {
    if (linear < 1e-9) return -90.0;
    return 20.0 * math.log(linear) / math.ln10;
  }

  // Maps linear amplitude to a 0..1 gauge value (log scale, 60 dB range).
  static double toGaugePct(double linear) {
    if (linear < 1e-9) return 0.0;
    final db = 20.0 * math.log(linear) / math.ln10;
    return ((db + 60.0) / 60.0).clamp(0.0, 1.0);
  }
}

// ─── Track info ───────────────────────────────────────────────────────────────

class TrackInfo {
  final String? title, artist, album;
  final int? durationMs;
  final int? positionMs;
  final DateTime? positionReceivedAt;

  const TrackInfo({
    this.title,
    this.artist,
    this.album,
    this.durationMs,
    this.positionMs,
    this.positionReceivedAt,
  });

  bool get isEmpty => title == null && artist == null && album == null;

  factory TrackInfo.fromJson(Map<String, dynamic> j) {
    final posMs = j['position_ms'] as int?;
    return TrackInfo(
      title: j['title'] as String?,
      artist: j['artist'] as String?,
      album: j['album'] as String?,
      durationMs: j['duration_ms'] as int?,
      positionMs: posMs,
      positionReceivedAt: posMs != null ? DateTime.now() : null,
    );
  }

  int? get currentPositionMs {
    if (positionMs == null) return null;
    if (positionReceivedAt == null) return positionMs;
    final elapsed =
        DateTime.now().difference(positionReceivedAt!).inMilliseconds;
    final end = durationMs ?? 999999999;
    return (positionMs! + elapsed).clamp(0, end);
  }

  String get subtitle {
    final a = artist ?? '';
    final al = album ?? '';
    if (a.isNotEmpty && al.isNotEmpty) return '$a — $al';
    if (a.isNotEmpty) return a;
    if (al.isNotEmpty) return al;
    return '';
  }
}

// ─── Incoming message ─────────────────────────────────────────────────────────

sealed class ServiceMessage {
  const ServiceMessage();
}

class StateMessage extends ServiceMessage {
  final DspState state;
  const StateMessage(this.state);
}

class StatsMessage extends ServiceMessage {
  final StatsSnapshot stats;
  const StatsMessage(this.stats);
}

class NowPlayingMessage extends ServiceMessage {
  final TrackInfo track;
  const NowPlayingMessage(this.track);
}

ServiceMessage? parseMessage(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return switch (map['type'] as String?) {
      'state' => StateMessage(DspState.fromJson(map)),
      'stats' => StatsMessage(StatsSnapshot.fromJson(map)),
      'now_playing' => NowPlayingMessage(TrackInfo.fromJson(map)),
      _ => null,
    };
  } catch (_) {
    return null;
  }
}

// ─── Commands ─────────────────────────────────────────────────────────────────

String encodeCmd(Map<String, dynamic> cmd) => jsonEncode(cmd);

Map<String, dynamic> cmdVolume(double v) => {'cmd': 'set_volume', 'value': v};
Map<String, dynamic> cmdEqBand(int band, double db) =>
    {'cmd': 'set_eq_band', 'band': band, 'gain_db': db};
Map<String, dynamic> cmdLoudness(bool v) => {'cmd': 'set_loudness', 'value': v};
Map<String, dynamic> cmdLimiter(bool v) => {'cmd': 'set_limiter', 'value': v};
Map<String, dynamic> cmdSource(AudioSource s) =>
    {'cmd': 'set_source', 'value': s.jsonValue};
Map<String, dynamic> cmdMute(bool v) => {'cmd': 'set_mute', 'value': v};
