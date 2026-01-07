import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list.dart';
import 'package:tuikit_atomic_x/message_list/utils/asr_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/calling_message_data_provider.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_status_mixin.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_tooltip.dart';

class MessageItem extends StatelessWidget with MessageStatusMixin {
  final MessageInfo message;
  final String conversationID;
  final bool isGroup;
  final double maxWidth;
  final MessageListStore messageListStore;
  final bool isHighlighted;
  final VoidCallback? onHighlightComplete;
  final OnUserClick? onUserClick;
  /// Callback when user long presses on avatar (for @ mention feature)
  final OnUserLongPress? onUserLongPress;
  final List<MessageCustomAction> customActions;
  final MessageListConfigProtocol config;

  // Multi-select mode related
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onEnterMultiSelectMode;

  // Merged detail view mode - disables long press menu and read receipt
  final bool isInMergedDetailView;

  // ASR display manager for voice-to-text feature
  final AsrDisplayManager? asrDisplayManager;
  // Callback when ASR text bubble is long pressed, provides message and GlobalKey for positioning popup menu
  final void Function(MessageInfo message, GlobalKey asrBubbleKey)? onAsrBubbleLongPress;

  // Translation display manager for text translation feature
  final TranslationDisplayManager? translationDisplayManager;
  // Callback when translation bubble is long pressed, provides message and GlobalKey for positioning popup menu
  final void Function(MessageInfo message, GlobalKey translationBubbleKey)? onTranslationBubbleLongPress;

  const MessageItem({
    super.key,
    required this.message,
    required this.conversationID,
    this.isGroup = false,
    this.maxWidth = 200,
    required this.messageListStore,
    required this.isHighlighted,
    this.onHighlightComplete,
    this.onUserClick,
    this.onUserLongPress,
    this.customActions = const [],
    required this.config,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.onEnterMultiSelectMode,
    this.isInMergedDetailView = false,
    this.asrDisplayManager,
    this.onAsrBubbleLongPress,
    this.translationDisplayManager,
    this.onTranslationBubbleLongPress,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelf = message.isSelf;
    String? avatarURL = message.rawMessage?.faceUrl;
    String senderName = ChatUtil.getMessageSenderName(message);
    CallingMessageDataProvider provider = CallingMessageDataProvider(message, context);

    if (provider.isCallingSignal && provider.participantType == CallParticipantType.c2c) {
      if (provider.content.isEmpty) {
        return Container();
      }

      isSelf = provider.direction == CallMessageDirection.outcoming;
      if (!isSelf) {
        return _buildWithConversationInfo(isSelf, avatarURL, senderName);
      }
    }

    Widget messageBubble = MessageBubble(
      message: message,
      conversationID: conversationID,
      isSelf: isSelf,
      maxWidth: maxWidth,
      config: config,
      messageListStore: messageListStore,
      isHighlighted: isHighlighted,
      onHighlightComplete: onHighlightComplete,
      customActions: customActions,
      menuCallbacks: _buildMenuCallbacks(context),
      isInMergedDetailView: isInMergedDetailView,
      asrDisplayManager: asrDisplayManager,
      onAsrBubbleLongPress: onAsrBubbleLongPress,
      translationDisplayManager: translationDisplayManager,
      onTranslationBubbleLongPress: onTranslationBubbleLongPress,
    );

    if (message.messageType == MessageType.system || MessageUtil.isSystemStyleCustomMessage(message, context)) {
      // Check if system messages should be shown
      if (!config.isShowSystemMessage) {
        return const SizedBox.shrink();
      }
      return messageBubble;
    }

    // In merged detail view, always use left-aligned layout
    if (isInMergedDetailView) {
      return _buildLeftAlignedLayout(context, messageBubble, isSelf, avatarURL, senderName);
    }

    Widget messageRow;
    switch (config.alignment) {
      case AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED:
        messageRow = _buildTwoSidedLayout(context, messageBubble, isSelf, avatarURL, senderName);
        break;
      case AppBuilder.MESSAGE_ALIGNMENT_LEFT:
        messageRow = _buildLeftAlignedLayout(context, messageBubble, isSelf, avatarURL, senderName);
        break;
      case AppBuilder.MESSAGE_ALIGNMENT_RIGHT:
        messageRow = _buildRightAlignedLayout(context, messageBubble, isSelf, avatarURL, senderName);
        break;
      default:
        messageRow = _buildTwoSidedLayout(context, messageBubble, isSelf, avatarURL, senderName);
    }

    // Add checkbox in multi-select mode
    if (isMultiSelectMode) {
      return _buildMultiSelectRow(messageRow, isSelf);
    }

    return messageRow;
  }

  /// Build row layout in multi-select mode
  Widget _buildMultiSelectRow(Widget messageRow, bool isSelf) {
    return GestureDetector(
      onTap: onToggleSelection,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox always on the left
          MessageCheckbox(
            isSelected: isSelected,
            isEnabled: true,
          ),
          const SizedBox(width: 8),
          // Message content
          Expanded(child: messageRow),
        ],
      ),
    );
  }

  /// Build menu callbacks
  MessageMenuCallbacks? _buildMenuCallbacks(BuildContext context) {
    if (isMultiSelectMode) {
      // Disable menu in multi-select mode
      return null;
    }
    return DefaultMessageMenuCallbacks(
      context: context,
      messageListStore: messageListStore,
      messageActionStore: MessageActionStore.create(message),
      conversationID: conversationID,
      config: config,
      onMultiSelectTriggered: onEnterMultiSelectMode,
    );
  }

  /// Show resend confirmation dialog
  void _showResendConfirmDialog(BuildContext context) {
    final locale = AtomicLocalizations.of(context);
    AlertDialog.show(
      context,
      title: locale.resendTips,
      onConfirm: () => _handleResendMessage(),
      content: '',
    );
  }

  /// Handle resend message
  void _handleResendMessage() {
    final messageInputStore = MessageInputStore.create(conversationID: conversationID);
    messageInputStore.sendMessage(message: message);
  }

  Widget _buildWithConversationInfo(bool isSelf, String? defaultAvatarURL, String defaultSenderName) {
    return FutureBuilder<ConversationInfo?>(
      future: _fetchConversationInfo(),
      builder: (context, snapshot) {
        String? avatarURL = defaultAvatarURL;
        String senderName = defaultSenderName;

        if (snapshot.hasData && snapshot.data != null) {
          final conversationInfo = snapshot.data!;
          avatarURL = conversationInfo.avatarURL ?? defaultAvatarURL;
          senderName = conversationInfo.title ?? defaultSenderName;
        }

        return _buildMessageLayout(isSelf, avatarURL, senderName, context);
      },
    );
  }

  Future<ConversationInfo?> _fetchConversationInfo() async {
    try {
      ConversationListStore conversationListStore = ConversationListStore.create();
      final result = await conversationListStore.fetchConversationInfo(conversationID: conversationID);

      if (result.isSuccess) {
        final conversationList = conversationListStore.conversationListState.conversationList;
        return conversationList.firstWhere(
          (conv) => conv.conversationID == conversationID,
          orElse: () => ConversationInfo(conversationID: conversationID),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching conversation info: $e');
      return null;
    }
  }

  Widget _buildMessageLayout(bool isSelf, String? avatarUrl, String senderName, BuildContext context) {
    Widget messageBubble = MessageBubble(
      message: message,
      conversationID: conversationID,
      isSelf: isSelf,
      maxWidth: maxWidth,
      config: config,
      messageListStore: messageListStore,
      isHighlighted: isHighlighted,
      onHighlightComplete: onHighlightComplete,
      customActions: customActions,
      isInMergedDetailView: isInMergedDetailView,
      asrDisplayManager: asrDisplayManager,
      onAsrBubbleLongPress: onAsrBubbleLongPress,
      translationDisplayManager: translationDisplayManager,
      onTranslationBubbleLongPress: onTranslationBubbleLongPress,
    );

    if (message.messageType == MessageType.system || MessageUtil.isSystemStyleCustomMessage(message, context)) {
      // Check if system messages should be shown
      if (!config.isShowSystemMessage) {
        return const SizedBox.shrink();
      }
      return messageBubble;
    }

    switch (config.alignment) {
      case AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED:
        return _buildTwoSidedLayout(context, messageBubble, isSelf, avatarUrl, senderName);
      case AppBuilder.MESSAGE_ALIGNMENT_LEFT:
        return _buildLeftAlignedLayout(context, messageBubble, isSelf, avatarUrl, senderName);
      case AppBuilder.MESSAGE_ALIGNMENT_RIGHT:
        return _buildRightAlignedLayout(context, messageBubble, isSelf, avatarUrl, senderName);
      default:
        return _buildTwoSidedLayout(context, messageBubble, isSelf, avatarUrl, senderName);
    }
  }

  Widget _buildTwoSidedLayout(BuildContext context, Widget messageBubble, bool isSelf,
      [String? avatarUrl, String? senderName]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isSelf
            ? _buildSelfMessage(context, messageBubble, avatarUrl, senderName)
            : _buildOtherMessage(context, messageBubble, avatarUrl, senderName),
      ),
    );
  }

  Widget _buildLeftAlignedLayout(BuildContext context, Widget messageBubble, bool isSelf,
      [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.sender.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final colors = BaseThemeProvider.colorsOf(context);

    // In merged detail view: always show avatar, disable click, hide nickname
    final shouldShowAvatar = isInMergedDetailView || config.isShowLeftAvatar;
    final shouldShowNickname = !isInMergedDetailView && config.isShowLeftNickname;

    // Build status indicator if needed (only for self messages)
    final statusIndicator = isSelf
        ? buildOutsideBubbleStatusIndicator(
            message: message,
            colorsTheme: colors,
            onResendTap: message.status == MessageStatus.sendFail ? () => _showResendConfirmDialog(context) : null,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shouldShowAvatar)
            GestureDetector(
              onTap: isInMergedDetailView
                  ? null
                  : () {
                      // Disable avatar click in multi-select mode
                      if (isMultiSelectMode) {
                        onToggleSelection?.call();
                        return;
                      }
                      if (!isSelf && onUserClick != null) {
                        onUserClick!(message.sender.userID);
                      }
                    },
              onLongPress: isInMergedDetailView || isSelf
                  ? null
                  : () {
                      // Disable avatar long press in multi-select mode
                      if (isMultiSelectMode) return;
                      // Trigger @ mention callback
                      if (onUserLongPress != null) {
                        onUserLongPress!(message.sender.userID, displaySenderName);
                      }
                    },
              child: Avatar(
                content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
              ),
            ),
          if (shouldShowAvatar) SizedBox(width: config.avatarSpacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shouldShowNickname && displaySenderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 8, bottom: 4),
                    child: Text(
                      '$displaySenderName:',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                // Bubble row with status icon on the right (for self messages in left-aligned layout)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(child: messageBubble),
                    if (statusIndicator != null) ...[
                      const SizedBox(width: 6),
                      statusIndicator,
                    ],
                  ],
                ),
                // Violation hint text below the bubble
                _buildViolationHintText(context),
                // Reaction bar for left-aligned layout
                if (config.isSupportReaction && message.reactionList.isNotEmpty)
                  _buildReactionBar(context, isLeft: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightAlignedLayout(BuildContext context, Widget messageBubble, bool isSelf,
      [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.sender.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final colors = BaseThemeProvider.colorsOf(context);

    // Build status indicator if needed (only for self messages)
    final statusIndicator = isSelf
        ? buildOutsideBubbleStatusIndicator(
            message: message,
            colorsTheme: colors,
            onResendTap: message.status == MessageStatus.sendFail ? () => _showResendConfirmDialog(context) : null,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (config.isShowRightNickname && displaySenderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 2, top: 8, bottom: 4),
                    child: Text(
                      '$displaySenderName:',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                // Bubble row with status icon on the left
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (statusIndicator != null) ...[
                      statusIndicator,
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: messageBubble),
                  ],
                ),
                // Violation hint text below the bubble
                _buildViolationHintText(context),
                // Reaction bar for right-aligned layout
                if (config.isSupportReaction && message.reactionList.isNotEmpty)
                  _buildReactionBar(context, isLeft: false),
              ],
            ),
          ),
          if (config.isShowLeftAvatar) SizedBox(width: config.avatarSpacing),
          if (config.isShowLeftAvatar)
            GestureDetector(
              onTap: () {
                // Disable avatar click in multi-select mode
                if (isMultiSelectMode) {
                  onToggleSelection?.call();
                  return;
                }
                if (!isSelf && onUserClick != null) {
                  onUserClick!(message.sender.userID);
                }
              },
              child: Avatar(
                content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSelfMessage(BuildContext context, Widget messageBubble, [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.sender.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final colors = BaseThemeProvider.colorsOf(context);

    // Build status indicator if needed
    final statusIndicator = buildOutsideBubbleStatusIndicator(
      message: message,
      colorsTheme: colors,
      onResendTap: message.status == MessageStatus.sendFail ? () => _showResendConfirmDialog(context) : null,
    );

    return [
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (config.isShowRightNickname && displaySenderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 2, top: 8, bottom: 4),
                child: Text(
                  '$displaySenderName:',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            // Bubble row with status icon on the left
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (statusIndicator != null) ...[
                  statusIndicator,
                  const SizedBox(width: 6),
                ],
                Flexible(child: messageBubble),
              ],
            ),
            // Violation hint text below the bubble
            _buildViolationHintText(context),
            // Reaction bar for self messages (right aligned)
            if (config.isSupportReaction && message.reactionList.isNotEmpty) _buildReactionBar(context, isLeft: false),
          ],
        ),
      ),
      if (config.isShowRightAvatar) SizedBox(width: config.avatarSpacing),
      if (config.isShowRightAvatar)
        Avatar(
          content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
        ),
    ];
  }

  List<Widget> _buildOtherMessage(BuildContext context, Widget messageBubble, [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.sender.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);

    return [
      if (config.isShowLeftAvatar)
        GestureDetector(
          onTap: () {
            // Disable avatar click in multi-select mode
            if (isMultiSelectMode) {
              onToggleSelection?.call();
              return;
            }
            if (onUserClick != null) {
              onUserClick!(message.sender.userID);
            }
          },
          onLongPress: () {
            // Disable avatar long press in multi-select mode
            if (isMultiSelectMode) return;
            // Trigger @ mention callback
            if (onUserLongPress != null) {
              onUserLongPress!(message.sender.userID, displaySenderName);
            }
          },
          child: Avatar(
            content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
          ),
        ),
      if (config.isShowLeftAvatar) SizedBox(width: config.avatarSpacing),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.isShowLeftNickname && displaySenderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 8, bottom: 4),
                child: Text(
                  '$displaySenderName:',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            messageBubble,
            // Violation hint text below the bubble
            _buildViolationHintText(context),
            // Reaction bar for other messages (left aligned)
            if (config.isSupportReaction && message.reactionList.isNotEmpty) _buildReactionBar(context, isLeft: true),
          ],
        ),
      ),
    ];
  }

  Widget _buildReactionBar(BuildContext context, {required bool isLeft}) {
    return MessageReactionBar(
      reactionList: message.reactionList,
      isLeft: isLeft,
      onClick: () => _showReactionDetailSheet(context),
    );
  }

  void _showReactionDetailSheet(BuildContext context) {
    final messageActionStore = MessageActionStore.create(message);
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;

    ReactionDetailSheet.show(
      context: context,
      reactionList: message.reactionList,
      currentUserID: currentUserID,
      onFetchUsers: (reactionID) {
        messageActionStore.fetchMessageReactionUsers(
          reactionID: reactionID,
          count: 20,
        );
      },
      onRemoveReaction: (reactionID) {
        messageActionStore.removeMessageReaction(reactionID: reactionID);
        Navigator.of(context).pop();
      },
      // Disable remove reaction in merged message detail view
      allowRemove: !isInMergedDetailView,
    );
  }

  /// Build violation hint text widget
  Widget _buildViolationHintText(BuildContext context) {
    if (message.status != MessageStatus.violation) {
      return const SizedBox.shrink();
    }

    final colors = BaseThemeProvider.colorsOf(context);
    final locale = AtomicLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        locale.messageTypeSecurityStrike,
        style: TextStyle(
          fontSize: 12,
          color: colors.textColorError,
        ),
      ),
    );
  }
}
