/// Living 底部工具栏：PK、连麦、翻转镜头、背景音乐与更多入口。
library;

import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../common/live_kit_resources.dart';
import '../../common/theme/live_theme.dart';

class LiveBottomToolbarView extends StatelessWidget {
  const LiveBottomToolbarView({
    super.key,
    this.onPK,
    this.onFlipCamera,
    this.onShowBackgroundMusic,
    this.onCoGuest,
    this.onMore,
    this.moreActionKey,
    this.hasCoGuestUnread = false,
    this.isCoGuestStageActive = false,
  });

  final VoidCallback? onPK;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onShowBackgroundMusic;
  final VoidCallback? onCoGuest;

  final VoidCallback? onMore;

  /// 点赞辅助动画的起点取自"更多"入口。
  final GlobalKey? moreActionKey;

  /// 有未读连麦申请时显示带提示的完整连麦图标。
  final bool hasCoGuestUnread;

  /// 连麦舞台可见时工具栏底色透明。
  final bool isCoGuestStageActive;

  /// UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1)
  static const Color _backgroundColor = Color(0xFF0A0A0F);

  @override
  Widget build(BuildContext context) {
    final titles = <String>[
      LiveKitResources.localizedString('tuilivekit.pusher.living.pk'),
      LiveKitResources.localizedString('tuilivekit.pusher.living.coguest'),
      LiveKitResources.localizedString('tuilivekit.pusher.flip_camera'),
      LiveKitResources.localizedString('tuilivekit.pusher.living.music'),
      LiveKitResources.localizedString('tuilivekit.common.more'),
    ];
    final assets = <String>[
      'livekit_living_pk',
      hasCoGuestUnread ? 'livekit_living_coguest_unread' : 'livekit_living_coguest',
      'livekit_living_setting_flip',
      'livekit_living_setting_music',
      'livekit_living_more',
    ];
    final callbacks = <VoidCallback?>[onPK, onCoGuest, onFlipCamera, onShowBackgroundMusic, onMore];
    final style = LiveTheme.textStyle(LiveTextRole.control, tone: LiveTextTone.secondary);
    final textWidths = titles.map((title) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }).toList();
    return ColoredBox(
      color: isCoGuestStageActive ? const Color(0x00000000) : _backgroundColor,
      child: LayoutBuilder(builder: (context, constraints) {
        // Preserve intrinsic label widths, shrinking only the extra space on narrow windows.
        final preferred = textWidths.map((width) => math.max(34.0, width.ceilToDouble())).toList();
        final extra = preferred.fold<double>(0, (sum, width) => sum + width - 34);
        final ratio = extra == 0 ? 1.0 : ((constraints.maxWidth - 80 - 5 * 34) / extra).clamp(0.0, 1.0);
        final widths = preferred.map((width) => 34 + (width - 34) * ratio).toList();
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12, top: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              for (var i = 0; i < 5; i++) ...<Widget>[
                if (i == 1) const SizedBox(width: 14),
                if (i == 2) ...<Widget>[const SizedBox(width: 12), const Spacer()],
                if (i > 2) const SizedBox(width: 12),
                _LivingActionControl(
                  key: i == 4 ? moreActionKey : null,
                  title: titles[i],
                  assetName: assets[i],
                  width: widths[i],
                  labelScale: textWidths[i] > 0 ? (widths[i] / textWidths[i]).clamp(0.75, 1.0) : 1,
                  iconSize: i < 2
                      ? const Size(46, 38)
                      : i < 4
                          ? const Size(22, 22)
                          : const Size(27, 27),
                  iconTop: i < 2
                      ? -6
                      : i < 4
                          ? 2.5
                          : 0,
                  onPressed: callbacks[i],
                ),
              ],
            ]),
          ),
        );
      }),
    );
  }
}

class _LivingActionControl extends StatelessWidget {
  const _LivingActionControl({
    super.key,
    required this.title,
    required this.assetName,
    required this.iconSize,
    required this.width,
    required this.labelScale,
    this.iconTop = 0,
    this.onPressed,
  });

  final String title;
  final String assetName;
  final Size iconSize;
  final double width;
  final double labelScale;
  final double iconTop;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              top: iconTop,
              left: (width - iconSize.width) / 2,
              width: iconSize.width,
              height: iconSize.height,
              child: Image(
                image: LiveKitResources.image(assetName),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 30,
              height: 16,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LiveTheme.textStyle(LiveTextRole.control, tone: LiveTextTone.secondary).copyWith(
                  fontSize: 11 * labelScale,
                  shadows: const <Shadow>[
                    Shadow(
                      color: Color(0x59000000),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
