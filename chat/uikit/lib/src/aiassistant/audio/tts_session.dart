import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_stream_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_stream_elem.dart';

/// TTS session of a stream message.
///
/// TTS hangs off [V2TimStreamElem], not a standalone session: it needs a
/// stream message that already has a streamID. Audio does not come out of
/// here; it arrives via `V2TimAdvancedMsgListener.onRecvTTSResponse`.
class TtsSession {
  static const String _tag = 'TtsSession';

  V2TimStreamElem? _elem;
  String? _msgID;

  /// The bound message, null when unbound.
  ///
  /// Incoming TTS chunks must be filtered by it: stopTTS is an asynchronous
  /// round trip and chunks already on the way still arrive. Only the msgID
  /// check keeps the previous turn's tail out of the next turn's playback.
  String? get boundMsgID => _msgID;

  /// Starts TTS for a stream message.
  ///
  /// Right after the message arrives the streamID may not be ready; startTTS
  /// then fails with ERR_INVALID_PARAMETERS without a network round trip.
  /// Callers retry on the next onRecvMessageModified until [onStarted] fires.
  ///
  /// Returns false when the message has no stream elem at all, no point
  /// retrying.
  bool startFor(
    V2TimMessage message, {
    required VoidCallback onStarted,
    required void Function(int code, String desc) onFailed,
  }) {
    final streamElem = message.streamElem;
    if (streamElem == null) return false;
    // Bind and unbind are both logged: boundMsgID is the only filter for
    // in-flight chunks, and without a trace "the start of the answer got
    // swallowed" can only be guessed at.
    debugPrint('$_tag: bind $_msgID -> ${message.msgID}');
    _elem = streamElem;
    _msgID = message.msgID;
    // TTS is still experimental. Keep this dynamic so Chat UIKit itself can
    // compile with IMSDK releases that do not expose the API yet; the page
    // hides the voice entry when the matching listener API is unavailable.
    try {
      final dynamic experimentalElem = streamElem;
      experimentalElem.startTTS().then((dynamic result) {
        if (result.code == 0) {
          debugPrint('$_tag: TTS started for ${message.msgID}');
          onStarted();
        } else {
          debugPrint('$_tag: startTTS failed: ${result.code} ${result.desc}');
          onFailed(result.code, result.desc);
        }
      });
    } catch (error) {
      debugPrint('$_tag: startTTS unavailable: $error');
      _elem = null;
      _msgID = null;
      onFailed(-1, error.toString());
    }
    return true;
  }

  void stop() {
    final streamElem = _elem;
    if (streamElem == null) return;
    debugPrint('$_tag: unbind $_msgID');
    _elem = null;
    _msgID = null;
    try {
      final dynamic experimentalElem = streamElem;
      experimentalElem.stopTTS().then((dynamic result) {
        if (result.code == 0) {
          debugPrint('$_tag: TTS stopped');
        } else {
          debugPrint('$_tag: stopTTS failed: ${result.code} ${result.desc}');
        }
      });
    } catch (error) {
      debugPrint('$_tag: stopTTS unavailable: $error');
    }
  }
}
