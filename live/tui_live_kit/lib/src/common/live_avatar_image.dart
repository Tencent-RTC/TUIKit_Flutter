import 'package:flutter/material.dart';

import 'live_image_loader.dart';
import 'live_kit_resources.dart';

class LiveAvatarImage extends StatelessWidget {
  const LiveAvatarImage({
    super.key,
    required this.avatarURL,
    this.fit = BoxFit.cover,
  });

  final String avatarURL;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = LiveImageLoader.provider(avatarURL);
    if (provider != null) {
      return Image(
        image: provider,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Image(
      image: LiveKitResources.image('livekit_livelist_default_avatar'),
      fit: fit,
    );
  }
}
