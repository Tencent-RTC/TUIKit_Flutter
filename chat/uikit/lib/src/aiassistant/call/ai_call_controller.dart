import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import '../../message_input/asr/asr_service_error.dart';
import '../../message_input/asr/opus_stream_player.dart';
import '../../message_input/asr/realtime_asr_experimental.dart';
import '../../message_input/asr/realtime_audio_capture.dart';
import '../ai_assistant_control_messages.dart';
import '../ai_constants.dart';
import '../audio/asr_barge_in.dart';
import '../audio/asr_session.dart';
import '../audio/energy_vad.dart';
import '../audio/tts_session.dart';
import 'ai_call_state.dart';

/// Errors the call page shows as a toast.
enum AICallError {
  replyTimeout,
  startFailed,
  sendFailed,
  audioUnavailable,
  playbackUnavailable,
}

@visibleForTesting
({String msgID, List<Uint8List> packets, bool isFinished})
    parseTtsResponsePayload(dynamic response) {
  final msgID = response.msgID as String? ?? '';
  final rawPackets = response.audioDataList as Iterable<dynamic>? ?? const [];
  final packets = <Uint8List>[
    for (final packet in rawPackets)
      if (packet is Uint8List && packet.isNotEmpty) packet,
  ];
  final isFinished = response.isFinished == true;
  return (msgID: msgID, packets: packets, isFinished: isFinished);
}

class AICallCallbacks {
  const AICallCallbacks({
    required this.onStateChanged,
    required this.onTranscriptChanged,
    required this.onAudioLevel,
    required this.onError,
    required this.onListeningFailed,
    required this.onAsrServiceUnavailable,
  });

  final void Function(AICallState state) onStateChanged;
  final void Function(List<TranscriptEntry> entries) onTranscriptChanged;
  final void Function(double level) onAudioLevel;
  final void Function(AICallError error) onError;

  /// The ASR session could not start; the call sits in idle until the user
  /// retries ([AICallController.retryListening]). The state callback alone
  /// cannot express this: idle also means "not started", "muted" and
  /// "paused".
  final VoidCallback onListeningFailed;

  /// Recognition is not enabled or the package ran out
  /// ([AsrServiceError.isServiceUnavailable]). Retrying does not help; neither
  /// [onError] nor [onListeningFailed] fires in this case.
  final VoidCallback onAsrServiceUnavailable;
}

/// State machine and pipeline of the voice call page.
///
/// The microphone and the ASR session stay open: listening, thinking and
/// speaking all upload microphone audio. The turn still ends on the local
/// energy VAD; barge-in during playback is decided on ASR text that does not
/// look like the current TTS. Only mute, pause and hang-up stop the session.
///
/// Everything runs on the UI isolate. Capture frames, IMSDK listeners, ASR
/// results and player events all arrive in order on it.
class AICallController {
  AICallController({required this.robotUserID, required this.callbacks})
      : _messageInputStore =
            MessageInputStore.create(conversationID: 'c2c_$robotUserID');

  static const String _tag = 'AICallController';

  /// The TTS listener is experimental and absent from older IMSDK releases.
  /// Build it dynamically so the rest of Chat UIKit remains source-compatible
  /// with those releases, then hide the voice entry when it is unavailable.
  static Future<bool> isSupported() async {
    if (!_hasTtsListenerApi()) return false;
    return await RealtimeAudioCapture.isSupported() &&
        await OpusStreamPlayer.isSupported();
  }

  static bool _hasTtsListenerApi() {
    try {
      _createAdvancedMessageListener(
        onMessage: (_) {},
        onTtsResponse: (_) {},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static V2TimAdvancedMsgListener _createAdvancedMessageListener({
    required void Function(V2TimMessage) onMessage,
    required void Function(dynamic) onTtsResponse,
  }) {
    final dynamic constructor = V2TimAdvancedMsgListener.new;
    return Function.apply(
      constructor,
      const [],
      <Symbol, dynamic>{
        #onRecvNewMessage: onMessage,
        #onRecvMessageModified: onMessage,
        #onRecvTTSResponse: onTtsResponse,
      },
    ) as V2TimAdvancedMsgListener;
  }

  final String robotUserID;
  final AICallCallbacks callbacks;

  final MessageInputStore _messageInputStore;

  final EnergyVad _vad = EnergyVad(
    frameDurationMs: AIConstants.frameDurationMs,
    calibrationFrames:
        AIConstants.noiseCalibrationMs ~/ AIConstants.frameDurationMs,
    minNoiseFloor: AIConstants.vadMinNoiseFloor,
  );

  AICallState _state = AICallState.idle;
  bool _released = false;

  /// Microphone mute. Muted frames are dropped whole: no VAD, no uplink.
  bool _muted = false;

  /// Whether [_sentences] holds non-empty text. The turn ends on "silent long
  /// enough **and** something was recognized".
  bool _hasRecognizedText = false;

  /// Null when the player could not be created; the call then degrades to
  /// text only. **Never enter speaking without it**: nothing would play and
  /// onFinished would never fire.
  OpusStreamPlayer? _player;

  /// Whether this controller currently holds the shared capture.
  bool _captureOwned = false;

  AsrSession? _asrSession;

  bool _listenersAdded = false;

  /// enterVoiceCall was sent, so leaveVoiceCall is owed on release.
  bool _voiceSessionEntered = false;

  /// Paused for an external reason (focus loss, page in background). Both
  /// sources share one flag on purpose: an incoming call often triggers both,
  /// and either recovery signal should bring the call back.
  bool _pausedExternally = false;

  /// [resume] reopens the capture asynchronously. A [pause] arriving in the
  /// meantime bumps [_resumeToken] so the late open is undone; a [resume]
  /// arriving in the meantime is queued.
  bool _resuming = false;
  bool _resumeQueued = false;
  int _resumeToken = 0;

  /// The ASR start failed; the call sits in idle until [retryListening].
  bool _startFailed = false;

  final TtsSession _ttsSession = TtsSession();

  /// The stream message currently being read.
  String? _streamingMsgID;

  /// startTTS succeeded for [_streamingMsgID]; set only in the success
  /// callback.
  bool _hasStartedTTS = false;

  /// startTTS is out without a result yet. Repeating it on every stream delta
  /// is pointless.
  bool _ttsStartPending = false;

  /// Whether the latest delta of [_streamingMsgID] ended the stream.
  bool _streamEnded = false;

  /// Index of the AI line of this turn in [_transcript], -1 before it exists.
  int _aiEntryIndex = -1;

  /// TTS audio queued this turn, the upper bound of the remaining playback for
  /// the speaking watchdog.
  int _enqueuedAudioMs = 0;

  /// This turn's ASR results: chunkIndex -> latest full text of that sentence
  /// (overwritten, not incremental).
  final SplayTreeMap<int, String> _sentences = SplayTreeMap<int, String>();

  /// Generation of the ASR drain window, +1 per window. The timeout captures
  /// the value it was armed with and exits on mismatch.
  int _drainGeneration = 0;

  /// Non-null means **the drain window is open**; [_handleAsrResponse] lets
  /// late results in through it.
  Timer? _drainTimeout;

  /// [AsrSession.start] was just called and onStarted should switch to
  /// listening. Not used when ASR restarts mid-playback, or speaking would be
  /// overwritten.
  bool _awaitingAsrForListening = false;

  /// User text already sent to the robot. With the session always open the
  /// backend keeps sending tail updates for it; those must not count as
  /// barge-in.
  String _committedUserText = '';

  final List<TranscriptEntry> _transcript = [];

  Timer? _replyTimeout;

  /// Fallback for speaking. [_replyTimeout] only covers thinking: a broken
  /// downlink that never sends isFinished, or a device that never fires
  /// onFinished, would otherwise leave the call speaking forever.
  Timer? _speakingWatchdog;

  late final V2TimAdvancedMsgListener _msgListener =
      _createAdvancedMessageListener(
    onMessage: _handleStreamMessage,
    onTtsResponse: _handleTtsResponse,
  );

  AICallState get state => _state;

  /// The microphone permission must already be granted. Resolves true when
  /// the microphone started.
  Future<bool> start() async {
    if (_released) return false;
    if (!await RealtimeAudioCapture.isSupported()) {
      _debug('Opus encoder unavailable');
      if (!_released) callbacks.onError(AICallError.audioUnavailable);
      return false;
    }
    if (_released) return false;
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: _msgListener);
    RealtimeAsrExperimental.addResponseListener(_handleAsrResponse);
    _listenersAdded = true;

    final opened = await _openCapture();
    if (_released) return false;
    if (!opened) {
      _debug('capture failed to start');
      _removeListeners();
      callbacks.onError(AICallError.audioUnavailable);
      return false;
    }
    if (kDebugMode) {
      RealtimeAudioCapture.instance
          .effectSummary()
          .then((summary) => _debug('capture $summary'));
    }

    // A player that cannot start does not stop listening and recognition; the
    // call only degrades to text: without it TTS is never requested and
    // replies show in the transcript.
    final player = OpusStreamPlayer()
      ..onChunkQueued = _onTtsChunkQueued
      ..onFinished = _onPlaybackFinished;
    final created = await player.create();
    if (_released) {
      unawaited(player.release());
      return false;
    }
    _player = created ? player : null;
    if (!_canPlayTts) {
      _debug('TTS playback unavailable');
      callbacks.onError(AICallError.playbackUnavailable);
    }

    _asrSession =
        AsrSession(onStarted: _onAsrStarted, onStartFailed: _onAsrStartFailed);
    // The first turn skips _enterListening(): the state is idle with nothing
    // to leave, and idle's resting orb is the right "not listening yet" look.
    _awaitingAsrForListening = true;
    // The encoder was just created; resetting it now only races the start.
    _startNewAsrSession(resetEncoder: false);
    _sendVoiceSessionPing(AIConstants.voiceEnterAction);
    _voiceSessionEntered = true;
    return true;
  }

  void release() {
    if (_released) return;
    _released = true;
    if (_voiceSessionEntered) {
      _sendVoiceSessionPing(AIConstants.voiceLeaveAction);
    }
    _cancelReplyTimeout();
    _cancelSpeakingWatchdog();
    _closeDrainWindow();
    // Capture first: once it stops no more frames reach the session.
    _stopCapture();
    _ttsSession.stop();
    final player = _player;
    _player = null;
    if (player != null) {
      unawaited(player.release());
    }
    _asrSession?.stop();
    _asrSession = null;
    _removeListeners();
    _setState(AICallState.idle);
  }

  // ------------------------------------------------------------ mute / pause

  /// Microphone mute.
  ///
  /// Muting **voids the whole turn**, not just the uplink: the answer being
  /// read stops at once and the half-recognized sentence is dropped.
  ///
  /// The ASR session must really stop: [AsrSession.start] returns early while
  /// a session is live, so unmuting would be swallowed and the call would
  /// hang in thinking. Unmuting reuses [_enterListening], the same path as
  /// finishing a turn.
  void setMuted(bool newMuted) {
    if (_released || _muted == newMuted) return;
    _muted = newMuted;
    _debug('muted -> $newMuted');
    if (newMuted) {
      _abandonCurrentReply();
      _asrSession?.stop();
      _awaitingAsrForListening = false;
      _committedUserText = '';
      _clearSentences();
      _notifyTranscript();
      _setState(AICallState.idle);
    } else if (!_pausedExternally) {
      // While paused the capture is stopped; [resume] restarts listening.
      _enterListening();
    }
  }

  /// Pauses the whole call: audio focus lost (incoming call, another app) or
  /// the page went to the background.
  ///
  /// Unlike [setMuted] the capture is stopped too, **actually handing the
  /// microphone back**. In the background the system takes the microphone and
  /// capture returns all-zero frames; the VAD reads them as silence and a half
  /// sentence would be sent automatically, with the TTS reply then playing out
  /// loud in the background.
  ///
  /// [_streamingMsgID] / [_hasStartedTTS] stay untouched (see
  /// [_enterListening]): [TtsSession.stop] unbinds the message and in-flight
  /// chunks are dropped by the msgID check; clearing them early would make a
  /// late modify look like a new turn and read the same answer again.
  void pause() {
    if (_released) return;
    if (_pausedExternally) {
      _resumeToken++;
      _resumeQueued = false;
      return;
    }
    _pausedExternally = true;
    _debug('paused');
    _abandonCurrentReply();
    _asrSession?.stop();
    _awaitingAsrForListening = false;
    _committedUserText = '';
    _clearSentences();
    _notifyTranscript();
    _stopCapture();
    _setState(AICallState.idle);
  }

  /// Takes the microphone back and returns to listening, on focus gain or when
  /// the page is visible again. No-op when not paused.
  Future<void> resume() async {
    if (_released || !_pausedExternally) return;
    if (_resuming) {
      _resumeQueued = true;
      return;
    }
    _resuming = true;
    final token = _resumeToken;
    final opened = await _openCapture();
    _resuming = false;
    if (_released) return;
    if (token != _resumeToken) {
      // Paused again while the capture was opening.
      _stopCapture();
      if (_resumeQueued) {
        _resumeQueued = false;
        unawaited(resume());
      }
      return;
    }
    _resumeQueued = false;
    if (!opened) {
      // Right after focus returns the microphone may still be held by the
      // phone call. [_pausedExternally] stays set so the next focus gain or
      // resume can try again instead of pinning the page in idle.
      _debug('resume failed: capture did not start');
      callbacks.onError(AICallError.audioUnavailable);
      return;
    }
    _pausedExternally = false;
    _debug('resumed');
    // The environment may have changed completely during the call; measure
    // the noise floor again.
    _vad.resetCalibration();
    if (_muted) {
      // Muted: only take the microphone back; the session opens on unmute.
      return;
    }
    _enterListening();
  }

  /// Manual retry after the ASR start failed.
  ///
  /// No automatic retry: on a weak network consecutive retries only stack
  /// toasts while the user may want to hang up. Ignored while muted or paused;
  /// their own exits restart listening.
  void retryListening() {
    if (_released || !_startFailed || _muted || _pausedExternally) return;
    _debug('retry listening');
    _enterListening();
  }

  // ------------------------------------------------------------------ audio

  Future<bool> _openCapture() async {
    _captureOwned = true;
    final opened = await RealtimeAudioCapture.instance.start(
      mode: RealtimeAudioCaptureMode.voiceCommunication,
      onFrame: _onAudioFrame,
    );
    if (!opened) {
      _captureOwned = false;
    }
    return opened;
  }

  void _stopCapture() {
    if (!_captureOwned) return;
    _captureOwned = false;
    unawaited(RealtimeAudioCapture.instance.stop());
  }

  void _onAudioFrame(List<Uint8List> packets, double rms) {
    if (_released || _muted) return;
    final frameState = _state;
    if (frameState != AICallState.idle) {
      final session = _asrSession;
      if (session != null) {
        for (final packet in packets) {
          session.pushPacket(packet);
        }
      }
    }
    _vad.accept(rms);
    // While speaking the level follows playback; following the microphone
    // there would animate the AI's own voice leaking in.
    final level = frameState == AICallState.speaking
        ? (_player?.currentLevel ?? 0.0)
        // 3000 is an empirical full-scale reference for the microphone, used
        // only for the animation.
        : (rms / 3000.0).clamp(0.0, 1.0).toDouble();
    callbacks.onAudioLevel(level);

    if (frameState == AICallState.listening) {
      // Without the second condition the turn would end before the user said
      // anything.
      if (_vad.hasSilenceFor(AIConstants.silenceHoldMs) && _hasRecognizedText) {
        _finishListeningTurn();
      }
    }
  }

  // -------------------------------------------------------------------- ASR

  void _onAsrStarted() {
    if (_released) return;
    _debug(
        'vad noise floor: raw=${_vad.rawNoiseFloor}, effective=${_vad.effectiveNoiseFloor}, '
        'calibrated=${_vad.isCalibrated}');
    _startFailed = false;
    if (!_awaitingAsrForListening) {
      _debug('asr started, staying in $_state (session recovered)');
      return;
    }
    _awaitingAsrForListening = false;
    // TTS may have taken this turn during the start window. Switching to
    // listening would let the speaker leak into recognition.
    if (_state == AICallState.speaking || _ttsSession.boundMsgID != null) {
      _debug(
          'asr started but this turn is taken over by TTS, staying in $_state');
      if (_state == AICallState.thinking) {
        _armReplyTimeout();
      }
      return;
    }
    _setState(AICallState.listening);
  }

  void _onAsrStartFailed(int code, String desc) {
    if (_released) return;
    _awaitingAsrForListening = false;
    _debug('ASR start failed: $code $desc');
    // Flag before the state change: idle's text needs it to show "tap the mic
    // to retry" instead of "listening", and the state callback is synchronous.
    _startFailed = true;
    if (AsrServiceError.isServiceUnavailable(code)) {
      // The call cannot go on; hand the microphone back now.
      _stopCapture();
      callbacks.onAsrServiceUnavailable();
    } else {
      callbacks.onError(AICallError.startFailed);
      callbacks.onListeningFailed();
    }
    _setState(AICallState.idle);
  }

  /// [resetEncoder] drops the Opus inter-frame state. The microphone stays
  /// open while sessions open and close per turn, so without a reset the
  /// first word of the new session would be encoded with the previous turn's
  /// prediction state.
  void _startNewAsrSession({bool resetEncoder = true}) {
    // stop() first: [AsrSession.start] returns early while a session is live
    // or starting, and onStarted would then never arrive, leaving the call
    // stuck in thinking.
    _asrSession?.stop();
    _vad.reset();
    if (resetEncoder && _captureOwned) {
      unawaited(RealtimeAudioCapture.instance.requestEncoderReset());
    }
    _asrSession?.start();
  }

  void _handleAsrResponse(RealtimeAsrResponse response) {
    if (_released) return;
    final session = _asrSession;
    if (session == null) return;
    final responseID = response.sessionID;
    if (responseID.isEmpty) return;
    final accepted = responseID == session.sessionID ||
        (_drainTimeout != null && responseID == session.drainSessionID);
    if (!accepted) return;
    if (response.isFinished && responseID == session.sessionID) {
      _debug('ASR session finished remotely, restarting');
      session.noteRemoteFinished(responseID);
      if (!_muted && !_pausedExternally) {
        final wantListen =
            _state == AICallState.listening || _awaitingAsrForListening;
        if (wantListen) {
          _awaitingAsrForListening = true;
        }
        session.start();
      }
    }
    final text = response.text;
    if (text.isEmpty) return;
    switch (_state) {
      case AICallState.listening:
        _sentences[response.chunkIndex] = text;
        _hasRecognizedText = true;
        _notifyTranscript(pendingUserText: _joinedText());
        break;
      case AICallState.thinking:
        if (_drainTimeout != null) {
          _sentences[response.chunkIndex] = text;
          _hasRecognizedText = true;
          _notifyTranscript(pendingUserText: _joinedText());
        } else {
          _maybeBargeInFromAsr(response.chunkIndex, text, 'thinking');
        }
        break;
      case AICallState.speaking:
        _maybeBargeInFromAsr(response.chunkIndex, text, 'speaking');
        break;
      case AICallState.idle:
        break;
    }
  }

  /// ASR text while thinking / speaking. Tail updates and TTS echo are
  /// dropped; the rest counts as the user speaking up.
  void _maybeBargeInFromAsr(int chunkIndex, String text, String where) {
    final probe = SplayTreeMap<int, String>.of(_sentences)..[chunkIndex] = text;
    final candidate = probe.values.join();
    if (!AsrBargeIn.shouldBargeIn(
      asrText: candidate,
      committed: _committedUserText,
      llmText: _currentLlmText(),
      minChars: AIConstants.asrBargeInMinChars,
    )) {
      _debug('asr $where ignored: "$candidate"');
      return;
    }
    _sentences[chunkIndex] = text;
    _hasRecognizedText = true;
    final extra =
        AsrBargeIn.extraBeyondCommitted(candidate, _committedUserText);
    if (extra != null) {
      _sentences
        ..clear()
        ..[0] = extra;
    }
    _debug('asr barge-in ($where): "$candidate" keep="${_joinedText()}"');
    _notifyTranscript(pendingUserText: _joinedText());
    if (_state == AICallState.speaking) {
      _bargeIn();
    } else {
      _interruptThinking();
    }
  }

  void _clearSentences() {
    _sentences.clear();
    _hasRecognizedText = false;
  }

  /// Sentences in ascending chunkIndex, joined without separators.
  String _joinedText() => _sentences.values.join();

  /// The user finished a turn: switch to thinking and open the drain window.
  /// **Nothing is snapshotted or sent here.**
  ///
  /// ASR is streaming: when the VAD declares silence, results for the tail
  /// audio are often still on the way. Snapshotting now drops the last words,
  /// so the snapshot waits for [_finishDrain]; [_clearSentences] waits too, or
  /// it would wipe what the window is about to merge.
  void _finishListeningTurn() {
    if (_state != AICallState.listening) return;
    final gen = ++_drainGeneration;
    _drainTimeout = Timer(
        const Duration(milliseconds: AIConstants.asrDrainTimeoutMs),
        () => _finishDrain(gen));
    // The session stays open; only wait a little for the tail.
    _vad.reset();
    _setState(AICallState.thinking);
    _notifyTranscript(pendingUserText: _joinedText());
  }

  /// The drain window ended: snapshot the text and send it.
  ///
  /// [_replyTimeout] is aligned with the **actual send**, not the end of
  /// turn: waiting for the tail should not eat into the reply budget.
  void _finishDrain(int gen) {
    if (_released || gen != _drainGeneration) return;
    _closeDrainWindow();

    final text = _joinedText();
    _committedUserText = text;
    _clearSentences();

    // The state was moved during the drain (a late TTS chunk pushed thinking
    // to speaking, etc.); this turn is no longer ours and sending would collide.
    if (_state != AICallState.thinking) {
      _debug('asr drain finished in $_state, skip sending "$text"');
      return;
    }
    if (text.isEmpty) {
      // Should not happen: the turn ends only with non-empty text. If the
      // backend took the text back, return to listening ourselves or the call
      // stays in thinking forever.
      _debug('asr drain finished with empty text, back to listening');
      _enterListening();
      return;
    }

    _transcript.add(TranscriptEntry(isFromUser: true, text: text));
    // Capture the index now: a late failure callback would otherwise mark the
    // user's newer line.
    final entryIndex = _transcript.length - 1;
    _notifyTranscript();
    _armReplyTimeout();
    _sendToRobot(text, entryIndex);
  }

  /// Closes the drain window and voids whatever half has not run yet. The
  /// generation bump is what matters: a timer that already fired but is still
  /// queued exits on mismatch.
  void _closeDrainWindow() {
    _drainGeneration++;
    _drainTimeout?.cancel();
    _drainTimeout = null;
    _asrSession?.endDrain();
  }

  void _sendToRobot(String text, int entryIndex) {
    _messageInputStore
        .sendMessage(payload: TextSendMessagePayload(text: text))
        .then((result) {
      if (result.isSuccess) {
        _debug('sent to robot: $text');
        return;
      }
      _debug('sendMessage failed: ${result.errorCode} ${result.errorMessage}');
      if (_released) return;
      // Mark the line and toast either way, but only move the state machine
      // while still waiting for this turn's reply. The callback may be very
      // late (incoming call, network switch), when the turn was long since
      // cleaned up by a timeout or pause / resume.
      _markUserEntryFailed(entryIndex);
      callbacks.onError(AICallError.sendFailed);
      if (_state != AICallState.thinking) {
        _debug('sendMessage failure arrived in $_state, skip recovery');
        return;
      }
      _cancelReplyTimeout();
      _enterListening();
    });
  }

  void _sendVoiceSessionPing(String action) {
    AIAssistantControlMessages.sendVoiceSessionSignal(
            robotUserID: robotUserID, action: action)
        .then((result) {
      if (result.isSuccess) {
        _debug('voice session $action');
      } else {
        _debug(
            'voice session $action failed: ${result.errorCode} ${result.errorMessage}');
      }
    });
  }

  // ----------------------------------------------------- stream message / TTS

  bool get _canPlayTts => _player != null;

  /// Picks the robot's stream messages.
  ///
  /// Right after the message arrives the streamID may not be ready and
  /// startTTS is rejected with ERR_INVALID_PARAMETERS; [_hasStartedTTS] stays
  /// false and the next onRecvMessageModified tries again until it succeeds.
  void _handleStreamMessage(V2TimMessage msg) {
    if (_released) return;
    if (msg.sender != robotUserID) return;
    if (msg.elemType != MessageElemType.V2TIM_ELEM_TYPE_STREAM) return;
    final streamElem = msg.streamElem;
    if (streamElem == null) return;

    // A new reply: reset the previous turn's TTS state.
    if (_streamingMsgID != msg.msgID) {
      _debug('stream msg $_streamingMsgID -> ${msg.msgID}');
      _streamingMsgID = msg.msgID;
      _hasStartedTTS = false;
      _ttsStartPending = false;
      _aiEntryIndex = -1;
      _enqueuedAudioMs = 0;
      // A new TTS audio stream; drop the previous decoder state. Here rather
      // than in the startTTS callback, because this is guaranteed to precede
      // every audio chunk of this message.
      _player?.beginStream();
    }
    _streamEnded = streamElem.isStreamEnded == true;

    _updateAiTranscript(streamElem.markdown ?? '');

    if (!_hasStartedTTS &&
        !_ttsStartPending &&
        _state == AICallState.thinking &&
        _canPlayTts) {
      _ttsStartPending = true;
      final msgID = msg.msgID;
      // Only the success callback sets _hasStartedTTS: on failure it stays
      // false and the next modify retries until the streamID is ready.
      final attached = _ttsSession.startFor(
        msg,
        onStarted: () {
          if (msgID != _streamingMsgID) return;
          _ttsStartPending = false;
          if (!_released) {
            _hasStartedTTS = true;
          }
        },
        onFailed: (code, desc) {
          if (msgID != _streamingMsgID) return;
          _ttsStartPending = false;
          _debug('startTTS rejected ($code $desc), will retry on next modify');
          // The rejection resolves asynchronously; the stream may have ended
          // in the meantime and no further modify will come.
          _maybeFallBackToTextOnly();
        },
      );
      if (!attached) {
        _ttsStartPending = false;
      }
    }

    _maybeFallBackToTextOnly();
  }

  /// The stream ended without TTS ever starting (the backend never delivered
  /// a streamID, or playback is unavailable): show the text only and return to
  /// listening right away instead of waiting for the 30s timeout.
  ///
  /// A pending startTTS is excluded: returning to listening while it is on the
  /// way would let its audio collide with the new turn. An open drain window
  /// is excluded too: the question has not been sent yet, there is no reply to
  /// degrade, and listening would cancel the window and lose what the user
  /// just said. Only a late redelivery of the previous turn reaches here then.
  void _maybeFallBackToTextOnly() {
    if (_released) return;
    if (_streamEnded &&
        !_hasStartedTTS &&
        !_ttsStartPending &&
        _state == AICallState.thinking &&
        _drainTimeout == null) {
      _debug('stream ended without TTS, falling back to text only');
      _enterListening();
    }
  }

  void _updateAiTranscript(String markdown) {
    if (markdown.isEmpty) return;
    final entry = TranscriptEntry(isFromUser: false, text: markdown);
    if (_aiEntryIndex >= 0 && _aiEntryIndex < _transcript.length) {
      _transcript[_aiEntryIndex] = entry;
    } else {
      _transcript.add(entry);
      _aiEntryIndex = _transcript.length - 1;
    }
    _notifyTranscript();
  }

  void _handleTtsResponse(dynamic response) {
    if (_released) return;
    final payload = parseTtsResponsePayload(response);
    // stopTTS is an asynchronous round trip; chunks already on the way still
    // arrive. Without the msgID filter the previous turn's audio would leak
    // into the freshly flushed player.
    if (payload.msgID != _ttsSession.boundMsgID) {
      _debug(
          'drop TTS response of ${payload.msgID}, bound to ${_ttsSession.boundMsgID}');
      return;
    }
    final player = _player;
    if (player == null) return;
    player.feed(
      payload.packets,
      payload.isFinished,
    );

    // Receiving this turn's audio is what moves thinking to speaking, without
    // waiting for the decoder: the first decoded packet already plays.
    if (_state == AICallState.thinking) {
      _cancelReplyTimeout();
      _setState(AICallState.speaking);
    }
    if (_state == AICallState.speaking) {
      _armSpeakingWatchdog(0);
    }
  }

  /// The player queued one fed chunk. The watchdog is renewed here as well:
  /// the backend delivers faster than realtime, so chunks may all have
  /// arrived while the decoder is still working through the backlog.
  void _onTtsChunkQueued(int durationMs, bool isFinished) {
    if (_released) return;
    _enqueuedAudioMs += durationMs;
    if (_state == AICallState.speaking) {
      // After isFinished no more chunks come; what is left is queued
      // playback, bounded by the total queued duration.
      _armSpeakingWatchdog(isFinished ? _enqueuedAudioMs : 0);
    }
  }

  void _armSpeakingWatchdog(int pendingPlaybackMs) {
    _cancelSpeakingWatchdog();
    _speakingWatchdog = Timer(
      Duration(
          milliseconds: AIConstants.speakingIdleTimeoutMs + pendingPlaybackMs),
      () {
        _speakingWatchdog = null;
        if (_released || _state != AICallState.speaking) return;
        // Same recovery as a normal end of playback, without a toast: the user
        // stopped hearing anything long ago.
        _debug('speaking watchdog fired, recovering to listening');
        _enterListening();
      },
    );
  }

  void _cancelSpeakingWatchdog() {
    _speakingWatchdog?.cancel();
    _speakingWatchdog = null;
  }

  void _armReplyTimeout() {
    _cancelReplyTimeout();
    _replyTimeout = Timer(
        const Duration(milliseconds: AIConstants.streamReplyTimeoutMs), () {
      _replyTimeout = null;
      if (_released || _state != AICallState.thinking) return;
      _debug('stream reply timed out');
      callbacks.onError(AICallError.replyTimeout);
      _enterListening();
    });
  }

  void _cancelReplyTimeout() {
    _replyTimeout?.cancel();
    _replyTimeout = null;
  }

  void _onPlaybackFinished() {
    if (_released || _state != AICallState.speaking) return;
    _enterListening();
  }

  /// ASR barge-in while speaking: stop TTS, drop the queue, keep what the user
  /// started saying for the next listening turn.
  void _bargeIn() {
    if (_released || _state != AICallState.speaking) return;
    _debug('barge-in detected');
    _enterListening(keepAsrText: true);
  }

  /// The user spoke up while thinking: void the reply, keep the new text and
  /// keep listening.
  void _interruptThinking() {
    if (_released || _state != AICallState.thinking || _drainTimeout != null) {
      return;
    }
    _debug('thinking interrupted by ASR text');
    _enterListening(keepAsrText: true);
  }

  /// Starts another listening turn.
  ///
  /// With the ASR session alive it switches to listening directly. Only after
  /// mute, pause or a remote finish is the session empty and
  /// [_startNewAsrSession] runs.
  ///
  /// [keepAsrText] keeps what was recognized for barge-in; finishing playback
  /// or timing out drops echo leftovers.
  void _enterListening({bool resetEncoder = true, bool keepAsrText = false}) {
    _debug('enterListening from $_state keepAsrText=$keepAsrText');
    _abandonCurrentReply();
    if (!keepAsrText) {
      _clearSentences();
    }
    _vad.reset();
    final live = _asrSession?.isLive == true;
    if (live) {
      _awaitingAsrForListening = false;
      _setState(AICallState.listening);
      _notifyTranscript(pendingUserText: _joinedText());
      return;
    }
    _awaitingAsrForListening = true;
    _setState(AICallState.thinking);
    _startNewAsrSession(resetEncoder: resetEncoder);
  }

  /// Gives up this turn's reply: both timeouts and the drain window go, TTS is
  /// unbound and stopped, the player queue is dropped.
  ///
  /// Every "this turn no longer counts" path passes here: barge-in, mute,
  /// pause, reply timeout, send failure.
  void _abandonCurrentReply() {
    _cancelReplyTimeout();
    _cancelSpeakingWatchdog();
    _closeDrainWindow();
    _ttsSession.stop();
    final player = _player;
    if (player != null) {
      unawaited(player.flush());
    }
  }

  /// [index] was captured by [_finishDrain]. [_transcript] is only appended
  /// to and replaced in place, so the index stays valid.
  void _markUserEntryFailed(int index) {
    if (index < 0 || index >= _transcript.length) return;
    _transcript[index] = _transcript[index].copyWith(isFailed: true);
    _notifyTranscript();
  }

  void _setState(AICallState newState) {
    if (_state == newState) return;
    _state = newState;
    _debug('state -> $newState');
    callbacks.onStateChanged(newState);
  }

  String _currentLlmText() {
    if (_aiEntryIndex >= 0 && _aiEntryIndex < _transcript.length) {
      return _transcript[_aiEntryIndex].text;
    }
    for (final entry in _transcript.reversed) {
      if (!entry.isFromUser) return entry.text;
    }
    return '';
  }

  void _notifyTranscript({String pendingUserText = ''}) {
    final entries = List<TranscriptEntry>.of(_transcript);
    if (pendingUserText.isNotEmpty) {
      entries.add(TranscriptEntry(isFromUser: true, text: pendingUserText));
    }
    callbacks.onTranscriptChanged(entries);
  }

  void _removeListeners() {
    if (!_listenersAdded) return;
    _listenersAdded = false;
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .removeAdvancedMsgListener(listener: _msgListener);
    RealtimeAsrExperimental.removeResponseListener(_handleAsrResponse);
  }

  void _debug(String msg) {
    if (kDebugMode) {
      debugPrint('$_tag: $msg');
    }
  }
}
