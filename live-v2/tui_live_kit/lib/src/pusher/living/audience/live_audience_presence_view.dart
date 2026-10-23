import 'package:flutter/widgets.dart';

import '../../../common/live_image_loader.dart';
import '../../../common/live_kit_resources.dart';
import 'pusher_audience_store.dart';
import '../../../common/theme/live_text.dart';
import '../../../common/theme/live_theme.dart';

class LiveAudiencePresenceView extends StatefulWidget {
  const LiveAudiencePresenceView({
    super.key,
    required this.audience,
    required this.count,
    this.onTap,
  });

  final List<AudienceUser> audience;
  final int count;

  final VoidCallback? onTap;

  /// UIColor(red: 0.039, green: 0.047, blue: 0.071, alpha: 0.22)
  static const Color _countBackgroundColor = LiveVideoOverlayStyle.capsuleBackground;

  static String formattedCount(int count) {
    final int safeCount = count < 0 ? 0 : count;
    if (safeCount < 10000) {
      return '$safeCount';
    }
    final int unit = safeCount ~/ 10000;
    return LiveKitResources.localizedFormat('tuilivekit.pusher.living.audience_count_compact', unit.clamp(1, 10));
  }

  @override
  State<LiveAudiencePresenceView> createState() => _LiveAudiencePresenceViewState();
}

class _LiveAudiencePresenceViewState extends State<LiveAudiencePresenceView> {
  final List<String> _avatarURLs = [];
  final List<Widget> _avatars = [];
  Widget? _count;

  @override
  void didUpdateWidget(LiveAudiencePresenceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) _count = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Localizations.maybeLocaleOf(context);
    _count = null;
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = widget.count > 0 ? widget.audience.length.clamp(0, 3) : 0;
    for (int index = 0; index < visibleCount; index++) {
      final url = widget.audience[index].avatarURL;
      if (index == _avatars.length) {
        _avatarURLs.add(url);
        _avatars.add(_AudienceAvatarView(avatarURL: url));
      } else if (_avatarURLs[index] != url) {
        _avatarURLs[index] = url;
        _avatars[index] = _AudienceAvatarView(avatarURL: url);
      }
    }
    if (_avatars.length > visibleCount) {
      _avatars.removeRange(visibleCount, _avatars.length);
      _avatarURLs.removeRange(visibleCount, _avatarURLs.length);
    }
    return Semantics(
      label: LiveKitResources.localizedString('tuilivekit.player.online_audience'),
      value: '${widget.count}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int index = 0; index < _avatars.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: 2),
              _avatars[index],
            ],
            if (_avatars.isNotEmpty) const SizedBox(width: 4),
            _count ??= Container(
              height: 26,
              constraints: const BoxConstraints(minWidth: 26),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: LiveAudiencePresenceView._countBackgroundColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: LiveText(LiveTextRole.caption,
                    text: LiveAudiencePresenceView.formattedCount(widget.count), alignment: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceAvatarView extends StatefulWidget {
  const _AudienceAvatarView({required this.avatarURL});
  final String avatarURL;

  @override
  State<_AudienceAvatarView> createState() => _AudienceAvatarViewState();
}

class _AudienceAvatarViewState extends State<_AudienceAvatarView> {
  Widget? _avatar;

  @override
  void didUpdateWidget(_AudienceAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarURL != widget.avatarURL) _avatar = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 26,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 3,
            top: 0,
            width: 26,
            height: 26,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _avatar ??= _buildAvatar(),
            ),
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
    final ImageProvider? provider = LiveImageLoader.provider(widget.avatarURL);
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
