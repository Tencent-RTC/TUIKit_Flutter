import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../../common/theme/level_badge_view.dart';
import '../../../common/live_image_loader.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import '../../../common/theme/live_text.dart';
import '../../../common/theme/live_theme.dart';
import 'pusher_audience_store.dart';

class PusherAudienceListView extends StatefulWidget {
  const PusherAudienceListView({
    super.key,
    required this.audience,
    required this.onDismiss,
    required this.onSelectAudience,
  });

  final List<AudienceUser> audience;

  /// 抽屉关闭。
  final VoidCallback onDismiss;
  final void Function(AudienceUser user) onSelectAudience;

  @override
  State<PusherAudienceListView> createState() => _PusherAudienceListViewState();
}

class _PusherAudienceListViewState extends State<PusherAudienceListView> {
  static const double _sheetHeight = 422;
  final BottomSheetController _sheetController = BottomSheetController();

  AudienceUser? _selectedAudience;

  void _selectAudience(AudienceUser user) {
    if (_selectedAudience != null) return;
    _selectedAudience = user;
    _sheetController.dismiss();
  }

  void _onDismiss() {
    final selected = _selectedAudience;
    _selectedAudience = null;
    final onSelect = widget.onSelectAudience;
    widget.onDismiss();
    if (selected != null) onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    final List<AudienceUser> displayedAudience = widget.audience;

    final rankStyle = LiveTheme.textStyle(LiveTextRole.listTitle);
    double widestDigit = 0;
    for (var digit = 0; digit < 10; digit++) {
      final painter = TextPainter(
          text: TextSpan(text: '$digit', style: rankStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context))
        ..layout();
      widestDigit = math.max(widestDigit, painter.width);
      painter.dispose();
    }
    final rankWidth = math.max(12.0, (widestDigit * displayedAudience.length.toString().length).ceilToDouble());

    return BottomSheetView(
      sheetHeight: _sheetHeight,
      controller: _sheetController,
      onDismiss: _onDismiss,
      sheetTitle: LiveKitResources.localizedString('tuilivekit.player.online_audience'),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 16,
            right: 16,
            top: 58,
            bottom: 24,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemExtent: 64,
              itemCount: displayedAudience.length,
              itemBuilder: (BuildContext context, int index) {
                return _AudienceListCell(
                  rank: index + 1,
                  rankWidth: rankWidth,
                  user: displayedAudience[index],
                  onTap: () => _selectAudience(displayedAudience[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceListCell extends StatelessWidget {
  const _AudienceListCell({
    required this.rank,
    required this.rankWidth,
    required this.user,
    required this.onTap,
  });

  final int rank;
  final double rankWidth;
  final AudienceUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: LiveAudienceRowStyle.edgeInset,
              top: 0,
              bottom: 0,
              width: rankWidth,
              child: Center(
                child: LiveText(LiveTextRole.listTitle,
                    text: '$rank', tone: LiveTextTone.disabled, alignment: TextAlign.center),
              ),
            ),
            Positioned(
              left: LiveAudienceRowStyle.avatarLeading + rankWidth - 12,
              top: LiveAudienceRowStyle.avatarTop,
              width: LiveAudienceRowStyle.avatarSize,
              height: LiveAudienceRowStyle.avatarSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LiveAudienceRowStyle.avatarRadius),
                child: _buildAvatar(),
              ),
            ),
            Positioned(
              left: LiveAudienceRowStyle.nameLeading + rankWidth - 12,
              right: 10 + 38 + 12,
              top: 0,
              bottom: 0,
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: LiveText(LiveTextRole.listTitle,
                        text: user.userName.isEmpty ? user.userID : user.userName, tone: LiveTextTone.secondary),
                  ),
                  const SizedBox(width: 8),
                  LevelBadgeView(level: user.level),
                ],
              ),
            ),
            const Positioned(
              right: LiveAudienceRowStyle.edgeInset,
              top: 0,
              bottom: 0,
              width: LiveAudienceRowStyle.giftValueWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '0',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: LiveTheme.audienceGiftValue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              left: LiveAudienceRowStyle.edgeInset,
              right: LiveAudienceRowStyle.edgeInset,
              bottom: 0,
              height: 1 / MediaQuery.of(context).devicePixelRatio,
              child: const ColoredBox(
                color: LiveAudienceRowStyle.separator,
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final Widget placeholder = Image(
      image: LiveKitResources.image('livekit_livelist_default_avatar'),
      fit: BoxFit.cover,
    );
    final ImageProvider? provider = LiveImageLoader.provider(user.avatarURL);
    if (provider == null) {
      return placeholder;
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return placeholder;
      },
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder,
    );
  }
}
