import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import '../../common/app_strings.dart';

class LiveHomeItemView extends StatelessWidget {
  const LiveHomeItemView({super.key, required this.info, this.onTap, this.active = true, this.hero = false});
  final LiveInfo info;
  final VoidCallback? onTap;
  final bool active;
  final bool hero;
  @override
  Widget build(BuildContext context) {
    final title = info.liveName.trim().isEmpty ? AppStrings.of(context, 'untitledLive') : info.liveName;
    final owner = info.liveOwner.userName.trim().isEmpty
        ? AppStrings.of(context, 'unknownHost')
        : info.liveOwner.userName;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: const Color(0xff29364a),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                AppStrings.of(context, 'coverUnavailable'),
                style: const TextStyle(fontSize: 13, color: Color(0x8cffffff)),
              ),
            ),
            if (Uri.tryParse(info.coverURL)?.hasScheme == true)
              Image.network(
                info.coverURL,
                fit: BoxFit.cover,
                gaplessPlayback: false,
                errorBuilder: (_, error, stack) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .35, .6, 1],
                  colors: [Color(0x40000000), Colors.transparent, Colors.transparent, Color(0xad000000)],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xffff3845)),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${info.totalViewerCount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 20 / 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 21 / 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: ClipOval(
                          child: ColoredBox(
                            color: const Color(0x26ffffff),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: Text(
                                    owner.characters.first.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                if (Uri.tryParse(info.liveOwner.avatarURL)?.hasScheme == true)
                                  Image.network(
                                    info.liveOwner.avatarURL,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xb3ffffff)),
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
    return TickerMode(
      enabled: active,
      child: Semantics(
        button: true,
        label: '$title, $owner, ${info.totalViewerCount}',
        child: GestureDetector(
          onTap: onTap,
          child: hero
              ? Hero(
                  tag: 'live-cover-${info.liveID}',
                  child: Material(type: MaterialType.transparency, child: card),
                )
              : card,
        ),
      ),
    );
  }
}
