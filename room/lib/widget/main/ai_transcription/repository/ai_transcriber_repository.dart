import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import '../config/ai_transcription_config.dart';

/// Subscribes to AI transcriber state, converts messages to AITranscriptionData,
/// and publishes events via streams for the view layer.
class AITranscriberRepository extends ChangeNotifier {
  // Event stream consumed by subtitle/minutes views.
  final StreamController<AISubtitleDataEvent> _eventController = StreamController<AISubtitleDataEvent>.broadcast();

  Stream<AISubtitleDataEvent> get subtitleEventStream => _eventController.stream;

  final Map<String, AITranscriptionData> _subtitleDataMap = {};
  Map<String, AITranscriptionData> get subtitleDataMap => Map.unmodifiable(_subtitleDataMap);

  final List<String> _orderedSegmentIds = [];
  List<String> get orderedSegmentIds => List.unmodifiable(_orderedSegmentIds);

  final List<SourceLanguage> sourceLanguageList = [
    SourceLanguage.chineseEnglish,
    SourceLanguage.chinese,
    SourceLanguage.english,
    SourceLanguage.cantonese,
    SourceLanguage.vietnamese,
    SourceLanguage.japanese,
    SourceLanguage.korean,
    SourceLanguage.indonesian,
    SourceLanguage.thai,
    SourceLanguage.portuguese,
    SourceLanguage.turkish,
    SourceLanguage.arabic,
    SourceLanguage.spanish,
    SourceLanguage.hindi,
    SourceLanguage.french,
    SourceLanguage.malay,
    SourceLanguage.filipino,
    SourceLanguage.german,
    SourceLanguage.italian,
    SourceLanguage.russian,
  ];

  final List<TranslationLanguage?> translationLanguageList = [
    null,
    TranslationLanguage.chinese,
    TranslationLanguage.english,
    TranslationLanguage.vietnamese,
    TranslationLanguage.japanese,
    TranslationLanguage.korean,
    TranslationLanguage.indonesian,
    TranslationLanguage.thai,
    TranslationLanguage.portuguese,
    TranslationLanguage.arabic,
    TranslationLanguage.spanish,
    TranslationLanguage.french,
    TranslationLanguage.malay,
    TranslationLanguage.german,
    TranslationLanguage.italian,
    TranslationLanguage.russian,
  ];

  SourceLanguage _selectedSourceLanguage = SourceLanguage.chineseEnglish;
  SourceLanguage get selectedSourceLanguage => _selectedSourceLanguage;

  TranslationLanguage? _selectedTranslationLanguage = TranslationLanguage.english;
  TranslationLanguage? get selectedTranslationLanguage => _selectedTranslationLanguage;

  bool _isTranscriptionStart = false;
  bool get isTranscriptionStart => _isTranscriptionStart;

  bool _isBilingualEnabled = true;
  bool get isBilingualEnabled => _isBilingualEnabled;
  set isBilingualEnabled(bool value) {
    if (_isBilingualEnabled != value) {
      _isBilingualEnabled = value;
      notifyListeners();
    }
  }

  // Internal

  final AITranscriberStore _transcriberStore = AITranscriberStore.shared;
  TranscriberConfig? _currentConfig;
  VoidCallback? _messageListListener;
  late final AITranscriberStoreListener _transcriberListener;
  final String roomID;

  TranscriberConfig? get currentConfig => _currentConfig;

  AITranscriberRepository({required this.roomID}) {
    _transcriberListener = AITranscriberStoreListener(
      onRealtimeTranscriberStarted: (eventRoomID, transcriberRobotID) {
        if (roomID == eventRoomID) {
          _isTranscriptionStart = true;
          notifyListeners();
        }
      },
      onRealtimeTranscriberStopped: (eventRoomID, transcriberRobotID, reason) {
        if (roomID == eventRoomID) {
          _isTranscriptionStart = false;
          notifyListeners();
        }
      },
    );
    _transcriberStore.addAITranscriberListener(_transcriberListener);
    _subscribeToTranscriberState();
  }

  // Transcription control

  void startTranscription() {
    final config = TranscriberConfig(
      sourceLanguage: _selectedSourceLanguage,
      translationLanguages: _selectedTranslationLanguage != null ? [_selectedTranslationLanguage!] : [],
    );

    _transcriberStore.startRealtimeTranscriber(config);
    _currentConfig = config;
    notifyListeners();
  }

  void updateSourceLanguage(SourceLanguage sourceLanguage) {
    if (_currentConfig == null) return;
    final updatedConfig = TranscriberConfig(
      sourceLanguage: sourceLanguage,
      translationLanguages: _currentConfig!.translationLanguages,
    );
    _selectedSourceLanguage = sourceLanguage;
    _transcriberStore.updateRealtimeTranscriber(updatedConfig);
    _currentConfig = updatedConfig;
    notifyListeners();
  }

  void updateTranslationLanguage(TranslationLanguage? translationLanguage) {
    if (_currentConfig == null) return;
    final updatedConfig = TranscriberConfig(
      sourceLanguage: _currentConfig!.sourceLanguage,
      translationLanguages: translationLanguage == null ? [] : [translationLanguage],
    );
    _selectedTranslationLanguage = translationLanguage;
    _transcriberStore.updateRealtimeTranscriber(updatedConfig);
    _currentConfig = updatedConfig;
    notifyListeners();
  }

  void stopTranscription() {
    _transcriberStore.stopRealtimeTranscriber();
    _currentConfig = null;
  }

  // Data access

  AITranscriptionData? getData(String segmentId) {
    return _subtitleDataMap[segmentId];
  }

  /// Returns the localized display name for the given source language.
  String displayNameForSource(BuildContext context, SourceLanguage sourceLanguage) {
    final l10n = RoomLocalizations.of(context)!;
    switch (sourceLanguage) {
      case SourceLanguage.chineseEnglish:
        return l10n.roomkit_transcription_auto_detect_chinese_english;
      case SourceLanguage.chinese:
        return l10n.roomkit_transcription_speaking_chinese;
      case SourceLanguage.english:
        return l10n.roomkit_transcription_speaking_english;
      case SourceLanguage.cantonese:
        return l10n.roomkit_transcription_speaking_cantonese;
      case SourceLanguage.vietnamese:
        return l10n.roomkit_transcription_speaking_vietnamese;
      case SourceLanguage.japanese:
        return l10n.roomkit_transcription_speaking_japanese;
      case SourceLanguage.korean:
        return l10n.roomkit_transcription_speaking_korean;
      case SourceLanguage.indonesian:
        return l10n.roomkit_transcription_speaking_indonesian;
      case SourceLanguage.thai:
        return l10n.roomkit_transcription_speaking_thai;
      case SourceLanguage.portuguese:
        return l10n.roomkit_transcription_speaking_portuguese;
      case SourceLanguage.turkish:
        return l10n.roomkit_transcription_speaking_turkish;
      case SourceLanguage.arabic:
        return l10n.roomkit_transcription_speaking_arabic;
      case SourceLanguage.spanish:
        return l10n.roomkit_transcription_speaking_spanish;
      case SourceLanguage.hindi:
        return l10n.roomkit_transcription_speaking_hindi;
      case SourceLanguage.french:
        return l10n.roomkit_transcription_speaking_french;
      case SourceLanguage.malay:
        return l10n.roomkit_transcription_speaking_malay;
      case SourceLanguage.filipino:
        return l10n.roomkit_transcription_speaking_filipino;
      case SourceLanguage.german:
        return l10n.roomkit_transcription_speaking_german;
      case SourceLanguage.italian:
        return l10n.roomkit_transcription_speaking_italian;
      case SourceLanguage.russian:
        return l10n.roomkit_transcription_speaking_russian;
    }
  }

  /// Returns the localized display name for the given translation language.
  String displayNameForTranslation(BuildContext context, TranslationLanguage? translationLanguage) {
    final l10n = RoomLocalizations.of(context)!;
    if (translationLanguage == null) return l10n.roomkit_transcription_no_translation;
    switch (translationLanguage) {
      case TranslationLanguage.chinese:
        return l10n.roomkit_transcription_language_chinese;
      case TranslationLanguage.english:
        return l10n.roomkit_transcription_language_english;
      case TranslationLanguage.vietnamese:
        return l10n.roomkit_transcription_language_vietnamese;
      case TranslationLanguage.japanese:
        return l10n.roomkit_transcription_language_japanese;
      case TranslationLanguage.korean:
        return l10n.roomkit_transcription_language_korean;
      case TranslationLanguage.indonesian:
        return l10n.roomkit_transcription_language_indonesian;
      case TranslationLanguage.thai:
        return l10n.roomkit_transcription_language_thai;
      case TranslationLanguage.portuguese:
        return l10n.roomkit_transcription_language_portuguese;
      case TranslationLanguage.arabic:
        return l10n.roomkit_transcription_language_arabic;
      case TranslationLanguage.spanish:
        return l10n.roomkit_transcription_language_spanish;
      case TranslationLanguage.french:
        return l10n.roomkit_transcription_language_french;
      case TranslationLanguage.malay:
        return l10n.roomkit_transcription_language_malay;
      case TranslationLanguage.german:
        return l10n.roomkit_transcription_language_german;
      case TranslationLanguage.italian:
        return l10n.roomkit_transcription_language_italian;
      case TranslationLanguage.russian:
        return l10n.roomkit_transcription_language_russian;
    }
  }

  // State Subscription

  void _subscribeToTranscriberState() {
    _unsubscribeFromTranscriberState();
    _messageListListener = _onMessageListChanged;
    _transcriberStore.transcriberState.realtimeMessageList.addListener(_messageListListener!);
  }

  void _unsubscribeFromTranscriberState() {
    if (_messageListListener != null) {
      _transcriberStore.transcriberState.realtimeMessageList.removeListener(_messageListListener!);
      _messageListListener = null;
    }
  }

  void _onMessageListChanged() {
    final messageList = _transcriberStore.transcriberState.realtimeMessageList.value;
    _processMessageListUpdate(messageList);
  }

  void _processMessageListUpdate(List<TranscriberMessage> messageList) {
    final groups = _groupMessages(messageList);
    for (final groupData in groups) {
      final groupId = groupData.segmentId;
      final existingData = _subtitleDataMap[groupId];
      if (existingData != null) {
        if (groupData == existingData) continue;
        _subtitleDataMap[groupId] = groupData;
        _eventController.add(groupData.isCompleted ? AISubtitleDataCompleted(groupData) : AISubtitleDataUpdated(groupData));
      } else {
        _subtitleDataMap[groupId] = groupData;
        _orderedSegmentIds.add(groupId);
        _eventController.add(AISubtitleDataAdded(groupData));
        if (groupData.isCompleted) {
          _eventController.add(AISubtitleDataCompleted(groupData));
        }
      }
    }
    notifyListeners();
  }

  /// Groups messages by: filter → sort → merge (same speaker + 60s time window).
  List<AITranscriptionData> _groupMessages(List<TranscriberMessage> messageList) {
    // Step 1: Filter — keep messages with displayable sourceText and valid timestamp
    final filtered = messageList.where((message) {
      final hasContent = message.sourceText.trim().isNotEmpty;
      final hasValidTimestamp = message.timestamp > 0;
      return hasContent && hasValidTimestamp;
    }).toList();

    // Step 2: Sort by timestamp ascending
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Step 3: Group by same speaker + 60s time window
    final List<AITranscriptionData> groups = [];

    for (final message in filtered) {
      final data = _convertToSubtitleData(message);

      if (groups.isNotEmpty
          && groups.last.speakerUserId == data.speakerUserId
          && (data.timestamp - groups.last.timestamp).abs() <= 60) {
        // Merge into existing group
        final lastGroup = groups.last;
        final mergedTranslationText = data.translationText.isEmpty
            ? lastGroup.translationText
            : lastGroup.translationText.isEmpty
                ? data.translationText
                : '${lastGroup.translationText}\n${data.translationText}';
        groups[groups.length - 1] = lastGroup.copyWith(
          sourceText: '${lastGroup.sourceText}\n${data.sourceText}',
          translationText: mergedTranslationText,
          isCompleted: data.isCompleted,
        );
      } else {
        // Start a new group (uses this message's segmentId as group ID)
        groups.add(data);
      }
    }

    return groups;
  }

  void _clearAllData() {
    _subtitleDataMap.clear();
    _orderedSegmentIds.clear();
    _eventController.add(const AISubtitleDataClearedAll());
  }

  // Data Conversion

  AITranscriptionData _convertToSubtitleData(TranscriberMessage message) {
    return AITranscriptionData(
      segmentId: message.segmentId,
      speakerUserId: message.speakerUserId,
      speakerUserName: message.speakerUserName,
      sourceText: message.sourceText,
      translationText: _extractTranslationText(message),
      timestamp: message.timestamp,
      isCompleted: message.isCompleted,
    );
  }

  String _extractTranslationText(TranscriberMessage message) {
    if (message.translationTexts.isEmpty) return '';
    return message.translationTexts.values.first;
  }

  @override
  void dispose() {
    _clearAllData();
    _unsubscribeFromTranscriberState();
    _transcriberStore.removeAITranscriberListener(_transcriberListener);
    _eventController.close();
    super.dispose();
  }
}
