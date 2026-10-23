import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../live_list_define.dart';

class DoubleColumnItemWidget extends StatefulWidget {
  final int index;
  final LiveInfo liveInfo;
  final LiveCoreController liveCoreController;
  final ValueListenable<bool> offstageListenable;
  final OnItemClick? onItemClick;
  final VoidCallback? onInitState;
  final VoidCallback? onDispose;

  const DoubleColumnItemWidget({
    super.key,
    required this.index,
    required this.liveInfo,
    required this.liveCoreController,
    required this.offstageListenable,
    this.onItemClick,
    this.onInitState,
    this.onDispose,
  });

  @override
  State<DoubleColumnItemWidget> createState() => _DoubleColumnItemWidgetState();
}

class _DoubleColumnItemWidgetState extends State<DoubleColumnItemWidget> {
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
    final index = widget.index;
    final liveInfo = widget.liveInfo;
    late final cellWidth = (1.screenWidth - 39.width) * 0.5;
    return Padding(
      padding: EdgeInsets.only(
        left: index % 2 == 0 ? 16.width : 3.5.width,
        right: index % 2 == 1 ? 16.width : 3.5.width,
        top: 8.height,
      ),
      child: GestureDetector(
        onTap: () => widget.onItemClick?.call(liveInfo),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(12.radius)),
          child: SizedBox(
            width: cellWidth,
            child: Stack(
              children: [
                // Cover
                Positioned.fill(child: _buildCoverWidget()),
                // RenderView
                Positioned.fill(child: _buildRenderWidget()),
                // Viewers
                Positioned(
                  left: 8.width,
                  top: 6.height,
                  child: _buildViewersWidget(),
                ),
                // Live Info
                Positioned(
                  left: 8.width,
                  right: 8.width,
                  bottom: 8.height,
                  child: _buildLiveInfoWidget(),
                ),
              ],
            ),
          ),
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

  Widget _buildCoverWidget() {
    final liveInfo = widget.liveInfo;
    final firstUrl = liveInfo.coverURL.split(';').first;
    final url = _isValidUrl(firstUrl) ? firstUrl : Constants.defaultCoverUrl;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return Image.asset(LiveImages.streamDefaultCover, fit: BoxFit.cover, package: Constants.pluginName);
      },
      errorWidget: (context, url, error) {
        return Image.asset(LiveImages.streamDefaultCover, fit: BoxFit.cover, package: Constants.pluginName);
      },
    );
  }

  Widget _buildViewersWidget() {
    final liveInfo = widget.liveInfo;
    return Row(
      children: [
        SizedBox(
          height: 8.radius,
          width: 8.radius,
          child: Image.asset(
            fit: BoxFit.fill,
            LiveImages.roomListItemLiveStatus,
            package: Constants.pluginName,
          ),
        ),
        SizedBox(width: 5.width),
        Text(
          LiveKitLocalizations.of(Global.appContext())!
              .livelist_viewed_audience_count
              .replaceAll('xxx', "${liveInfo.totalViewerCount}"),
          style: const TextStyle(
            color: LiveColors.designStandardFlowkitWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveInfoWidget() {
    final liveInfo = widget.liveInfo;
    final roomName =
        liveInfo.liveName.isNotEmpty ? liveInfo.liveName : liveInfo.liveID;
    final ownerName = liveInfo.liveOwner.userName.isNotEmpty
        ? liveInfo.liveOwner.userName
        : liveInfo.liveOwner.userID;
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 22 / 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.width),
        // Owner info
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.radius),
              child: SizedBox(
                width: 16.radius,
                height: 16.radius,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        )
      ],
    );
  }

  bool _isValidUrl(String urlString) {
    try {
      Uri parsedUri = Uri.parse(urlString);
      return parsedUri.scheme.isNotEmpty && parsedUri.host.isNotEmpty;
    } on FormatException {
      return false;
    }
  }
}
