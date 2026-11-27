/// 对应 iOS `LiveKitAccess/LiveList/LiveSelectListItemView.swift`。
///
/// 列表单卡片：封面、渐变、直播状态点、观看人数、直播主题、主播头像与昵称。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import 'live_list_support.dart';

class LiveSelectListItemView extends StatelessWidget {
  const LiveSelectListItemView({super.key, required this.liveInfo});

  final LiveInfo liveInfo;

  /// UIColor(red: 1, green: 0.22, blue: 0.27, alpha: 1)
  static const Color _liveStatusColor = Color(0xFFFF3845);

  /// UIColor(white: 1, alpha: 0.70)
  static const Color _ownerTextColor = Color(0xB3FFFFFF);

  @override
  Widget build(BuildContext context) {
    final String liveName = liveInfo.liveName.isEmpty ? liveInfo.liveID : liveInfo.liveName;
    final String ownerName = liveInfo.liveOwner.userName.isEmpty
        ? liveInfo.liveOwner.userID
        : liveInfo.liveOwner.userName;
    final String viewerText = LiveSelectListResources.localizedString('tuilivekit.live_list.viewers')
        .replaceAll('%d', '${liveInfo.totalViewerCount}');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: const Color(0xFF000000),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildCover(),
            const _LiveSelectListCoverGradientView(),
            Positioned(
              left: 8,
              top: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _liveStatusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    viewerText,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    liveName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: _buildAvatar(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ownerTextColor,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    final Widget placeholder = Image(
      image: LiveSelectListResources.image('livekit_livelist_default_cover'),
      fit: BoxFit.cover,
    );
    final String resolvedURL =
        liveInfo.coverURL.isEmpty ? LiveSelectListResources.defaultCoverURL : liveInfo.coverURL;
    return _buildNetworkImage(resolvedURL, placeholder);
  }

  Widget _buildAvatar() {
    final Widget placeholder = Image(
      image: LiveSelectListResources.image('livekit_livelist_default_avatar'),
      fit: BoxFit.cover,
    );
    return _buildNetworkImage(liveInfo.liveOwner.avatarURL, placeholder);
  }

  Widget _buildNetworkImage(String urlString, Widget placeholder) {
    final ImageProvider? provider = LiveSelectListImageLoader.provider(urlString);
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

/// 对应 iOS 同文件内的私有渐变视图，保持私有作用域。
class _LiveSelectListCoverGradientView extends StatelessWidget {
  const _LiveSelectListCoverGradientView();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0x00000000),
              Color(0x00000000),
              Color(0x66000000),
            ],
            stops: <double>[0, 0.55, 1],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
