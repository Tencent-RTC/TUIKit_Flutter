import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/common/language/gen/chat_localizations.dart';
import 'package:tencent_chat_uikit/src/emoji_picker/emoji_picker_model.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/recent_emoji_manager.dart';

const int _columnCount = 6;
const int _rowCount = 2;
const double _cellSize = 32;
const double _emojiSize = 26;

/// Paddings mirror the action menu in MessageTooltip: both panels share one
/// tooltip that must not resize when they are swapped.
const double _panelVerticalPadding = 10;
const double _rowInset = 10;
const double _dividerInset = 12;
const double _dividerSpacing = 4;
const double _headerSpacing = 6;

/// Emojis sit centred in their cell, so the header needs that slack for the
/// title to line up with the first emoji and the collapse button with the last.
/// A round emoji also reads as starting further in than its box does, since it
/// only reaches that box at its own mid-height, hence the optical nudge on top.
const double _headerOpticalNudge = 2;
const double _headerInset = _rowInset + (_cellSize - _emojiSize) / 2 + _headerOpticalNudge;

/// Emoji slots in the quick panel; the trailing cell belongs to the expand button.
const int quickReactionEmojiCount = _columnCount * _rowCount - 1;

/// Quick reaction panel shown inside the message tooltip: a title row with a
/// collapse button, then two rows of emojis ending with the expand button.
class ReactionEmojiPicker extends StatefulWidget {
  final void Function(EmojiPickerModelItem emoji) onEmojiClick;

  /// Opens the full emoji list in a bottom sheet.
  final VoidCallback onExpandClick;

  /// Returns to the message action menu.
  final VoidCallback onCollapseClick;

  const ReactionEmojiPicker({
    super.key,
    required this.onEmojiClick,
    required this.onExpandClick,
    required this.onCollapseClick,
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

  Future<void> _loadQuickEmojis() async {
    final emojis = await RecentEmojiManager.getQuickEmojis(
      context,
      count: quickReactionEmojiCount,
    );
    if (mounted) {
      setState(() {
        _quickEmojis = emojis;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _panelVerticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(colors),
          const SizedBox(height: _headerSpacing),
          ..._buildEmojiRows(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(SemanticColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _headerInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ChatLocalizations.of(context).postEmojis,
            style: FontScheme.caption4Regular.copyWith(
              decoration: TextDecoration.none,
              color: colors.textColorPrimary,
            ),
          ),
          GestureDetector(
            onTap: widget.onCollapseClick,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: SvgPicture.asset(
                'chat_assets/icon/post_emojis_back.svg',
                package: 'tencent_chat_uikit',
                width: 12,
                height: 12,
                colorFilter: ColorFilter.mode(colors.textColorPrimary, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps the panel a fixed [_rowCount] x [_columnCount] grid so its height
  /// doesn't jump once the recent emojis finish loading.
  List<Widget> _buildEmojiRows(SemanticColorScheme colors) {
    final cells = <Widget>[
      for (final emoji in _quickEmojis.take(quickReactionEmojiCount))
        _ReactionEmojiItem(
          emoji: emoji,
          onTap: () => widget.onEmojiClick(emoji),
        ),
    ];
    while (cells.length < quickReactionEmojiCount) {
      cells.add(const SizedBox(width: _cellSize, height: _cellSize));
    }
    cells.add(_buildExpandButton(colors));

    final rows = <Widget>[];
    for (var start = 0; start < cells.length; start += _columnCount) {
      final rowCells = cells.sublist(start, start + _columnCount);
      if (rows.isNotEmpty) {
        rows.add(_buildRowDivider(colors));
      }
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: _rowInset),
        // Spreading fixed-width cells keeps the outer columns flush with the
        // panel's content inset, so they line up with the header above.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowCells,
        ),
      ));
    }
    return rows;
  }

  Widget _buildRowDivider(SemanticColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _dividerInset,
        vertical: _dividerSpacing,
      ),
      child: Container(
        height: 0.5,
        color: colors.strokeColorSecondary,
      ),
    );
  }

  Widget _buildExpandButton(SemanticColorScheme colors) {
    return GestureDetector(
      onTap: widget.onExpandClick,
      child: SizedBox(
        width: _cellSize,
        height: _cellSize,
        child: Icon(
          Icons.more_horiz,
          size: 20,
          color: colors.textColorSecondary,
        ),
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
      child: SizedBox(
        width: _cellSize,
        height: _cellSize,
        child: Center(
          child: Image.asset(
            emoji.path,
            package: 'tencent_chat_uikit',
            width: _emojiSize,
            height: _emojiSize,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.sentiment_satisfied_alt,
                size: _emojiSize,
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
class ReactionEmojiPickerSheet extends StatefulWidget {
  final void Function(EmojiPickerModelItem emoji) onEmojiClick;
  final ScrollController? scrollController;

  const ReactionEmojiPickerSheet({
    super.key,
    required this.onEmojiClick,
    this.scrollController,
  });

  @override
  State<ReactionEmojiPickerSheet> createState() => _ReactionEmojiPickerSheetState();

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
              scrollController: scrollController,
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

class _ReactionEmojiPickerSheetState extends State<ReactionEmojiPickerSheet> {
  List<EmojiPickerModelItem> _recentEmojis = [];
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      _isLoaded = true;
      _loadRecentEmojis();
    }
  }

  Future<void> _loadRecentEmojis() async {
    final ids = await RecentEmojiManager.getRecentEmojiIds();
    if (!mounted) return;
    final emojis = <EmojiPickerModelItem>[];
    for (final id in ids) {
      final emoji = RecentEmojiManager.getEmojiByReactionID(context, id);
      if (emoji != null) {
        emojis.add(emoji);
      }
    }
    setState(() {
      _recentEmojis = emojis;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final chatLocal = ChatLocalizations.of(context);
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
          Expanded(
            child: CustomScrollView(
              controller: widget.scrollController,
              slivers: [
                // Section titles only earn their place once there are two
                // sections to tell apart.
                if (_recentEmojis.isNotEmpty) ...[
                  _buildSectionTitle(chatLocal.recentlyUsed, colors),
                  _buildEmojiGrid(_recentEmojis, colors),
                  _buildSectionTitle(chatLocal.allEmojis, colors),
                ],
                _buildEmojiGrid(
                  allEmojis,
                  colors,
                  // Without a section title above, the grid needs its own
                  // breathing room below the drag handle.
                  topPadding: _recentEmojis.isEmpty ? 16 : 0,
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, SemanticColorScheme colors) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: FontScheme.caption2Regular.copyWith(
            color: colors.textColorSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiGrid(
    List<EmojiPickerModelItem> emojis,
    SemanticColorScheme colors, {
    double topPadding = 0,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          childCount: emojis.length,
          (context, index) {
            final emoji = emojis[index];
            return GestureDetector(
              onTap: () => widget.onEmojiClick(emoji),
              child: Image.asset(
                emoji.path,
                package: 'tencent_chat_uikit',
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
    );
  }

}
