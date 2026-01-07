import 'dart:convert';
import 'dart:ui';

import 'package:tuikit_atomic_x/base_component/utils/storage_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBuilder {
  static AppBuilder? _instance;
  late Map<String, dynamic> _config;
  bool _isLoaded = false;

  static const String THEME_MODE_LIGHT = 'light';
  static const String THEME_MODE_DARK = 'dark';

  static const String MESSAGE_ALIGNMENT_TWO_SIDED = 'two-sided';
  static const String MESSAGE_ALIGNMENT_LEFT = 'left';
  static const String MESSAGE_ALIGNMENT_RIGHT = 'right';

  static const String MESSAGE_ACTION_COPY = 'copy';
  static const String MESSAGE_ACTION_RECALL = 'recall';
  static const String MESSAGE_ACTION_QUOTE = 'quote';
  static const String MESSAGE_ACTION_FORWARD = 'forward';
  static const String MESSAGE_ACTION_DELETE = 'delete';

  static const String CONVERSATION_ACTION_DELETE = 'delete';
  static const String CONVERSATION_ACTION_MUTE = 'mute';
  static const String CONVERSATION_ACTION_PIN = 'pin';
  static const String CONVERSATION_ACTION_MARK_UNREAD = 'markUnread';
  static const String CONVERSATION_ACTION_CLEAR_HISTORY = 'clearHistory';

  static const String ATTACHMENT_PICKER_MODE_COLLAPSED = 'collapsed';
  static const String ATTACHMENT_PICKER_MODE_EXPANDED = 'expanded';

  static const String AVATAR_SHAPE_CIRCULAR = 'circular';
  static const String AVATAR_SHAPE_SQUARE = 'square';
  static const String AVATAR_SHAPE_ROUNDED = 'rounded';

  late AtomicThemeConfig themeConfig;

  late MessageListConfig messageListConfig;

  late MessageInputConfig messageInputConfig;

  late ConversationListConfig conversationListConfig;

  late SearchConfig searchConfig;

  late AvatarConfig avatarConfig;

  late TranslateConfig translateConfig;

  AppBuilder._();

  static AppBuilder getInstance() {
    if (_instance == null) {
      _instance = AppBuilder._();
      if (!_instance!._isLoaded) {
        _instance!._setDefaultConfig();
        _instance!._isLoaded = true;
      }
    }
    return _instance!;
  }

  static Future<void> init({required String path}) async {
    final instance = getInstance();
    await instance._loadConfig(path: path);
  }

  Future<void> _loadConfig({required String path}) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      _config = json.decode(jsonString);
      _parseConfig();
      _isLoaded = true;
    } catch (e) {
      debugPrint('_loadConfig failed: $e');
      _config = {};
      _setDefaultConfig();
      _isLoaded = true;
    }
  }

  void _parseConfig() {
    themeConfig = AtomicThemeConfig.fromJson(_config['theme'] ?? {});
    messageListConfig = MessageListConfig.fromJson(_config['messageList'] ?? {});
    messageInputConfig = MessageInputConfig.fromJson(_config['messageInput'] ?? {});
    conversationListConfig = ConversationListConfig.fromJson(_config['conversationList'] ?? {});
    searchConfig = SearchConfig.fromJson(_config['search'] ?? {});
    avatarConfig = AvatarConfig.fromJson(_config['avatar'] ?? {});
    translateConfig = TranslateConfig();
  }

  void _setDefaultConfig() {
    themeConfig = AtomicThemeConfig.defaultConfig();
    messageListConfig = MessageListConfig.defaultConfig();
    messageInputConfig = MessageInputConfig.defaultConfig();
    conversationListConfig = ConversationListConfig.defaultConfig();
    searchConfig = SearchConfig.defaultConfig();
    avatarConfig = AvatarConfig.defaultConfig();
    translateConfig = TranslateConfig();
  }
}

class AtomicThemeConfig {
  final String mode;
  final String? primaryColor;

  AtomicThemeConfig({
    required this.mode,
    this.primaryColor,
  });

  factory AtomicThemeConfig.fromJson(Map<String, dynamic> json) {
    String mode = json['mode'] ?? 'light';
    String primaryColor = json['primaryColor'] ?? '#1C66E5';

    return AtomicThemeConfig(
      mode: mode,
      primaryColor: primaryColor,
    );
  }

  factory AtomicThemeConfig.defaultConfig() {
    return AtomicThemeConfig(
      mode: 'light',
      primaryColor: '#1C66E5',
    );
  }
}

class MessageListConfig {
  static const String _enableReadReceiptKey = 'atomic_enable_read_receipt';
  
  final String alignment;
  final List<String> messageActionList;
  final bool _jsonEnableReadReceipt;

  MessageListConfig({
    required this.alignment,
    required this.messageActionList,
    required bool jsonEnableReadReceipt,
  }) : _jsonEnableReadReceipt = jsonEnableReadReceipt;

  bool get enableReadReceipt {
    final value = StorageUtil.get(_enableReadReceiptKey);
    if (value is bool) {
      return value;
    }

    return _jsonEnableReadReceipt;
  }

  Future<bool> setEnableReadReceipt(bool value) {
    return StorageUtil.set(_enableReadReceiptKey, value);
  }

  factory MessageListConfig.fromJson(Map<String, dynamic> json) {
    List<String> actionList = [];
    if (json['messageActionList'] != null) {
      actionList = List<String>.from(json['messageActionList']);
    }

    return MessageListConfig(
      alignment: json['alignment'] ?? AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED,
      messageActionList: actionList,
      jsonEnableReadReceipt: json['enableReadReceipt'] ?? false,
    );
  }

  factory MessageListConfig.defaultConfig() {
    return MessageListConfig(
      alignment: AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED,
      messageActionList: [
        AppBuilder.MESSAGE_ACTION_COPY,
        AppBuilder.MESSAGE_ACTION_RECALL,
        AppBuilder.MESSAGE_ACTION_QUOTE,
        AppBuilder.MESSAGE_ACTION_FORWARD,
        AppBuilder.MESSAGE_ACTION_DELETE
      ],
      jsonEnableReadReceipt: false,
    );
  }
}

class ConversationListConfig {
  final bool enableCreateConversation;
  final List<String> conversationActionList;

  ConversationListConfig({
    required this.enableCreateConversation,
    required this.conversationActionList,
  });

  factory ConversationListConfig.fromJson(Map<String, dynamic> json) {
    List<String> actionList = [];
    if (json['conversationActionList'] != null) {
      actionList = List<String>.from(json['conversationActionList']);
    }

    return ConversationListConfig(
      enableCreateConversation: json['enableCreateConversation'] ?? true,
      conversationActionList: actionList,
    );
  }

  factory ConversationListConfig.defaultConfig() {
    return ConversationListConfig(
      enableCreateConversation: true,
      conversationActionList: [
        AppBuilder.CONVERSATION_ACTION_DELETE,
        AppBuilder.CONVERSATION_ACTION_MUTE,
        AppBuilder.CONVERSATION_ACTION_PIN,
        AppBuilder.CONVERSATION_ACTION_MARK_UNREAD,
        AppBuilder.CONVERSATION_ACTION_CLEAR_HISTORY
      ],
    );
  }
}

class MessageInputConfig {
  final bool hideSendButton;
  final String attachmentPickerMode;

  MessageInputConfig({
    required this.hideSendButton,
    required this.attachmentPickerMode,
  });

  factory MessageInputConfig.fromJson(Map<String, dynamic> json) {
    return MessageInputConfig(
      hideSendButton: json['hideSendButton'] ?? false,
      attachmentPickerMode: json['attachmentPickerMode'] ?? AppBuilder.ATTACHMENT_PICKER_MODE_COLLAPSED,
    );
  }

  factory MessageInputConfig.defaultConfig() {
    return MessageInputConfig(
      hideSendButton: false,
      attachmentPickerMode: AppBuilder.ATTACHMENT_PICKER_MODE_COLLAPSED,
    );
  }
}

class SearchConfig {
  final bool hideSearch;

  SearchConfig({
    required this.hideSearch,
  });

  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    return SearchConfig(
      hideSearch: json['hideSearch'] ?? false,
    );
  }

  factory SearchConfig.defaultConfig() {
    return SearchConfig(
      hideSearch: false,
    );
  }
}

class AvatarConfig {
  final String shape;

  AvatarConfig({
    required this.shape,
  });

  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    return AvatarConfig(
      shape: json['shape'] ?? AppBuilder.AVATAR_SHAPE_CIRCULAR,
    );
  }

  factory AvatarConfig.defaultConfig() {
    return AvatarConfig(
      shape: AppBuilder.AVATAR_SHAPE_CIRCULAR,
    );
  }
}

class TranslateConfig {
  static const String _translateTargetLanguageKey = 'atomic_translate_target_language';

  /// Get translate target language
  /// Returns saved language or device language as default
  String get targetLanguage {
    final saved = StorageUtil.get(_translateTargetLanguageKey);
    if (saved is String && saved.isNotEmpty) {
      return saved;
    }
    // Return device language as default
    return PlatformDispatcher.instance.locale.languageCode;
  }

  /// Set translate target language
  Future<bool> setTargetLanguage(String languageCode) {
    return StorageUtil.set(_translateTargetLanguageKey, languageCode);
  }
}
