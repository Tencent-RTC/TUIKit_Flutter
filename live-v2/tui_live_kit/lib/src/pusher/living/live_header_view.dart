/// Living 顶部信息：主播胶囊（头像、昵称、本场点赞、粉丝团）、观众胶囊、
/// 关闭入口、直播时长与状态触发。
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../common/live_image_loader.dart';
import '../../common/live_kit_resources.dart';
import 'audience/pusher_audience_store.dart';
import '../../common/theme/live_theme.dart';
import 'audience/live_audience_presence_view.dart';

class LiveHeaderView extends StatefulWidget {
  const LiveHeaderView({
    super.key,
    required this.hostName,
    required this.hostAvatarURL,
    required this.elapsedSeconds,
    required this.likeCount,
    required this.audience,
    required this.viewerCount,
    required this.networkQuality,
    this.onClose,
    this.onAudience,
    this.onStatus,
  });

  final String hostName;
  final String hostAvatarURL;
  final int elapsedSeconds;
  final int likeCount;
  final List<AudienceUser> audience;
  final int viewerCount;
  final int networkQuality;

  final VoidCallback? onClose;

  final VoidCallback? onAudience;

  final VoidCallback? onStatus;

  /// UIColor(red: 0.039, green: 0.047, blue: 0.071, alpha: 0.22)
  static const Color _darkCapsuleColor = LiveVideoOverlayStyle.capsuleBackground;

  /// UIColor.white.withAlphaComponent(0.06)
  static const Color _hostBorderColor = _LiveHeaderStyle.border;

  /// UIColor.white.withAlphaComponent(0.08)
  static const Color _darkCapsuleBorderColor = Color(0x14FFFFFF);

  /// UIColor.white.withAlphaComponent(0.68)
  static const Color _likeTextColor = Color(0xADFFFFFF);

  static String formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = (seconds % 3600 ~/ 60).toString().padLeft(2, '0');
    final second = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$second';
  }

  @override
  State<LiveHeaderView> createState() => _LiveHeaderViewState();
}

class _LiveHeaderViewState extends State<LiveHeaderView> {
  Widget? _topRow;
  Widget? _hostCapsule;
  Widget? _hostName;
  Widget? _likeCount;
  Widget? _avatar;
  Widget? _audience;
  Widget? _close;
  Widget? _network;
  Widget? _status;
  late final Widget _fan = Image(
    image: LiveKitResources.image('livekit_living_fan'),
    fit: BoxFit.contain,
  );
  List<String> _audienceURLs = const [];
  double _networkWidth = 0;
  String _networkTitle = '';

  @override
  void didUpdateWidget(LiveHeaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsedSeconds != widget.elapsedSeconds) _status = null;
    if (oldWidget.hostName != widget.hostName) _hostName = null;
    if (oldWidget.likeCount != widget.likeCount) _likeCount = null;
    if (oldWidget.hostAvatarURL != widget.hostAvatarURL) _avatar = null;
    if (_hostName == null || _likeCount == null || _avatar == null) {
      _hostCapsule = null;
      _topRow = null;
    }
    final urls = widget.viewerCount > 0 ? widget.audience.take(3).map((user) => user.avatarURL).toList() : <String>[];
    if (oldWidget.viewerCount != widget.viewerCount ||
        !listEquals(_audienceURLs, urls) ||
        (oldWidget.onAudience == null) != (widget.onAudience == null)) {
      _audience = null;
      _topRow = null;
    }
    if ((oldWidget.onClose == null) != (widget.onClose == null)) {
      _close = null;
      _topRow = null;
    }
    if (_NetworkStatusPresentation.fromQuality(oldWidget.networkQuality) !=
            _NetworkStatusPresentation.fromQuality(widget.networkQuality) ||
        (oldWidget.onStatus == null) != (widget.onStatus == null)) {
      _network = null;
      _status = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Localizations.maybeLocaleOf(context);
    Directionality.of(context);
    _hostName = null;
    _likeCount = null;
    _hostCapsule = null;
    _topRow = null;
    _network = null;
    _status = null;
  }

  void _onClose() => widget.onClose?.call();
  void _onAudience() => widget.onAudience?.call();
  void _onStatus() => widget.onStatus?.call();

  @override
  Widget build(BuildContext context) {
    _network ??= _buildNetworkStatus(context);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        _topRow ??= _buildTopRow(),
        _status ??= Positioned(
          // Header 自身左右各留 12，向右补偿 12 后胶囊贴住屏幕边缘。
          right: -12,
          top: 42,
          width: _networkWidth,
          height: 24,
          child: Semantics(
            label: _networkTitle,
            value: LiveHeaderView.formatDuration(widget.elapsedSeconds),
            child: _network,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkStatus(BuildContext context) {
    final _NetworkStatusPresentation networkStatus = _NetworkStatusPresentation.fromQuality(widget.networkQuality);
    final String networkStatusTitle = LiveKitResources.localizedString(networkStatus.titleKey);
    final TextStyle networkStatusTextStyle =
        TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: networkStatus.color);
    final TextPainter networkStatusTextPainter = TextPainter(
      text: TextSpan(text: networkStatusTitle, style: networkStatusTextStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: TextScaler.noScaling,
    )..layout();
    final double networkStatusWidth = math.max(
      networkStatus.minimumWidth,
      networkStatus.labelLeading +
          networkStatusTextPainter.width.ceilToDouble() +
          3 +
          networkStatus.chevronWidth +
          networkStatus.chevronTrailing,
    );
    networkStatusTextPainter.dispose();
    _networkWidth = networkStatusWidth;
    _networkTitle = networkStatusTitle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onStatus == null ? null : _onStatus,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: LiveHeaderView._darkCapsuleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Stack(
          children: <Widget>[
            if (networkStatus.iconName != null)
              Positioned(
                left: 7,
                top: 5.5,
                width: networkStatus.iconWidth,
                height: 13,
                child: Image(
                  image: LiveKitResources.image(networkStatus.iconName!),
                  fit: BoxFit.contain,
                ),
              ),
            Positioned(
              left: networkStatus.labelLeading,
              right: networkStatus.chevronTrailing + networkStatus.chevronWidth + 3,
              top: 0,
              bottom: 0,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    networkStatusTitle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.right,
                    textScaler: TextScaler.noScaling,
                    style: networkStatusTextStyle,
                  )),
            ),
            Positioned(
              right: networkStatus.chevronTrailing,
              top: 7.5,
              width: networkStatus.chevronWidth,
              height: 9,
              child: Image(
                image: LiveKitResources.image(networkStatus.chevronName),
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    _audienceURLs =
        widget.viewerCount > 0 ? widget.audience.take(3).map((user) => user.avatarURL).toList() : <String>[];
    return Positioned(
      // 主播胶囊、观众区与关闭入口共处一行：iOS 用
      // `width 165 .priority(.high)` + `trailing ≤ audiencePresenceView.leading - 4`
      // 表达「基准取 165、空间不足时收缩」，Flutter 等价写法是 Row + Flexible，
      // 由 Row 把剩余空间约束传给胶囊，不预估观众区宽度。
      left: 0,
      right: 0,
      top: 0,
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            // `Expanded` 吃掉剩余空间，把观众区与关闭入口顶到右边界，
            // 内层 `Align` 在 loose 约束下让胶囊取 min(165, 可用宽度)：
            // 390pt 基准得到 165，小屏收缩，内部文本随之截断。
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 165,
                height: 36,
                child: _hostCapsule ??= _buildHostCapsule(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: _audience ??= LiveAudiencePresenceView(
              audience: widget.audience,
              count: widget.viewerCount,
              onTap: widget.onAudience == null ? null : _onAudience,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: _close ??= GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose == null ? null : _onClose,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: LiveHeaderView._darkCapsuleColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: LiveHeaderView._darkCapsuleBorderColor, width: 1),
                ),
                child: Center(
                  // 图标本身按 Ardot `close-svg` 的 15×15 显示，不撑满 26×26 胶囊。
                  child: Image(
                    image: LiveKitResources.image('livekit_living_close'),
                    width: 15,
                    height: 15,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCapsule() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_LiveHeaderStyle.capsuleRadius),
        border: Border.all(color: LiveHeaderView._hostBorderColor, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            LiveVideoOverlayStyle.capsuleBackground,
            _LiveHeaderStyle.middle,
            _LiveHeaderStyle.purple,
            _LiveHeaderStyle.rose,
          ],
          stops: <double>[0, 0.52, 0.82, 1],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 2,
            top: 2,
            width: 32,
            height: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_LiveHeaderStyle.avatarRadius),
              child: _avatar ??= _buildAvatar(),
            ),
          ),
          Positioned(
            // 宽度跟随可用空间并截断。
            left: 40,
            right: 42 + 2 + 2,
            top: 5,
            height: 15,
            child: _hostName ??= Text(
              widget.hostName.isEmpty ? LiveKitResources.localizedString('tuilivekit.common.host') : widget.hostName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LiveTheme.textStyle(LiveTextRole.caption),
            ),
          ),
          Positioned(
            left: 40,
            right: 42 + 2 + 2,
            top: 20,
            height: 11,
            child: _likeCount ??= Text(
              LiveKitResources.localizedFormat('tuilivekit.pusher.living.like_count', widget.likeCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LiveHeaderView._likeTextColor,
                fontSize: 8,
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 4,
            width: 42,
            height: 28,
            child: _fan,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final Widget placeholder = Image(
      image: LiveKitResources.image('livekit_livelist_default_avatar'),
      fit: BoxFit.cover,
    );
    final ImageProvider? provider = LiveImageLoader.provider(widget.hostAvatarURL);
    if (provider == null) {
      return placeholder;
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      gaplessPlayback: false,
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

enum _NetworkStatusPresentation {
  normal,
  poor,
  veryPoor,
  disconnected;

  factory _NetworkStatusPresentation.fromQuality(int quality) {
    return switch (quality) {
      3 => poor,
      4 || 5 => veryPoor,
      6 => disconnected,
      _ => normal,
    };
  }

  String get titleKey => switch (this) {
        normal => 'tuilivekit.pusher.status.title',
        poor => 'tuilivekit.pusher.living.network_poor',
        veryPoor => 'tuilivekit.pusher.living.network_very_poor',
        disconnected => 'tuilivekit.pusher.living.network_disconnected',
      };

  String? get iconName => switch (this) {
        normal => null,
        poor => 'livekit_living_network_poor',
        veryPoor => 'livekit_living_network_very_poor',
        disconnected => 'livekit_living_network_disconnected',
      };

  String get chevronName => switch (this) {
        normal => 'livekit_living_status_chevron',
        poor => 'livekit_living_network_poor_chevron',
        veryPoor => 'livekit_living_network_very_poor_chevron',
        disconnected => 'livekit_living_network_disconnected_chevron',
      };

  Color get color => switch (this) {
        normal => const Color(0xFFFFFFFF),
        poor => const Color(0xFFFFD08A),
        veryPoor => const Color(0xFFFF927D),
        disconnected => const Color(0xFFFF6978),
      };

  double get minimumWidth => switch (this) {
        normal => 68,
        poor => 82,
        veryPoor || disconnected => 94,
      };

  double get iconWidth => switch (this) {
        normal || poor => 13,
        veryPoor || disconnected => 17,
      };

  double get labelLeading => switch (this) {
        normal => 8.8,
        poor => 25,
        veryPoor || disconnected => 29,
      };

  double get chevronTrailing => switch (this) {
        normal => 9.7,
        poor => 10.1,
        veryPoor || disconnected => 8.08,
      };

  double get chevronWidth => switch (this) {
        normal => 5.080645,
        poor => 5.646774,
        veryPoor || disconnected => 5.690323,
      };
}

abstract final class _LiveHeaderStyle {
  static const middle = Color(0x330E101C);
  static const purple = Color(0x2E7B4DFF);
  static const rose = Color(0x29FF5B7A);
  static const border = Color(0x0FFFFFFF);
  static const capsuleRadius = 18.0;
  static const avatarRadius = 16.0;
}
