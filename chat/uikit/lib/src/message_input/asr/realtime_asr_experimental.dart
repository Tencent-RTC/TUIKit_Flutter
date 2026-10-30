import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

/// One realtime transcription result pushed by the backend.
///
/// The backend re-sends the same [chunkIndex] with corrected text as it
/// refines a sentence, so callers should overwrite by index, then join the
/// sentences in ascending index order.
class RealtimeAsrResponse {
  const RealtimeAsrResponse({
    required this.sessionID,
    required this.chunkIndex,
    required this.text,
    required this.isFinished,
  });

  /// Session this result belongs to; empty when the backend omitted it.
  final String sessionID;

  /// Sentence index within the session.
  final int chunkIndex;

  /// Latest text of that sentence. May be empty; an empty text must not
  /// overwrite a sentence already received.
  final String text;

  /// True on the final response of the session, sent after stop.
  final bool isFinished;

  @override
  String toString() =>
      'RealtimeAsrResponse(sessionID: $sessionID, chunkIndex: $chunkIndex, text: $text, isFinished: $isFinished)';
}

/// Outcome of a [RealtimeAsrExperimental] call. [code] 0 means success.
class RealtimeAsrCallResult {
  const RealtimeAsrCallResult({required this.code, this.desc = ''});

  final int code;
  final String desc;

  bool get isSuccess => code == 0;
}

/// Outcome of [RealtimeAsrExperimental.start]. On success [sessionID] is the
/// new session; it can still be empty if the backend allocated nothing.
class RealtimeAsrStartResult extends RealtimeAsrCallResult {
  const RealtimeAsrStartResult({required super.code, super.desc, this.sessionID = ''});

  final String sessionID;
}

/// Listener for [RealtimeAsrExperimental.addResponseListener].
typedef RealtimeAsrResponseListener = void Function(RealtimeAsrResponse response);

/// Realtime speech recognition over the IMSDK experimental API.
///
/// Audio goes up as raw 16kHz mono Opus packets (see `RealtimeAudioCapture`);
/// results come back through [addResponseListener]. Not available on web.
///
/// Calls never throw: failures are reported through the result code, with
/// -1 for local exceptions (e.g. SDK not initialized).
class RealtimeAsrExperimental {
  RealtimeAsrExperimental._();

  /// Experimental notify key carrying [RealtimeAsrResponse] payloads.
  static const String notifyKey = 'onRecvRealtimeTranscriberResponse';

  static const String _apiStart = 'internal_operation_start_realtime_transcriber';
  static const String _apiFeed = 'internal_operation_feed_realtime_audio_data';
  static const String _apiStop = 'internal_operation_stop_realtime_transcriber';
  static const String _keyLanguage = 'request_start_realtime_transcriber_language_param';
  static const String _keySessionID = 'request_realtime_transcriber_session_id_param';
  static const String _keyDataList = 'request_feed_realtime_audio_data_list_param';
  static const String _keyStartResponseSessionID = 'response_start_realtime_transcriber_session_id';

  static const int _localErrorCode = -1;

  static final List<RealtimeAsrResponseListener> _listeners = [];
  static V2TimSDKListener? _sdkListener;

  /// Opens a session. [language] is an ISO 639-1 code such as "zh" or "en";
  /// empty lets the backend detect it.
  static Future<RealtimeAsrStartResult> start({required String language}) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
        api: _apiStart,
        param: {_keyLanguage: language},
      );
      if (result.code != 0) {
        return RealtimeAsrStartResult(code: result.code, desc: result.desc);
      }
      return RealtimeAsrStartResult(code: 0, desc: result.desc, sessionID: _normalizeSessionID(result.data));
    } catch (e) {
      return RealtimeAsrStartResult(code: _localErrorCode, desc: e.toString());
    }
  }

  /// Uploads [packets] (raw Opus, oldest first) to [sessionID].
  static Future<RealtimeAsrCallResult> feed({
    required String sessionID,
    required List<Uint8List> packets,
  }) {
    return _call(_apiFeed, {
      _keySessionID: sessionID,
      _keyDataList: packets.map(base64Encode).toList(),
    });
  }

  /// Closes [sessionID]. Success only acknowledges the close; trailing
  /// results keep arriving until the one with `isFinished`.
  static Future<RealtimeAsrCallResult> stop({required String sessionID}) {
    return _call(_apiStop, {_keySessionID: sessionID});
  }

  /// Subscribes to results of every session. The SDK listener is registered
  /// with the first subscriber and removed with the last.
  static void addResponseListener(RealtimeAsrResponseListener listener) {
    if (_listeners.contains(listener)) {
      return;
    }
    _listeners.add(listener);
    if (_sdkListener == null) {
      final sdkListener = V2TimSDKListener(onExperimentalNotify: _onExperimentalNotify);
      _sdkListener = sdkListener;
      try {
        TencentImSDKPlugin.v2TIMManager.addIMSDKListener(sdkListener);
      } catch (e) {
        debugPrint('RealtimeAsrExperimental addIMSDKListener failed: $e');
      }
    }
  }

  static void removeResponseListener(RealtimeAsrResponseListener listener) {
    _listeners.remove(listener);
    final sdkListener = _sdkListener;
    if (_listeners.isNotEmpty || sdkListener == null) {
      return;
    }
    _sdkListener = null;
    try {
      TencentImSDKPlugin.v2TIMManager.removeIMSDKListener(sdkListener);
    } catch (e) {
      debugPrint('RealtimeAsrExperimental removeIMSDKListener failed: $e');
    }
  }

  /// Parses an experimental notify into a response; null when [key] is not
  /// [notifyKey] or the payload is malformed. [param] may be a map or a JSON
  /// string depending on the SDK build.
  static RealtimeAsrResponse? parseNotify(String key, dynamic param) {
    if (key != notifyKey) {
      return null;
    }
    final data = _decodeJson(param);
    if (data is! Map) {
      return null;
    }
    final chunkIndex = data['realtime_transcriber_response_chunk_index'];
    final isFinished = data['realtime_transcriber_response_is_finished'];
    return RealtimeAsrResponse(
      sessionID: data['realtime_transcriber_response_session_id']?.toString() ?? '',
      chunkIndex: chunkIndex is num ? chunkIndex.toInt() : int.tryParse('$chunkIndex') ?? 0,
      text: data['realtime_transcriber_response_text']?.toString() ?? '',
      isFinished: isFinished == true || isFinished == 1 || isFinished == 'true',
    );
  }

  static void _onExperimentalNotify(String key, dynamic param) {
    final response = parseNotify(key, param);
    if (response == null) {
      return;
    }
    for (final listener in List<RealtimeAsrResponseListener>.of(_listeners)) {
      listener(response);
    }
  }

  static Future<RealtimeAsrCallResult> _call(String api, Map<String, dynamic> param) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(api: api, param: param);
      return RealtimeAsrCallResult(code: result.code, desc: result.desc);
    } catch (e) {
      return RealtimeAsrCallResult(code: _localErrorCode, desc: e.toString());
    }
  }

  /// The local SDK source hands back the bare sessionID; the pub.dev build
  /// decodes the C layer's JSON, so the same value may arrive as a map, a JSON
  /// string or a plain string.
  static String _normalizeSessionID(Object? data) {
    final decoded = _decodeJson(data);
    if (decoded is Map) {
      return decoded[_keyStartResponseSessionID]?.toString() ?? '';
    }
    if (decoded is String) {
      return decoded;
    }
    return data?.toString() ?? '';
  }

  static Object? _decodeJson(Object? value) {
    if (value is! String) {
      return value;
    }
    try {
      return json.decode(value);
    } on FormatException {
      return value;
    }
  }
}
