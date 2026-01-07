import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/services.dart';
import 'super_tooltip.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_picker_model.dart';
import 'package:tuikit_atomic_x/message_list/message_list.dart';
import 'package:tuikit_atomic_x/message_list/utils/asr_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/calling_message_data_provider.dart';
import 'package:tuikit_atomic_x/message_list/utils/recent_emoji_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_text_parser.dart';
import 'package:tuikit_atomic_x/message_list/widgets/forward/forward_service.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_read_receipt_view.dart';

import 'message_tooltip.dart';
import 'message_types/call_message_widget.dart';
import 'message_types/file_message_widget.dart';
import 'message_types/image_message_widget.dart';
import 'message_types/merged_message_widget.dart';
import 'message_types/sound_message_widget.dart';
import 'message_types/text_message_widget.dart';
import 'message_types/video_message_widget.dart';

class DefaultMessageMenuCallbacks implements MessageMenuCallbacks {
  final BuildContext context;
  final MessageListStore messageListStore;
  final String conversationID;
  final MessageListConfigProtocol config;
  MessageActionStore messageActionStore;
  final VoidCallback? onMultiSelectTriggered;

  DefaultMessageMenuCallbacks({
    required this.context,
    required this.messageListStore,
    required this.messageActionStore,
    required this.conversationID,
    required this.config,
    this.onMultiSelectTriggered,
  });

  @override
  void onCopyMessage(MessageInfo message) {
    Clipboard.setData(ClipboardData(text: message.messageBody?.text ?? ""));
  }

  @override
  void onDeleteMessage(MessageInfo message) {
    messageActionStore.deleteMessage();
  }

  @override
  void onRecallMessage(MessageInfo message) {
    messageActionStore.recallMessage();
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
  void onQuoteMessage(MessageInfo message) {}

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
  final ValueChanged<String>? onLinkTapped;
  final MessageListStore messageListStore;
  final MessageMenuCallbacks? menuCallbacks;
  final bool isHighlighted;
  final VoidCallback? onHighlightComplete;
  final List<MessageCustomAction> customActions;
  final MessageListConfigProtocol config;
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

  const MessageBubble({
    super.key,
    required this.message,
    required this.conversationID,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onLinkTapped,
    required this.messageListStore,
    this.menuCallbacks,
    this.isHighlighted = false,
    this.onHighlightComplete,
    this.customActions = const [],
    this.isInMergedDetailView = false,
    this.asrDisplayManager,
    this.onAsrBubbleLongPress,
    this.translationDisplayManager,
    this.onTranslationBubbleLongPress,
  });

  @override
  State<StatefulWidget> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late MessageMenuCallbacks _menuCallbacks;
  final GlobalKey _messageKey = GlobalKey();
  SuperTooltip? tooltip;

  late AnimationController _highlightAnimationController;
  bool _wasHighlighted = false;

  late AtomicLocalizations atomicLocal;

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

    _wasHighlighted = widget.isHighlighted;
    if (widget.isHighlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _highlightAnimationController.forward(from: 0.0);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocal = AtomicLocalizations.of(context);
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHighlighted && !_wasHighlighted) {
      _highlightAnimationController.forward(from: 0.0);
    }
    _wasHighlighted = widget.isHighlighted;
  }

  @override
  void dispose() {
    super.dispose();
    if (tooltip?.isOpen ?? false) {
      tooltip?.close();
    }
    _highlightAnimationController.dispose();
  }

  void _showResendConfirmDialog() {
    AlertDialog.show(
      context,
      title: atomicLocal.resendTips,
      onConfirm: _handleResendMessage,
      content: '',
    );
  }

  void _handleResendMessage() {
    final messageInputStore = MessageInputStore.create(conversationID: widget.conversationID);
    messageInputStore.sendMessage(message: widget.message);
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

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

    Widget messageWidget;

    switch (widget.message.messageType) {
      case MessageType.text:
        final messageID = widget.message.msgID ?? '';
        final isTranslating = widget.translationDisplayManager?.isTranslating(messageID) ?? false;
        final isTranslationHidden = widget.translationDisplayManager?.isHidden(messageID) ?? false;
        messageWidget = TextMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          onLinkTapped: widget.onLinkTapped,
          bubbleKey: _messageKey,
          backgroundBuilder: backgroundBuilder,
          onResendTap: widget.message.status == MessageStatus.sendFail ? _showResendConfirmDialog : null,
          isInMergedDetailView: widget.isInMergedDetailView,
          isTranslating: isTranslating,
          isTranslationHidden: isTranslationHidden,
          onTranslationBubbleLongPress: (translationBubbleKey) => widget.onTranslationBubbleLongPress?.call(widget.message, translationBubbleKey),
        );
        break;

      case MessageType.image:
        messageWidget = ImageMessageWidget(
          message: widget.message,
          conversationID: widget.conversationID,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          messageListStore: widget.messageListStore,
          isInMergedDetailView: widget.isInMergedDetailView,
          bubbleKey: _messageKey,
        );
        break;

      case MessageType.video:
        messageWidget = VideoMessageWidget(
          message: widget.message,
          conversationID: widget.conversationID,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          messageListStore: widget.messageListStore,
          isInMergedDetailView: widget.isInMergedDetailView,
          bubbleKey: _messageKey,
        );
        break;

      case MessageType.sound:
        final messageID = widget.message.msgID ?? '';
        final isConverting = widget.asrDisplayManager?.isConverting(messageID) ?? false;
        final isAsrHidden = widget.asrDisplayManager?.isHidden(messageID) ?? false;
        messageWidget = SoundMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          messageListStore: widget.messageListStore,
          isInMergedDetailView: widget.isInMergedDetailView,
          bubbleKey: _messageKey,
          isConverting: isConverting,
          isAsrHidden: isAsrHidden,
          onAsrBubbleLongPress: (asrBubbleKey) => widget.onAsrBubbleLongPress?.call(widget.message, asrBubbleKey),
        );
        break;

      case MessageType.file:
        messageWidget = FileMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          messageListStore: widget.messageListStore,
          isInMergedDetailView: widget.isInMergedDetailView,
          bubbleKey: _messageKey,
        );
        break;

      case MessageType.system:
        messageWidget = SystemMessageWidget(
          message: widget.message,
        );
        break;

      case MessageType.custom:
        CallingMessageDataProvider provider = CallingMessageDataProvider(widget.message, context);
        if (provider.isCallingSignal) {
          messageWidget = CallMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            isInMergedDetailView: widget.isInMergedDetailView,
            config: widget.config,
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
        messageWidget = MergedMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _longPressCallback,
          bubbleKey: _messageKey,
          messageListStore: widget.messageListStore,
          isInMergedDetailView: widget.isInMergedDetailView,
        );
        break;

      default:
        if (!widget.config.isShowUnsupportMessage) {
          return const SizedBox.shrink();
        }
        messageWidget = _buildUnsupportedMessage(context);
    }

    return messageWidget;
  }

  void _handleLongPress() {
    _onOpenToolTip();
  }

  /// Get long press callback - returns null if in merged detail view
  VoidCallback? get _longPressCallback => widget.isInMergedDetailView ? null : _handleLongPress;

  void _onOpenToolTip() {
    if (tooltip != null && tooltip!.isOpen) {
      tooltip!.close();
      return;
    }
    tooltip = null;

    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final isSelf = widget.isSelf;

    // Estimated menu height including reaction picker
    const estimatedMenuHeight = 120.0;
    // Minimum top padding to avoid going above message_list area (considering app bar, status bar, etc.)
    const minTopPadding = 100.0;
    // Minimum bottom padding to avoid going below message_list area (considering input bar, etc.)
    const minBottomPadding = 120.0;
    // Minimum horizontal padding to prevent tooltip from touching screen edges
    const minHorizontalPadding = 8.0;

    TooltipDirection popupDirection = TooltipDirection.up;
    double? left;
    double? right;
    double arrowTipDistance = 15;
    bool hasArrow = true;
    Offset? customTargetCenter;

    RenderBox? box = _messageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;
      Offset offset = box.localToGlobal(Offset.zero);
      double boxWidth = box.size.width;
      double boxHeight = box.size.height;
      double targetX = offset.dx + boxWidth / 2;
      
      // Bubble top Y position (relative to screen)
      double bubbleTopY = offset.dy;
      // Bubble bottom Y position (relative to screen)
      double bubbleBottomY = offset.dy + boxHeight;

      // Check if current layout is RTL (e.g., Arabic)
      final isRTL = Directionality.of(context) == TextDirection.rtl;
      
      // In RTL layout, the positioning logic needs to be reversed
      // isSelf messages appear on the left in RTL, and on the right in LTR
      final shouldAlignRight = isRTL ? !isSelf : isSelf;
      
      // For RTL support: set both left and right to properly constrain tooltip width
      // This ensures the tooltip doesn't overflow screen boundaries
      if (shouldAlignRight) {
        // Align to right edge of bubble
        double calculatedRight = screenWidth - offset.dx - boxWidth;
        // Ensure right is not negative (bubble might be partially off-screen)
        right = calculatedRight < minHorizontalPadding ? minHorizontalPadding : calculatedRight;
        // Set left to ensure tooltip doesn't overflow left edge
        left = minHorizontalPadding;
      } else {
        // Align to left edge of bubble
        double calculatedLeft = offset.dx;
        // Ensure left is not negative
        left = calculatedLeft < minHorizontalPadding ? minHorizontalPadding : calculatedLeft;
        // Set right to ensure tooltip doesn't overflow right edge
        right = minHorizontalPadding;
      }

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
      right: right,
      left: left,
      hasArrow: hasArrow,
      borderColor: colorsTheme.bgColorDefault,
      backgroundColor: colorsTheme.bgColorDialog,
      shadowColor: colorsTheme.shadowColor,
      hasShadow: true,
      borderWidth: 1.0,
      showCloseButton: ShowCloseButton.none,
      touchThroughAreaShape: ClipAreaShape.rectangle,
      content: MessageTooltip(
        menuItems: menuItems,
        message: widget.message,
        onCloseTooltip: () => tooltip?.close(),
        isSelf: isSelf,
        // Violation messages should not show reaction picker
        showReactionPicker: widget.config.isSupportReaction && widget.message.status != MessageStatus.violation,
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
      messageActionStore.removeMessageReaction(reactionID: emoji.name);
    } else {
      // Add reaction
      messageActionStore.addMessageReaction(reactionID: emoji.name);
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
        items.addAll(_buildTextMessageMenuItems());
        break;
      case MessageType.image:
        items.addAll(_buildImageMessageMenuItems());
        break;
      case MessageType.video:
        items.addAll(_buildVideoMessageMenuItems());
        break;
      case MessageType.sound:
        items.addAll(_buildSoundMessageMenuItems());
        break;
      case MessageType.file:
        items.addAll(_buildFileMessageMenuItems());
        break;
      case MessageType.custom:
        items.addAll(_buildCustomMessageMenuItems());
        break;
      default:
        items.addAll(_buildCommonMenuItems());
    }

    return items;
  }

  List<MessageMenuItem> _buildTextMessageMenuItems() {
    final items = <MessageMenuItem>[];

    // Translate menu item
    if (_shouldShowTranslateMenuItem()) {
      items.add(MessageMenuItem(
        title: atomicLocal.translate,
        icon: Icons.translate,
        onTap: () => _handleTranslateText(),
      ));
    }

    items.addAll(_buildCommonMenuItems(includeCopy: true));

    return items;
  }

  /// Check if "Translate" menu item should be shown
  bool _shouldShowTranslateMenuItem() {
    // Only for text messages
    if (widget.message.messageType != MessageType.text) return false;
    
    // Only for successfully sent messages
    if (widget.message.status != MessageStatus.sendSuccess) return false;
    
    // Violation messages cannot be translated
    if (widget.message.status == MessageStatus.violation) return false;
    
    final hasTranslation = widget.message.messageBody?.translatedText?.isNotEmpty == true;
    final messageID = widget.message.msgID ?? '';
    final isHidden = widget.translationDisplayManager?.isHidden(messageID) ?? false;
    
    // Show menu when: no translation OR translation is hidden
    return !hasTranslation || isHidden;
  }

  /// Handle translate text action
  void _handleTranslateText() async {
    final messageID = widget.message.msgID ?? '';
    final hasTranslation = widget.message.messageBody?.translatedText?.isNotEmpty == true;
    
    // Check if target language has changed
    final cachedLanguage = widget.message.messageBody?.translateLanguage;
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
    final text = widget.message.messageBody?.text ?? '';
    if (text.isEmpty) {
      widget.translationDisplayManager?.setTranslating(messageID, false);
      return;
    }
    
    // Get @ user names first, then parse and translate
    final allMembersText = atomicLocal.messageInputAllMembers;
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
          Toast.error(context, atomicLocal.translateFailed);
        }
      }
      // On success, translatedText will be updated in message and shown by default
    });
  }

  List<MessageMenuItem> _buildImageMessageMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildVideoMessageMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildSoundMessageMenuItems() {
    final items = <MessageMenuItem>[];

    // Convert to text menu item
    if (_shouldShowConvertToTextMenuItem()) {
      items.add(MessageMenuItem(
        title: atomicLocal.convertToText,
        icon: Icons.text_fields,
        onTap: () => _handleConvertVoiceToText(),
      ));
    }

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  /// Check if "Convert to Text" menu item should be shown
  bool _shouldShowConvertToTextMenuItem() {
    // Only for sound messages
    if (widget.message.messageType != MessageType.sound) return false;
    
    // Only for successfully sent messages
    if (widget.message.status != MessageStatus.sendSuccess) return false;
    
    // If already converted and not hidden in this session, hide the menu item
    final hasAsrText = widget.message.messageBody?.asrText?.isNotEmpty == true;
    final messageID = widget.message.msgID ?? '';
    final isHidden = widget.asrDisplayManager?.isHidden(messageID) ?? false;
    
    // Show menu when: no asrText OR asrText exists but hidden in this session
    return !hasAsrText || isHidden;
  }

  /// Handle convert voice to text action
  void _handleConvertVoiceToText() {
    final messageID = widget.message.msgID ?? '';
    final hasAsrText = widget.message.messageBody?.asrText?.isNotEmpty == true;
    
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
          Toast.error(context, atomicLocal.convertToTextFailed);
        }
      } else {
        // Wait for next frame to ensure messageListStore has been updated via notificationCenter
        await Future.delayed(Duration.zero);
        if (!mounted) return;
        
        // On success, check if asrText is empty from the latest state in messageListStore
        final messageList = widget.messageListStore.messageListState.messageList;
        final updatedMessage = messageList.firstWhere(
          (msg) => msg.msgID == messageID,
          orElse: () => widget.message,
        );
        final asrText = updatedMessage.messageBody?.asrText ?? '';
        
        if (asrText.isEmpty) {
          // Voice message has no content, show error toast and collapse ASR bubble
          if (mounted) {
            Toast.error(context, atomicLocal.convertToTextFailed);
          }
          widget.asrDisplayManager?.hide(messageID);
        }
      }
    });
  }

  List<MessageMenuItem> _buildFileMessageMenuItems() {
    final items = <MessageMenuItem>[];

    items.addAll(_buildCommonMenuItems());

    return items;
  }

  List<MessageMenuItem> _buildCustomMessageMenuItems() {
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
        package: 'tuikit_atomic_x',
        icon: Icons.checklist,
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
          title: atomicLocal.forward,
          assetName: 'chat_assets/icon/forward.svg',
          package: 'tuikit_atomic_x',
          icon: Icons.shortcut,
          onTap: () => _menuCallbacks.onForwardMessage(widget.message),
        ));
      }
    }

    // Copy button (only for text messages)
    // Violation messages cannot be copied
    if (includeCopy && widget.config.isSupportCopy && widget.message.status != MessageStatus.violation) {
      items.add(MessageMenuItem(
        title: atomicLocal.copy,
        assetName: 'chat_assets/icon/copy.svg',
        package: 'tuikit_atomic_x',
        icon: Icons.copy,
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
          title: atomicLocal.recall,
          icon: Icons.undo,
          onTap: () => _menuCallbacks.onRecallMessage(widget.message),
        ));
      }
    }

    // Delete button
    if (widget.config.isSupportDelete) {
      items.add(MessageMenuItem(
        title: atomicLocal.delete,
        assetName: 'chat_assets/icon/delete.svg',
        package: 'tuikit_atomic_x',
        icon: Icons.delete_outline,
        isDestructive: true,
        onTap: () => _menuCallbacks.onDeleteMessage(widget.message),
      ));
    }

    // Info button (read receipt detail)
    if (_shouldShowReadReceiptDetail()) {
      items.add(MessageMenuItem(
        title: atomicLocal.detail,
        assetName: 'chat_assets/icon/info.svg',
        package: 'tuikit_atomic_x',
        icon: Icons.info_outline,
        onTap: () => _showReadReceiptDetail(),
      ));
    }

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
    return atomicLocal.multiSelect;
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
              atomicLocal.unknown,
              style: TextStyle(
                fontSize: 14,
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

  BorderRadius _getBubbleBorderRadius() {
    switch (widget.config.alignment) {
      case 'left':
        return const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(18),
        );
      case 'right':
        return const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(0),
        );
      case 'two-sided':
      default:
        if (widget.isSelf) {
          return const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(0),
          );
        } else {
          return const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(18),
          );
        }
    }
  }

  bool _shouldShowReadReceiptDetail() {
    final groupID = widget.message.groupID;
    if (groupID == null || groupID.isEmpty) return false;

    if (!widget.isSelf) return false;

    if (!widget.message.needReadReceipt) return false;

    if (widget.message.status != MessageStatus.sendSuccess) return false;

    return true;
  }

  void _showReadReceiptDetail() {
    final messageActionStore = MessageActionStore.create(widget.message);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageReadReceiptView(
          messageActionStore: messageActionStore,
          messageListStore: widget.messageListStore,
          message: widget.message,
        ),
      ),
    );
  }
}
