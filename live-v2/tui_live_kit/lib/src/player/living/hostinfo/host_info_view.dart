import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../follow_service.dart';

class HostInfoView extends StatefulWidget {
  const HostInfoView({
    super.key,
    this.onFollowTap,
    this.onError,
  });

  final ValueChanged<String>? onFollowTap;
  final ValueChanged<String>? onError;

  @override
  State<HostInfoView> createState() => HostInfoViewState();
}

class HostInfoViewState extends State<HostInfoView> {
  final PlayerFollowService _followService = PlayerFollowService.shared;
  LiveInfo? _liveInfo;
  LikeStore? _likeStore;
  VoidCallback? _likeListener;
  int _likeCount = 0;
  bool _followButtonHidden = false;
  DateTime? _lastFollowTapAt;

  @override
  void initState() {
    super.initState();
    _followService.addListener(_handleFollowStateChanged);
    unawaited(_followService.startListening());
  }

  @override
  void dispose() {
    _detachLikeStore();
    _followService.removeListener(_handleFollowStateChanged);
    unawaited(_followService.stopListening());
    super.dispose();
  }

  void bind(
    LiveInfo liveInfo, {
    LikeStore? likeStore,
    int? likeCount,
  }) {
    final bool userChanged = _liveInfo?.liveOwner.userID != liveInfo.liveOwner.userID;
    _liveInfo = liveInfo;
    if (likeCount != null) _likeCount = likeCount;
    if (likeStore != null) _attachLikeStore(likeStore);
    final String selfUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    _followButtonHidden = liveInfo.liveOwner.userID.isEmpty || liveInfo.liveOwner.userID == selfUserID;
    if (mounted) setState(() {});
    if (userChanged && !_followButtonHidden) {
      _followService.refresh(liveInfo.liveOwner.userID).then((String? error) {
        if (error != null && error.isNotEmpty) widget.onError?.call(error);
      });
    }
  }

  void prepareForReuse() {
    _detachLikeStore();
    _liveInfo = null;
    _likeCount = 0;
    _followButtonHidden = false;
    if (mounted) setState(() {});
  }

  void setLikeCount(int count) {
    if (_likeCount == count) return;
    _likeCount = count;
    if (mounted) setState(() {});
  }

  void setFollowing(bool following) {
    final String userID = _liveInfo?.liveOwner.userID ?? '';
    _followService.update(userID, following);
  }

  void setFollowButtonHidden(bool hidden) {
    if (_followButtonHidden == hidden) return;
    _followButtonHidden = hidden;
    if (mounted) setState(() {});
  }

  void _attachLikeStore(LikeStore store) {
    if (identical(_likeStore, store)) return;
    _detachLikeStore();
    _likeStore = store;
    _likeCount = store.likeState.totalLikeCount.value;
    _likeListener = () {
      setLikeCount(store.likeState.totalLikeCount.value);
    };
    store.likeState.totalLikeCount.addListener(_likeListener!);
  }

  void _detachLikeStore() {
    final LikeStore? store = _likeStore;
    final VoidCallback? listener = _likeListener;
    if (store != null && listener != null) {
      store.likeState.totalLikeCount.removeListener(listener);
    }
    _likeStore = null;
    _likeListener = null;
  }

  void _handleFollowStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFollow() async {
    final String userID = _liveInfo?.liveOwner.userID ?? '';
    if (userID.isEmpty || _followService.isLoading(userID)) return;
    final DateTime now = DateTime.now();
    if (_lastFollowTapAt != null && now.difference(_lastFollowTapAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastFollowTapAt = now;
    final String? error = await _followService.toggle(userID);
    if (!mounted) return;
    if (error != null && error.isNotEmpty) {
      widget.onError?.call(error);
      return;
    }
    widget.onFollowTap?.call(userID);
  }

  String _likeText() {
    return LiveKitResources.localizedString('tuilivekit.player.like_count').replaceFirst('%d', '$_likeCount');
  }

  @override
  Widget build(BuildContext context) {
    final LiveInfo? liveInfo = _liveInfo;
    if (liveInfo == null) return const SizedBox.shrink();
    final String userID = liveInfo.liveOwner.userID;
    final String rawName = liveInfo.liveOwner.userName.isEmpty ? userID : liveInfo.liveOwner.userName;
    final String name = rawName.characters.length > 7 ? '${rawName.characters.take(7).string}…' : rawName;
    final bool following = _followService.isFollowing(userID);
    final bool loading = _followService.isLoading(userID);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _PlayerHostStyle.capsuleBorder),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            _PlayerHostStyle.gradientFirst,
            _PlayerHostStyle.gradientSecond,
            _PlayerHostStyle.gradientThird,
            _PlayerHostStyle.gradientFourth,
          ],
          stops: <double>[0, 0.52, 0.82, 1],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 32,
            height: 32,
            child: ClipOval(
              child: LiveAvatarImage(
                avatarURL: liveInfo.liveOwner.avatarURL,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    _likeText(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_followButtonHidden) ...<Widget>[
            const SizedBox(width: 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: loading ? null : _toggleFollow,
              child: Container(
                constraints: const BoxConstraints(minWidth: 44),
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: following ? _PlayerHostStyle.followingBackground : _PlayerHostStyle.followBackground,
                  borderRadius: BorderRadius.circular(13.5),
                  border: Border.all(
                    color: following ? _PlayerHostStyle.followingBorder : const Color(0x00000000),
                    width: 1,
                  ),
                ),
                child: Text(
                  LiveKitResources.localizedString(
                    following ? 'tuilivekit.player.unfollow' : 'tuilivekit.player.follow',
                  ),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 对应 iOS `HostInfoView` 的胶囊渐变与关注按钮配方。
abstract final class _PlayerHostStyle {
  static const followingBackground = Color(0x40FE2876);
  static const followBackground = Color(0xFFFE2876);
  static const followingBorder = Color(0x61FE2876);

  static const capsuleBorder = Color(0x0FFFFFFF);
  static const gradientFirst = Color(0x380A0C12);
  static const gradientSecond = Color(0x330E101C);
  static const gradientThird = Color(0x2E7B4DFF);
  static const gradientFourth = Color(0x29FF5B7A);
}
