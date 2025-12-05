import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list.dart';
import 'package:tuikit_atomic_x/message_list/utils/calling_message_data_provider.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/services.dart';
import 'package:tencent_super_tooltip/tencent_super_tooltip.dart';

import 'message_tooltip.dart';
import 'message_types/call_message_widget.dart';
import 'message_types/file_message_widget.dart';
import 'message_types/image_message_widget.dart';
import 'message_types/sound_message_widget.dart';
import 'message_types/text_message_widget.dart';
import 'message_types/video_message_widget.dart';

class DefaultMessageMenuCallbacks implements MessageMenuCallbacks {
  final BuildContext context;
  final MessageListStore? messageListStore;
  MessageActionStore? messageActionStore;

  DefaultMessageMenuCallbacks({
    required this.context,
    this.messageListStore,
  }) {
    messageActionStore = MessageActionStore.create();
  }

  @override
  void onCopyMessage(MessageInfo message) {
    Clipboard.setData(ClipboardData(text: message.messageBody?.text ?? ""));
  }

  @override
  void onDeleteMessage(MessageInfo message) {
    messageActionStore?.deleteMessage(message: message);
  }

  @override
  void onRecallMessage(MessageInfo message) {
    messageActionStore?.recallMessage(message: message);
  }

  @override
  void onForwardMessage(MessageInfo message) {}

  @override
  void onQuoteMessage(MessageInfo message) {}

  @override
  void onMultiSelectMessage(MessageInfo message) {}

  @override
  void onResendMessage(MessageInfo message) {}
}

class MessageBubble extends StatefulWidget {
  final MessageInfo message;
  final String conversationID;
  final bool isSelf;
  final double maxWidth;
  final ValueChanged<String>? onLinkTapped;
  final MessageListStore? messageListStore;
  final MessageMenuCallbacks? menuCallbacks;
  final bool isHighlighted;
  final VoidCallback? onHighlightComplete;
  final List<MessageCustomAction> customActions;
  final MessageListConfigProtocol config;

  const MessageBubble({
    super.key,
    required this.message,
    required this.conversationID,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onLinkTapped,
    this.messageListStore,
    this.menuCallbacks,
    this.isHighlighted = false,
    this.onHighlightComplete,
    this.customActions = const [],
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
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    atomicLocal = AtomicLocalizations.of(context);

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
        messageWidget = TextMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _handleLongPress,
          onLinkTapped: widget.onLinkTapped,
          bubbleKey: _messageKey,
          backgroundBuilder: backgroundBuilder,
          onResendTap: widget.message.status == MessageStatus.sendFail ? _showResendConfirmDialog : null,
        );
        break;

      case MessageType.image:
        messageWidget = ImageMessageWidget(
          message: widget.message,
          conversationID: widget.conversationID,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _handleLongPress,
          messageListStore: widget.messageListStore,
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
          onLongPress: _handleLongPress,
          messageListStore: widget.messageListStore,
          bubbleKey: _messageKey,
        );
        break;

      case MessageType.sound:
        messageWidget = SoundMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _handleLongPress,
          messageListStore: widget.messageListStore,
          bubbleKey: _messageKey,
        );
        break;

      case MessageType.file:
        messageWidget = FileMessageWidget(
          message: widget.message,
          isSelf: widget.isSelf,
          maxWidth: widget.maxWidth,
          config: widget.config,
          onLongPress: _handleLongPress,
          messageListStore: widget.messageListStore,
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
            config: widget.config,
          );
        } else {
          messageWidget = CustomMessageWidget(
            message: widget.message,
            isSelf: widget.isSelf,
            maxWidth: widget.maxWidth,
            onLongPress: _handleLongPress,
            messageListStore: widget.messageListStore,
          );
        }
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

  void _onOpenToolTip() {
    if (tooltip != null && tooltip!.isOpen) {
      tooltip!.close();
      return;
    }
    tooltip = null;

    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final isSelf = widget.isSelf;

    final estimatedMenuHeight = 120.0;

    TooltipDirection popupDirection = TooltipDirection.up;
    double? left;
    double? right;
    double arrowTipDistance = 10;

    RenderBox? box = _messageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      double screenWidth = MediaQuery.of(context).size.width;
      Offset offset = box.localToGlobal(Offset.zero);
      double boxWidth = box.size.width;

      if (isSelf) {
        right = screenWidth - offset.dx - boxWidth;
      } else {
        left = offset.dx;
      }

      if (offset.dy < estimatedMenuHeight + 50) {
        popupDirection = TooltipDirection.down;
        arrowTipDistance = 15;
      } else {
        popupDirection = TooltipDirection.up;
        arrowTipDistance = 15;
      }
    }

    final menuItems = _buildMenuItems();

    tooltip = SuperTooltip(
      popupDirection: popupDirection,
      minimumOutSidePadding: 0,
      arrowTipDistance: arrowTipDistance,
      arrowBaseWidth: 10,
      arrowLength: 10,
      right: right,
      left: left,
      hasArrow: true,
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
      ),
    );

    tooltip?.show(context);
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

    if (widget.config.isSupportCopy) {
      items.add(MessageMenuItem(
        title: atomicLocal.copy,
        icon: Icons.copy,
        onTap: () => _menuCallbacks.onCopyMessage(widget.message),
      ));
    }

    items.addAll(_buildCommonMenuItems());

    return items;
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

    items.addAll(_buildCommonMenuItems());

    return items;
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

  List<MessageMenuItem> _buildCommonMenuItems() {
    final items = <MessageMenuItem>[];

    if (widget.config.isSupportDelete) {
      items.add(MessageMenuItem(
        title: atomicLocal.delete,
        icon: Icons.delete_outline,
        isDestructive: true,
        onTap: () => _menuCallbacks.onDeleteMessage(widget.message),
      ));
    }

    if (widget.config.isSupportRecall && widget.isSelf) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final isWithin2Minutes = (now - (widget.message.timestamp ?? 0)) <= 2 * 60;
      final isSentSuccess = widget.message.status == MessageStatus.sendSuccess;

      if (isWithin2Minutes && isSentSuccess) {
        items.add(MessageMenuItem(
          title: atomicLocal.recall,
          icon: Icons.undo,
          onTap: () => _menuCallbacks.onRecallMessage(widget.message),
        ));
      }
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

  Widget _buildUnsupportedMessage(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onLongPress: _handleLongPress,
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
}
