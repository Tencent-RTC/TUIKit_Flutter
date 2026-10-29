import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../message_input/asr/realtime_asr_experimental.dart';
import '../ai_constants.dart';

/// IMSDK realtime transcription session: owns the sessionID lifecycle and
/// batches audio packets.
///
/// Results do not come through here; they arrive via
/// [RealtimeAsrExperimental.addResponseListener] and are handled by the call
/// controller.
class AsrSession {
  AsrSession({required this.onStarted, required this.onStartFailed});

  static const String _tag = 'AsrSession';

  /// Reported through [onStartFailed] when the start request times out.
  static const int errStartTimeout = -1001;

  /// Reported through [onStartFailed] when the backend returned no sessionID.
  static const int errEmptySessionID = -1;

  final VoidCallback onStarted;
  final void Function(int code, String desc) onStartFailed;

  final List<Uint8List> _pendingPackets = [];

  String? _currentSessionID;
  bool _starting = false;
  Timer? _startTimeout;

  /// The sessionID just closed by [stop] whose trailing results may still be
  /// on the way. Its lifetime belongs to the caller: [stop] sets it, [endDrain]
  /// clears it.
  String? _drainingSessionID;

  /// Bumped on every transition (start / started / failed / timeout / stop).
  /// Each start request and its timeout capture the value they were issued
  /// with; a mismatch means they are stale. A boolean would not do: a start
  /// right after stop would reset it and let the earlier request's late
  /// callback be taken for the current session.
  int _generation = 0;

  String? get sessionID => _currentSessionID;

  /// The start request is out and the sessionID has not come back yet.
  bool get isStarting => _starting;

  /// The session being drained, null when none. Callers use it to claim
  /// results arriving after [stop].
  String? get drainSessionID => _drainingSessionID;

  /// Has a sessionID, or a start request is in flight.
  bool get isLive => _currentSessionID != null || _starting;

  void start() {
    // A new session means the previous drain is over either way.
    _drainingSessionID = null;
    if (_starting || _currentSessionID != null) {
      // A caller that forgot stop() shows up as "stuck thinking": onStarted
      // never arrives and this line is the only clue.
      debugPrint(
          '$_tag: start ignored, session already active (starting=$_starting, id=$_currentSessionID)');
      return;
    }
    _starting = true;
    final gen = ++_generation;
    _pendingPackets.clear();
    _scheduleStartTimeout(gen);

    RealtimeAsrExperimental.start(language: AIConstants.asrLanguage)
        .then((result) {
      final id = result.sessionID;
      if (result.isSuccess) {
        // Late success after the caller gave up: close the backend session
        // right away so it does not dangle.
        if (gen != _generation) {
          debugPrint(
              '$_tag: start succeeded after abandon, closing session $id');
          if (id.isNotEmpty) {
            RealtimeAsrExperimental.stop(sessionID: id);
          }
          return;
        }
        _cancelStartTimeout();
        _generation++;
        _starting = false;
        if (id.isEmpty) {
          debugPrint('$_tag: start returned an empty sessionID');
          onStartFailed(errEmptySessionID, 'empty sessionID');
          return;
        }
        _currentSessionID = id;
        debugPrint('$_tag: ASR session started: $id');
        onStarted();
        return;
      }
      if (gen != _generation) {
        debugPrint(
            '$_tag: start failed after abandon: ${result.code} ${result.desc}');
        return;
      }
      _cancelStartTimeout();
      _generation++;
      _starting = false;
      debugPrint('$_tag: start failed: ${result.code} ${result.desc}');
      onStartFailed(result.code, result.desc);
    });
  }

  /// Queues one raw Opus packet; every [AIConstants.uploadBatchFrames] packets
  /// (100ms) are uploaded. Dropped while no session is ready.
  void pushPacket(Uint8List packet) {
    final id = _currentSessionID;
    if (id == null) return;
    _pendingPackets.add(packet);
    if (_pendingPackets.length >= AIConstants.uploadBatchFrames) {
      _flush(id);
    }
  }

  /// Flushes the tail packets and stops the session. Safe to call repeatedly.
  ///
  /// [onStopped] fires once when the stop request completes, success or not.
  /// It is **not guaranteed** to fire (the backend may never answer), so
  /// callers need their own timeout. Without a session to stop it fires
  /// immediately, meaning "the drain is already over".
  void stop({VoidCallback? onStopped}) {
    _cancelStartTimeout();
    // Invalidates in-flight start requests; their success callbacks close the
    // session they got.
    _generation++;
    _starting = false;
    final id = _currentSessionID;
    _currentSessionID = null;
    if (id == null) {
      _pendingPackets.clear();
      onStopped?.call();
      return;
    }
    // The tail batch must go up before the drain session is recorded: it is
    // where the trailing results come from.
    if (_pendingPackets.isNotEmpty) {
      _flush(id);
    }
    _drainingSessionID = id;
    RealtimeAsrExperimental.stop(sessionID: id).then((result) {
      if (result.isSuccess) {
        debugPrint('$_tag: ASR session stopped: $id');
      } else {
        // Let the drain end on failure too: a session that cannot be stopped
        // will not produce more results.
        debugPrint('$_tag: stop failed: ${result.code} ${result.desc}');
      }
      onStopped?.call();
    });
  }

  /// Ends the drain window: [drainSessionID] becomes null and late results are
  /// no longer claimed. Safe to call repeatedly.
  void endDrain() {
    _drainingSessionID = null;
  }

  /// The backend already closed [sessionID] (idle / hard timeout isFinished):
  /// stop pushing audio and do not call stop on it. [start] can then open a
  /// new session.
  void noteRemoteFinished(String sessionID) {
    if (_currentSessionID != sessionID) {
      return;
    }
    _generation++;
    _starting = false;
    _currentSessionID = null;
    _pendingPackets.clear();
  }

  void _scheduleStartTimeout(int gen) {
    _startTimeout =
        Timer(const Duration(milliseconds: AIConstants.asrStartTimeoutMs), () {
      _startTimeout = null;
      if (gen != _generation) {
        return;
      }
      debugPrint(
          '$_tag: start timed out after ${AIConstants.asrStartTimeoutMs}ms');
      // Invalidate the request: a success arriving later takes the "abandoned"
      // branch and stops its own session.
      _generation++;
      _starting = false;
      onStartFailed(errStartTimeout, 'startRealtimeTranscriber timeout');
    });
  }

  void _cancelStartTimeout() {
    _startTimeout?.cancel();
    _startTimeout = null;
  }

  void _flush(String sessionID) {
    final batch = List<Uint8List>.of(_pendingPackets);
    _pendingPackets.clear();
    RealtimeAsrExperimental.feed(sessionID: sessionID, packets: batch)
        .then((result) {
      // Packet loss is tolerated: log and keep the session going.
      if (!result.isSuccess) {
        debugPrint('$_tag: feed failed: ${result.code} ${result.desc}');
      }
    });
  }
}
