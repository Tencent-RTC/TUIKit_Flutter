import 'dart:math' as math;
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import '../../common/app_strings.dart';

class LiveHomePreviewItemView extends StatelessWidget {
  const LiveHomePreviewItemView({
    super.key,
    required this.info,
    required this.player,
    required this.onEnter,
    this.bottomInset = 0,
    this.showPreview = true,
    this.joining = false,
    this.ended = false,
    this.hidePlayer = false,
  });
  final LiveInfo info;
  final Widget player;
  final VoidCallback onEnter;
  final double bottomInset;
  final bool showPreview;
  final bool joining;
  final bool ended;
  final bool hidePlayer;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final height = math.max(0.0, bounds.maxHeight - bottomInset);
      final owner = info.liveOwner.userName.trim().isEmpty
          ? AppStrings.of(context, 'unknownHost')
          : info.liveOwner.userName;
      final title = info.liveName.trim().isEmpty ? AppStrings.of(context, 'untitledLive') : info.liveName;
      return ColoredBox(
        color: const Color(0xff29364a),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                AppStrings.of(context, 'coverUnavailable'),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
            if (Uri.tryParse(info.coverURL)?.hasScheme == true)
              Image.network(
                info.coverURL,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => const SizedBox.shrink(),
              ),
            // Opacity keeps the player attached with the same canvas while the initial cover is held for joining.
            Opacity(opacity: hidePlayer ? 0 : 1, child: player),
            if (showPreview) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: math.max(120, MediaQuery.paddingOf(context).top + 73),
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .32, .72, 1],
                        colors: [Color(0x73000000), Color(0x61000000), Color(0x3b000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: math.max(0, height - 242),
                height: math.min(242, height),
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .16, .44, .77, 1],
                        colors: [
                          Colors.transparent,
                          Color(0x24000000),
                          Color(0x38000000),
                          Color(0x4f000000),
                          Color(0x70000000),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: joining || ended ? null : onEnter),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 174,
                height: 46,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 226),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: joining || ended ? null : onEnter,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0x24ffffff),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: const Color(0x4dffffff)),
                          ),
                          child: Text(
                            AppStrings.of(context, ended ? 'liveEnded' : 'enterLive'),
                            style: TextStyle(
                              color: joining || ended ? Colors.white70 : Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 123,
                height: 24,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IntrinsicWidth(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 62),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ended ? const Color(0xe64d4d4d) : const Color(0xffe83b67),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppStrings.of(context, ended ? 'liveEnded' : 'liveNow'),
                        maxLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 82,
                height: 30,
                child: Text(
                  '@$owner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 51,
                height: 24,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 19,
                height: 22,
                child: Text(
                  '${info.totalViewerCount} ${AppStrings.of(context, 'watching')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xffd6d3d0), fontSize: 13, height: 22 / 13),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
