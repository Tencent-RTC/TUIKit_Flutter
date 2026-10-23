import 'dart:math';
import 'dart:ui';

import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

class SingleColumnItemWidget extends StatefulWidget {
  final LiveInfo liveInfo;
  final LiveCoreController liveCoreController;
  final ValueListenable<bool> offstageListenable;
  final VoidCallback? onTap;
  final VoidCallback? onInitState;
  final VoidCallback? onDispose;

  /// Whether to enable the expensive [BackdropFilter] blur on the background.
  /// Only enable it for the current page and its two neighbours to save GPU.
  final bool enableBlur;

  const SingleColumnItemWidget({
    super.key,
    required this.liveInfo,
    required this.liveCoreController,
    required this.offstageListenable,
    this.onTap,
    this.onInitState,
    this.onDispose,
    this.enableBlur = true,
  });

  @override
  State<SingleColumnItemWidget> createState() => _SingleColumnItemWidgetState();
}

class _SingleColumnItemWidgetState extends State<SingleColumnItemWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInitState?.call();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveCoreController = widget.liveCoreController;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        color: LiveColors.notStandardPureBlack,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            _buildBackgroundWidget(),
            // RenderView
            Positioned.fill(child: _buildRenderWidget()),
            // Live info
            Positioned(
              left: 20.width,
              right: 20.width,
              bottom: 43.height,
              child: _buildLiveInfoWidget(),
            ),
            // Enter Live
            Positioned(
              bottom: 234.height,
              left: 0,
              right: 0,
              child: Center(child: _buildEnterLiveWidget()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenderWidget() {
    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.offstageListenable,
        builder: (context, offstage, child) {
          return Offstage(offstage: offstage, child: child);
        },
        child: LiveCoreWidget(controller: widget.liveCoreController),
      ),
    );
  }

  Widget _buildBackgroundWidget() {
    final liveInfo = widget.liveInfo;
    final enableBlur = widget.enableBlur;
    String coverUrl = liveInfo.coverURL.isNotEmpty ? liveInfo.coverURL.split(';').first : '';
    if (coverUrl.isEmpty) coverUrl = liveInfo.backgroundURL;
    if (coverUrl.isEmpty) coverUrl = Constants.defaultCoverUrl;
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: coverUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Image.asset(
            LiveImages.streamDefaultCover,
            fit: BoxFit.cover,
            package: Constants.pluginName,
          ),
        ),
        // Blur/darken layer.
        Positioned.fill(
          child: enableBlur
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.white.withAlpha(50)),
                  ),
                )
              : Container(color: Colors.white.withAlpha(50)),
        )
      ],
    );
  }

  Widget _buildLiveInfoWidget() {
    final liveInfo = widget.liveInfo;
    final roomName = liveInfo.liveName.isNotEmpty ? liveInfo.liveName : liveInfo.liveID;
    final ownerName = liveInfo.liveOwner.userName.isNotEmpty ? liveInfo.liveOwner.userName : liveInfo.liveOwner.userID;
    final ownerAvatarUrl = liveInfo.liveOwner.avatarURL;
    return Column(
      children: [
        // Room info
        Row(
          children: [
            Expanded(
              child: Text(
                roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: LiveColors.designStandardFlowkitWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 22 / 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 0, height: 20.height),
        // Owner info
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.radius),
              child: SizedBox(
                width: 24.radius,
                height: 24.radius,
                child: CachedNetworkImage(
                  imageUrl: ownerAvatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                    LiveImages.defaultAvatar,
                    fit: BoxFit.cover,
                    package: Constants.pluginName,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.width),
            Expanded(
              child: Text(
                ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: LiveColors.designStandardFlowkitWhite.withAlpha(140),
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEnterLiveWidget() {
    return Container(
      width: 220.width,
      height: 40.height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(20.height),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16.radius,
            height: 16.radius,
            child: const _LiveStatusAnimationWidget(),
          ),
          SizedBox(width: 8.width),
          Flexible(
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.livelist_click_enter_room,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated audio bar indicator widget.
/// Draws 3 vertical bars that oscillate in height using a sine wave,
class _LiveStatusAnimationWidget extends StatefulWidget {
  const _LiveStatusAnimationWidget();

  @override
  State<_LiveStatusAnimationWidget> createState() => _LiveStatusAnimationWidgetState();
}

class _LiveStatusAnimationWidgetState extends State<_LiveStatusAnimationWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AudioBarPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _AudioBarPainter extends CustomPainter {
  final double progress;
  static const int barCount = 3;
  static const double barWidth = 2.0;
  static const double minBarHeight = 7.0;
  static const double barSpacing = 3.0;

  _AudioBarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final totalWidth = barWidth * barCount + barSpacing * (barCount - 1);
    final startX = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final phase = i * 0.6;
      final adjustedProgress = (progress + phase) % 1.0;
      final barHeight = minBarHeight + sin(adjustedProgress * pi) * 15;

      final left = startX + i * (barWidth + barSpacing);
      final top = centerY - barHeight / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_AudioBarPainter oldDelegate) => oldDelegate.progress != progress;
}
