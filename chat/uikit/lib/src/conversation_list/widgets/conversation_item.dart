import 'package:atomic_x_core/atomicxcore.dart' hide CompletionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/common/utils/time_util.dart';
import 'package:tencent_chat_uikit/src/conversation_list/conversation_list.dart';
import 'package:tencent_chat_uikit/src/conversation_list/conversation_list_config.dart';
import 'package:tencent_chat_uikit/src/emoji_picker/emoji_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/third_party/flutter_swipe_action_cell/core/cell.dart';
import '../../common/language/gen/chat_localizations.dart';

const double _horizontalPadding = 14;
const double _avatarSpacing = 10;
const AvatarSize _avatarSize = AvatarSize.l;

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
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    chatLocale = ChatLocalizations.of(context);

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
        title: hasUnread ? chatLocale.markAsRead : chatLocale.markAsUnread,
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
          hasUnread ? 'chat_assets/icon/message_read_status.svg' : 'chat_assets/icon/message_unread_status.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(colorsTheme.textColorButton, BlendMode.srcIn),
          package: 'tencent_chat_uikit',
        ),
        style: FontScheme.caption3Regular.copyWith(
          color: colorsTheme.textColorButton,
        ),
      ));
    }

    if (_hasMoreActions()) {
      actions.add(SwipeAction(
        title: chatLocale.more,
        onTap: (CompletionHandler handler) async {
          await _showMoreActions(context, colorsTheme);
          handler(false);
        },
        color: colorsTheme.bgColorMask,
        icon: Icon(
          Icons.more_horiz,
          color: colorsTheme.textColorButton,
        ),
        style: FontScheme.caption3Regular.copyWith(
          color: colorsTheme.textColorButton,
        ),
      ));
    }

    return actions;
  }

  /// Returns true if the conversation has unread status (unreadCount > 0 or marked as unread).
  bool _hasUnreadStatus() {
    return widget.conversation.unreadCount > 0 ||
        widget.conversation.conversationMarkList.any((mark) => mark == ConversationMarkType.unread);
  }

  Widget _buildConversationContent(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    String formatTime = TimeUtil.convertToFormatTime(
      widget.conversation.lastMessage?.timestamp ?? 0,
      context,
      style: TimeFormatStyle.conversationList,
    );

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: widget.conversation.isPinned ? colorsTheme.bgColorDefault : colorsTheme.bgColorTopBar,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: _horizontalPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(context),
                  const SizedBox(width: _avatarSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.conversation.title ?? '',
                                style: FontScheme.body4Regular.copyWith(
                                  color: colorsTheme.textColorPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatTime,
                              style: FontScheme.caption3Regular.copyWith(
                                color: colorsTheme.textColorTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildErrorStatusIcon(colorsTheme),
                            Expanded(
                              child: _buildSubtitle(context, colorsTheme),
                            ),
                            _buildMuteIcon(colorsTheme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildDivider(colorsTheme),
          ],
        ),
      ),
    );
  }

  /// Separator between items: starts at the title (aligned past the avatar) and
  /// runs to the right edge.
  Widget _buildDivider(SemanticColorScheme colorsTheme) {
    return Padding(
      padding: EdgeInsets.only(
        left: _horizontalPadding + _avatarSize.value + _avatarSpacing,
      ),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: colorsTheme.strokeColorPrimary,
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
      if (widget.conversation.receiveOption == ReceiveMessageOption.notNotify && widget.conversation.unreadCount >= 2) {
        unreadPrefix = '[${_formatUnreadCount(widget.conversation.unreadCount)} ${chatLocale.messageNum}]';
      }

      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            if (atPrefix.isNotEmpty)
              TextSpan(
                text: atPrefix,
                style: FontScheme.caption2Regular.copyWith(
                  color: colorsTheme.textColorError,
                ),
              ),
            if (unreadPrefix.isNotEmpty)
              TextSpan(
                text: unreadPrefix,
                style: FontScheme.caption2Regular.copyWith(
                  color: colorsTheme.textColorTertiary,
                ),
              ),
            TextSpan(
              text: chatLocale.draft,
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorError,
              ),
            ),
            TextSpan(
              text: ' $localizedDraft',
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorTertiary,
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
        widget.conversation.receiveOption == ReceiveMessageOption.notNotify && widget.conversation.unreadCount >= 2
            ? '[${_formatUnreadCount(widget.conversation.unreadCount)} ${chatLocale.messageNum}]'
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
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorError,
              ),
            ),
            if (unreadPrefix.isNotEmpty)
              TextSpan(
                text: unreadPrefix,
                style: FontScheme.caption2Regular.copyWith(
                  color: colorsTheme.textColorTertiary,
                ),
              ),
            TextSpan(
              text: replaceText,
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorTertiary,
              ),
            ),
          ],
        ),
      );
    }

    String displayText = '$unreadPrefix$replaceText';

    return Text(
      displayText,
      style: FontScheme.caption2Regular.copyWith(
        color: colorsTheme.textColorTertiary,
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
      return '${chatLocale.conversationListAtAll} ${chatLocale.conversationListAtMe} ';
    } else if (hasAtMe) {
      return '${chatLocale.conversationListAtMe} ';
    } else if (hasAtAll) {
      return '${chatLocale.conversationListAtAll} ';
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
        title: widget.conversation.isPinned ? chatLocale.unpin : chatLocale.pin,
        onTap: () => widget.onPinToggle?.call(),
      ));
    }

    if (widget.config.isSupportClearHistory) {
      actions.add(ActionSheetItem(
        title: chatLocale.clearMessage,
        onTap: () => widget.onClearHistory?.call(),
      ));
    }

    if (widget.config.isSupportDelete) {
      actions.add(ActionSheetItem(
        title: chatLocale.delete,
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
    final bool isMuted = widget.conversation.receiveOption == ReceiveMessageOption.notNotify;
    final bool hasUnreadMark = widget.conversation.conversationMarkList
        .any((mark) => mark == ConversationMarkType.unread);
    final int unreadCount = widget.conversation.unreadCount;
    final bool hasUnread = unreadCount > 0 || hasUnreadMark;

    AvatarBadge badge;
    if (!hasUnread) {
      badge = const NoBadge();
    } else if (isMuted) {
      badge = const DotBadge();
    } else if (unreadCount > 0) {
      badge = CountBadge(unreadCount);
    } else {
      badge = const CountBadge(1);
    }

    return Avatar.image(
      name: _getAvatarText(),
      url: widget.conversation.avatarURL!,
      badge: badge,
      size: _avatarSize,
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

  /// Build mute icon shown on the right side of the subtitle when the
  /// conversation is muted (excluding meeting groups).
  Widget _buildMuteIcon(SemanticColorScheme colorsTheme) {
    if (widget.conversation.receiveOption == ReceiveMessageOption.notNotify &&
        widget.conversation.groupType != GroupType.meeting) {
      return Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: SvgPicture.asset(
          'chat_assets/icon/ic_mute.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(colorsTheme.textColorDisable, BlendMode.srcIn),
          package: 'tencent_chat_uikit',
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Build error status icon (sendFail or violation) - shown to the left of the subtitle text
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
