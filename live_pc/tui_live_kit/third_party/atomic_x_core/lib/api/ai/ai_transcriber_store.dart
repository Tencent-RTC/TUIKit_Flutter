// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   AITranscriberStore @ AtomicXCore
// Function: AI real-time transcription related interfaces, managing real-time speech-to-text transcription and translation features.

// <docgen-keep-start>
import 'dart:async';
import 'dart:convert';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:atomic_x_core/impl/common/list_modify_type.dart';
import 'package:atomic_x_core/impl/common/store_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:atomic_x_core/api/define.dart';

part '../../impl/ai/ai_transcriber_store_impl.dart';
// <docgen-keep-end>

/// Source language type for transcription recognition.
///
/// Defines the source language for speech recognition during real-time transcription. The transcriber will recognize speech in the specified source language and convert it to text.
///
/// > **Note**: Choose the source language that matches the speaker's language for best recognition accuracy. Use `chineseEnglish` for mixed Chinese and English scenarios.
///
/// ### Source Language List
///
/// | Language | Value | Description |
/// |--------|------|-----------|
/// | [chineseEnglish] | zh_en | Chinese-English mixed |
/// | [chinese] | zh | Chinese |
/// | [english] | en | English |
/// | [cantonese] | zh-yue | Cantonese |
/// | [vietnamese] | vi | Vietnamese |
/// | [japanese] | ja | Japanese |
/// | [korean] | ko | Korean |
/// | [indonesian] | id | Indonesian |
/// | [thai] | th | Thai |
/// | [portuguese] | pt | Portuguese |
/// | [turkish] | tr | Turkish |
/// | [arabic] | ar | Arabic |
/// | [spanish] | es | Spanish |
/// | [hindi] | hi | Hindi |
/// | [french] | fr | French |
/// | [malay] | ms | Malay |
/// | [filipino] | fil | Filipino |
/// | [german] | de | German |
/// | [italian] | it | Italian |
/// | [russian] | ru | Russian |
enum SourceLanguage {
  /// Chinese-English mixed recognition.
  chineseEnglish('zh_en'),

  /// Chinese.
  chinese('zh'),

  /// English.
  english('en'),

  /// Cantonese.
  cantonese('zh-yue'),

  /// Vietnamese.
  vietnamese('vi'),

  /// Japanese.
  japanese('ja'),

  /// Korean.
  korean('ko'),

  /// Indonesian.
  indonesian('id'),

  /// Thai.
  thai('th'),

  /// Portuguese.
  portuguese('pt'),

  /// Turkish.
  turkish('tr'),

  /// Arabic.
  arabic('ar'),

  /// Spanish.
  spanish('es'),

  /// Hindi.
  hindi('hi'),

  /// French.
  french('fr'),

  /// Malay.
  malay('ms'),

  /// Filipino.
  filipino('fil'),

  /// German.
  german('de'),

  /// Italian.
  italian('it'),

  /// Russian.
  russian('ru');

  final String value;

  const SourceLanguage(this.value);
}

/// Target language type for translation.
///
/// Defines the target language for translation during real-time transcription. The transcriber will translate recognized text into the specified target languages.
///
/// > **Note**: Multiple translation languages can be configured simultaneously. The translation results will be stored in the `translationTexts` map of `TranscriberMessage`.
///
/// ### Translation Language List
///
/// | Language | Value | Description |
/// |--------|------|-----------|
/// | [chinese] | zh | Chinese |
/// | [english] | en | English |
/// | [vietnamese] | vi | Vietnamese |
/// | [japanese] | ja | Japanese |
/// | [korean] | ko | Korean |
/// | [indonesian] | id | Indonesian |
/// | [thai] | th | Thai |
/// | [portuguese] | pt | Portuguese |
/// | [arabic] | ar | Arabic |
/// | [spanish] | es | Spanish |
/// | [french] | fr | French |
/// | [malay] | ms | Malay |
/// | [german] | de | German |
/// | [italian] | it | Italian |
/// | [russian] | ru | Russian |
enum TranslationLanguage {
  /// Chinese.
  chinese('zh'),

  /// English.
  english('en'),

  /// Vietnamese.
  vietnamese('vi'),

  /// Japanese.
  japanese('ja'),

  /// Korean.
  korean('ko'),

  /// Indonesian.
  indonesian('id'),

  /// Thai.
  thai('th'),

  /// Portuguese.
  portuguese('pt'),

  /// Arabic.
  arabic('ar'),

  /// Spanish.
  spanish('es'),

  /// French.
  french('fr'),

  /// Malay.
  malay('ms'),

  /// German.
  german('de'),

  /// Italian.
  italian('it'),

  /// Russian.
  russian('ru');

  final String value;

  const TranslationLanguage(this.value);
}

/// Voice type for interpretation.
enum InterpretationVoice {
  /// Female voice.
  female('female'),

  /// Male voice.
  male('male');

  final String value;
  const InterpretationVoice(this.value);
}

/// Transcription message, representing a single segment of transcribed speech.
///
/// Represents a single segment of transcribed speech, containing the original text, translation texts, speaker information, and completion status.
/// Each message corresponds to a continuous speech segment from a speaker.
///
/// > **Note**: A message with [isCompleted] set to `true` indicates that the speaker has finished this segment of speech. The `sourceText` and `translationTexts` will no longer be updated for completed messages.
///
/// ### Property Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [segmentId] | `String` | Unique identifier of the transcription segment |
/// | [speakerUserId] | `String` | User ID of the speaker |
/// | [speakerUserName] | `String` | Display name of the speaker |
/// | [sourceText] | `String` | Original transcribed text |
/// | [translationTexts] | `Map<TranslationLanguage, String>` | Translation results, keyed by target language |
/// | [timestamp] | `int` | Timestamp of the message |
/// | [isCompleted] | `bool` | Whether the segment transcription is completed |
class TranscriberMessage {
  /// Unique identifier of the transcription segment.
  final String segmentId;

  /// User ID of the speaker.
  String speakerUserId;

  /// Display name of the speaker.
  String speakerUserName;

  /// Original transcribed text from the speech recognition.
  String sourceText;

  /// Translation results, keyed by target language. Contains translation texts for each configured translation language.
  final Map<TranslationLanguage, String> translationTexts;

  /// Timestamp of the message.
  int timestamp;

  /// Whether the segment transcription is completed. When `true`, the source text and translation texts will no longer be updated.
  bool isCompleted;

  TranscriberMessage({
    required this.segmentId,
    this.speakerUserId = '',
    this.speakerUserName = '',
    this.sourceText = '',
    Map<TranslationLanguage, String>? translationTexts,
    this.timestamp = 0,
    this.isCompleted = false,
  }) : translationTexts = translationTexts ?? {};
}

/// Configuration for transcription features.
///
/// Configuration for the transcription feature, including whether to enable translation.
class TranscriptionConfig {
  /// Whether to enable translation during transcription.
  bool enableTranslation;

  TranscriptionConfig({this.enableTranslation = false});
}

/// Configuration for interpretation features.
///
/// Configuration for the interpretation feature, including voice type selection.
class InterpretationConfig {
  /// Voice type for interpretation output.
  InterpretationVoice voice;

  InterpretationConfig({this.voice = InterpretationVoice.female});
}

/// Transcription configuration, used to configure source language and translation languages.
///
/// Configuration for real-time transcription, including the source language for speech recognition and the target languages for translation.
///
/// ### Configuration Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [sourceLanguage] | `SourceLanguage` | Source language for speech recognition, defaults to Chinese-English mixed |
/// | [translationLanguages] | `List<TranslationLanguage>` | List of target languages for translation |
@Deprecated('Use TranscriptionConfig or InterpretationConfig instead')
class TranscriberConfig {
  /// Source language for speech recognition, defaults to Chinese-English mixed.
  SourceLanguage sourceLanguage;

  /// List of target languages for translation. Multiple languages can be configured simultaneously.
  final List<TranslationLanguage> translationLanguages;

  TranscriberConfig({
    this.sourceLanguage = SourceLanguage.chineseEnglish,
    List<TranslationLanguage>? translationLanguages,
  }) : translationLanguages = translationLanguages ?? [];
}

/// Transcription state data provided by AITranscriberStore.
///
/// Contains the real-time transcription state. Subscribe to this state to display transcription results in the UI.
///
/// > **Note**: The message list is updated automatically as transcription progresses. Subscribe to [transcriberState] to receive real-time updates.
///
/// ### State Property Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [selfLanguage] | `ValueListenable<SourceLanguage>` | Current user's self language |
/// | [realtimeMessageList] | `ValueListenable<List<TranscriberMessage>>` | List of real-time transcription messages |
/// | [isTranscriptionRunning] | `ValueListenable<bool>` | Whether transcription is running |
/// | [transcriptionConfig] | `ValueListenable<TranscriptionConfig>` | Current transcription configuration |
/// | [isInterpretationRunning] | `ValueListenable<bool>` | Whether interpretation is running |
/// | [interpretationConfig] | `ValueListenable<InterpretationConfig>` | Current interpretation configuration |
/// | [interpretationVolume] | `ValueListenable<int>` | Current interpretation volume |
abstract class TranscriberState {
  /// Current user's self language.
  ValueListenable<SourceLanguage> get selfLanguage;

  /// List of real-time transcription messages, updated automatically as transcription progresses.
  ValueListenable<List<TranscriberMessage>> get realtimeMessageList;

  /// Whether transcription is currently running.
  ValueListenable<bool> get isTranscriptionRunning;

  /// Current transcription configuration.
  ValueListenable<TranscriptionConfig> get transcriptionConfig;

  /// Whether interpretation is currently running.
  ValueListenable<bool> get isInterpretationRunning;

  /// Current interpretation configuration.
  ValueListenable<InterpretationConfig> get interpretationConfig;

  /// Current interpretation volume level.
  ValueListenable<int> get interpretationVolume;
}

/// AI transcriber event callback.
@Deprecated('Use transcriberState to observe state changes instead')
class AITranscriberStoreListener {
  /// Triggered when a new transcription message is received.
  /// - [roomID] : Room ID.
  /// - [message] : The transcription message containing recognized text, translation results, and speaker information.
  void Function(String roomID, TranscriberMessage message)? onReceiveTranscriberMessage;

  /// Triggered when the real-time transcription service has been started successfully.
  /// - [roomID] : Room ID.
  /// - [transcriberRobotID] : Transcriber robot ID.
  void Function(String roomID, String transcriberRobotID)? onRealtimeTranscriberStarted;

  /// Triggered when the real-time transcription service has been stopped.
  /// - [roomID] : Room ID.
  /// - [transcriberRobotID] : Transcriber robot ID.
  /// - [reason] : Stop reason code. - 0: User proactively stopped the transcription task. - 1: Room was dissolved by the server. - 2: All users involved in transcription left the room for more than 30 seconds, causing the task to end automatically.
  void Function(String roomID, String transcriberRobotID, int reason)? onRealtimeTranscriberStopped;

  /// Triggered when an error occurs during real-time transcription.
  /// - [roomID] : Room ID.
  /// - [transcriberRobotID] : Transcriber robot ID.
  /// - [code] : Error code.
  /// - [message] : Error message description.
  void Function(String roomID, String transcriberRobotID, int code, String message)? onRealtimeTranscriberError;

  AITranscriberStoreListener({
    this.onReceiveTranscriberMessage,
    this.onRealtimeTranscriberStarted,
    this.onRealtimeTranscriberStopped,
    this.onRealtimeTranscriberError,
  });
}

/// AI real-time transcription related interfaces, managing real-time speech-to-text transcription and translation features.
///
/// `AITranscriberStore` AI real-time transcription management class for handling speech-to-text transcription and translation business.
/// `AITranscriberStore` provides a complete set of AI real-time transcription management APIs, including starting, updating, and stopping real-time transcription.
/// Through this class, you can implement real-time speech-to-text transcription with multi-language translation support during audio/video calls or live streaming.
///
/// ### Key Features
///
/// - **Real-time Transcription**：Supports real-time speech-to-text transcription during audio/video sessions
/// - **Multi-language Source**：Supports 20 source languages including Chinese, English, Japanese, Korean, etc.
/// - **Real-time Translation**：Supports translating transcribed text into 15 target languages in real-time
/// - **State Management**：Provides real-time message list state for UI display
///
/// > **Important**: Use the [create] factory method to create an `AITranscriberStore` instance for a specific room. Configure the source language and translation languages before starting transcription.
///
/// > **Note**: Transcription state updates are delivered through the [transcriberState] publisher. Subscribe to it to receive real-time transcription messages.
///
/// ### Usage Example
///
/// ```dart
/// // Create instance for a specific room
/// final store = AITranscriberStore.create("your_room_id");
///
/// // Subscribe to state changes
/// store.transcriberState.realtimeMessageList.addListener(() {
///     final messages = store.transcriberState.realtimeMessageList.value;
///     for (final message in messages) {
///         print("Speaker: ${message.speakerUserName}");
///         print("Source text: ${message.sourceText}");
///     }
/// });
///
/// // Configure transcription
/// final config = TranscriberConfig(
///     sourceLanguage: SourceLanguage.chineseEnglish,
///     translationLanguages: [TranslationLanguage.english, TranslationLanguage.japanese],
/// );
///
/// // Start transcription
/// final result = await store.startRealtimeTranscriber(config);
/// ```
///
/// ## Topics
///
/// ### Getting Instance
/// - [create] : Create an instance for a specific room
///
/// ### Observing State and Events
/// - [transcriberState] : Transcriber state data
///
/// ### Transcription Control
/// - [startTranscription] : Start transcription
/// - [updateTranscription] : Update transcription configuration
/// - [stopTranscription] : Stop transcription
///
/// ### Interpretation Control
/// - [startInterpretation] : Start interpretation
/// - [updateInterpretation] : Update interpretation configuration
/// - [stopInterpretation] : Stop interpretation
/// - [setInterpretationVolume] : Set interpretation volume
///
/// ## See Also
///
/// - [SourceLanguage]
/// - [TranslationLanguage]
/// - [InterpretationVoice]
/// - [TranscriberMessage]
/// - [TranscriptionConfig]
/// - [InterpretationConfig]
/// - [TranscriberState]
/// - [AITranscriberStoreListener]
abstract class AITranscriberStore {
  /// Transcription state for the current room, including real-time message list, transcription running status, and interpretation configuration. By subscribing to this state, transcription results can be displayed in the UI in real time.
  TranscriberState get transcriberState;

  /// Add AI transcriber event callback listener
  @Deprecated('Use transcriberState to observe state changes instead')
  void addAITranscriberListener(AITranscriberStoreListener listener);

  /// Remove AI transcriber event callback listener
  @Deprecated('Use transcriberState to observe state changes instead')
  void removeAITranscriberListener(AITranscriberStoreListener listener);

  /// Create an AITranscriberStore instance for a specific room.
  /// - [roomID] : Room ID.
  /// Returns: AITranscriberStore instance.
  static AITranscriberStore create(String roomID) {
    return StoreFactory.shared.getStore<AITranscriberStore>(roomID: roomID);
  }

  /// Start transcription
  ///
  /// Start the AI transcription service with the specified language and configuration.
  /// Once started, the transcriber will recognize speech in the room and provide real-time transcription results through the state publisher.
  ///
  /// - [myLanguage] : The source language for the current user's speech recognition.
  /// - [config] : Transcription configuration, including whether to enable translation.
  Future<CompletionHandler> startTranscription(SourceLanguage myLanguage, {TranscriptionConfig? config});

  /// Update transcription configuration
  ///
  /// Update the configuration of the ongoing transcription service.
  /// This can be used to change the source language or modify the translation settings without stopping and restarting the transcription.
  ///
  /// - [myLanguage] : The new source language for speech recognition.
  /// - [config] : New transcription configuration.
  Future<CompletionHandler> updateTranscription(SourceLanguage myLanguage, {TranscriptionConfig? config});

  /// Stop transcription
  ///
  /// Stop the ongoing AI transcription service. After stopping, the transcriber will no longer recognize speech or provide transcription results.
  ///
  Future<CompletionHandler> stopTranscription();

  /// Start interpretation
  ///
  /// Start the AI interpretation service with the specified language and configuration.
  /// Once started, the interpreter will provide real-time voice interpretation in the room.
  ///
  /// - [myLanguage] : The source language for interpretation.
  /// - [config] : Interpretation configuration, including voice type.
  Future<CompletionHandler> startInterpretation(SourceLanguage myLanguage, {InterpretationConfig? config});

  /// Update interpretation configuration
  ///
  /// Update the configuration of the ongoing interpretation service.
  ///
  /// - [myLanguage] : The new source language for interpretation.
  /// - [config] : New interpretation configuration.
  Future<CompletionHandler> updateInterpretation(SourceLanguage myLanguage, {InterpretationConfig? config});

  /// Stop interpretation
  ///
  /// Stop the ongoing AI interpretation service.
  ///
  Future<CompletionHandler> stopInterpretation();

  /// Set interpretation volume
  ///
  /// Set the volume level for the interpretation audio output.
  ///
  /// - [volume] : Volume level.
  Future<CompletionHandler> setInterpretationVolume(int volume);

  /// Start real-time transcription
  ///
  /// Start the AI real-time transcription service with the specified configuration.
  /// Once started, the transcriber will recognize speech in the room and provide real-time transcription and translation results through the state publisher.
  ///
  /// - [config] : Transcription configuration, including source language and translation languages.
  @Deprecated('Use startTranscription instead')
  Future<CompletionHandler> startRealtimeTranscriber(TranscriberConfig config);

  /// Update transcription configuration
  ///
  /// Update the configuration of the ongoing real-time transcription service.
  /// This can be used to change the source language or modify the translation language list without stopping and restarting the transcription.
  ///
  /// - [config] : New transcription configuration.
  @Deprecated('Use updateTranscription instead')
  Future<CompletionHandler> updateRealtimeTranscriber(TranscriberConfig config);

  /// Stop real-time transcription
  ///
  /// Stop the ongoing AI real-time transcription service. After stopping, the transcriber will no longer recognize speech or provide transcription results.
  ///
  @Deprecated('Use stopTranscription instead')
  Future<CompletionHandler> stopRealtimeTranscriber();
}
