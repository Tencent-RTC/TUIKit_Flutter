import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/utils/recent_emoji_manager.dart';

/// Bottom sheet showing reaction details with user list
class ReactionDetailSheet extends StatefulWidget {
  final List<MessageReaction> reactionList;
  final String? currentUserID;
  final void Function(String reactionID) onFetchUsers;
  final void Function(String reactionID) onRemoveReaction;
  final ScrollController? scrollController;
  /// Whether to allow removing reactions (default: true)
  /// Set to false in merged message detail view
  final bool allowRemove;

  const ReactionDetailSheet({
    super.key,
    required this.reactionList,
    this.currentUserID,
    required this.onFetchUsers,
    required this.onRemoveReaction,
    this.scrollController,
    this.allowRemove = true,
  });

  @override
  State<ReactionDetailSheet> createState() => _ReactionDetailSheetState();

  /// Show the reaction detail sheet
  static Future<void> show({
    required BuildContext context,
    required List<MessageReaction> reactionList,
    String? currentUserID,
    required void Function(String reactionID) onFetchUsers,
    required void Function(String reactionID) onRemoveReaction,
    bool allowRemove = true,
  }) {
    // Unfocus and clear primary focus to prevent keyboard from popping up when sheet closes
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GestureDetector(
        onTap: () {
          // Ensure focus is cleared before closing
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(sheetContext).pop();
        },
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) => ReactionDetailSheet(
              reactionList: reactionList,
              currentUserID: currentUserID,
              onFetchUsers: onFetchUsers,
              onRemoveReaction: onRemoveReaction,
              scrollController: scrollController,
              allowRemove: allowRemove,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionDetailSheetState extends State<ReactionDetailSheet> {
  String _selectedReactionID = '';

  @override
  void initState() {
    super.initState();
    if (widget.reactionList.isNotEmpty) {
      _selectedReactionID = widget.reactionList.first.reactionID;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFetchUsers(_selectedReactionID);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgColorOperate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.strokeColorPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Reaction tabs
          if (widget.reactionList.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _ReactionTabRow(
                  reactionList: widget.reactionList,
                  selectedReactionID: _selectedReactionID,
                  onTabSelected: (reactionID) {
                    setState(() {
                      _selectedReactionID = reactionID;
                    });
                    widget.onFetchUsers(reactionID);
                  },
                ),
              ),
            ),
          // User list
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final selectedReaction = widget.reactionList.firstWhere(
      (r) => r.reactionID == _selectedReactionID,
      orElse: () => MessageReaction(
        reactionID: '',
        totalUserCount: 0,
        partialUserList: [],
        reactedByMyself: false,
      ),
    );

    if (selectedReaction.reactionID.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ReactionUserList(
      reaction: selectedReaction,
      currentUserID: widget.currentUserID,
      onRemoveReaction: () => widget.onRemoveReaction(_selectedReactionID),
      scrollController: widget.scrollController,
      allowRemove: widget.allowRemove,
    );
  }
}

class _ReactionTabRow extends StatelessWidget {
  final List<MessageReaction> reactionList;
  final String selectedReactionID;
  final void Function(String reactionID) onTabSelected;

  const _ReactionTabRow({
    required this.reactionList,
    required this.selectedReactionID,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: reactionList.map((reaction) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ReactionTab(
              reaction: reaction,
              isSelected: reaction.reactionID == selectedReactionID,
              onTap: () => onTabSelected(reaction.reactionID),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReactionTab extends StatelessWidget {
  final MessageReaction reaction;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionTab({
    required this.reaction,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final emoji = RecentEmojiManager.getEmojiByReactionID(context, reaction.reactionID);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonColorPrimaryDefault.withOpacity(0.1)
              : colors.bgColorInput,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: colors.buttonColorPrimaryDefault, width: 1)
              : null,
        ),
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
            const SizedBox(width: 4),
            Text(
              '${reaction.totalUserCount}',
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? colors.buttonColorPrimaryDefault
                    : colors.textColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionUserList extends StatelessWidget {
  final MessageReaction reaction;
  final String? currentUserID;
  final VoidCallback onRemoveReaction;
  final ScrollController? scrollController;
  final bool allowRemove;

  const _ReactionUserList({
    required this.reaction,
    this.currentUserID,
    required this.onRemoveReaction,
    this.scrollController,
    this.allowRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    final sortedUsers = _getSortedUsers();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        final isSelf = user.userID == currentUserID && reaction.reactedByMyself;
        // Only allow tap to remove if allowRemove is true
        final canRemove = isSelf && allowRemove;

        return _ReactionUserItem(
          user: user,
          isSelf: canRemove,
          onTap: canRemove ? onRemoveReaction : null,
        );
      },
    );
  }

  List<UserProfile> _getSortedUsers() {
    final users = List<UserProfile>.from(reaction.partialUserList);

    // Move current user to the front if they reacted
    if (reaction.reactedByMyself && currentUserID != null) {
      final selfIndex = users.indexWhere((u) => u.userID == currentUserID);
      if (selfIndex > 0) {
        final selfUser = users.removeAt(selfIndex);
        users.insert(0, selfUser);
      }
    }

    return users;
  }
}

class _ReactionUserItem extends StatelessWidget {
  final UserProfile user;
  final bool isSelf;
  final VoidCallback? onTap;

  const _ReactionUserItem({
    required this.user,
    required this.isSelf,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final atomicLocal = AtomicLocalizations.of(context);
    final displayName = (user.nickname?.isNotEmpty == true) ? user.nickname! : user.userID;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Avatar(
              content: AvatarImageContent(
                url: user.avatarURL,
                name: displayName,
              ),
              size: AvatarSize.s,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textColorPrimary,
                    ),
                  ),
                  if (isSelf)
                    Text(
                      atomicLocal.tapToRemove,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textColorTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
