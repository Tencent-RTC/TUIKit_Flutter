import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/utils/recent_emoji_manager.dart';

/// Maximum number of reactions to display before showing "..."
const int _maxDisplayReactions = 5;

/// Bar displaying message reactions below the message bubble
class MessageReactionBar extends StatelessWidget {
  final List<MessageReaction> reactionList;
  final bool isLeft;
  final VoidCallback onClick;
  final void Function(MessageReaction reaction)? onReactionTap;

  const MessageReactionBar({
    super.key,
    required this.reactionList,
    required this.isLeft,
    required this.onClick,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactionList.isEmpty) return const SizedBox.shrink();

    final colors = BaseThemeProvider.colorsOf(context);
    final displayReactions = reactionList.take(_maxDisplayReactions).toList();
    final hasMore = reactionList.length > _maxDisplayReactions;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onClick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.bgColorBubbleReciprocal,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: colors.strokeColorPrimary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...displayReactions.map((reaction) => _ReactionItem(
                        reaction: reaction,
                        showCount: displayReactions.length == 1,
                        onTap: onReactionTap != null ? () => onReactionTap!(reaction) : null,
                      )),
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '...',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textColorTertiary,
                        ),
                      ),
                    ),
                  if (displayReactions.length > 1 || hasMore)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '${_getTotalCount()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textColorTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalCount() {
    return reactionList.fold(0, (sum, r) => sum + r.totalUserCount);
  }
}

class _ReactionItem extends StatelessWidget {
  final MessageReaction reaction;
  final bool showCount;
  final VoidCallback? onTap;

  const _ReactionItem({
    required this.reaction,
    required this.showCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final emoji = RecentEmojiManager.getEmojiByReactionID(context, reaction.reactionID);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Image.asset(
                emoji.path,
                package: 'tuikit_atomic_x',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sentiment_satisfied_alt,
                    size: 18,
                    color: colors.textColorSecondary,
                  );
                },
              )
            else
              Icon(
                Icons.sentiment_satisfied_alt,
                size: 18,
                color: colors.textColorSecondary,
              ),
            if (showCount && reaction.totalUserCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '${reaction.totalUserCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textColorTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
