import 'dart:math' as math;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/recent_emoji_manager.dart';
import '../../common/language/gen/chat_localizations.dart';

/// Reactions beyond this count are dropped rather than collapsed into a
/// "+N" chip — the detail sheet is the place to see the full list.
const int _maxDisplayReactions = 5;

const double _chipSpacing = 8;
const double _chipRunSpacing = 6;
const double _chipCornerRadius = 12;
const double _emojiSize = 16;
const double _dividerWidth = 1;
const double _dividerHeight = 14;
const double _labelMaxWidth = 120;
const double _chipMaxWidth = 180;

/// Chip fill and divider are tinted with the bubble's own text colour so they
/// stay legible against either bubble background. Alphas are 0-255 to keep the
/// values directly comparable with the Android implementation.
const double _selfChipFillAlpha = 24 / 255;
const double _otherChipFillAlpha = 16 / 255;
const double _selfChipDividerAlpha = 64 / 255;
const double _otherChipDividerAlpha = 32 / 255;

/// Reaction chips rendered at the bottom of a message bubble.
///
/// Each chip pairs the emoji with who reacted, e.g. "🙂 | Alice and 2 others",
/// and tapping any of them opens the full reaction detail sheet.
class MessageReactionBar extends StatelessWidget {
  final List<MessageReaction> reactionList;

  /// Drives both the tint palette and which edge the chips line up against.
  final bool isSelf;

  final VoidCallback onClick;

  const MessageReactionBar({
    super.key,
    required this.reactionList,
    required this.isSelf,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    if (reactionList.isEmpty) return const SizedBox.shrink();

    final colors = BaseThemeProvider.colorsOf(context);
    final baseColor = isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary;
    final labelColor = isSelf ? colors.textColorAntiPrimary : colors.textColorSecondary;

    return Wrap(
      spacing: _chipSpacing,
      runSpacing: _chipRunSpacing,
      alignment: isSelf ? WrapAlignment.end : WrapAlignment.start,
      children: reactionList
          .take(_maxDisplayReactions)
          .map((reaction) => _buildChip(context, reaction, baseColor, labelColor))
          .toList(),
    );
  }

  Widget _buildChip(
    BuildContext context,
    MessageReaction reaction,
    Color baseColor,
    Color labelColor,
  ) {
    final label = _buildLabel(context, reaction);

    return GestureDetector(
      onTap: onClick,
      child: Container(
        constraints: const BoxConstraints(maxWidth: _chipMaxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: baseColor.withValues(
            alpha: isSelf ? _selfChipFillAlpha : _otherChipFillAlpha,
          ),
          borderRadius: BorderRadius.circular(_chipCornerRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmoji(context, reaction),
            if (label != null) ...[
              const SizedBox(width: _chipSpacing / 2),
              Container(
                width: _dividerWidth,
                height: _dividerHeight,
                decoration: BoxDecoration(
                  color: baseColor.withValues(
                    alpha: isSelf ? _selfChipDividerAlpha : _otherChipDividerAlpha,
                  ),
                  borderRadius: BorderRadius.circular(_dividerWidth),
                ),
              ),
              const SizedBox(width: _chipSpacing / 2),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _labelMaxWidth),
                  child: Text(
                    label,
                    style: FontScheme.caption3Regular.copyWith(color: labelColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmoji(BuildContext context, MessageReaction reaction) {
    final colors = BaseThemeProvider.colorsOf(context);
    final emoji = RecentEmojiManager.getEmojiByReactionID(context, reaction.reactionID);
    final fallback = Icon(
      Icons.sentiment_satisfied_alt,
      size: _emojiSize,
      color: colors.textColorSecondary,
    );

    if (emoji == null) return fallback;
    return Image.asset(
      emoji.path,
      package: 'tencent_chat_uikit',
      width: _emojiSize,
      height: _emojiSize,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  /// Who reacted, as shown next to the emoji.
  ///
  /// Only the first user of [MessageReaction.partialUserList] is named; the
  /// rest are folded into a count. Falls back to the bare count when the
  /// profile hasn't been resolved yet, and to nothing at all when the reaction
  /// has no users (which shouldn't happen, but would otherwise render a lone
  /// divider).
  String? _buildLabel(BuildContext context, MessageReaction reaction) {
    final totalCount = reaction.totalUserCount;
    if (totalCount <= 0) return null;

    final firstUser = reaction.partialUserList.firstOrNull;
    final name = firstUser?.nickname?.trim().isNotEmpty == true
        ? firstUser!.nickname!.trim()
        : firstUser?.userID.trim();
    if (name == null || name.isEmpty) return '$totalCount';
    if (totalCount == 1) return name;

    return ChatLocalizations.of(context).reactionUserSummary(
      name,
      totalCount,
      math.max(totalCount - 1, 1),
    );
  }
}
