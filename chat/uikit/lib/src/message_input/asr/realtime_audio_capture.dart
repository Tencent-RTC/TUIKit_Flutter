import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audio source profile for [RealtimeAudioCapture.start].
enum RealtimeAudioCaptureMode {
  /// Plain microphone for speech recognition, no echo cancellation. Used by
  /// the press-to-talk realtime transcription.
  recognition,

  /// Voice-call source with AEC / NS / AGC where available. Use it while the
  /// device is also playing audio (e.g. AI voice call) so the playback is not
  /// picked up again.
  voiceCommunication,
}

/// Called every 20ms with the raw Opus packets encoded from that frame
/// (0..n, no Ogg container) and the frame's PCM16 RMS (0~32767).
typedef RealtimeAudioFrameCallback = void Function(List<Uint8List> packets, double rms);

/// Realtime 16kHz mono microphone capture encoded to raw Opus packets
/// (24kbps, 20ms frames), plus the audio-session switching needed by voice
/// calls.
///
/// Process-wide singleton backed by the `tencent_chat_uikit/realtime_audio`
/// plugin channel. Only one capture runs at a time: [start] replaces any
/// capture already running, and only the latest `onFrame` receives frames.
/// Supported on Android 10+ and iOS; elsewhere [isSupported] is false and
/// every other call is a no-op.
class RealtimeAudioCapture {
  RealtimeAudioCapture._();

  /// The shared instance.
  static final RealtimeAudioCapture instance = RealtimeAudioCapture._();

  static const MethodChannel _methodChannel = MethodChannel('tencent_chat_uikit/realtime_audio');
  static const EventChannel _eventChannel = EventChannel('tencent_chat_uikit/realtime_audio_events');

  static Future<bool>? _supported;

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<bool> _focusController = StreamController<bool>.broadcast();
  RealtimeAudioFrameCallback? _onFrame;

  /// Bumped on every start / stop; a start that resolves after a newer
  /// start / stop must not reclaim the frame callback.
  int _session = 0;

  /// Whether this device can capture and encode Opus in realtime. Resolved
  /// once and cached. Always false on web and on platforms other than
  /// Android / iOS, without touching the channel.
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
      debugPrint('RealtimeAudioCapture.isSupported failed: $e');
      return false;
    }
  }

  /// Starts capturing. A capture already running is stopped first.
  ///
  /// [minBufferFrames] sizes the native record buffer in 20ms frames; leave it
  /// null to use the mode default (8 for [RealtimeAudioCaptureMode.recognition],
  /// 10 for [RealtimeAudioCaptureMode.voiceCommunication]).
  ///
  /// Returns false when capture could not start (unsupported device, missing
  /// microphone permission, encoder failure). Callers should not retry.
  Future<bool> start({
    required RealtimeAudioCaptureMode mode,
    int? minBufferFrames,
    required RealtimeAudioFrameCallback onFrame,
  }) async {
    if (!await isSupported()) {
      return false;
    }
    final session = ++_session;
    _onFrame = null;
    // The native side only has an event sink while Dart listens, so the
    // subscription must exist before frames start flowing.
    _ensureEvents();
    bool started;
    try {
      started = await _methodChannel.invokeMethod<bool>('startCapture', {
            'mode': mode == RealtimeAudioCaptureMode.voiceCommunication ? 'voiceCommunication' : 'recognition',
            if (minBufferFrames != null) 'minBufferFrames': minBufferFrames,
          }) ??
          false;
    } catch (e) {
      debugPrint('RealtimeAudioCapture.start failed: $e');
      started = false;
    }
    if (session != _session) {
      return false;
    }
    if (started) {
      _onFrame = onFrame;
    }
    return started;
  }

  /// Stops capturing. Safe to call repeatedly or when nothing is running.
  Future<void> stop() async {
    _session++;
    _onFrame = null;
    if (!await isSupported()) {
      return;
    }
    await _invoke('stopCapture');
  }

  /// Resets the Opus encoder on the next captured frame, so a new recognition
  /// session does not start with state carried over from the previous one.
  Future<void> requestEncoderReset() async {
    if (!await isSupported()) {
      return;
    }
    await _invoke('requestEncoderReset');
  }

  /// Debug description of the active audio source and AEC / NS / AGC state;
  /// `capture=idle` when nothing is running.
  Future<String> effectSummary() async {
    if (!await isSupported()) {
      return 'capture=unsupported';
    }
    try {
      return await _methodChannel.invokeMethod<String>('effectSummary') ?? '';
    } catch (e) {
      return 'capture=error($e)';
    }
  }

  /// Switches the audio session into voice-call mode (Android
  /// `MODE_IN_COMMUNICATION` + audio focus, iOS `.playAndRecord` /
  /// `.voiceChat`). Pair with [exitVoiceCallMode]. Focus / interruption
  /// changes are reported through [focusChanges] while in this mode.
  Future<bool> enterVoiceCallMode() async {
    if (!await isSupported()) {
      return false;
    }
    _ensureEvents();
    try {
      return await _methodChannel.invokeMethod<bool>('enterVoiceCallMode') ?? false;
    } catch (e) {
      debugPrint('RealtimeAudioCapture.enterVoiceCallMode failed: $e');
      return false;
    }
  }

  /// Restores the audio mode / focus saved by [enterVoiceCallMode].
  Future<void> exitVoiceCallMode() async {
    if (!await isSupported()) {
      return;
    }
    await _invoke('exitVoiceCallMode');
  }

  /// Audio focus / session interruption changes: true when focus is
  /// (re)gained, false when it is lost to a call or another app.
  Stream<bool> get focusChanges {
    _ensureEvents();
    return _focusController.stream;
  }

  Future<void> _invoke(String method) async {
    try {
      await _methodChannel.invokeMethod<void>(method);
    } catch (e) {
      debugPrint('RealtimeAudioCapture.$method failed: $e');
    }
  }

  void _ensureEvents() {
    if (_eventSubscription != null || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (Object e) => debugPrint('RealtimeAudioCapture event error: $e'),
    );
  }

  void _onEvent(dynamic event) {
    if (event is! Map) {
      return;
    }
    switch (event['type']) {
      case 'frame':
        final onFrame = _onFrame;
        if (onFrame == null) {
          return;
        }
        final rawPackets = event['packets'];
        final packets = <Uint8List>[
          if (rawPackets is List)
            for (final packet in rawPackets)
              if (packet is Uint8List && packet.isNotEmpty) packet,
        ];
        final rms = (event['rms'] as num?)?.toDouble() ?? 0;
        onFrame(packets, rms);
        break;
      case 'focus':
        _focusController.add(event['state'] == 'gain');
        break;
    }
  }
}
