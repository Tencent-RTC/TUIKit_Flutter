import 'package:atomic_x_core/atomicxcore.dart' hide CompletionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/base_component/utils/time_util.dart';
import 'package:tuikit_atomic_x/conversation_list/conversation_list.dart';
import 'package:tuikit_atomic_x/conversation_list/conversation_list_config.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';

class ConversationItem extends StatefulWidget {
  final ConversationInfo conversation;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  final VoidCallback? onPinToggle;

  final VoidCallback? onDelete;

  final VoidCallback? onClearHistory;

  final VoidCallback? onMarkAsRead;

  final VoidCallback? onMarkAsUnread;

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
    this.onMarkAsRead,
    this.onMarkAsUnread,
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

    // Mark as read/unread button
    if (widget.config.isSupportMarkUnread) {
      final bool hasUnread = _hasUnreadStatus();
      actions.add(SwipeAction(
        title: hasUnread ? atomicLocale.markAsRead : atomicLocale.markAsUnread,
        onTap: (CompletionHandler handler) async {
          if (hasUnread) {
            widget.onMarkAsRead?.call();
          } else {
            widget.onMarkAsUnread?.call();
          }
          handler(false);
        },
        color: colorsTheme.textColorLink,
        icon: SvgPicture.asset(
          hasUnread ? 'chat_assets/icon/message_read_status.svg' : 'chat_assets/icon/read_receipt_check.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(colorsTheme.textColorButton, BlendMode.srcIn),
          package: 'tuikit_atomic_x',
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

  /// Returns true if the conversation has unread status (unreadCount > 0 or marked as unread).
  bool _hasUnreadStatus() {
    return widget.conversation.unreadCount > 0 ||
        widget.conversation.markList.any((mark) => mark == ConversationMarkType.unread);
  }

  Widget _buildConversationContent(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
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
                        child: _buildSubtitle(context, colorsTheme),
                      ),
                      const SizedBox(width: 8),
                      _buildErrorStatusIcon(colorsTheme),
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

  /// Build subtitle widget with draft support
  Widget _buildSubtitle(BuildContext context, SemanticColorScheme colorsTheme) {
    final draft = widget.conversation.draft;

    // Build @ mention prefix
    String atPrefix = _buildAtMentionPrefix();

    // If there's a draft, show draft with red label
    if (draft != null && draft.isNotEmpty) {
      // Convert emoji codes to localized names for preview
      String localizedDraft = EmojiManager.getEmojiMap(context).keys.fold(draft, (previous, key) {
        return previous.replaceAll(key, EmojiManager.getEmojiMap(context)[key]!);
      });

      // Replace newlines with spaces for single-line display
      localizedDraft = localizedDraft.replaceAll('\n', ' ');

      // Build prefix for unread count (only when muted and unreadCount >= 2)
      String unreadPrefix = '';
      if (widget.conversation.receiveOption == ReceiveMessageOpt.notNotify && widget.conversation.unreadCount >= 2) {
        unreadPrefix = '[${_formatUnreadCount(widget.conversation.unreadCount)} ${atomicLocale.messageNum}]';
      }

      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            if (atPrefix.isNotEmpty)
              TextSpan(
                text: atPrefix,
                style: TextStyle(
                  fontSize: 12,
                  color: colorsTheme.textColorError,
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (unreadPrefix.isNotEmpty)
              TextSpan(
                text: unreadPrefix,
                style: TextStyle(
                  fontSize: 12,
                  color: colorsTheme.textColorSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            TextSpan(
              text: atomicLocale.draft,
              style: TextStyle(
                fontSize: 12,
                color: colorsTheme.textColorError,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: ' $localizedDraft',
              style: TextStyle(
                fontSize: 12,
                color: colorsTheme.textColorSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    // No draft: show last message as before
    String replaceText = EmojiManager.getEmojiMap(context)
        .keys
        .fold(MessageUtil.getMessageAbstract(widget.conversation.lastMessage, context), (previous, key) {
      return previous.replaceAll(key, EmojiManager.getEmojiMap(context)[key]!);
    });

    String unreadPrefix =
        widget.conversation.receiveOption == ReceiveMessageOpt.notNotify && widget.conversation.unreadCount >= 2
            ? '[${_formatUnreadCount(widget.conversation.unreadCount)} ${atomicLocale.messageNum}]'
            : '';

    // If there's @ mention, show with red color
    if (atPrefix.isNotEmpty) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: atPrefix,
              style: TextStyle(
                fontSize: 12,
                color: colorsTheme.textColorError,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (unreadPrefix.isNotEmpty)
              TextSpan(
                text: unreadPrefix,
                style: TextStyle(
                  fontSize: 12,
                  color: colorsTheme.textColorSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            TextSpan(
              text: replaceText,
              style: TextStyle(
                fontSize: 12,
                color: colorsTheme.textColorSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    String displayText = '$unreadPrefix$replaceText';

    return Text(
      displayText,
      style: TextStyle(
        fontSize: 12,
        color: colorsTheme.textColorSecondary,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build @ mention prefix based on groupAtInfoList
  String _buildAtMentionPrefix() {
    // Only show @ tag when unreadCount > 0 and is group chat
    if (widget.conversation.unreadCount <= 0) {
      return '';
    }

    // Check if it's a group chat
    if (!widget.conversation.conversationID.startsWith('group_')) {
      return '';
    }

    final atInfoList = widget.conversation.groupAtInfoList;
    if (atInfoList == null || atInfoList.isEmpty) {
      return '';
    }

    // Check for different @ types
    bool hasAtAll = false;
    bool hasAtMe = false;

    for (final atInfo in atInfoList) {
      switch (atInfo.atType) {
        case GroupAtType.atAll:
          hasAtAll = true;
          break;
        case GroupAtType.atMe:
          hasAtMe = true;
          break;
        case GroupAtType.atAllAtMe:
          hasAtAll = true;
          hasAtMe = true;
          break;
      }
    }

    // Build prefix based on @ types
    // Priority: @All + @Me shows both tags, @Me shows [@Me], @All shows [@All]
    if (hasAtAll && hasAtMe) {
      return '${atomicLocale.conversationListAtAll} ${atomicLocale.conversationListAtMe} ';
    } else if (hasAtMe) {
      return '${atomicLocale.conversationListAtMe} ';
    } else if (hasAtAll) {
      return '${atomicLocale.conversationListAtAll} ';
    }

    return '';
  }

  bool _hasMoreActions() {
    return widget.config.isSupportPin ||
        widget.config.isSupportClearHistory ||
        widget.config.isSupportDelete ||
        widget.customActions.isNotEmpty;
  }

  Future<void> _showMoreActions(BuildContext context, SemanticColorScheme colors) async {
    final actions = <ActionSheetItem>[];

    // Pin/Unpin action
    if (widget.config.isSupportPin) {
      actions.add(ActionSheetItem(
        title: widget.conversation.isPinned ? atomicLocale.unpin : atomicLocale.pin,
        onTap: () => widget.onPinToggle?.call(),
      ));
    }

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
    // Show red dot for muted conversations with unread status
    bool hasDot = false;
    if (widget.conversation.receiveOption == ReceiveMessageOpt.notNotify) {
      // Check both unreadCount and markList for unread status
      hasDot = widget.conversation.unreadCount > 0 ||
          widget.conversation.markList.any((mark) => mark == ConversationMarkType.unread);
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

    // For muted conversations (except meeting groups), show mute icon
    if (widget.conversation.receiveOption == ReceiveMessageOpt.notNotify &&
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
    }

    // Check for unread status: unreadCount > 0 OR marked as unread
    final bool hasUnreadMark = widget.conversation.markList.any((mark) => mark == ConversationMarkType.unread);

    if (widget.conversation.unreadCount > 0) {
      // Show real unread count
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
    } else if (hasUnreadMark) {
      // Show virtual badge with "1" when marked as unread but unreadCount is 0
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: colorsTheme.textColorError,
          borderRadius: BorderRadius.circular(8),
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Text(
          '1',
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

  /// Build error status icon (sendFail or violation) - shown to the left of time
  Widget _buildErrorStatusIcon(SemanticColorScheme colorsTheme) {
    final lastMessage = widget.conversation.lastMessage;
    if (lastMessage != null &&
        (lastMessage.status == MessageStatus.sendFail || lastMessage.status == MessageStatus.violation)) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: Icon(
          Icons.error,
          size: 16,
          color: colorsTheme.textColorError,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
