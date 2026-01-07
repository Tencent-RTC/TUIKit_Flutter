import 'dart:convert';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_manager.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/widgets/forward/forward_target_selector.dart';

/// Forward type
enum ForwardType {
  /// Forward separately
  separate,

  /// Forward as merged
  merged,
}

/// Forward service
class ForwardService {
  /// Group conversation ID prefix
  static const String _groupConversationIDPrefix = 'group_';

  /// Maximum number of messages allowed for separate forwarding
  static const int _forwardSeparateLimit = 30;

  // ==================== Validation Methods ====================

  /// Validate if messages can be forwarded (all must be sendSuccess)
  /// Returns error message if validation fails, null if valid
  static String? validateMessagesStatus(BuildContext context, List<MessageInfo> messages) {
    final locale = AtomicLocalizations.of(context);
    final hasFailedMessage = messages.any((msg) => msg.status != MessageStatus.sendSuccess);
    if (hasFailedMessage) {
      return locale.forwardFailedMessageTip;
    }
    return null;
  }

  /// Validate if separate forward limit is exceeded
  /// Returns error message if validation fails, null if valid
  static String? validateSeparateForwardLimit(BuildContext context, List<MessageInfo> messages, ForwardType forwardType) {
    if (forwardType != ForwardType.separate) return null;
    
    final locale = AtomicLocalizations.of(context);
    if (messages.length > _forwardSeparateLimit) {
      return locale.forwardSeparateLimitTip;
    }
    return null;
  }

  /// Execute single message forward flow
  /// Single message forward skips type selection and goes directly to conversation selector
  /// Note: Caller should validate message status before calling this method
  static Future<bool> forwardSingleMessage({
    required BuildContext context,
    required MessageInfo message,
    required MessageListStore messageListStore,
    required MessageListConfigProtocol config,
    String? excludeConversationID,
  }) async {
    // Single message: skip type selection, directly show forward target selector
    final selectResult = await ForwardTargetSelectorPage.show(
      context,
    );
    if (selectResult == null || selectResult.conversationIDs.isEmpty) {
      return false;
    }

    // Execute forward (default to separate for single message)
    final success = await _executeForward(
      context: context,
      messages: [message],
      messageListStore: messageListStore,
      forwardType: ForwardType.separate,
      targetConversationIDs: selectResult.conversationIDs,
      sourceConversationID: excludeConversationID,
      needReadReceipt: config.enableReadReceipt,
    );

    return success;
  }

  /// Select forward type (exposed for external validation flow)
  static Future<ForwardType?> showForwardTypeSelector(BuildContext context) {
    return _showForwardTypeSelector(context);
  }

  /// Execute multiple messages forward with pre-selected forward type
  /// Used when validation is done externally (e.g., from multi-select mode)
  static Future<bool> forwardMessagesWithType({
    required BuildContext context,
    required List<MessageInfo> messages,
    required MessageListStore messageListStore,
    required MessageListConfigProtocol config,
    required ForwardType forwardType,
    String? sourceConversationID,
  }) async {
    if (messages.isEmpty) {
      return false;
    }

    // Select target conversations
    final selectResult = await ForwardTargetSelectorPage.show(
      context,
    );
    if (selectResult == null || selectResult.conversationIDs.isEmpty) {
      return false;
    }

    // Execute forward
    final success = await _executeForward(
      context: context,
      messages: messages,
      messageListStore: messageListStore,
      forwardType: forwardType,
      targetConversationIDs: selectResult.conversationIDs,
      sourceConversationID: sourceConversationID,
      needReadReceipt: config.enableReadReceipt,
    );

    return success;
  }

  /// Execute forward operation
  static Future<bool> _executeForward({
    required BuildContext context,
    required List<MessageInfo> messages,
    required MessageListStore messageListStore,
    required ForwardType forwardType,
    required List<String> targetConversationIDs,
    String? sourceConversationID,
    required bool needReadReceipt,
    bool supportExtension = false,
    OfflinePushInfo? offlinePushInfo,
  }) async {
    try {
      // Build forward options
      final forwardOption = MessageForwardOption(
        forwardType: forwardType == ForwardType.separate ? MessageForwardType.separate : MessageForwardType.merged,
        mergedForwardInfo: forwardType == ForwardType.merged
            ? _buildMergedForwardInfo(
                context,
                messages,
                sourceConversationID,
                needReadReceipt: needReadReceipt,
                supportExtension: supportExtension,
                offlinePushInfo: offlinePushInfo,
              )
            : null,
      );

      // Call SDK forward API for each target conversation
      int failureCount = 0;
      for (final targetConversationID in targetConversationIDs) {
        final result = await messageListStore.forwardMessages(
          messageList: messages,
          forwardOption: forwardOption,
          conversationID: targetConversationID,
        );
        if (!result.isSuccess) {
          failureCount++;
        }
      }

      return failureCount == 0;
    } catch (e) {
      debugPrint('Forward error: $e');
      return false;
    }
  }

  /// Build merged forward info
  static MergedForwardInfo _buildMergedForwardInfo(
    BuildContext context,
    List<MessageInfo> messages,
    String? conversationID, {
    required bool needReadReceipt,
    bool supportExtension = false,
    OfflinePushInfo? offlinePushInfo,
  }) {
    final locale = AtomicLocalizations.of(context);

    // Generate title
    final title = _generateMergedTitle(locale, messages, conversationID);

    // Generate abstract list (max 4 items)
    final abstractList = _generateAbstractList(context, messages);

    // Compatible text
    final compatibleText = _getCompatibleText(locale);

    return MergedForwardInfo(
      title: title,
      abstractList: abstractList,
      compatibleText: compatibleText,
      needReadReceipt: needReadReceipt,
      supportExtension: supportExtension,
      offlinePushInfo: offlinePushInfo,
    );
  }

  /// Generate merged message title
  /// Follows Swift MessageListHelper.generateMergedTitle logic
  static String _generateMergedTitle(
    AtomicLocalizations locale,
    List<MessageInfo> messages,
    String? conversationID,
  ) {
    if (messages.isEmpty) {
      return locale.chatHistory;
    }

    // Check if it's a group chat (conversationID starts with "group_")
    final isGroupChat = conversationID?.startsWith(_groupConversationIDPrefix) ?? false;

    if (isGroupChat) {
      // Group chat: return group chat history
      return locale.groupChatHistory;
    } else {
      // C2C chat: collect unique senders in order of appearance
      final senderNames = <String>[];
      final seenSenders = <String>{};

      for (final message in messages) {
        final sender = message.sender.userID;
        if (!seenSenders.contains(sender)) {
          seenSenders.add(sender);
          // Use nickname, fallback to sender ID
          final name = message.sender.nickname ?? sender;
          senderNames.add(name);
        }
        // Only need at most 2 senders for C2C
        if (senderNames.length >= 2) {
          break;
        }
      }

      if (senderNames.length == 2) {
        // Two senders: "A and B chat history"
        return locale.chatHistoryForSomebodyFormat(senderNames[0], senderNames[1]);
      } else if (senderNames.length == 1) {
        // One sender: "A's chat history"
        return locale.c2cChatHistoryFormat(senderNames[0]);
      } else {
        // Fallback
        return locale.chatHistory;
      }
    }
  }

  /// Generate abstract list
  static List<String> _generateAbstractList(BuildContext context, List<MessageInfo> messages) {
    final abstractList = <String>[];

    for (int i = 0; i < messages.length && abstractList.length < 4; i++) {
      final message = messages[i];
      final senderName = ChatUtil.getMessageSenderName(message);
      final content = _getMessageAbstract(context, message);

      if (content.isNotEmpty) {
        abstractList.add('$senderName: $content');
      }
    }

    return abstractList;
  }

  /// Get message abstract
  static String _getMessageAbstract(BuildContext context, MessageInfo message) {
    final locale = AtomicLocalizations.of(context);
    switch (message.messageType) {
      case MessageType.text:
        return message.messageBody?.text ?? '';
      case MessageType.image:
        return locale.messageTypeImage;
      case MessageType.video:
        return locale.messageTypeVideo;
      case MessageType.sound:
        return locale.messageTypeVoice;
      case MessageType.file:
        return locale.messageTypeFile;
      case MessageType.face:
        return locale.messageTypeSticker;
      case MessageType.merged:
        return '[${locale.chatHistory}]';
      case MessageType.custom:
        return locale.messageTypeCustom;
      default:
        return '';
    }
  }

  /// Get compatible text
  static String _getCompatibleText(AtomicLocalizations locale) {
    return locale.forwardCompatibleText;
  }

  /// Show forward type selector using ActionSheet
  static Future<ForwardType?> _showForwardTypeSelector(BuildContext context) async {
    final locale = AtomicLocalizations.of(context);
    ForwardType? selectedType;

    await ActionSheet.show(
      context,
      actions: [
        ActionSheetItem(
          title: locale.forwardIndividually,
          onTap: () {
            selectedType = ForwardType.separate;
          },
        ),
        ActionSheetItem(
          title: locale.forwardMerged,
          onTap: () {
            selectedType = ForwardType.merged;
          },
        ),
      ],
    );

    return selectedType;
  }

  /// Forward text as a text message (used for ASR text, translation text, etc.)
  /// Uses MessageInputStore.sendMessage to send text to each target conversation
  static Future<bool> forwardText({
    required BuildContext context,
    required String text,
    String? excludeConversationID,
  }) async {
    if (text.isEmpty) {
      return false;
    }

    // Select target conversations
    final selectResult = await ForwardTargetSelectorPage.show(
      context,
    );
    if (selectResult == null || selectResult.conversationIDs.isEmpty) {
      return false;
    }

    // Get conversation list store for fetching conversation info
    final conversationListStore = ConversationListStore.create();

    // Send text message to each target conversation using MessageInputStore
    int failureCount = 0;

    for (final targetConversationID in selectResult.conversationIDs) {
      final messageInputStore = MessageInputStore.create(conversationID: targetConversationID);

      // Build text message
      final messageInfo = MessageInfo();
      messageInfo.messageType = MessageType.text;
      final messageBody = MessageBody();
      messageBody.text = text;
      messageInfo.messageBody = messageBody;

      // Create offline push info (same as Swift)
      messageInfo.offlinePushInfo = _createOfflinePushInfo(
        context: context,
        conversationID: targetConversationID,
        message: messageInfo,
        conversationListStore: conversationListStore,
      );

      final result = await messageInputStore.sendMessage(message: messageInfo);
      if (!result.isSuccess) {
        failureCount++;
        debugPrint('Failed to send text to $targetConversationID: ${result.errorCode}, ${result.errorMessage}');
      }
    }

    return failureCount == 0;
  }

  // ==================== Offline Push Info ====================

  /// Create offline push info for a message
  static OfflinePushInfo _createOfflinePushInfo({
    required BuildContext context,
    String? conversationID,
    MessageInfo? message,
    ConversationListStore? conversationListStore,
  }) {
    final loginUserInfo = LoginStore.shared.loginState.loginUserInfo;
    final selfUserId = loginUserInfo?.userID ?? '';
    final selfName = loginUserInfo?.nickname ?? selfUserId;

    bool isGroup = false;
    String groupId = '';
    String title = selfName;
    String description = '';

    if (conversationID != null) {
      isGroup = conversationID.startsWith(_groupConversationIDPrefix);
      groupId = isGroup ? conversationID.substring(_groupConversationIDPrefix.length) : '';

      // Try to get chat name from conversation list
      String? chatName;
      if (conversationListStore != null) {
        final conversation = conversationListStore.conversationListState.conversationList
            .where((conv) => conv.conversationID == conversationID)
            .firstOrNull;
        if (conversation != null && (conversation.title?.isNotEmpty ?? false)) {
          chatName = conversation.title;
        }
      }

      title = isGroup ? (chatName ?? groupId) : selfName;
    }

    if (message != null) {
      description = _trimPushDescription(_getMessageTypeAbstract(context, message));
    }

    final ext = _createOfflinePushExtJson(
      isGroup: isGroup,
      senderId: isGroup ? groupId : selfUserId,
      senderNickName: title,
      faceUrl: loginUserInfo?.avatarURL,
      version: 1,
      action: 1,
      content: description,
      customData: null,
    );

    final pushInfo = OfflinePushInfo();
    pushInfo.title = title;
    pushInfo.description = description;
    pushInfo.extensionInfo = {
      'ext': ext,
      'AndroidOPPOChannelID': 'tuikit',
      'AndroidHuaWeiCategory': 'IM',
      'AndroidVIVOCategory': 'IM',
      'AndroidHonorImportance': 'NORMAL',
      'AndroidMeizuNotifyType': 1,
      'iOSInterruptionLevel': 'time-sensitive',
      'enableIOSBackgroundNotification': false,
    };

    return pushInfo;
  }

  /// Get message type abstract for push notification
  static String _getMessageTypeAbstract(BuildContext context, MessageInfo message) {
    final locale = AtomicLocalizations.of(context);
    switch (message.messageType) {
      case MessageType.text:
        // Convert emoji codes to localized names
        return EmojiManager.createLocalizedStringFromEmojiCodes(context, message.messageBody?.text ?? '');
      case MessageType.image:
        return locale.messageTypeImage;
      case MessageType.video:
        return locale.messageTypeVideo;
      case MessageType.file:
        return locale.messageTypeFile;
      case MessageType.sound:
        return locale.messageTypeVoice;
      case MessageType.face:
        return locale.messageTypeSticker;
      case MessageType.merged:
        return '[${locale.chatHistory}]';
      default:
        return '';
    }
  }

  /// Trim push description to max length
  static String _trimPushDescription(String text, {int maxLength = 50}) {
    final normalized = text.trim().replaceAll('\n', ' ').replaceAll('\r', ' ');
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  /// Create offline push ext JSON string
  static String _createOfflinePushExtJson({
    required bool isGroup,
    required String senderId,
    required String senderNickName,
    String? faceUrl,
    required int version,
    required int action,
    String? content,
    String? customData,
  }) {
    final entity = <String, dynamic>{
      'sender': senderId,
      'nickname': senderNickName,
      'chatType': isGroup ? 2 : 1,
      'version': version,
      'action': action,
    };

    if (content != null && content.isNotEmpty) {
      entity['content'] = content;
    }
    if (faceUrl != null) {
      entity['faceUrl'] = faceUrl;
    }
    if (customData != null) {
      entity['customData'] = customData;
    }

    final timPushFeatures = <String, dynamic>{
      'fcmPushType': 'data',
      'fcmNotificationType': 'timpush',
    };

    final extDict = <String, dynamic>{
      'entity': entity,
      'timPushFeatures': timPushFeatures,
    };

    try {
      return jsonEncode(extDict);
    } catch (e) {
      return '{}';
    }
  }
}
