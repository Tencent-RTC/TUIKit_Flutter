// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   AITranscriberStoreImpl @ AtomicXCore
// Function: AITranscriberStore 主动接口 + 被动事件/State 实现，通过 AtomicEngine 桥接到 native 层。

part of 'package:atomic_x_core/api/ai/ai_transcriber_store.dart';

class _TranscriberStateImpl implements TranscriberState {
  @override
  final ValueNotifier<SourceLanguage> selfLanguage = ValueNotifier<SourceLanguage>(SourceLanguage.english);

  @override
  final ValueNotifier<List<TranscriberMessage>> realtimeMessageList =
      ValueNotifier<List<TranscriberMessage>>(const <TranscriberMessage>[]);

  @override
  final ValueNotifier<bool> isTranscriptionRunning = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<TranscriptionConfig> transcriptionConfig =
      ValueNotifier<TranscriptionConfig>(TranscriptionConfig());

  @override
  final ValueNotifier<bool> isInterpretationRunning = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<InterpretationConfig> interpretationConfig =
      ValueNotifier<InterpretationConfig>(InterpretationConfig());

  @override
  final ValueNotifier<int> interpretationVolume = ValueNotifier<int>(80);
}

// API keys
const String _kStartTranscription = 'AITranscriberModule.startTranscription';
const String _kUpdateTranscription = 'AITranscriberModule.updateTranscription';
const String _kStopTranscription = 'AITranscriberModule.stopTranscription';
const String _kStartInterpretation = 'AITranscriberModule.startInterpretation';
const String _kUpdateInterpretation = 'AITranscriberModule.updateInterpretation';
const String _kStopInterpretation = 'AITranscriberModule.stopInterpretation';
const String _kSetInterpretationVolume = 'AITranscriberModule.setInterpretationVolume';
// Deprecated
const String _kStartRealtimeTranscriber = 'AITranscriberModule.startRealtimeTranscriber';
const String _kUpdateRealtimeTranscriber = 'AITranscriberModule.updateRealtimeTranscriber';
const String _kStopRealtimeTranscriber = 'AITranscriberModule.stopRealtimeTranscriber';
const String _kCreateModule = 'AITranscriberModule.createModule';
const String _kDestroyModule = 'AITranscriberModule.destroyModule';

// Passive channels (engine → Dart)
const String _aiTranscriberEventChannel = 'AITranscriberModule.event';
const String _aiTranscriberStateChannel = 'AITranscriberModule.stateChanged';

class AITranscriberStoreImpl extends AITranscriberStore implements IStore {
  AITranscriberStoreImpl(this._roomID) {
    _registerEventHandlers();
  }

  final String _roomID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _TranscriberStateImpl _state = _TranscriberStateImpl();
  final Set<AITranscriberStoreListener> _listeners = <AITranscriberStoreListener>{};

  @override
  TranscriberState get transcriberState => _state;

  // MARK: - Active APIs (transcription)

  @override
  Future<CompletionHandler> startTranscription(SourceLanguage myLanguage, {TranscriptionConfig? config}) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'myLanguage': myLanguage.value,
      'config': <String, Object>{
        'enableTranslation': config?.enableTranslation ?? false,
      },
    });
    return EngineBridge.invoke(_kStartTranscription, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> updateTranscription(SourceLanguage myLanguage, {TranscriptionConfig? config}) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'myLanguage': myLanguage.value,
      'config': <String, Object>{
        'enableTranslation': config?.enableTranslation ?? false,
      },
    });
    return EngineBridge.invoke(_kUpdateTranscription, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> stopTranscription() {
    final param = jsonEncode(<String, Object>{'roomID': _roomID});
    return EngineBridge.invoke(_kStopTranscription, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  // MARK: - Active APIs (interpretation)

  @override
  Future<CompletionHandler> startInterpretation(SourceLanguage myLanguage, {InterpretationConfig? config}) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'myLanguage': myLanguage.value,
      'config': <String, Object>{
        'voice': (config?.voice ?? InterpretationVoice.female).value,
      },
    });
    return EngineBridge.invoke(_kStartInterpretation, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> updateInterpretation(SourceLanguage myLanguage, {InterpretationConfig? config}) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'myLanguage': myLanguage.value,
      'config': <String, Object>{
        'voice': (config?.voice ?? InterpretationVoice.female).value,
      },
    });
    return EngineBridge.invoke(_kUpdateInterpretation, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> stopInterpretation() {
    final param = jsonEncode(<String, Object>{'roomID': _roomID});
    return EngineBridge.invoke(_kStopInterpretation, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setInterpretationVolume(int volume) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'volume': volume,
    });
    return EngineBridge.invoke(_kSetInterpretationVolume, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  // MARK: - Active APIs (deprecated realtime transcriber)

  @Deprecated('Use startTranscription instead')
  @override
  Future<CompletionHandler> startRealtimeTranscriber(TranscriberConfig config) {
    final param = jsonEncode(<String, Object>{
      'sourceLanguage': config.sourceLanguage.value,
      'translationLanguages': config.translationLanguages.map((e) => e.value).toList(),
    });
    return EngineBridge.invoke(_kStartRealtimeTranscriber, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @Deprecated('Use updateTranscription instead')
  @override
  Future<CompletionHandler> updateRealtimeTranscriber(TranscriberConfig config) {
    final param = jsonEncode(<String, Object>{
      'sourceLanguage': config.sourceLanguage.value,
      'translationLanguages': config.translationLanguages.map((e) => e.value).toList(),
    });
    return EngineBridge.invoke(_kUpdateRealtimeTranscriber, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @Deprecated('Use stopTranscription instead')
  @override
  Future<CompletionHandler> stopRealtimeTranscriber() {
    return EngineBridge.invoke(_kStopRealtimeTranscriber, '{}', id: _roomID).then((r) => r.toCompletionHandler());
  }

  @Deprecated('Use transcriberState to observe state changes instead')
  @override
  void addAITranscriberListener(AITranscriberStoreListener listener) {
    _listeners.add(listener);
  }

  @Deprecated('Use transcriberState to observe state changes instead')
  @override
  void removeAITranscriberListener(AITranscriberStoreListener listener) {
    _listeners.remove(listener);
  }

  // MARK: - IStore lifecycle

  void _registerEventHandlers() {
    _eventToken = EngineBridge.subscribe(_aiTranscriberEventChannel, _onModuleEvent);
    _stateToken = EngineBridge.subscribe(_aiTranscriberStateChannel, _onModuleStateChanged);
  }

  @override
  void beforeEnterRoom(String roomID) {
  }

  @override
  void afterEnterRoom(dynamic info) {
    unawaited(EngineBridge.invoke(_kCreateModule, '{}', id: _roomID));
  }

  @override
  void didLeaveRoom(String roomID) {
    unawaited(EngineBridge.invoke(_kDestroyModule, '{}', id: roomID));
    final eventToken = _eventToken;
    if (eventToken != null) {
      EngineBridge.unsubscribe(eventToken);
    }
    _eventToken = null;
    final stateToken = _stateToken;
    if (stateToken != null) {
      EngineBridge.unsubscribe(stateToken);
    }
    _stateToken = null;
    _listeners.clear();
    _state.selfLanguage.value = SourceLanguage.chineseEnglish;
    _state.realtimeMessageList.value = const <TranscriberMessage>[];
    _state.isTranscriptionRunning.value = false;
    _state.transcriptionConfig.value = TranscriptionConfig();
    _state.isInterpretationRunning.value = false;
    _state.interpretationConfig.value = InterpretationConfig();
    _state.interpretationVolume.value = 100;
  }

  // MARK: - Passive Event dispatcher (type based)

  void _onModuleEvent(String id, String json) {
    if (id != _roomID) return;
    final dict = _parseJSON(json);
    if (dict == null) return;
    final type = dict['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'onReceiveTranscriberMessage':
        final roomID = dict['roomID'] as String? ?? '';
        final message = _mapToTranscriberMessage(
          dict['message'] is Map ? (dict['message'] as Map).cast<String, dynamic>() : null,
        );
        for (final l in _listeners) {
          l.onReceiveTranscriberMessage?.call(roomID, message);
        }
        break;
      case 'onRealtimeTranscriberStarted':
        final roomID = dict['roomID'] as String? ?? '';
        final robotID = dict['transcriberRobotID'] as String? ?? '';
        for (final l in _listeners) {
          l.onRealtimeTranscriberStarted?.call(roomID, robotID);
        }
        break;
      case 'onRealtimeTranscriberStopped':
        final roomID = dict['roomID'] as String? ?? '';
        final robotID = dict['transcriberRobotID'] as String? ?? '';
        final reason = (dict['reason'] as num?)?.toInt() ?? 0;
        for (final l in _listeners) {
          l.onRealtimeTranscriberStopped?.call(roomID, robotID, reason);
        }
        break;
      case 'onRealtimeTranscriberError':
        final roomID = dict['roomID'] as String? ?? '';
        final robotID = dict['transcriberRobotID'] as String? ?? '';
        final code = (dict['code'] as num?)?.toInt() ?? 0;
        final message = dict['message'] as String? ?? '';
        for (final l in _listeners) {
          l.onRealtimeTranscriberError?.call(roomID, robotID, code, message);
        }
        break;
    }
  }

  // MARK: - Passive State dispatcher (property based)

  void _onModuleStateChanged(String id, String json) {
    if (id != _roomID) return;
    final dict = _parseJSON(json);
    if (dict == null) return;
    final property = dict['property'] as String?;
    if (property == null) return;

    final modify = (dict['listModifyType'] as num?)?.toInt() ?? 1;
    switch (property) {
      case 'selfLanguage':
        final value = dict['selfLanguage'] as String? ?? SourceLanguage.chineseEnglish.value;
        _state.selfLanguage.value = SourceLanguage.values.firstWhere(
          (e) => e.value == value,
          orElse: () => SourceLanguage.chineseEnglish,
        );
        break;
      case 'realtimeMessageList':
        {
          final rawList = (dict['realtimeMessageList'] as List?) ?? const [];
          final items =
              rawList.map((e) => _mapToTranscriberMessage(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.realtimeMessageList.value =
              _applyListModify(_state.realtimeMessageList.value, modify, items, (e) => e.segmentId);
          break;
        }
      case 'isTranscriptionRunning':
        _state.isTranscriptionRunning.value = dict['isTranscriptionRunning'] as bool? ?? false;
        break;
      case 'transcriptionConfig':
        _state.transcriptionConfig.value = _mapToTranscriptionConfig(
          dict['transcriptionConfig'] is Map ? (dict['transcriptionConfig'] as Map).cast<String, dynamic>() : null,
        );
        break;
      case 'isInterpretationRunning':
        _state.isInterpretationRunning.value = dict['isInterpretationRunning'] as bool? ?? false;
        break;
      case 'interpretationConfig':
        _state.interpretationConfig.value = _mapToInterpretationConfig(
          dict['interpretationConfig'] is Map ? (dict['interpretationConfig'] as Map).cast<String, dynamic>() : null,
        );
        break;
      case 'interpretationVolume':
        _state.interpretationVolume.value = (dict['interpretationVolume'] as num?)?.toInt() ?? 100;
        break;
    }
  }

  List<T> _applyListModify<T>(
    List<T> current,
    int modifyType,
    List<T> payload,
    String Function(T) keyOf,
  ) {
    final type = ListModifyType.fromValue(modifyType);
    switch (type) {
      case ListModifyType.full:
        return payload;
      case ListModifyType.add:
        final map = <String, T>{};
        for (final e in current) {
          map[keyOf(e)] = e;
        }
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return map.values.toList();
      case ListModifyType.remove:
        final removing = payload.map(keyOf).toSet();
        return current.where((e) => !removing.contains(keyOf(e))).toList();
      case ListModifyType.replace:
        final map = <String, T>{};
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return current.map((e) => map[keyOf(e)] ?? e).toList();
      case ListModifyType.none:
        return current;
    }
  }

  // MARK: - Model mappers

  TranslationLanguage? _translationLanguageFromValue(String value) {
    for (final e in TranslationLanguage.values) {
      if (e.value == value) return e;
    }
    return null;
  }

  TranscriberMessage _mapToTranscriberMessage(Map<String, dynamic>? map) {
    if (map == null) return TranscriberMessage(segmentId: '');
    final translationTexts = <TranslationLanguage, String>{};
    final rawTexts = map['translationTexts'];
    if (rawTexts is Map) {
      rawTexts.forEach((key, value) {
        if (key is String && value is String) {
          final lang = _translationLanguageFromValue(key);
          if (lang != null) {
            translationTexts[lang] = value;
          }
        }
      });
    }
    return TranscriberMessage(
      segmentId: (map['segmentId'] as String?) ?? '',
      speakerUserId: (map['speakerUserId'] as String?) ?? '',
      speakerUserName: (map['speakerUserName'] as String?) ?? '',
      sourceText: (map['sourceText'] as String?) ?? '',
      translationTexts: translationTexts,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
    );
  }

  TranscriptionConfig _mapToTranscriptionConfig(Map<String, dynamic>? map) {
    if (map == null) return TranscriptionConfig();
    return TranscriptionConfig(enableTranslation: (map['enableTranslation'] as bool?) ?? false);
  }

  InterpretationConfig _mapToInterpretationConfig(Map<String, dynamic>? map) {
    if (map == null) return InterpretationConfig();
    final voiceValue = (map['voice'] as String?) ?? InterpretationVoice.female.value;
    final voice = InterpretationVoice.values.firstWhere(
      (e) => e.value == voiceValue,
      orElse: () => InterpretationVoice.female,
    );
    return InterpretationConfig(voice: voice);
  }

  static Map<String, dynamic>? _parseJSON(String json) {
    if (json.isEmpty) return null;
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }
}
