import 'dart:math' as math;

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tencent_chat_uikit/src/common/language/gen/chat_localizations.dart';
import 'package:tencent_chat_uikit/src/emoji_picker/emoji_picker_model.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/reaction_emoji_picker.dart';

/// Action grid layout. Five columns, kept wide enough that a four-character CJK
/// label stays on one line: at caption4 each glyph is as wide as the font size,
/// so a column needs ~43pt of text room once iOS applies its font scale.
/// ReactionEmojiPicker mirrors these paddings, since the two panels share one
/// tooltip that must not resize when they are swapped.
const int _columnCount = 5;
const double _maxPanelWidth = 240;
const double _panelVerticalPadding = 10;
const double _rowInset = 4;
const double _dividerInset = 12;

/// Breathing room between a row and the divider under or above it.
const double _dividerSpacing = 4;

class MessageMenuItem {
  final String title;
  final IconData? icon;
  final String? assetName;
  final String? package;
  final VoidCallback onTap;
  final bool isDestructive;

  const MessageMenuItem({
    required this.title,
    this.icon,
    this.assetName,
    this.package,
    required this.onTap,
    this.isDestructive = false,
  });
}

abstract class MessageMenuCallbacks {
  void onCopyMessage(MessageInfo message);

  void onDeleteMessage(MessageInfo message);

  void onRecallMessage(MessageInfo message);

  void onForwardMessage(MessageInfo message);

  void onQuoteMessage(MessageInfo message);

  void onMultiSelectMessage(MessageInfo message);

  void onResendMessage(MessageInfo message);
}

class MessageTooltip extends StatefulWidget {
  final List<MessageMenuItem> menuItems;
  final MessageInfo message;
  final VoidCallback onCloseTooltip;
  final bool isSelf;

  /// Whether the "post emojis" entry is offered alongside the action menu.
  final bool isSupportReaction;
  final void Function(EmojiPickerModelItem emoji)? onReactionSelected;

  const MessageTooltip({
    super.key,
    required this.menuItems,
    required this.message,
    required this.onCloseTooltip,
    required this.isSelf,
    this.isSupportReaction = false,
    this.onReactionSelected,
  });

  @override
  State<StatefulWidget> createState() => MessageTooltipState();
}

class MessageTooltipState extends State<MessageTooltip> {
  /// The tooltip shows either the action menu or the quick reaction panel.
  bool _showReactionPanel = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = BaseThemeProvider.colorsOf(context);

    // Background and corner radius are owned by the enclosing SuperTooltip;
    // painting them again here would cover its rounded corners. Padding is left
    // to the panels so both can share one spec.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: math.min(MediaQuery.of(context).size.width * 0.75, _maxPanelWidth),
      ),
      // An IndexedStack lays out both panels and sizes itself to their union,
      // so the tooltip keeps the same width and height across the switch.
      child: _canPostEmojis
          ? IndexedStack(
              alignment: Alignment.center,
              index: _showReactionPanel ? 1 : 0,
              children: [
                _buildMenu(colorTheme),
                _buildReactionPanel(),
              ],
            )
          : _buildMenu(colorTheme),
    );
  }

  Widget _buildMenu(SemanticColorScheme colorTheme) {
    final entries = <Widget>[
      ...widget.menuItems.map((item) => _buildMenuItem(item, colorTheme)),
      if (_canPostEmojis) _buildPostEmojisItem(colorTheme),
    ];

    final rows = <Widget>[];
    for (var start = 0; start < entries.length; start += _columnCount) {
      final end = math.min(start + _columnCount, entries.length);
      if (rows.isNotEmpty) {
        rows.add(_buildRowDivider(colorTheme));
      }
      rows.add(_buildMenuRow(entries.sublist(start, end)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _panelVerticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _buildMenuRow(List<Widget> entries) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _rowInset),
      // Equal columns, with trailing blanks so a short last row stays aligned
      // with the one above it.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries) Expanded(child: entry),
          for (var i = entries.length; i < _columnCount; i++)
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildRowDivider(SemanticColorScheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _dividerInset,
        vertical: _dividerSpacing,
      ),
      child: Container(
        height: 0.5,
        color: colorTheme.strokeColorSecondary,
      ),
    );
  }

  Widget _buildReactionPanel() {
    return ReactionEmojiPicker(
      onEmojiClick: (emoji) {
        widget.onCloseTooltip();
        widget.onReactionSelected!(emoji);
      },
      onCollapseClick: () => setState(() => _showReactionPanel = false),
      onExpandClick: () async {
        // Capture both before closing: this widget is unmounted along with the
        // tooltip overlay, so its context can no longer host the bottom sheet.
        final onReactionSelected = widget.onReactionSelected;
        final sheetContext = Navigator.of(context).context;
        widget.onCloseTooltip();
        final selectedEmoji = await ReactionEmojiPickerSheet.show(sheetContext);
        if (selectedEmoji != null) {
          onReactionSelected?.call(selectedEmoji);
        }
      },
    );
  }

  bool get _canPostEmojis => widget.isSupportReaction && widget.onReactionSelected != null;

  Widget _buildMenuItem(MessageMenuItem item, SemanticColorScheme colorTheme) {
    return _buildEntry(
      icon: _buildMenuIcon(item, colorTheme),
      title: item.title,
      color: item.isDestructive ? colorTheme.textColorError : colorTheme.textColorPrimary,
      onTap: () {
        widget.onCloseTooltip();
        item.onTap();
      },
    );
  }

  /// Unlike the other entries this one swaps the tooltip content instead of
  /// dismissing it.
  Widget _buildPostEmojisItem(SemanticColorScheme colorTheme) {
    return _buildEntry(
      icon: SvgPicture.asset(
        'chat_assets/icon/post_emojis.svg',
        package: 'tencent_chat_uikit',
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(colorTheme.textColorPrimary, BlendMode.srcIn),
      ),
      title: ChatLocalizations.of(context).postEmojis,
      color: colorTheme.textColorPrimary,
      onTap: () => setState(() => _showReactionPanel = true),
    );
  }

  Widget _buildEntry({
    required Widget icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        // The enclosing column already fixes the width, so horizontal padding
        // here would only eat into the label and wrap it.
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                title,
                style: FontScheme.caption4Regular.copyWith(
                  decoration: TextDecoration.none,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(MessageMenuItem item, SemanticColorScheme colorTheme) {
    // Derive the icon color from the theme (ThemeState) so it stays visible in
    // both light and dark modes; destructive actions (e.g. delete) use the
    // error color to match their label.
    final color = item.isDestructive ? colorTheme.textColorError : colorTheme.textColorPrimary;
    
    if (item.assetName != null && item.assetName!.isNotEmpty) {
      final isSvg = item.assetName!.toLowerCase().endsWith('.svg');
      
      if (isSvg) {
        return SvgPicture.asset(
          item.assetName!,
          package: item.package,
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          placeholderBuilder: (context) => Icon(
            item.icon,
            size: 16,
            color: color,
          ),
        );
      } else {
        return Image.asset(
          item.assetName!,
          package: item.package,
          width: 16,
          height: 16,
          color: color,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              item.icon,
              size: 16,
              color: color,
            );
          },
        );
      }
    }
    
    return Icon(
      item.icon,
      size: 18,
      color: color,
    );
  }
}
