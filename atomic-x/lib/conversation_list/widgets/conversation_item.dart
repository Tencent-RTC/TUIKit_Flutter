import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/base_component/utils/time_util.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide CompletionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import '../../emoji_picker/emoji_manager.dart';
import '../conversation_list.dart';
import '../conversation_list_config.dart';

class ConversationItem extends StatefulWidget {
  final ConversationInfo conversation;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  final VoidCallback? onPinToggle;

  final VoidCallback? onDelete;

  final VoidCallback? onClearHistory;

  final List<ConversationCustomAction> customActions;

  final ConversationActionConfigProtocol config;

  const ConversationItem({
    super.key,
    required this.conversation,
    this.onTap,
    this.onLongPress,
    this.onPinToggle,
    this.onDelete,
    this.onClearHistory,
    this.customActions = const [],
    required this.config,
  });

  @override
  State<StatefulWidget> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<ConversationItem> {
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);

    return SwipeActionCell(
      key: ObjectKey(widget.conversation.conversationID),
      trailingActions: _buildSwipeActions(colorsTheme),
      backgroundColor: colorsTheme.clearColor,
      child: _buildConversationContent(context),
    );
  }

  List<SwipeAction> _buildSwipeActions(SemanticColorScheme colorsTheme) {
    final actions = <SwipeAction>[];

    if (widget.config.isSupportPin) {
      actions.add(SwipeAction(
        title: widget.conversation.isPinned ? atomicLocale.unpin : atomicLocale.pin,
        onTap: (CompletionHandler handler) async {
          widget.onPinToggle?.call();
          handler(false);
        },
        color: colorsTheme.buttonColorPrimaryDefault,
        icon: Icon(
          widget.conversation.isPinned ? Icons.vertical_align_bottom_rounded : Icons.vertical_align_top_rounded,
          color: colorsTheme.textColorButton,
        ),
        style: TextStyle(
          fontSize: 12,
          color: colorsTheme.textColorButton,
        ),
      ));
    }

    if (_hasMoreActions()) {
      actions.add(SwipeAction(
        title: atomicLocale.more,
        onTap: (CompletionHandler handler) async {
          await _showMoreActions(context, colorsTheme);
          handler(false);
        },
        color: colorsTheme.bgColorMask,
        icon: Icon(
          Icons.more_horiz,
          color: colorsTheme.textColorButton,
        ),
        style: TextStyle(
          fontSize: 12,
          color: colorsTheme.textColorButton,
        ),
      ));
    }

    return actions;
  }

  Widget _buildConversationContent(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    String replaceText = EmojiManager.getEmojiMap(context)
        .keys
        .fold(MessageUtil.getMessageAbstract(widget.conversation.lastMessage, context), (previous, key) {
      return previous.replaceAll(key, EmojiManager.getEmojiMap(context)[key]!);
    });

    String formatTime = TimeUtil.convertToFormatTime(widget.conversation.timestamp ?? 0, context);

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: widget.conversation.isPinned ? colorsTheme.bgColorDefault : colorsTheme.bgColorOperate,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.conversation.title ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorsTheme.textColorPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildUnreadOrMuteIcon(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.conversation.receiveOption == ConversationReceiveOption.notNotify &&
                                  widget.conversation.unreadCount > 0
                              ? '[${_formatUnreadCount(widget.conversation.unreadCount)} ${atomicLocale.messageNum}]$replaceText'
                              : replaceText,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorsTheme.textColorSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorsTheme.textColorTertiary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMoreActions() {
    return widget.config.isSupportClearHistory || widget.config.isSupportDelete || widget.customActions.isNotEmpty;
  }

  Future<void> _showMoreActions(BuildContext context, SemanticColorScheme colors) async {
    final actions = <ActionSheetItem>[];

    if (widget.config.isSupportClearHistory) {
      actions.add(ActionSheetItem(
        title: atomicLocale.clearMessage,
        onTap: () => widget.onClearHistory?.call(),
      ));
    }

    if (widget.config.isSupportDelete) {
      actions.add(ActionSheetItem(
        title: atomicLocale.delete,
        isDestructive: true,
        onTap: () => widget.onDelete?.call(),
      ));
    }

    // Add custom actions
    for (final customAction in widget.customActions) {
      actions.add(ActionSheetItem(
        title: customAction.title,
        onTap: () => customAction.action(widget.conversation),
      ));
    }

    if (actions.isNotEmpty) {
      ActionSheet.show(
        context,
        actions: actions,
      );
    }
  }

  Widget _buildAvatar(BuildContext context) {
    bool hasDot = false;
    if (widget.conversation.receiveOption == ConversationReceiveOption.notNotify &&
        widget.conversation.unreadCount > 0) {
      hasDot = true;
    }

    return Avatar.image(
      name: _getAvatarText(),
      url: widget.conversation.avatarURL!,
      badge: hasDot ? DotBadge() : NoBadge(),
    );
  }

  String _getAvatarText() {
    if (widget.conversation.title == null || widget.conversation.title!.isEmpty) {
      return '?';
    }

    return widget.conversation.title!.substring(0, 1).toUpperCase();
  }

  String _formatUnreadCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return count.toString();
  }

  Widget _buildUnreadOrMuteIcon() {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    if (widget.conversation.receiveOption == ConversationReceiveOption.notNotify &&
        widget.conversation.groupType != GroupType.meeting) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: SvgPicture.asset(
          'chat_assets/icon/ic_mute.svg',
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(colorsTheme.textColorTertiary, BlendMode.srcIn),
          package: 'tuikit_atomic_x',
        ),
      );
    } else if (widget.conversation.unreadCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: colorsTheme.textColorError,
          borderRadius: BorderRadius.circular(8),
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Text(
          _formatUnreadCount(widget.conversation.unreadCount),
          style: TextStyle(
            color: colorsTheme.textColorButton,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
