import 'package:atomic_x_core/api/message/message_action_store.dart';
import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/image_viewer/image_viewer.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/image_viewer_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_status_mixin.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

class ImageMessageWidget extends StatefulWidget {
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
  /// When this widget is rendered inside a merged-message detail page,
  /// the conversation-backed [messageListStore] is empty and the image
  /// viewer cannot page over the live history. Pass the merged bundle's
  /// own message list here so the viewer can render images / videos
  /// from the bundle directly.
  final List<MessageInfo>? mergedMediaMessages;

  static const double kImageFixedHeight = 160.0;

  const ImageMessageWidget({
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
    this.mergedMediaMessages,
  });

  @override
  State<ImageMessageWidget> createState() => _ImageMessageWidgetState();
}

class _ImageMessageWidgetState extends State<ImageMessageWidget> with MessageStatusMixin {
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
      presetMediaMessages: widget.mergedMediaMessages,
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
            _buildImageContent(colorsTheme),
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

  Widget _buildImageContent(SemanticColorScheme colorsTheme) {
    final imagePayload = widget.message.messagePayload as ImageMessagePayload?;
    String? originalImagePath = imagePayload?.originalImagePath;
    String? largeImagePath = imagePayload?.largeImagePath;
    String? thumbImagePath = imagePayload?.thumbImagePath;

    // Remote URL fallbacks. In the merged-forward detail view the bundle is
    // re-downloaded on every open and the local thumb files are transient /
    // may be gone the second time, so we must be able to render straight from
    // the server URL instead of getting stuck on the loading spinner
    // (bug#161210776). Local path always wins when present.
    String? thumbImageURL = imagePayload?.thumbImageURL;
    String? largeImageURL = imagePayload?.largeImageURL;
    String? originalImageURL = imagePayload?.originalImageURL;

    final bool hasLocalPath = (originalImagePath != null && originalImagePath.isNotEmpty) ||
        (largeImagePath != null && largeImagePath.isNotEmpty) ||
        (thumbImagePath != null && thumbImagePath.isNotEmpty);
    final bool hasRemoteURL = (thumbImageURL != null && thumbImageURL.isNotEmpty) ||
        (largeImageURL != null && largeImageURL.isNotEmpty) ||
        (originalImageURL != null && originalImageURL.isNotEmpty);

    if (!hasLocalPath && !hasRemoteURL) {
      if (widget.messageListStore != null && widget.message.rawMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MessageActionStore.create(widget.message).downloadMedia(quality: MediaQuality.thumbnail);
        });

        return Container(
          width: 200,
          height: ImageMessageWidget.kImageFixedHeight,
          decoration: BoxDecoration(
            color: colorsTheme.bgColorTopBar,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorsTheme.buttonColorPrimaryDefault),
            ),
          ),
        );
      }
    }

    final double aspectRatio = (widget.message.messagePayload as ImageMessagePayload?)?.originalImageWidth != null &&
            (widget.message.messagePayload as ImageMessagePayload?)?.originalImageHeight != null &&
            (widget.message.messagePayload as ImageMessagePayload).originalImageHeight > 0
        ? (widget.message.messagePayload as ImageMessagePayload).originalImageWidth / (widget.message.messagePayload as ImageMessagePayload).originalImageHeight
        : 1.0;

    double displayHeight = ImageMessageWidget.kImageFixedHeight;
    double displayWidth = displayHeight * aspectRatio;

    if (displayWidth > widget.maxWidth) {
      displayWidth = widget.maxWidth;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: displayWidth,
        height: displayHeight,
        child: (() {
          // Prefer any available local file, then fall back to a remote URL.
          String? displayPath;
          if (originalImagePath != null && originalImagePath.isNotEmpty) {
            displayPath = originalImagePath;
          } else if (largeImagePath != null && largeImagePath.isNotEmpty) {
            displayPath = largeImagePath;
          } else if (thumbImagePath != null && thumbImagePath.isNotEmpty) {
            displayPath = thumbImagePath;
          } else if (thumbImageURL != null && thumbImageURL.isNotEmpty) {
            displayPath = thumbImageURL;
          } else if (largeImageURL != null && largeImageURL.isNotEmpty) {
            displayPath = largeImageURL;
          } else if (originalImageURL != null && originalImageURL.isNotEmpty) {
            displayPath = originalImageURL;
          }

          if (displayPath != null) {
            if (displayPath.startsWith('http')) {
              return Image.network(
                displayPath,
                width: displayWidth,
                height: displayHeight,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colorsTheme.buttonColorPrimaryDefault),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorsTheme.bgColorTopBar,
                    child: Center(
                      child: Icon(Icons.broken_image, color: colorsTheme.textColorSecondary),
                    ),
                  );
                },
              );
            } else {
              return Image.file(
                File(displayPath),
                width: displayWidth,
                height: displayHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorsTheme.bgColorTopBar,
                    child: Center(
                      child: Icon(Icons.broken_image, color: colorsTheme.textColorSecondary),
                    ),
                  );
                },
              );
            }
          } else {
            return Container(
              color: colorsTheme.bgColorTopBar,
              child: Center(
                child: Icon(Icons.broken_image, color: colorsTheme.textColorSecondary),
              ),
            );
          }
        })(),
      ),
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
}
