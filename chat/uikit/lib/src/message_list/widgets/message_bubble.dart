import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/services.dart';
import 'super_tooltip.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_resender.dart';
import 'package:tencent_chat_uikit/src/emoji_picker/emoji_picker_model.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/asr_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/calling_message_data_provider.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/recent_emoji_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_text_parser.dart';
import 'package:tencent_chat_uikit/src/common/language/index.dart';
import 'package:tencent_chat_uikit/src/message_list/listen/listen_from_here_controller.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/forward/forward_service.dart';
import 'message_tooltip.dart';
import 'message_types/call_message_widget.dart';
import 'message_types/file_message_widget.dart';
import 'message_types/image_message_widget.dart';
import 'message_types/merged_message_widget.dart';
import 'message_types/sound_message_widget.dart';
import 'message_types/text_message_widget.dart';
import 'message_types/video_message_widget.dart';
import '../../common/language/gen/chat_localizations.dart';

class DefaultMessageMenuCallbacks implements MessageMenuCallbacks {
  final BuildContext context;
  final MessageListStore messageListStore;
  final String conversationID;
  final MessageListConfigProtocol config;
  MessageActionStore messageActionStore;
  final VoidCallback? onMultiSelectTriggered;
  final void Function(MessageInfo message)? onQuoteMessageCallback;

  DefaultMessageMenuCallbacks({
    required this.context,
    required this.messageListStore,
    required this.messageActionStore,
    required this.conversationID,
    required this.config,
    this.onMultiSelectTriggered,
    this.onQuoteMessageCallback,
  });

  @override
  void onCopyMessage(MessageInfo message) {
    Clipboard.setData(ClipboardData(text: (message.messagePayload as TextMessagePayload?)?.text ?? ""));
  }

  @override
  void onDeleteMessage(MessageInfo message) {
    messageActionStore.delete();
  }

  @override
  void onRecallMessage(MessageInfo message) {
    messageActionStore.revoke();
  }

  @override
  void onForwardMessage(MessageInfo message) {
    // Validate message status first
    final statusError = ForwardService.validateMessagesStatus(context, [message]);
    if (statusError != null) {
      Toast.error(context, statusError);
      return;
    }

    ForwardService.forwardSingleMessage(
      context: context,
      message: message,
      messageListStore: messageListStore,
      config: config,
      excludeConversationID: conversationID,
    );
  }

  @override
  void onQuoteMessage(MessageInfo message) {
    onQuoteMessageCallback?.call(message);
  }

  @override
  void onMultiSelectMessage(MessageInfo message) {
    onMultiSelectTriggered?.call();
  }

  @override
  void onResendMessage(MessageInfo message) {}
}

class MessageBubble extends StatefulWidget {
  final MessageInfo message;
  final String conversationID;
  final bool isSelf;
  final double maxWidth;
  final MessageListStore messageListStore;
  final MessageMenuCallbacks? menuCallbacks;
  final bool isHighlighted;
  final VoidCallback? onHighlightComplete;
  final List<MessageCustomAction> customActions;
  final MessageListConfigProtocol config;
  // Merged detail view mode - disables long press menu and read receipt
  final bool isInMergedDetailView;
  // Multi-select mode - the row-level tap toggles selection, so payloads must
  // not install their own tap handlers while it is active.
  final bool isMultiSelectMode;
  // ASR display manager for voice-to-text feature
  final AsrDisplayManager? asrDisplayManager;
  // Callback when ASR text bubble is long pressed, provides message and GlobalKey for positioning popup menu
  final void Function(MessageInfo message, GlobalKey asrBubbleKey)? onAsrBubbleLongPress;
  // Translation display manager for text translation feature
  final TranslationDisplayManager? translationDisplayManager;
  // Callback when translation bubble is long pressed, provides message and GlobalKey for positioning popup menu
  final void Function(MessageInfo message, GlobalKey translationBubbleKey)? onTranslationBubbleLongPress;
  // Callback when call message is clicked in C2C conversation
  final void Function(String userID, bool isVideoCall)? onCallMessageClick;
  /// In merged detail view: the bundle's full message list, used as the
  /// static data source for image / video viewers (the page's
  /// MessageListStore is empty in this mode).
  final List<MessageInfo>? mergedMediaMessages;

  const MessageBubble({
    super.key,
    required this.message,
    required this.conversationID,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    required this.messageListStore,
    this.menuCallbacks,
    this.isHighlighted = false,
    this.onHighlightComplete,
    this.customActions = const [],
    this.isInMergedDetailView = false,
    this.isMultiSelectMode = false,
    this.asrDisplayManager,
    this.onAsrBubbleLongPress,
    this.translationDisplayManager,
    this.onTranslationBubbleLongPress,
    this.onCallMessageClick,
    this.mergedMediaMessages,
  });

  @override
  State<StatefulWidget> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late MessageMenuCallbacks _menuCallbacks;
  final GlobalKey _messageKey = GlobalKey();
  SuperTooltip? tooltip;

  late AnimationController _highlightAnimationController;

  late ChatLocalizations chatLocal;

  @override
  void initState() {
    super.initState();
    _menuCallbacks = widget.menuCallbacks ??
        DefaultMessageMenuCallbacks(
          context: context,
          messageListStore: widget.messageListStore,
          messageActionStore: MessageActionStore.create(widget.message),
          conversationID: widget.conversationID,
          config: widget.config,
        );

    _highlightAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _highlightAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onHighlightComplete != null) {
        widget.onHighlightComplete!();
      }
    });

    if (widget.isHighlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _highlightAnimationController.forward(from: 0.0);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocal = ChatLocalizations.of(context);
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHighlighted && !_highlightAnimationController.isAnimating) {
      _highlightAnimationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _highlightAnimationController.dispose();
    if (tooltip?.isOpen ?? false) {
      tooltip?.close();
    }
    super.dispose();
  }

  void _showResendConfirmDialog() {
    AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        title: chatLocal.resendTips,
        cancelConfig: ButtonConfig(text: chatLocal.cancel),
        confirmConfig: ButtonConfig(
          text: chatLocal.confirm,
          type: TextColorPreset.blue,
          onClick: _handleResendMessage,
        ),
      ),
    );
  }

  /// Deleting is irreversible, so it goes through the same confirmation the
  /// multi-select delete uses. Lives here rather than in the menu callback so
  /// that a caller-supplied [MessageMenuCallbacks] stays a plain action.
  void _showDeleteConfirmDialog() {
    AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        content: chatLocal.deleteMessagesConfirmTip,
        cancelConfig: ButtonConfig(text: chatLocal.cancel),
        confirmConfig: ButtonConfig(
          text: chatLocal.confirm,
          type: TextColorPreset.red,
          onClick: () => _menuCallbacks.onDeleteMessage(widget.message),
        ),
      ),
    );
  }

  void _handleResendMessage() {
    MessageResender.resend(
      message: widget.message,
      conversationID: widget.conversationID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    // The reaction strip lives *inside* the bubble, under the payload. When it
    // is present the bubble background is painted once around the pair, so the
    // payload itself must not paint one — see [_buildPayloadBubble].
    final reactionStrip = _buildReactionStrip(context);
    final sharesBubbleWithReactions = reactionStrip != null && !_payloadOwnsBubble;

    Widget backgroundBuilder(Widget child) {
      if (widget.isHighlighted) {
        return AnimatedBuilder(
          animation: _highlightAnimationController,
          builder: (context, animChild) {
            final colorAnimation = ColorTween(
              begin: _getBubbleColor(colorsTheme),
              end: colorsTheme.textColorWarning,
            ).animate(CurvedAnimation(
              parent: _highlightAnimationController,
              curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
            ));
            final reverseColorAnimation = ColorTween(
              begin: colorsTheme.textColorWarning,
              end: _getBubbleColor(colorsTheme),
            ).animate(CurvedAnimation(
              parent: _highlightAnimationController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            ));

            return Container(
              decoration: BoxDecoration(
                color: _highlightAnimationController.value <= 0.5 ? colorAnimation.value : reverseColorAnimation.value,
                borderRadius: _getBubbleBorderRadius(),
              ),
              child: animChild,
            );
          },
          child: child,
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: _getBubbleColor(colorsTheme),
          borderRadius: _getBubbleBorderRadius(),
        ),
        child: child,
      );
    }

    if (widget.message.status == MessageStatus.revoked) {
      return SystemMessageWidget(
        message: widget.message,
      );
    }

    Widget messageWidget;

    switch (widget.message.messageType) {
      case MessageType.text:
        messageWidget = TextMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          bubbleKey: _messageKey,
          backgroundBuilder: sharesBubbleWithReactions ? (child) => child : backgroundBuilder,
          onResendTap: widget.message.status == MessageStatus.sendFail ? _showResendConfirmDialog : null,
          isInMergedDetailView: widget.isInMergedDetailView,
        );
        break;

      case MessageType.image:
        messageWidget = _wrapMediaHighlight(
          ImageMessageWidget(
            message: widget.message,
            conversationID: widget.conversationID,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            config: widget.config,
            onLongPress: _longPressCallback,
            messageListStore: widget.messageListStore,
            isInMergedDetailView: widget.isInMergedDetailView,
            mergedMediaMessages: widget.mergedMediaMessages,
            bubbleKey: _messageKey,
          ),
          colorsTheme,
        );
        break;

      case MessageType.video:
        messageWidget = _wrapMediaHighlight(
          VideoMessageWidget(
            message: widget.message,
            conversationID: widget.conversationID,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            config: widget.config,
            onLongPress: _longPressCallback,
            messageListStore: widget.messageListStore,
            isInMergedDetailView: widget.isInMergedDetailView,
            mergedMediaMessages: widget.mergedMediaMessages,
            bubbleKey: _messageKey,
          ),
          colorsTheme,
        );
        break;

      case MessageType.audio:
        messageWidget = _buildPayloadBubble(
          colorsTheme,
          hasReactionStrip: sharesBubbleWithReactions,
          builder: (bubbleColor) => SoundMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            config: widget.config,
            onLongPress: _longPressCallback,
            messageListStore: widget.messageListStore,
            isInMergedDetailView: widget.isInMergedDetailView,
            bubbleKey: _messageKey,
            bubbleColor: bubbleColor,
          ),
        );
        break;

      case MessageType.file:
        messageWidget = _buildPayloadBubble(
          colorsTheme,
          hasReactionStrip: sharesBubbleWithReactions,
          builder: (bubbleColor) => FileMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            config: widget.config,
            onLongPress: _longPressCallback,
            messageListStore: widget.messageListStore,
            isInMergedDetailView: widget.isInMergedDetailView,
            bubbleKey: _messageKey,
            bubbleColor: bubbleColor,
          ),
        );
        break;

      case MessageType.tips:
        messageWidget = SystemMessageWidget(
          message: widget.message,
        );
        break;

      case MessageType.custom:
        final businessID = customMessageBusinessID(widget.message);
        final customBuilder = businessID == null ? null : widget.config.customMessageBuilders[businessID];
        CallingMessageDataProvider provider = CallingMessageDataProvider(widget.message, context);
        if (customBuilder != null) {
          messageWidget = customBuilder(
            context,
            CustomMessageRenderInfo(
              message: widget.message,
              conversationID: widget.conversationID,
              isSelf: widget.isSelf,
              maxWidth: widget.maxWidth,
              isInMergedDetailView: widget.isInMergedDetailView,
              isMultiSelectMode: widget.isMultiSelectMode,
              onLongPress: _longPressCallback,
            ),
          );
        } else if (provider.isCallingSignal) {
          messageWidget = CallMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            isInMergedDetailView: widget.isInMergedDetailView,
            config: widget.config,
            onCallMessageClick: widget.onCallMessageClick,
          );
        } else {
          messageWidget = CustomMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            onLongPress: _longPressCallback,
            messageListStore: widget.messageListStore,
          );
        }
        break;

      case MessageType.merged:
        messageWidget = _buildPayloadBubble(
          colorsTheme,
          hasReactionStrip: sharesBubbleWithReactions,
          builder: (bubbleColor) => MergedMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            config: widget.config,
            onLongPress: _longPressCallback,
            bubbleKey: _messageKey,
            messageListStore: widget.messageListStore,
            isInMergedDetailView: widget.isInMergedDetailView,
            bubbleColor: bubbleColor,
          ),
        );
        break;

      default:
        if (!widget.config.isShowUnsupportMessage) {
          return const SizedBox.shrink();
        }
        messageWidget = _buildUnsupportedMessage(context);
    }

    if (reactionStrip != null) {
      final withReactions = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          messageWidget,
          reactionStrip,
        ],
      );
      // Cooperating payloads skipped their own background above, so paint the
      // bubble once around payload + reactions to make them read as one.
      messageWidget = sharesBubbleWithReactions ? backgroundBuilder(withReactions) : withReactions;
    }

    return messageWidget;
  }

  /// Whether the payload paints a background this widget can't take over.
  ///
  /// Custom, system and unsupported payloads style themselves end to end and
  /// expose no colour hook, so wrapping them would nest one bubble inside
  /// another. Merged forwards opt out too: they render as a bordered card
  /// instead of a bubble. Their reaction strip hangs below the payload instead
  /// of sharing its bubble.
  bool get _payloadOwnsBubble => !const {
        MessageType.text,
        MessageType.image,
        MessageType.video,
        MessageType.audio,
        MessageType.file,
      }.contains(widget.message.messageType);

  /// Builds a payload that paints its own bubble container.
  ///
  /// Passes down the bubble colour the payload should use: transparent when an
  /// outer wrapper owns the background (reaction strip present), an animated
  /// colour while the highlight flash plays, or null to let the payload pick
  /// its own default.
  Widget _buildPayloadBubble(
    SemanticColorScheme colorsTheme, {
    required bool hasReactionStrip,
    required Widget Function(Color? bubbleColor) builder,
  }) {
    if (hasReactionStrip) return builder(Colors.transparent);
    if (!widget.isHighlighted) return builder(null);
    return AnimatedBuilder(
      animation: _highlightAnimationController,
      builder: (context, _) => builder(_animatedBubbleColor(colorsTheme)),
    );
  }

  /// Reaction chips rendered at the bottom of the bubble, or null when the
  /// message carries no reactions.
  Widget? _buildReactionStrip(BuildContext context) {
    if (!widget.config.isSupportReaction || widget.message.reactionList.isEmpty) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth * 0.9),
        child: MessageReactionBar(
          reactionList: widget.message.reactionList,
          isSelf: widget.isSelf,
          onClick: () => _showReactionDetailSheet(context),
        ),
      ),
    );
  }

  void _showReactionDetailSheet(BuildContext context) {
    final messageActionStore = MessageActionStore.create(widget.message);
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;

    ReactionDetailSheet.show(
      context: context,
      reactionList: widget.message.reactionList,
      currentUserID: currentUserID,
      onFetchUsers: (reactionID) {
        messageActionStore.loadReactionUsers(reactionID: reactionID, count: 20);
      },
      onRemoveReaction: (reactionID) {
        messageActionStore.removeReaction(reactionID: reactionID);
        Navigator.of(context).pop();
      },
      // Reactions are read-only inside a merged forward.
      allowRemove: !widget.isInMergedDetailView,
    );
  }

  void _handleLongPress() {
    _onOpenToolTip();
  }

  /// Get long press callback - returns null if in merged detail view
  VoidCallback? get _longPressCallback => widget.isInMergedDetailView ? null : _handleLongPress;

  /// Compute animated bubble color for highlight effect (used by audio/file widgets)
  Color _animatedBubbleColor(SemanticColorScheme colorsTheme) {
    final baseColor = _getBubbleColor(colorsTheme);
    final highlightColor = colorsTheme.textColorWarning;
    final t = _highlightAnimationController.value;
    if (t <= 0.5) {
      // 0.0 -> 0.4: ease in to highlight
      final progress = (t / 0.4).clamp(0.0, 1.0);
      return Color.lerp(baseColor, highlightColor, Curves.easeIn.transform(progress))!;
    } else {
      // 0.6 -> 1.0: ease out back to base
      final progress = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
      return Color.lerp(highlightColor, baseColor, Curves.easeOut.transform(progress))!;
    }
  }

  /// Wrap a media child (image / video) with a translucent highlight
  /// overlay animation. Media payloads don't have a bubble background of
  /// their own — the image/video fills the entire bubble area, so the
  /// bubble-colour animation used for text / audio / file / merged is
  /// invisible behind the media. Instead we overlay a semi-transparent
  /// warning-coloured rectangle that fades in, holds, then fades back
  /// out, on the same curve as the bubble-colour animation.
  ///
  /// The overlay is wrapped in [IgnorePointer] so it doesn't eat taps
  /// (the underlying tap → open-image-viewer flow still works).
  Widget _wrapMediaHighlight(Widget child, SemanticColorScheme colorsTheme) {
    if (!widget.isHighlighted) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _highlightAnimationController,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorsTheme.textColorWarning.withValues(
                      alpha: _mediaHighlightOverlayAlpha(
                          _highlightAnimationController.value),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Eased-in / hold / eased-out alpha curve for the media highlight
  /// overlay. Matches the timing of the bubble-colour animation:
  ///   t ∈ [0.0, 0.4): ease in to peak
  ///   t ∈ [0.4, 0.6): hold at peak
  ///   t ∈ [0.6, 1.0]: ease out to 0
  double _mediaHighlightOverlayAlpha(double t) {
    const peak = 0.4;
    if (t <= 0.4) {
      return Curves.easeIn.transform((t / 0.4).clamp(0.0, 1.0)) * peak;
    }
    if (t < 0.6) {
      return peak;
    }
    return (1 - Curves.easeOut.transform(((t - 0.6) / 0.4).clamp(0.0, 1.0))) *
        peak;
  }

  void _onOpenToolTip() {
    if (tooltip != null && tooltip!.isOpen) {
      tooltip!.close();
      return;
    }
    tooltip = null;

    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final isSelf = widget.isSelf;

    // Estimated height of the action menu, which is the taller of the two panels
    const estimatedMenuHeight = 120.0;
    // Minimum top padding to avoid going above message_list area (considering app bar, status bar, etc.)
    const minTopPadding = 100.0;
    // Minimum bottom padding to avoid going below message_list area (considering input bar, etc.)
    const minBottomPadding = 120.0;
    // Minimum horizontal padding to prevent tooltip from touching screen edges
    const minHorizontalPadding = 8.0;

    TooltipDirection popupDirection = TooltipDirection.up;
    double arrowTipDistance = 15;
    bool hasArrow = true;
    Offset? customTargetCenter;

    RenderBox? box = _messageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      double screenHeight = MediaQuery.of(context).size.height;
      Offset offset = box.localToGlobal(Offset.zero);
      double boxWidth = box.size.width;
      double boxHeight = box.size.height;

      // Bubble top Y position (relative to screen)
      double bubbleTopY = offset.dy;
      // Bubble bottom Y position (relative to screen)
      double bubbleBottomY = offset.dy + boxHeight;

      // Anchor X to the bubble's horizontal center. The arrow inside
      // SuperTooltip will then point straight down (or up) to this X,
      // so it visually originates from the bubble's center.
      //
      // We intentionally don't pass `left`/`right` to SuperTooltip:
      // when both sides are pinned, `_PopupBallonLayoutDelegate` uses
      // `_left` verbatim regardless of the menu's actual width, which
      // produces a menu rect that does NOT contain targetX — that's
      // what was making the arrow render as a long diagonal tether
      // from the menu's edge to the bubble. The default layout
      // (no left/right) centers the menu on targetX and clamps it to
      // the screen's outside padding, so the menu rect always
      // contains targetX and the arrow stays as a short triangle
      // anchored at the bubble's center.
      final double targetX = offset.dx + boxWidth / 2;

      // Calculate available space:
      // - Space above bubble top: from minTopPadding to bubble top
      // - Space below bubble bottom: from bubble bottom to (screenHeight - minBottomPadding)
      double spaceAboveBubbleTop = bubbleTopY - minTopPadding;
      double spaceBelowBubbleBottom = (screenHeight - minBottomPadding) - bubbleBottomY;

      // Priority 1: If there's enough space above the bubble top, show tooltip above
      if (spaceAboveBubbleTop >= estimatedMenuHeight) {
        popupDirection = TooltipDirection.up;
        hasArrow = true;
        arrowTipDistance = 15;
        // Use bubble top as target center (not bubble center) so tooltip appears above the visible top
        customTargetCenter = Offset(targetX, bubbleTopY);
      }
      // Priority 2: If there's enough space below the bubble bottom, show tooltip below
      else if (spaceBelowBubbleBottom >= estimatedMenuHeight) {
        popupDirection = TooltipDirection.down;
        hasArrow = true;
        arrowTipDistance = 15;
        // Use bubble bottom as target center so tooltip appears below the visible bottom
        customTargetCenter = Offset(targetX, bubbleBottomY);
      }
      // Priority 3: Not enough space above or below, show at the bottom of message_list
      else {
        popupDirection = TooltipDirection.up;
        hasArrow = false;
        arrowTipDistance = 0;
        // Position tooltip at the bottom of message_list area (but not exceeding it)
        // The tooltip will be placed above this target center point
        double targetY = screenHeight - minBottomPadding;
        customTargetCenter = Offset(targetX, targetY);
      }
    }

    final menuItems = _buildMenuItems();

    tooltip = SuperTooltip(
      popupDirection: popupDirection,
      minimumOutSidePadding: minHorizontalPadding,
      arrowTipDistance: arrowTipDistance,
      arrowBaseWidth: hasArrow ? 10 : 0,
      arrowLength: hasArrow ? 10 : 0,
      hasArrow: hasArrow,
      borderColor: colorsTheme.bgColorDefault,
      backgroundColor: colorsTheme.bgColorDialog,
      shadowColor: colorsTheme.shadowColor,
      hasShadow: true,
      borderWidth: 1.0,
      borderRadius: 8.0,
      showCloseButton: ShowCloseButton.none,
      touchThroughAreaShape: ClipAreaShape.rectangle,
      content: MessageTooltip(
        menuItems: menuItems,
        message: widget.message,
        onCloseTooltip: () => tooltip?.close(),
        isSelf: isSelf,
        // Violation messages cannot be reacted to
        isSupportReaction: widget.config.isSupportReaction && widget.message.status != MessageStatus.violation,
        onReactionSelected: widget.config.isSupportReaction && widget.message.status != MessageStatus.violation ? _handleReactionSelected : null,
      ),
    );

    tooltip?.show(context, targetCenter: customTargetCenter);
  }

  void _handleReactionSelected(EmojiPickerModelItem emoji) {
    final messageActionStore = MessageActionStore.create(widget.message);
    // Check if already reacted with this emoji
    final existingReaction = widget.message.reactionList.firstWhere(
      (r) => r.reactionID == emoji.name && r.reactedByMyself,
      orElse: () => MessageReaction(
        reactionID: '',
        totalUserCount: 0,
        partialUserList: [],
        reactedByMyself: false,
      ),
    );
    
    if (existingReaction.reactionID.isNotEmpty) {
      // Remove reaction
      messageActionStore.removeReaction(reactionID: emoji.name);
    } else {
      // Add reaction
      messageActionStore.addReaction(reactionID: emoji.name);
      // Save to recent emojis
      RecentEmojiManager.addRecentEmoji(emoji.name);
    }
  }

  List<MessageMenuItem> _buildMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildMenuItemsForMessageType(widget.message.messageType));

    return items;
  }

  List<MessageMenuItem> _buildMenuItemsForMessageType(MessageType messageType) {
    final items = <MessageMenuItem>[];

    switch (messageType) {
      case MessageType.text:
        items.addAll(_buildTextMessagePayloadMenuItems());
        break;
      case MessageType.image:
        items.addAll(_buildImageMessagePayloadMenuItems());
        break;
      case MessageType.video:
        items.addAll(_buildVideoMessagePayloadMenuItems());
        break;
      case MessageType.audio:
        items.addAll(_buildSoundMessageMenuItems());
        break;
      case MessageType.file:
        items.addAll(_buildFileMessagePayloadMenuItems());
        break;
      case MessageType.custom:
        items.addAll(_buildCustomMessagePayloadMenuItems());
        break;
      default:
        items.addAll(_buildCommonMenuItems());
    }

    return items;
  }

  List<MessageMenuItem> _buildTextMessagePayloadMenuItems() {
    final items = <MessageMenuItem>[];

    // Translate menu item
    if (_shouldShowTranslateMenuItem()) {
      items.add(MessageMenuItem(
        title: chatLocal.translate,
        assetName: 'chat_assets/icon/translate.svg',
        package: 'tencent_chat_uikit',
        onTap: () => _handleTranslateText(),
      ));
    }

    items.addAll(_buildCommonMenuItems(includeCopy: true));

    return items;
  }

  /// Check if "Translate" menu item should be shown
  bool _shouldShowTranslateMenuItem() {
    // Check if translate feature is enabled in config
    if (!widget.config.isSupportTranslate) return false;

    // Only for text messages
    if (widget.message.messageType != MessageType.text) return false;
    
    // Only for successfully sent messages
    if (widget.message.status != MessageStatus.sendSuccess) return false;
    
    // Violation messages cannot be translated
    if (widget.message.status == MessageStatus.violation) return false;
    
    final hasTranslation = (widget.message.messagePayload as TextMessagePayload?)?.translatedText?.isNotEmpty == true;
    final messageID = widget.message.msgID ?? '';
    final isHidden = widget.translationDisplayManager?.isHidden(messageID) ?? false;
    
    // Show menu when: no translation OR translation is hidden
    return !hasTranslation || isHidden;
  }

  /// Handle translate text action
  void _handleTranslateText() async {
    final messageID = widget.message.msgID ?? '';
    final hasTranslation = (widget.message.messagePayload as TextMessagePayload?)?.translatedText?.isNotEmpty == true;
    
    // Check if target language has changed
    final cachedLanguage = (widget.message.messagePayload as TextMessagePayload?)?.translateLanguage;
    final currentTargetLanguage = AppBuilder.getInstance().translateConfig.targetLanguage;
    final languageChanged = hasTranslation && cachedLanguage != null && cachedLanguage != currentTargetLanguage;
    
    // If already has translation and language not changed, just show it again
    if (hasTranslation && !languageChanged) {
      widget.translationDisplayManager?.show(messageID);
      return;
    }
    
    // Set translating state (this also removes from hidden set)
    widget.translationDisplayManager?.setTranslating(messageID, true);
    
    // Get the text to translate
    final text = (widget.message.messagePayload as TextMessagePayload?)?.text ?? '';
    if (text.isEmpty) {
      widget.translationDisplayManager?.setTranslating(messageID, false);
      return;
    }
    
    // Get @ user names first, then parse and translate
    final allMembersText = chatLocal.messageInputAllMembers;
    final atUserNames = await TranslationTextParser.getAtUserNames(
      widget.message,
      allMembersText: allMembersText,
    );
    
    _performTranslation(text: text, atUserNames: atUserNames);
  }

  /// Perform the actual translation
  void _performTranslation({required String text, List<String>? atUserNames}) {
    final messageID = widget.message.msgID ?? '';
    
    // Parse text to separate emoji and @ from translatable text
    final splitResult = TranslationTextParser.splitTextByEmojiAndAtUsers(
      text,
      atUserNames: atUserNames,
    );
    final textArray = (splitResult?[TranslationTextParser.kSplitStringTextKey] as List<String>?) ?? [];
    
    // If nothing to translate (pure emoji/@ message), clear translating state
    if (textArray.isEmpty) {
      widget.translationDisplayManager?.setTranslating(messageID, false);
      return;
    }
    
    // Call the API - use target language from AppBuilder settings
    final messageActionStore = MessageActionStore.create(widget.message);
    final targetLanguage = AppBuilder.getInstance().translateConfig.targetLanguage;
    messageActionStore.translateText(
      sourceTextList: textArray,
      targetLanguage: targetLanguage,
    ).then((result) {
      // Clear translating state
      widget.translationDisplayManager?.setTranslating(messageID, false);
      
      if (!result.isSuccess) {
        // Show error toast using base_component Toast
        if (mounted) {
          Toast.error(context, chatLocal.translateFailed);
        }
      }
      // On success, translatedText will be updated in message and shown by default
    });
  }

  List<MessageMenuItem> _buildImageMessagePayloadMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildVideoMessagePayloadMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildSoundMessageMenuItems() {
    final items = <MessageMenuItem>[];

    // Convert to text menu item
    if (_shouldShowConvertToTextMenuItem()) {
      items.add(MessageMenuItem(
        title: chatLocal.convertToText,
        assetName: 'chat_assets/icon/to_text.svg',
        package: 'tencent_chat_uikit',
        onTap: () => _handleConvertVoiceToText(),
      ));
    }

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  /// Check if "Convert to Text" menu item should be shown
  bool _shouldShowConvertToTextMenuItem() {
    // Only for sound messages
    if (widget.message.messageType != MessageType.audio) return false;
    
    // Only for successfully sent messages
    if (widget.message.status != MessageStatus.sendSuccess) return false;
    
    // If already converted and not hidden in this session, hide the menu item
    final hasAsrText = (widget.message.messagePayload as AudioMessagePayload?)?.asrText?.isNotEmpty == true;
    final messageID = widget.message.msgID ?? '';
    final isHidden = widget.asrDisplayManager?.isHidden(messageID) ?? false;
    
    // Show menu when: no asrText OR asrText exists but hidden in this session
    return !hasAsrText || isHidden;
  }

  /// Handle convert voice to text action
  void _handleConvertVoiceToText() {
    final messageID = widget.message.msgID ?? '';
    final hasAsrText = (widget.message.messagePayload as AudioMessagePayload?)?.asrText?.isNotEmpty == true;
    
    // If already has asrText but was hidden, just show it again
    if (hasAsrText) {
      widget.asrDisplayManager?.show(messageID);
      return;
    }
    
    // Set converting state (this also removes from hidden set)`
    widget.asrDisplayManager?.setConverting(messageID, true);
    
    // Call the API
    final messageActionStore = MessageActionStore.create(widget.message);
    messageActionStore.convertVoiceToText(language: '').then((result) async {
      // Clear converting state
      widget.asrDisplayManager?.setConverting(messageID, false);
      
      if (!result.isSuccess) {
        // Show error toast
        if (mounted) {
          Toast.error(context, chatLocal.convertToTextFailed);
        }
      } else {
        // Wait for next frame to ensure messageListStore has been updated via notificationCenter
        await Future.delayed(Duration.zero);
        if (!mounted) return;
        
        // On success, check if asrText is empty from the latest state in messageListStore
        final messageList = widget.messageListStore.state.messageList.value;
        final updatedMessage = messageList.firstWhere(
          (msg) => msg.msgID == messageID,
          orElse: () => widget.message,
        );
        final asrText = (updatedMessage.messagePayload as AudioMessagePayload?)?.asrText ?? '';
        
        if (asrText.isEmpty) {
          // Voice message has no content, show error toast and collapse ASR bubble
          if (mounted) {
            Toast.error(context, chatLocal.convertToTextFailed);
          }
          widget.asrDisplayManager?.hide(messageID);
        }
      }
    });
  }

  List<MessageMenuItem> _buildFileMessagePayloadMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildCustomMessagePayloadMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildCommonMenuItems({bool includeCopy = false}) {
    final items = <MessageMenuItem>[];

    // Multi-select button
    if (widget.config.isSupportMultiSelect) {
      items.add(MessageMenuItem(
        title: _getMultiSelectText(),
        assetName: 'chat_assets/icon/multi_select.svg',
        package: 'tencent_chat_uikit',
        onTap: () => _menuCallbacks.onMultiSelectMessage(widget.message),
      ));
    }

    // Forward button
    if (widget.config.isSupportForward) {
      final isSentSuccess = widget.message.status == MessageStatus.sendSuccess;
      // Violation messages cannot be forwarded
      final isNotViolation = widget.message.status != MessageStatus.violation;
      if (isSentSuccess && isNotViolation) {
        items.add(MessageMenuItem(
          title: chatLocal.forward,
          assetName: 'chat_assets/icon/forward.svg',
          package: 'tencent_chat_uikit',
          onTap: () => _menuCallbacks.onForwardMessage(widget.message),
        ));
      }
    }

    // Quote button
    if (widget.config.isSupportQuote) {
      final isSentSuccess = widget.message.status == MessageStatus.sendSuccess;
      final isNotViolation = widget.message.status != MessageStatus.violation;
      if (isSentSuccess && isNotViolation) {
        items.add(MessageMenuItem(
          title: chatLocal.quote,
          assetName: 'chat_assets/icon/quote.svg',
          package: 'tencent_chat_uikit',
          onTap: () => _menuCallbacks.onQuoteMessage(widget.message),
        ));
      }
    }

    // Copy button (only for text messages)
    // Violation messages cannot be copied
    if (includeCopy && widget.config.isSupportCopy && widget.message.status != MessageStatus.violation) {
      items.add(MessageMenuItem(
        title: chatLocal.copy,
        assetName: 'chat_assets/icon/copy.svg',
        package: 'tencent_chat_uikit',
        onTap: () => _menuCallbacks.onCopyMessage(widget.message),
      ));
    }

    // Recall button
    if (widget.config.isSupportRecall && widget.isSelf) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final isWithin2Minutes = (now - (widget.message.timestamp ?? 0)) <= 2 * 60;
      final isSentSuccess = widget.message.status == MessageStatus.sendSuccess;
      // Violation messages cannot be revoked
      final isNotViolation = widget.message.status != MessageStatus.violation;

      if (isWithin2Minutes && isSentSuccess && isNotViolation) {
        items.add(MessageMenuItem(
          title: chatLocal.recall,
          assetName: 'chat_assets/icon/revoke.svg',
          package: 'tencent_chat_uikit',
          onTap: () => _menuCallbacks.onRecallMessage(widget.message),
        ));
      }
    }

    // Delete button
    if (widget.config.isSupportDelete) {
      items.add(MessageMenuItem(
        title: chatLocal.delete,
        assetName: 'chat_assets/icon/delete.svg',
        package: 'tencent_chat_uikit',
        onTap: _showDeleteConfirmDialog,
      ));
    }

    // Listen-from-here button (all message types).
    items.add(MessageMenuItem(
      title: ChatLocalizations.of(context).listenFromHere,
      assetName: 'chat_assets/icon/listen_from_here.svg',
      package: 'tencent_chat_uikit',
      onTap: () {
        ListenFromHereController.instance.start(
          messages: widget.messageListStore.state.messageList.value,
          fromMessageId: widget.message.msgID,
          l: ChatLocalizations.of(context),
        );
      },
    ));

    // Add custom actions
    for (final customAction in widget.customActions) {
      items.add(MessageMenuItem(
        title: customAction.title,
        assetName: customAction.assetName.isNotEmpty ? customAction.assetName : null,
        package: customAction.package,
        icon: customAction.systemIconFallback,
        onTap: () => customAction.action(widget.message),
      ));
    }

    return items;
  }

  String _getMultiSelectText() {
    return chatLocal.multiSelect;
  }

  Widget _buildUnsupportedMessage(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onLongPress: _longPressCallback,
      child: Container(
        key: _messageKey,
        constraints: BoxConstraints(
          maxWidth: _getBubbleMaxWidth(),
        ),
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: widget.isSelf ? colorsTheme.bgColorBubbleOwn : colorsTheme.bgColorBubbleReciprocal,
          borderRadius: _getBubbleBorderRadius(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorsTheme.textColorSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              chatLocal.unknown,
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBubbleColor(SemanticColorScheme colorsTheme) {
    if (widget.isSelf) {
      return colorsTheme.bgColorBubbleOwn;
    } else {
      return colorsTheme.bgColorBubbleReciprocal;
    }
  }

  double _getBubbleMaxWidth() {
    switch (widget.config.alignment) {
      case 'left':
      case 'right':
        return widget.maxWidth * 0.7;
      case 'two-sided':
      default:
        return widget.maxWidth * 0.7;
    }
  }

  BorderRadius _getBubbleBorderRadius() => MessageUtil.bubbleBorderRadius(
        alignment: widget.config.alignment,
        isSelf: widget.isSelf,
        radius: widget.config.textBubbleCornerRadius,
      );
}
