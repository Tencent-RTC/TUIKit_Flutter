import 'dart:ui' show ImageFilter;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../common/live_avatar_image.dart';
import '../../common/live_kit_resources.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({
    super.key,
    required this.liveInfo,
    this.reason,
  });

  static const double _backgroundBlurSigma = 80;

  static const double _titleTop = 114;
  static const double _titleHeight = 34;
  static const double _avatarRingTop = 211;
  static const double _avatarRingSize = 86;
  static const double _avatarSize = 80;
  static const double _nameTop = 314;
  static const double _nameHeight = 28;
  static const double _hintTop = 349;
  static const double _hintHeight = 21;
  static const double _swipeArrowBottom = 81;
  static const double _swipeArrowSize = 22;
  static const double _swipeHintBottom = 58;
  static const double _swipeHintHeight = 18;

  final LiveInfo liveInfo;

  /// 非空时展示具体结束原因，对应 iOS `SummaryView.bind(_:reason:)`。
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final String name = liveInfo.liveOwner.userName.isEmpty
        ? liveInfo.liveOwner.userID
        : liveInfo.liveOwner.userName;
    // 对应 iOS `SummaryView.hitTest` 返回 nil：结束页不拦截 Feed 的滑动手势。
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildBackground(),
        Positioned(
          top: _titleTop,
          left: 0,
          right: 0,
          height: _titleHeight,
          child: Center(
            child: Text(
              reason ??
                  LiveKitResources.localizedString(
                      'tuilivekit.player.live_ended'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                height: 34 / 27,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: _avatarRingTop,
          left: 0,
          right: 0,
          height: _avatarRingSize,
          child: Center(
            child: Container(
              width: _avatarRingSize,
              height: _avatarRingSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: LiveAvatarImage(
                      avatarURL: liveInfo.liveOwner.avatarURL),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: _nameTop,
          left: 24,
          right: 24,
          height: _nameHeight,
          child: Center(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: _hintTop,
          left: 0,
          right: 0,
          height: _hintHeight,
          child: Center(
            child: Text(
              LiveKitResources.localizedString(
                  'tuilivekit.player.summary.next_live_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 14,
                height: 21 / 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: _swipeArrowBottom,
          left: 0,
          right: 0,
          height: _swipeArrowSize,
          child: Center(
            child: Image(
              image: LiveKitResources.image('livekit_summary_swipe_arrow'),
              width: _swipeArrowSize,
              height: _swipeArrowSize,
              color: const Color(0xB8FFFFFF),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          bottom: _swipeHintBottom,
          left: 0,
          right: 0,
          height: _swipeHintHeight,
          child: Center(
            child: Text(
              LiveKitResources.localizedString(
                  'tuilivekit.player.summary.swipe_more'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xA8FFFFFF),
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final String url = liveInfo.backgroundURL.isNotEmpty
        ? liveInfo.backgroundURL
        : (liveInfo.coverURL.isNotEmpty
            ? liveInfo.coverURL
            : LiveKitResources.defaultBackgroundURL);
    return ColoredBox(
      color: const Color(0x99000000),
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _backgroundBlurSigma,
            sigmaY: _backgroundBlurSigma,
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image(
              image: LiveKitResources.image('livekit_livelist_default_cover'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
