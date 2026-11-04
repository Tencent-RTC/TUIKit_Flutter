import 'pusher_coguest_settings_view.dart';
import 'package:flutter/widgets.dart';

import '../../../../common/live_image_loader.dart';
import '../../../../common/live_kit_resources.dart';
import '../../../../common/theme/live_text.dart';
import '../../../../common/theme/live_theme.dart';
import '../pusher_coguest_store.dart';

enum PusherCoGuestActionStyle { primary, destructive }

class PusherCoGuestRow {
  const PusherCoGuestRow({
    required this.user,
    required this.actionTitle,
    required this.actionStyle,
    required this.isPending,
    required this.isEnabled,
  });

  final PusherCoGuestUser user;
  final String actionTitle;
  final PusherCoGuestActionStyle actionStyle;
  final bool isPending;
  final bool isEnabled;

  @override
  bool operator ==(Object other) =>
      other is PusherCoGuestRow &&
      user.userID == other.user.userID &&
      user.userName == other.user.userName &&
      user.avatarURL == other.user.avatarURL &&
      actionTitle == other.actionTitle &&
      actionStyle == other.actionStyle &&
      isPending == other.isPending &&
      isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      Object.hash(user.userID, user.userName, user.avatarURL, actionTitle, actionStyle, isPending, isEnabled);
}

class PusherCoGuestUserSectionView extends StatefulWidget {
  const PusherCoGuestUserSectionView({
    super.key,
    required this.title,
    required this.emptyText,
    required this.rows,
    required this.onAction,
    this.showsCount = false,
  });

  final String title;
  final String emptyText;
  final List<PusherCoGuestRow> rows;
  final void Function(String userID) onAction;
  final bool showsCount;

  static const double titleTop = 16;
  static const double separatorTop = 43;
  static const double rowsTop = 50;
  static const double rowHeight = 52;
  static const double bottomInset = 16;
  static const double emptyHeight = 152;

  static double preferredHeightOf(List<PusherCoGuestRow> rows) {
    return rows.isEmpty ? emptyHeight : rowsTop + rows.length * rowHeight + bottomInset;
  }

  @override
  State<PusherCoGuestUserSectionView> createState() => _PusherCoGuestUserSectionState();
}

class _PusherCoGuestUserSectionState extends State<PusherCoGuestUserSectionView> {
  final Map<String, (PusherCoGuestRow, Widget)> _rowViews = {};

  Widget _rowView(PusherCoGuestRow row) {
    final id = row.user.userID;
    final previous = _rowViews[id];
    if (previous != null && previous.$1 == row) return previous.$2;
    final view = SizedBox(
      key: ValueKey(id),
      height: PusherCoGuestUserSectionView.rowHeight,
      child: _PusherCoGuestUserRowView(row: row, onAction: () => widget.onAction(id)),
    );
    _rowViews[id] = (row, view);
    return view;
  }

  @override
  Widget build(BuildContext context) {
    _rowViews.removeWhere((id, _) => !widget.rows.any((row) => row.user.userID == id));
    final rows = widget.rows;
    final String displayTitle = widget.showsCount && rows.isNotEmpty ? '${widget.title}（${rows.length}）' : widget.title;

    return ClipRRect(
      borderRadius: BorderRadius.circular(PusherCoGuestGroupStyle.cornerRadius),
      child: ColoredBox(
        // UIColor.black.withAlphaComponent(0.278)
        color: PusherCoGuestGroupStyle.background,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 16,
              right: 16,
              top: PusherCoGuestUserSectionView.titleTop,
              height: 15,
              child: LiveText(LiveTextRole.sectionTitle, text: displayTitle, tone: LiveTextTone.secondary),
            ),
            if (rows.isEmpty)
              Positioned(
                left: 16,
                right: 16,
                top: 79,
                height: 18,
                child: LiveText(LiveTextRole.body,
                    text: widget.emptyText, tone: LiveTextTone.secondary, alignment: TextAlign.center),
              )
            else ...<Widget>[
              const Positioned(
                left: 16,
                right: 16,
                top: PusherCoGuestUserSectionView.separatorTop,
                height: 1,
                child: ColoredBox(
                  // UIColor.white.withAlphaComponent(0.07)
                  color: _PusherCoGuestMemberStyle.separator,
                  child: SizedBox.expand(),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: PusherCoGuestUserSectionView.rowsTop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final PusherCoGuestRow row in rows) _rowView(row),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PusherCoGuestUserRowView extends StatelessWidget {
  const _PusherCoGuestUserRowView({required this.row, required this.onAction});

  final PusherCoGuestRow row;
  final VoidCallback onAction;

  /// 与 `PusherAudienceListView` 一致：URL 非法或加载失败回落默认头像。
  Widget _buildAvatar(String avatarURL) {
    const Widget placeholder = Image(
      image: AssetImage('assets/livekit_livelist_default_avatar.png', package: LiveKitResources.packageName),
      fit: BoxFit.cover,
    );
    final ImageProvider? provider = LiveImageLoader.provider(avatarURL);
    if (provider == null) {
      return placeholder;
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, loaded) => loaded || frame != null ? child : placeholder,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = row.isEnabled && !row.isPending;
    final Color backgroundColor;
    final Color borderColor;
    final Color titleColor;
    switch (row.actionStyle) {
      case PusherCoGuestActionStyle.primary:
        backgroundColor = _PusherCoGuestMemberStyle.primaryBackground;
        borderColor = _PusherCoGuestMemberStyle.primaryBorder;
        titleColor = const Color(0xFFFFFFFF);
      case PusherCoGuestActionStyle.destructive:
        backgroundColor = _PusherCoGuestMemberStyle.dangerBackground;
        borderColor = _PusherCoGuestMemberStyle.dangerBorder;
        titleColor = _PusherCoGuestMemberStyle.dangerForeground;
    }

    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            // UIColor(red: 0.29, green: 0.62, blue: 1, alpha: 0.22)
            border: Border.all(color: _PusherCoGuestMemberStyle.avatarBorder),
          ),
          child: ClipOval(child: _buildAvatar(row.user.avatarURL)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LiveText(LiveTextRole.itemTitle, text: row.user.userName, tone: LiveTextTone.secondary),
        ),
        const SizedBox(width: 10),
        Opacity(
          opacity: isEnabled ? 1 : 0.46,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isEnabled ? onAction : null,
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 68),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  row.isPending ? LiveKitResources.localizedString('tuilivekit.common.processing') : row.actionTitle,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class _PusherCoGuestMemberStyle {
  static const separator = Color(0x12FFFFFF);
  static const avatarBorder = Color(0x384A9EFF);
  static const primaryBackground = Color(0x64226ADE);
  static const primaryBorder = Color(0x5669AEFF);
  static const dangerBackground = Color(0x1AFF4F57);
  static const dangerBorder = Color(0x38FF4F57);
  static const dangerForeground = Color(0xFFFF7076);
}
