import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Streaming player for raw Opus packets (16kHz mono, no Ogg container), e.g.
/// TTS audio pushed chunk by chunk.
///
/// Backed by the `tencent_chat_uikit/opus_player` plugin channel, which hosts
/// a single native player: create one [OpusStreamPlayer] at a time, and the
/// most recent one to call [create] receives the events. Playback uses the
/// voice-communication stream so it serves as the AEC reference for a
/// concurrent `RealtimeAudioCapture` in voice-communication mode.
/// Supported on Android 10+ and iOS; elsewhere [isSupported] is false.
class OpusStreamPlayer {
  static const MethodChannel _methodChannel = MethodChannel('tencent_chat_uikit/opus_player');
  static const EventChannel _eventChannel = EventChannel('tencent_chat_uikit/opus_player_events');

  static Future<bool>? _supported;
  static StreamSubscription<dynamic>? _eventSubscription;
  static OpusStreamPlayer? _owner;

  /// Fired after the packets of one [feed] call are decoded and queued, with
  /// the duration of the queued PCM.
  void Function(int durationMs, bool isFinished)? onChunkQueued;

  /// Fired once a stream fed with `isFinished: true` has fully played out.
  VoidCallback? onFinished;

  double _currentLevel = 0;

  /// Playback loudness in 0..1, refreshed about every 50ms while playing and
  /// reset to 0 when playback stops.
  double get currentLevel => _currentLevel;

  /// Whether this device can decode Opus for playback. Resolved once and
  /// cached. Always false on web and on platforms other than Android / iOS.
  static Future<bool> isSupported() {
    return _supported ??= _querySupported();
  }

  static Future<bool> _querySupported() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }
    try {
      return await _methodChannel.invokeMethod<bool>('isSupported') ?? false;
    } catch (e) {
      debugPrint('OpusStreamPlayer.isSupported failed: $e');
      return false;
    }
  }

  /// Creates the native player. Returns false when it cannot be created;
  /// calling it again on an existing player is a no-op returning true.
  Future<bool> create() async {
    if (!await isSupported()) {
      return false;
    }
    _owner = this;
    _ensureEvents();
    try {
      return await _methodChannel.invokeMethod<bool>('create') ?? false;
    } catch (e) {
      debugPrint('OpusStreamPlayer.create failed: $e');
      return false;
    }
  }

  /// Starts a new stream. Packets of the previous stream still being decoded
  /// are discarded.
  void beginStream() {
    _invoke('beginStream');
  }

  /// Queues [packets] for decoding and playback. Pass [isFinished] true with
  /// the last chunk of a stream so [onFinished] fires once it has played out.
  void feed(List<Uint8List> packets, bool isFinished) {
    _invoke('feed', {'packets': packets, 'isFinished': isFinished});
  }

  /// Drops everything queued or playing, e.g. when the user interrupts.
  Future<void> flush() async {
    await _invokeAsync('flush');
  }

  /// Releases the decoder and the native player.
  Future<void> release() async {
    await _invokeAsync('release');
    _currentLevel = 0;
    if (identical(_owner, this)) {
      _owner = null;
    }
  }

  void _invoke(String method, [Object? arguments]) {
    unawaited(_invokeAsync(method, arguments));
  }

  Future<void> _invokeAsync(String method, [Object? arguments]) async {
    if (!await isSupported()) {
      return;
    }
    try {
      await _methodChannel.invokeMethod<void>(method, arguments);
    } catch (e) {
      debugPrint('OpusStreamPlayer.$method failed: $e');
    }
  }

  static void _ensureEvents() {
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object e) => debugPrint('OpusStreamPlayer event error: $e'),
    );
  }

  static void _onEvent(dynamic event) {
    final owner = _owner;
    if (owner == null || event is! Map) {
      return;
    }
    switch (event['type']) {
      case 'chunk':
        owner.onChunkQueued?.call(
          (event['durationMs'] as num?)?.toInt() ?? 0,
          event['isFinished'] == true,
        );
        break;
      case 'level':
        owner._currentLevel = ((event['value'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
        break;
      case 'finished':
        owner._currentLevel = 0;
        owner.onFinished?.call();
        break;
    }
  }
}
