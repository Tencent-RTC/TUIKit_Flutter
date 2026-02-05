library ai_transcriber_manager;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import '../base_component/localizations/atomic_localizations.dart';

// ==================== Button Widget ====================

class AITranscriberButton extends StatelessWidget {
  final double size;

  const AITranscriberButton({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: aiTranscriberConfigManager.isPanelVisible,
      builder: (context, isPanelVisible, child) {
        return InkWell(
          onTap: aiTranscriberConfigManager.togglePanel,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                isPanelVisible
                    ? 'call_assets/ai_transcriber_open.png'
                    : 'call_assets/ai_transcriber_close.png',
                package: 'tuikit_atomic_x',
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== Models ====================

class LanguageDisplayConfig {
  static String getSourceLanguageDisplayName(BuildContext context, SourceLanguage language) {
    final locale = AtomicLocalizations.of(context);
    switch (language) {
      case SourceLanguage.chineseEnglish:
        return locale.aiSubtitleAutoDetectChineseEnglish;
      case SourceLanguage.chinese:
        return locale.aiSubtitleSpeakChinese;
      case SourceLanguage.english:
        return locale.aiSubtitleSpeakEnglish;
    }
  }

  static String getTranslationLanguageDisplayName(BuildContext context, TranslationLanguage? language) {
    final locale = AtomicLocalizations.of(context);
    if (language == null) {
      return locale.aiSubtitleNoTranslation;
    }
    switch (language) {
      case TranslationLanguage.chinese:
        return locale.aiSubtitleLanguageChinese;
      case TranslationLanguage.english:
        return locale.aiSubtitleLanguageEnglish;
      case TranslationLanguage.japanese:
        return locale.aiSubtitleLanguageJapanese;
      case TranslationLanguage.korean:
        return locale.aiSubtitleLanguageKorean;
      case TranslationLanguage.vietnamese:
        return locale.aiSubtitleLanguageVietnamese;
      case TranslationLanguage.indonesian:
        return locale.aiSubtitleLanguageIndonesian;
      case TranslationLanguage.thai:
        return locale.aiSubtitleLanguageThai;
      case TranslationLanguage.portuguese:
        return locale.aiSubtitleLanguagePortuguese;
      case TranslationLanguage.arabic:
        return locale.aiSubtitleLanguageArabic;
      case TranslationLanguage.spanish:
        return locale.aiSubtitleLanguageSpanish;
      case TranslationLanguage.french:
        return locale.aiSubtitleLanguageFrench;
      case TranslationLanguage.malay:
        return locale.aiSubtitleLanguageMalay;
      case TranslationLanguage.german:
        return locale.aiSubtitleLanguageGerman;
      case TranslationLanguage.italian:
        return locale.aiSubtitleLanguageItalian;
      case TranslationLanguage.russian:
        return locale.aiSubtitleLanguageRussian;
    }
  }
}

class AITranscriberSettings {
  final SourceLanguage sourceLanguage;
  final TranslationLanguage? translationLanguage;
  final bool showBilingual;

  const AITranscriberSettings({
    this.sourceLanguage = SourceLanguage.chineseEnglish,
    this.translationLanguage = TranslationLanguage.english,
    this.showBilingual = true,
  });

  AITranscriberSettings copyWith({
    SourceLanguage? sourceLanguage,
    TranslationLanguage? translationLanguage,
    bool clearTranslationLanguage = false,
    bool? showBilingual,
  }) {
    return AITranscriberSettings(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      translationLanguage: clearTranslationLanguage ? null : (translationLanguage ?? this.translationLanguage),
      showBilingual: showBilingual ?? this.showBilingual,
    );
  }

  TranscriberConfig toTranscriberConfig() {
    return TranscriberConfig(
      sourceLanguage: sourceLanguage,
      translationLanguages: translationLanguage != null ? [translationLanguage!] : [],
    );
  }
}

// ==================== Config Manager ====================

class AITranscriberConfigManager {
  static final AITranscriberConfigManager _instance = AITranscriberConfigManager._internal();
  
  factory AITranscriberConfigManager() => _instance;
  
  AITranscriberConfigManager._internal() {
    AITranscriberStore.shared;
    _currentSettings.addListener(_onSettingsChanged);
  }

  final ValueNotifier<AITranscriberSettings> _currentSettings = 
      ValueNotifier<AITranscriberSettings>(const AITranscriberSettings());
  final ValueNotifier<bool> _isRunning = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isPanelVisible = ValueNotifier<bool>(true);

  ValueNotifier<AITranscriberSettings> get currentSettings => _currentSettings;
  ValueNotifier<bool> get isRunning => _isRunning;
  ValueNotifier<bool> get isPanelVisible => _isPanelVisible;

  void _onSettingsChanged() {
    if (!_isRunning.value) return;
    try {
      AITranscriberStore.shared.updateRealtimeTranscriber(
        _currentSettings.value.toTranscriberConfig(),
      );
    } catch (_) {}
  }

  void start() {
    if (_isRunning.value) return;
    var selfId = CallStore.shared.state.selfInfo.value.id;
    var inviterId = CallStore.shared.state.activeCall.value.inviterId;
    if (selfId == inviterId) {
      AITranscriberStore.shared.startRealtimeTranscriber(
        _currentSettings.value.toTranscriberConfig(),
      );
      _closeVAD();
    }
    _isRunning.value = true;
  }

  void stop() {
    if (!_isRunning.value) return;
    var selfId = CallStore.shared.state.selfInfo.value.id;
    var activeCall = CallStore.shared.state.activeCall.value;
    var isMulti = activeCall.chatGroupId.isNotEmpty || activeCall.inviteeIds.length > 1;
    if (selfId == activeCall.inviterId && !isMulti) {
      AITranscriberStore.shared.stopRealtimeTranscriber();
    }
    _isRunning.value = false;
  }

  void toggle() {
    _isRunning.value ? stop() : start();
  }

  void showPanel() {
    _isPanelVisible.value = true;
  }

  void hidePanel() {
    _isPanelVisible.value = false;
  }

  void togglePanel() {
    _isPanelVisible.value = !_isPanelVisible.value;
  }

  void updateSettings(AITranscriberSettings settings) {
    _currentSettings.value = settings;
  }

  void reset({bool preserveSettings = true}) {
    stop();
    _isPanelVisible.value = true;
    if (!preserveSettings) {
      _currentSettings.value = const AITranscriberSettings();
    }
  }

  void _closeVAD() async {
    final trtcCloud = await TRTCCloud.sharedInstance();
    
    final resetObj = {
      "api": "setPrivateConfig",
      "params": {
        "configs": [
          {
            "key": "Liteav.Audio.common.enable.send.eos.packet.in.dtx",
            "action": "reset"
          }
        ]
      }
    };
    trtcCloud.callExperimentalAPI(jsonEncode(resetObj));

    final closeObj = {
      "api": "setPrivateConfig",
      "params": {
        "configs": [
          {
            "key": "Liteav.Audio.common.enable.send.eos.packet.in.dtx",
            "value": 0,
            "default": 0
          }
        ]
      }
    };
    trtcCloud.callExperimentalAPI(jsonEncode(closeObj));
  }
}

final aiTranscriberConfigManager = AITranscriberConfigManager();

