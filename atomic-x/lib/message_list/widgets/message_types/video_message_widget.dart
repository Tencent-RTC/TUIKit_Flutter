import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/image_viewer/image_viewer.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/widgets/image_viewer_manager.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_status_mixin.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

class VideoMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final String conversationID;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MessageListStore? messageListStore;
  final GlobalKey? bubbleKey;
  final MessageListConfigProtocol config;
  final bool isInMergedDetailView;

  static const double kVideoFixedHeight = 160.0;

  const VideoMessageWidget({
    super.key,
    required this.message,
    required this.conversationID,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onTap,
    this.onLongPress,
    this.messageListStore,
    this.bubbleKey,
    this.isInMergedDetailView = false,
  });

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> with MessageStatusMixin {
  ImageViewerManager? _imageViewerManager;

  @override
  void initState() {
    super.initState();
    _initializeImageViewerManager();
  }

  void _initializeImageViewerManager() {
    if (widget.message.rawMessage == null) return;

    _imageViewerManager = ImageViewerManager(
      conversationID: widget.conversationID,
      currentMessage: widget.message,
      context: context,
    );
  }

  @override
  void dispose() {
    _imageViewerManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    final statusAndTimeWidgets = buildStatusAndTimeWidgets(
      message: widget.message,
      isSelf: widget.isSelf,
      colors: colorsTheme,
      isOverlay: true,
      isShowTimeInBubble: widget.config.isShowTimeInBubble,
      enableReadReceipt: widget.config.enableReadReceipt,
      isInMergedDetailView: widget.isInMergedDetailView,
    );

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: Container(
        key: widget.bubbleKey,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
        ),
        margin: EdgeInsets.zero,
        child: Stack(
          children: [
            _buildVideoContent(colorsTheme),
            if (statusAndTimeWidgets.isNotEmpty)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorsTheme.bgColorDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: statusAndTimeWidgets,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    widget.onTap?.call();
    _showImageViewer();
  }

  Widget _buildVideoContent(SemanticColorScheme colorsTheme) {
    final String? videoSnapshotPath = widget.message.messageBody?.videoSnapshotPath;

    if ((videoSnapshotPath == null || videoSnapshotPath.isEmpty) &&
        widget.messageListStore != null &&
        widget.message.rawMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.messageListStore!.downloadMessageResource(
          message: widget.message,
          resourceType: MessageMediaFileType.videoSnapshot,
        );
      });
    }

    double displayHeight = VideoMessageWidget.kVideoFixedHeight;
    double displayWidth = 240;

    if (widget.message.messageBody?.videoSnapshotWidth != null &&
        widget.message.messageBody?.videoSnapshotHeight != null &&
        widget.message.messageBody!.videoSnapshotHeight > 0) {
      double aspectRatio =
          widget.message.messageBody!.videoSnapshotWidth / widget.message.messageBody!.videoSnapshotHeight;
      displayWidth = displayHeight * aspectRatio;

      if (displayWidth > widget.maxWidth) {
        displayWidth = widget.maxWidth;
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: _buildImageWithFallback(
              context,
              videoSnapshotPath,
              displayWidth,
              displayHeight,
              Icon(Icons.video_library, color: colorsTheme.textColorSecondary, size: 40),
            ),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorsTheme.bgColorDefault,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow,
            color: colorsTheme.textColorAntiPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Future<void> _showImageViewer() async {
    if (_imageViewerManager == null) return;

    await _imageViewerManager!.showImageViewerIfAvailable();

    if (_imageViewerManager!.initialImageElements.isNotEmpty && mounted) {
      ImageViewer.view(
        context,
        imageElements: _imageViewerManager!.initialImageElements,
        initialIndex: _imageViewerManager!.initialImageIndex,
        onEventTriggered: _imageViewerManager!.handleImageViewerEvent,
      );
    }
  }

  Widget _buildImageWithFallback(
      BuildContext context, String? imagePath, double width, double height, Widget fallback) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: colorsTheme.bgColorTopBar,
        child: Center(child: fallback),
      );
    }

    return imagePath.startsWith('http')
        ? Image.network(
            imagePath,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: colorsTheme.bgColorTopBar,
                child: Center(child: fallback),
              );
            },
          )
        : Image.file(
            File(imagePath),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: colorsTheme.bgColorTopBar,
                child: Center(child: fallback),
              );
            },
          );
  }
}
