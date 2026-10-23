import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../common/audience/audience_welcome_view.dart';
import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/live_theme.dart';

class AudienceView extends StatefulWidget {
  const AudienceView({
    super.key,
    this.onAudience,
    this.onAudienceEntered,
    this.onToast,
  });

  final VoidCallback? onAudience;
  final void Function(AudienceWelcome welcome)? onAudienceEntered;
  final ValueChanged<String>? onToast;

  @override
  State<AudienceView> createState() => AudienceViewState();
}

class AudienceViewState extends State<AudienceView> {
  static const int _maxAvatarCount = 3;
  static const double _avatarSize = 26;
  static const double _avatarStep = 17;

  LiveAudienceStore? _store;
  VoidCallback? _audienceListListener;
  VoidCallback? _audienceCountListener;
  LiveAudienceListener? _liveAudienceListener;
  List<LiveUserInfo> _audiences = <LiveUserInfo>[];
  int _audienceCount = 0;
  String _liveID = '';
  DateTime? _lastTapTime;

  void bind(LiveInfo liveInfo) {
    attachStore(liveInfo.liveID);
  }

  void unbind() {
    detachStore();
  }

  void attachStore(String liveID) {
    if (liveID.isEmpty) {
      detachStore();
      return;
    }
    if (_liveID == liveID && _store != null) return;
    detachStore();
    _liveID = liveID;
    final LiveAudienceStore store = LiveAudienceStore.create(liveID);
    _store = store;
    _audienceListListener = () {
      if (!mounted || _store != store) return;
      setState(() {
        _audiences = List<LiveUserInfo>.from(
          store.liveAudienceState.audienceList.value,
        );
      });
    };
    _audienceCountListener = () {
      if (!mounted || _store != store) return;
      setState(() {
        _audienceCount = store.liveAudienceState.audienceCount.value;
      });
    };
    store.liveAudienceState.audienceList.addListener(_audienceListListener!);
    store.liveAudienceState.audienceCount.addListener(_audienceCountListener!);
    _liveAudienceListener = LiveAudienceListener(
      onAudienceMessageDisabled: (LiveUserInfo audience, bool isDisable) {
        if (audience.userID ==
            LoginStore.shared.loginState.loginUserInfo?.userID) {
          widget.onToast?.call(LiveKitResources.localizedString(
            isDisable
                ? 'tuilivekit.player.audience.message_disabled'
                : 'tuilivekit.player.audience.message_enabled',
          ));
        }
      },
      onAudienceJoined: (LiveUserInfo audience) {
        if (audience.userID.isEmpty) return;
        widget.onAudienceEntered?.call(
          AudienceWelcome(
            userID: audience.userID,
            userName:
                audience.userName.isEmpty ? audience.userID : audience.userName,
            level: audience.level < 0 ? 0 : audience.level,
          ),
        );
      },
    );
    if (_liveAudienceListener != null) {
      store.addLiveAudienceListener(_liveAudienceListener!);
    }
    _audiences = List<LiveUserInfo>.from(
      store.liveAudienceState.audienceList.value,
    );
    _audienceCount = store.liveAudienceState.audienceCount.value;
    if (mounted) setState(() {});
    store.fetchAudienceList();
  }

  void detachStore() {
    final LiveAudienceStore? store = _store;
    if (store != null) {
      if (_audienceListListener != null) {
        store.liveAudienceState.audienceList
            .removeListener(_audienceListListener!);
      }
      if (_audienceCountListener != null) {
        store.liveAudienceState.audienceCount
            .removeListener(_audienceCountListener!);
      }
      if (_liveAudienceListener != null) {
        store.removeLiveAudienceListener(_liveAudienceListener!);
      }
    }
    _store = null;
    _audienceListListener = null;
    _audienceCountListener = null;
    _liveAudienceListener = null;
    _liveID = '';
    _audiences = <LiveUserInfo>[];
    _audienceCount = 0;
    _lastTapTime = null;
    if (mounted) setState(() {});
  }

  void _handleTap() {
    final DateTime now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastTapTime = now;
    widget.onAudience?.call();
  }

  @override
  void dispose() {
    final LiveAudienceStore? store = _store;
    if (store != null) {
      if (_audienceListListener != null) {
        store.liveAudienceState.audienceList
            .removeListener(_audienceListListener!);
      }
      if (_audienceCountListener != null) {
        store.liveAudienceState.audienceCount
            .removeListener(_audienceCountListener!);
      }
  
      if (_liveAudienceListener != null) {
        store.removeLiveAudienceListener(_liveAudienceListener!);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<LiveUserInfo> visible =
        _audiences.take(_maxAvatarCount).toList(growable: false);
    final double avatarWidth =
        visible.isEmpty ? 0 : _avatarSize + (visible.length - 1) * _avatarStep;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        height: 26,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (visible.isNotEmpty)
              SizedBox(
                width: avatarWidth,
                height: _avatarSize,
                child: Stack(
                  children: List<Widget>.generate(visible.length, (int index) {
                    final LiveUserInfo user = visible[index];
                    return Positioned(
                      left: index * _avatarStep,
                      child: SizedBox(
                        width: _avatarSize,
                        height: _avatarSize,
                        child: ClipPath(
                          clipper: _AudienceAvatarCutoutClipper(
                            showLeftCutout: index > 0,
                            step: _avatarStep,
                          ),
                          child: LiveAvatarImage(avatarURL: user.avatarURL),
                        ),
                      ),
                    );
                  }).reversed.toList(growable: false),
                ),
              ),
            if (visible.isNotEmpty) const SizedBox(width: 4),
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              height: 26,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: LiveVideoOverlayStyle.capsuleBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '$_audienceCount',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 对应 iOS `AudienceAvatarItemView` 的月牙挖空遮罩：后一个头像被前一个头像
/// 的圆形轮廓挖掉重叠部分，不使用描边圆环。
class _AudienceAvatarCutoutClipper extends CustomClipper<Path> {
  const _AudienceAvatarCutoutClipper({
    required this.showLeftCutout,
    required this.step,
  });

  final bool showLeftCutout;
  final double step;

  @override
  Path getClip(Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Path avatarPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: size.width / 2));
    if (!showLeftCutout) return avatarPath;
    final Offset neighborCenter = Offset(-step + size.width / 2, size.height / 2);
    final Path cutoutPath = Path()
      ..addOval(Rect.fromCircle(
        center: neighborCenter,
        radius: size.width / 2 + 1,
      ));
    return Path.combine(PathOperation.difference, avatarPath, cutoutPath);
  }

  @override
  bool shouldReclip(_AudienceAvatarCutoutClipper oldClipper) {
    return oldClipper.showLeftCutout != showLeftCutout ||
        oldClipper.step != step;
  }
}
