import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_picker_model.dart';
import 'package:tuikit_atomic_x/message_list/utils/recent_emoji_manager.dart';

/// Quick emoji picker for message reactions (6 emojis + expand button)
class ReactionEmojiPicker extends StatefulWidget {
  final void Function(EmojiPickerModelItem emoji) onEmojiClick;
  final VoidCallback onExpandClick;

  const ReactionEmojiPicker({
    super.key,
    required this.onEmojiClick,
    required this.onExpandClick,
  });

  @override
  State<ReactionEmojiPicker> createState() => _ReactionEmojiPickerState();
}

class _ReactionEmojiPickerState extends State<ReactionEmojiPicker> {
  List<EmojiPickerModelItem> _quickEmojis = [];
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      _isLoaded = true;
      _loadQuickEmojis();
    }
  }

  void _loadQuickEmojis() {
    setState(() {
      _quickEmojis = RecentEmojiManager.getQuickEmojis(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgColorOperate,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._quickEmojis.map((emoji) => _ReactionEmojiItem(
                emoji: emoji,
                onTap: () => widget.onEmojiClick(emoji),
              )),
          // "+" expand button
          GestureDetector(
            onTap: widget.onExpandClick,
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: colors.dropdownColorDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: colors.textColorSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionEmojiItem extends StatelessWidget {
  final EmojiPickerModelItem emoji;
  final VoidCallback onTap;

  const _ReactionEmojiItem({
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: colors.dropdownColorDefault,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Image.asset(
            emoji.path,
            package: 'tuikit_atomic_x',
            width: 22,
            height: 22,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.sentiment_satisfied_alt,
                size: 22,
                color: colors.textColorSecondary,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Full emoji picker sheet for reactions
class ReactionEmojiPickerSheet extends StatelessWidget {
  final void Function(EmojiPickerModelItem emoji) onEmojiClick;

  const ReactionEmojiPickerSheet({
    super.key,
    required this.onEmojiClick,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final allEmojis = RecentEmojiManager.getAllEmojis(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgColorOperate,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: allEmojis.length,
              itemBuilder: (context, index) {
                final emoji = allEmojis[index];
                return GestureDetector(
                  onTap: () => onEmojiClick(emoji),
                  child: Image.asset(
                    emoji.path,
                    package: 'tuikit_atomic_x',
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.sentiment_satisfied_alt,
                        color: colors.textColorSecondary,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show the full emoji picker as a bottom sheet
  static Future<EmojiPickerModelItem?> show(BuildContext context) {
    // Unfocus and clear primary focus to prevent keyboard from popping up when sheet closes
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    return showModalBottomSheet<EmojiPickerModelItem>(
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
            maxChildSize: 0.6,
            builder: (context, scrollController) => ReactionEmojiPickerSheet(
              onEmojiClick: (emoji) {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(sheetContext).pop(emoji);
              },
            ),
          ),
        ),
      ),
    );
  }
}
