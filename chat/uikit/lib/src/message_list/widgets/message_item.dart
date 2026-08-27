import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/common/utils/time_util.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/asr_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/calling_message_data_provider.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_resender.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_attachments.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_status_mixin.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_read_receipt_view.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_tooltip.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/quote_message_preview.dart';
import '../../common/language/gen/chat_localizations.dart';

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
  /// Callback when call message is clicked in C2C conversation
  final OnCallMessageClick? onCallMessageClick;
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

  // Callback when quote preview is tapped (for navigation to quoted message)
  final void Function(MessageInfo message)? onQuotePreviewTap;

  // Callback when "Quote" is selected from long-press menu
  final void Function(MessageInfo message)? onQuoteMessage;

  /// In merged detail view: the bundle's full message list, used as the
  /// static data source for image / video viewers when [isInMergedDetailView]
  /// is true. The page's MessageListStore is empty in that mode, so the
  /// viewer needs this fallback list to render any media at all.
  final List<MessageInfo>? mergedMediaMessages;

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
    this.onCallMessageClick,
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
    this.onQuotePreviewTap,
    this.onQuoteMessage,
    this.mergedMediaMessages,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelf = message.isSentBySelf;
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
      isMultiSelectMode: isMultiSelectMode,
      asrDisplayManager: asrDisplayManager,
      onAsrBubbleLongPress: onAsrBubbleLongPress,
      translationDisplayManager: translationDisplayManager,
      onTranslationBubbleLongPress: onTranslationBubbleLongPress,
      onCallMessageClick: onCallMessageClick,
      mergedMediaMessages: mergedMediaMessages,
    );

    if (message.messageType == MessageType.tips ||
        message.status == MessageStatus.revoked ||
        MessageUtil.isSystemStyleCustomMessagePayload(message, context)) {
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
      onQuoteMessageCallback: onQuoteMessage,
    );
  }

  /// Show resend confirmation dialog
  void _showResendConfirmDialog(BuildContext context) {
    final locale = ChatLocalizations.of(context);
    AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        title: locale.resendTips,
        cancelConfig: ButtonConfig(text: locale.cancel),
        confirmConfig: ButtonConfig(
          text: locale.confirm,
          type: TextColorPreset.blue,
          onClick: () => _handleResendMessage(),
        ),
      ),
    );
  }

  /// Handle resend message.
  ///
  /// Goes through [MessageResender] which deletes the failed row first
  /// and then sends a fresh message. This avoids the duplicate-row issue
  /// caused by minting a new msgID via [MessageInputStore.sendMessage] —
  /// see [MessageResender] for the rationale and the cross-platform
  /// alignment with the Kotlin team.
  void _handleResendMessage() {
    MessageResender.resend(message: message, conversationID: conversationID);
  }

  /// Show read receipt detail page (group messages only)
  void _showReadReceiptDetail(BuildContext context) {
    final messageActionStore = MessageActionStore.create(message);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageReadReceiptView(
          messageActionStore: messageActionStore,
          messageListStore: messageListStore,
          message: message,
        ),
      ),
    );
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
      final result = await conversationListStore.getConversationInfo(conversationID: conversationID);
      if (result.isSuccess && result.conversationInfo != null) {
        return result.conversationInfo;
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
      isMultiSelectMode: isMultiSelectMode,
      asrDisplayManager: asrDisplayManager,
      onAsrBubbleLongPress: onAsrBubbleLongPress,
      translationDisplayManager: translationDisplayManager,
      onTranslationBubbleLongPress: onTranslationBubbleLongPress,
      onCallMessageClick: onCallMessageClick,
      mergedMediaMessages: mergedMediaMessages,
    );

    if (message.messageType == MessageType.tips ||
        message.status == MessageStatus.revoked ||
        MessageUtil.isSystemStyleCustomMessagePayload(message, context)) {
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

  /// Build the optional attachment widget (ASR / translation bubble) that
  /// hangs below the main bubble. See `MessageAttachmentBuilder` for why
  /// this lives here instead of inside `SoundMessageWidget` /
  /// `TextMessageWidget`.
  Widget? _buildAttachmentIfAny(bool isSelf) {
    return MessageAttachmentBuilder.buildIfAny(
      message: message,
      isSelf: isSelf,
      maxWidth: maxWidth,
      config: config,
      isInMergedDetailView: isInMergedDetailView,
      asrDisplayManager: asrDisplayManager,
      onAsrBubbleLongPress: onAsrBubbleLongPress,
      translationDisplayManager: translationDisplayManager,
      onTranslationBubbleLongPress: onTranslationBubbleLongPress,
    );
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
    final displayAvatarUrl = avatarUrl ?? message.from.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);

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

    // Build read receipt label (only for self messages)
    final readReceiptLabel = isSelf
        ? buildOutsideReadReceiptLabel(
            message: message,
            colorsTheme: colors,
            locale: locale,
            enableReadReceipt: config.enableReadReceipt,
            isInMergedDetailView: isInMergedDetailView,
            onTap: () => _showReadReceiptDetail(context),
          )
        : null;

    final attachment = _buildAttachmentIfAny(isSelf);
    final quotePreview = _buildQuotePreview();
    final inlineTime = isInMergedDetailView ? _buildInlineTime(context, colors) : null;

    final messageColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldShowNickname && displaySenderName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 8, bottom: 4),
            child: Text(
              '$displaySenderName:',
              style: FontScheme.caption3Regular.copyWith(color: colors.textColorSecondary),
            ),
          ),
        // Bubble row with status icon and read receipt label
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: messageBubble),
            if (statusIndicator != null) ...[
              const SizedBox(width: 6),
              statusIndicator,
            ],
            if (readReceiptLabel != null) ...[
              const SizedBox(width: 4),
              readReceiptLabel,
            ],
          ],
        ),
        if (quotePreview != null) quotePreview,
        // ASR / translation bubble (when present) hangs *below*
        // the row so it doesn't shift the receipt down — see
        // Bug-956459.
        if (attachment != null) attachment,
        // Violation hint text below the bubble
        _buildViolationHintText(context),
      ],
    );

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
                        onUserClick!(message.from.userID);
                      }
                    },
              onLongPress: isInMergedDetailView || isSelf
                  ? null
                  : () {
                      // Disable avatar long press in multi-select mode
                      if (isMultiSelectMode) return;
                      // Trigger @ mention callback
                      if (onUserLongPress != null) {
                        onUserLongPress!(message.from.userID, displaySenderName);
                      }
                    },
              child: Avatar(
                content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
              ),
            ),
          if (shouldShowAvatar) SizedBox(width: config.avatarSpacing),
          // With a trailing timestamp the column has to claim the leftover
          // width so the time is pushed to the row's edge; without one it
          // shrink-wraps the bubble as usual.
          if (inlineTime != null)
            Expanded(child: messageColumn)
          else
            Flexible(child: messageColumn),
          if (inlineTime != null) inlineTime,
        ],
      ),
    );
  }

  /// Timestamp pinned to the trailing edge of a merged-detail row.
  ///
  /// The main chat interleaves standalone time dividers between messages, but
  /// a merged bundle is a flat transcript with no dividers, so every row has
  /// to carry its own time.
  Widget? _buildInlineTime(BuildContext context, SemanticColorScheme colors) {
    final timeText = TimeUtil.convertToFormatTime(
      message.timestamp ?? 0,
      context,
      style: TimeFormatStyle.messageList,
    );
    if (timeText.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        timeText,
        style: FontScheme.caption3Regular.copyWith(color: colors.textColorSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRightAlignedLayout(BuildContext context, Widget messageBubble, bool isSelf,
      [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.from.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);

    // Build status indicator if needed (only for self messages)
    final statusIndicator = isSelf
        ? buildOutsideBubbleStatusIndicator(
            message: message,
            colorsTheme: colors,
            onResendTap: message.status == MessageStatus.sendFail ? () => _showResendConfirmDialog(context) : null,
          )
        : null;

    // Build read receipt label (only for self messages)
    final readReceiptLabel = isSelf
        ? buildOutsideReadReceiptLabel(
            message: message,
            colorsTheme: colors,
            locale: locale,
            enableReadReceipt: config.enableReadReceipt,
            isInMergedDetailView: isInMergedDetailView,
            onTap: () => _showReadReceiptDetail(context),
          )
        : null;

    final attachment = _buildAttachmentIfAny(isSelf);
    final quotePreview = _buildQuotePreview();

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
                      style: FontScheme.caption3Regular.copyWith(color: colors.textColorSecondary),
                    ),
                  ),
                // Bubble row with read receipt label on the left, status icon, then bubble
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (readReceiptLabel != null) ...[
                      readReceiptLabel,
                      const SizedBox(width: 4),
                    ],
                    if (statusIndicator != null) ...[
                      statusIndicator,
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: messageBubble),
                  ],
                ),
                if (quotePreview != null) quotePreview,
                if (attachment != null) attachment,
                // Violation hint text below the bubble
                _buildViolationHintText(context),
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
                  onUserClick!(message.from.userID);
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
    final displayAvatarUrl = avatarUrl ?? message.from.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);

    // Build status indicator if needed
    final statusIndicator = buildOutsideBubbleStatusIndicator(
      message: message,
      colorsTheme: colors,
      onResendTap: message.status == MessageStatus.sendFail ? () => _showResendConfirmDialog(context) : null,
    );

    // Build read receipt label (shown outside bubble on the left)
    final readReceiptLabel = buildOutsideReadReceiptLabel(
      message: message,
      colorsTheme: colors,
      locale: locale,
      enableReadReceipt: config.enableReadReceipt,
      isInMergedDetailView: isInMergedDetailView,
      onTap: () => _showReadReceiptDetail(context),
    );

    final attachment = _buildAttachmentIfAny(true);
    final quotePreview = _buildQuotePreview();

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
                  style: FontScheme.caption3Regular.copyWith(color: colors.textColorSecondary),
                ),
              ),
            // Bubble row with read receipt label on the left, status icon, then bubble
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (readReceiptLabel != null) ...[
                  readReceiptLabel,
                  const SizedBox(width: 4),
                ],
                if (statusIndicator != null) ...[
                  statusIndicator,
                  const SizedBox(width: 6),
                ],
                Flexible(child: messageBubble),
              ],
            ),
            if (quotePreview != null) quotePreview,
            if (attachment != null) attachment,
            // Violation hint text below the bubble
            _buildViolationHintText(context),
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
    final colors = BaseThemeProvider.colorsOf(context);
    final displayAvatarUrl = avatarUrl ?? message.from.avatarURL;
    final displaySenderName = senderName ?? ChatUtil.getMessageSenderName(message);
    final attachment = _buildAttachmentIfAny(false);
    final quotePreview = _buildQuotePreview();

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
              onUserClick!(message.from.userID);
            }
          },
          onLongPress: () {
            // Disable avatar long press in multi-select mode
            if (isMultiSelectMode) return;
            // Trigger @ mention callback
            if (onUserLongPress != null) {
              onUserLongPress!(message.from.userID, displaySenderName);
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
                  style: FontScheme.caption3Regular.copyWith(color: colors.textColorSecondary),
                ),
              ),
            messageBubble,
            if (quotePreview != null) quotePreview,
            if (attachment != null) attachment,
            // Violation hint text below the bubble
            _buildViolationHintText(context),
          ],
        ),
      ),
    ];
  }

  /// Preview of the message this one replies to, hung under the bubble on the
  /// same side as it. It sits outside the bubble so that a reply reads as
  /// "here's what I said, and here's what I was answering".
  Widget? _buildQuotePreview() {
    final quoteInfo = message.quoteInfo;
    if (quoteInfo == null) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: QuoteMessagePreview(
        quoteInfo: quoteInfo,
        maxWidth: maxWidth * 0.9,
        onTap: onQuotePreviewTap != null ? () => onQuotePreviewTap!(message) : null,
      ),
    );
  }

  /// Build violation hint text widget
  Widget _buildViolationHintText(BuildContext context) {
    if (message.status != MessageStatus.violation) {
      return const SizedBox.shrink();
    }

    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        locale.messageTypeSecurityStrike,
        style: FontScheme.caption3Regular.copyWith(
          color: colors.textColorError,
        ),
      ),
    );
  }
}
