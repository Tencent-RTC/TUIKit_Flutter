import 'dart:async';
import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart' hide IconButton;
import 'package:tuikit_atomic_x/video_player/video_player.dart';
import 'package:tuikit_atomic_x/video_player/video_player_widget.dart';
import 'package:flutter/material.dart';

import 'image_element.dart';

typedef EventHandler = void Function(Map<String, dynamic> eventData, Function(dynamic) callback);

/// Play button overlay for videos that need to be downloaded
class _PlayButtonView extends StatelessWidget {
  final ImageElement element;
  final bool isDownloading;
  final VoidCallback onPlayTap;
  final VoidCallback onDownloadTap;

  const _PlayButtonView({
    required this.element,
    required this.isDownloading,
    required this.onPlayTap,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (element.hasVideoFile) {
          onPlayTap();
        } else if (!isDownloading) {
          onDownloadTap();
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isDownloading
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  element.hasVideoFile ? Icons.play_arrow : Icons.download,
                  color: Colors.white,
                  size: 40,
                ),
        ),
      ),
    );
  }
}

/// Image item view (for images only) with pinch-to-zoom and double-tap-to-zoom
class _ImageItemView extends StatefulWidget {
  final ImageElement element;
  final VoidCallback onTap;
  final ValueChanged<bool>? onZoomChanged;

  const _ImageItemView({
    required this.element,
    required this.onTap,
    this.onZoomChanged,
  });

  @override
  State<_ImageItemView> createState() => _ImageItemViewState();
}

class _ImageItemViewState extends State<_ImageItemView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Current committed scale & offset (updated on gesture end / animation)
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Whether currently zoomed in (for notifying parent)
  bool _isZoomed = false;

  // Tracking values during an active gesture
  double _gestureStartScale = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset? _scaleStartFocalPoint;

  // Double tap
  TapDownDetails? _doubleTapDetails;
  Size _viewportSize = Size.zero;

  // Actual image intrinsic size (loaded asynchronously)
  Size? _imageSize;

  // Animation
  double _animStartScale = 1.0;
  Offset _animStartOffset = Offset.zero;
  double _animEndScale = 1.0;
  Offset _animEndOffset = Offset.zero;

  static const double _doubleTapZoomScale = 2.5;
  static const double _maxScale = 5.0;
  static const double _minScale = 0.6;

  /// Elastic resistance factor for overscroll drag (0.0 ~ 1.0).
  /// Smaller = more resistance. 0.35 gives a natural rubber-band feel.
  static const double _elasticFactor = 0.35;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(_onAnimate);
    _loadImageSize();
  }

  /// Load the intrinsic image dimensions so we can correctly calculate
  /// how much room the image actually occupies inside the viewport (BoxFit.contain).
  void _loadImageSize() {
    final file = File(widget.element.imagePath);
    if (!file.existsSync()) return;
    final image = Image.file(file);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Notify parent when zoomed state changes
  void _updateZoomState(bool zoomed) {
    if (_isZoomed != zoomed) {
      _isZoomed = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  // ─── Animation ───

  void _onAnimate() {
    final t =
        Curves.easeInOut.transform(_animationController.value);
    final newScale = _animStartScale + (_animEndScale - _animStartScale) * t;
    setState(() {
      _scale = newScale;
      _offset = Offset.lerp(
          Offset(_animStartOffset.dx, _animStartOffset.dy),
          Offset(_animEndOffset.dx, _animEndOffset.dy),
          t)!;
    });
    _updateZoomState(newScale > 1.01);
  }

  void _animateTo(double targetScale, Offset targetOffset) {
    _animStartScale = _scale;
    _animStartOffset = _offset;
    _animEndScale = targetScale;
    _animEndOffset = targetOffset;
    _animationController.forward(from: 0);
  }

  // ─── Offset clamping ───

  /// Compute the fitted image size under BoxFit.contain.
  /// Returns the actual display size of the image at scale=1.0 within the viewport.
  Size _fittedImageSize() {
    if (_imageSize == null || _viewportSize == Size.zero) {
      // Fallback: assume image fills viewport
      return _viewportSize;
    }
    final double imgW = _imageSize!.width;
    final double imgH = _imageSize!.height;
    final double viewW = _viewportSize.width;
    final double viewH = _viewportSize.height;
    final double scaleX = viewW / imgW;
    final double scaleY = viewH / imgH;
    final double fitScale = scaleX < scaleY ? scaleX : scaleY;
    return Size(imgW * fitScale, imgH * fitScale);
  }

  /// Hard clamp: offset so the scaled image never leaves the viewport.
  /// Uses the actual fitted image size (BoxFit.contain) for correct boundary calculation.
  ///
  /// The Transform scales a viewport-sized container. The image (BoxFit.contain)
  /// is centered inside that container. So after scaling, the image occupies
  /// `fitted * scale` pixels, centered inside a `viewport * scale` box.
  /// The offset we apply is a translate on that box. We need to ensure the
  /// **image edges** (not the box edges) never recede into the viewport.
  ///
  /// - scale <= 1.0: image is centered, offset forced to center position.
  /// - scale > 1.0: for each axis, if scaled content > viewport → clamp so
  ///                image edges stay outside viewport edges;
  ///                if scaled content <= viewport → center on that axis.
  Offset _clampOffset(Offset offset, double scale) {
    if (_viewportSize == Size.zero) return offset;
    final double viewW = _viewportSize.width;
    final double viewH = _viewportSize.height;

    if (scale <= 1.0) {
      // Center the scaled-down image
      return Offset(
        (viewW - viewW * scale) / 2,
        (viewH - viewH * scale) / 2,
      );
    }

    // Use actual fitted image dimensions
    final fitted = _fittedImageSize();
    final double contentW = fitted.width * scale;
    final double contentH = fitted.height * scale;

    // The scaled container is viewport * scale.
    // The image is centered inside it, so the image starts at
    // (scaledBox - content) / 2 within the scaled box.
    // In viewport coordinates the image's top-left is at:
    //   imageLeft = offset.dx + (scaledBoxW - contentW) / 2
    //   imageTop  = offset.dy + (scaledBoxH - contentH) / 2
    // We want:
    //   imageLeft <= 0          (image left edge at or left of viewport left)
    //   imageLeft + contentW >= viewW  (image right edge at or right of viewport right)
    // Which gives:
    //   offset.dx <= -(scaledBoxW - contentW) / 2
    //   offset.dx >= viewW - contentW - (scaledBoxW - contentW) / 2
    // Simplify:
    //   let padX = (scaledBoxW - contentW) / 2
    //   maxDx = -padX
    //   minDx = viewW - contentW - padX = -(contentW - viewW) - padX

    double dx;
    double dy;

    // Horizontal axis
    if (contentW > viewW) {
      final double scaledBoxW = viewW * scale;
      final double padX = (scaledBoxW - contentW) / 2;
      final double maxDx = -padX;
      final double minDx = -(contentW - viewW) - padX;
      dx = offset.dx.clamp(minDx, maxDx);
    } else {
      // Image narrower than or equal to viewport after scaling: center horizontally
      final double scaledBoxW = viewW * scale;
      dx = (viewW - scaledBoxW) / 2;
    }

    // Vertical axis
    if (contentH > viewH) {
      final double scaledBoxH = viewH * scale;
      final double padY = (scaledBoxH - contentH) / 2;
      final double maxDy = -padY;
      final double minDy = -(contentH - viewH) - padY;
      dy = offset.dy.clamp(minDy, maxDy);
    } else {
      // Image shorter than viewport after scaling: center vertically
      final double scaledBoxH = viewH * scale;
      dy = (viewH - scaledBoxH) / 2;
    }

    return Offset(dx, dy);
  }

  /// Elastic offset: allows overscroll with rubber-band resistance.
  /// Returns the raw offset with elastic damping applied to the out-of-bounds portion.
  /// The boundary calculation must mirror [_clampOffset] exactly.
  Offset _elasticOffset(Offset rawOffset, double scale) {
    if (_viewportSize == Size.zero || scale <= 1.0) {
      return _clampOffset(rawOffset, scale);
    }

    final double viewW = _viewportSize.width;
    final double viewH = _viewportSize.height;
    final fitted = _fittedImageSize();
    final double contentW = fitted.width * scale;
    final double contentH = fitted.height * scale;

    double dx = rawOffset.dx;
    double dy = rawOffset.dy;

    // Horizontal axis
    if (contentW > viewW) {
      final double scaledBoxW = viewW * scale;
      final double padX = (scaledBoxW - contentW) / 2;
      final double maxDx = -padX;
      final double minDx = -(contentW - viewW) - padX;
      if (dx < minDx) {
        dx = minDx + (dx - minDx) * _elasticFactor;
      } else if (dx > maxDx) {
        dx = maxDx + (dx - maxDx) * _elasticFactor;
      }
    } else {
      // Content narrower than viewport: center with elastic
      final double scaledBoxW = viewW * scale;
      final double center = (viewW - scaledBoxW) / 2;
      if (dx != center) {
        dx = center + (dx - center) * _elasticFactor;
      }
    }

    // Vertical axis
    if (contentH > viewH) {
      final double scaledBoxH = viewH * scale;
      final double padY = (scaledBoxH - contentH) / 2;
      final double maxDy = -padY;
      final double minDy = -(contentH - viewH) - padY;
      if (dy < minDy) {
        dy = minDy + (dy - minDy) * _elasticFactor;
      } else if (dy > maxDy) {
        dy = maxDy + (dy - maxDy) * _elasticFactor;
      }
    } else {
      // Content shorter than viewport: center with elastic
      final double scaledBoxH = viewH * scale;
      final double center = (viewH - scaledBoxH) / 2;
      if (dy != center) {
        dy = center + (dy - center) * _elasticFactor;
      }
    }

    return Offset(dx, dy);
  }

  // ─── Gesture handlers ───

  void _onScaleStart(ScaleStartDetails details) {
    _animationController.stop();
    _gestureStartScale = _scale;
    _gestureStartOffset = _offset;
    _scaleStartFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // New scale
      double newScale =
          (_gestureStartScale * details.scale).clamp(_minScale, _maxScale);

      if (_scaleStartFocalPoint == null) return;

      if (details.scale == 1.0 && _gestureStartScale <= 1.0) {
        // Single-finger pan at original size → do nothing (no pan allowed)
        return;
      }

      // Focal point delta for panning
      final Offset focalDelta =
          details.focalPoint - _scaleStartFocalPoint!;

      Offset newOffset;
      if (details.pointerCount >= 2) {
        // Pinch: scale around the focal point on screen
        final double scaleChange = newScale / _gestureStartScale;
        newOffset = Offset(
          _scaleStartFocalPoint!.dx -
              (_scaleStartFocalPoint!.dx - _gestureStartOffset.dx) *
                  scaleChange +
              focalDelta.dx,
          _scaleStartFocalPoint!.dy -
              (_scaleStartFocalPoint!.dy - _gestureStartOffset.dy) *
                  scaleChange +
              focalDelta.dy,
        );
        // Pinch zoom: hard clamp (no elastic needed)
        _scale = newScale;
        _offset = _clampOffset(newOffset, newScale);
      } else {
        // Single-finger pan (only when zoomed in)
        newOffset = _gestureStartOffset + focalDelta;
        _scale = newScale;
        // Allow elastic overscroll on single-finger drag when zoomed in
        _offset = _elasticOffset(newOffset, newScale);
      }

      _updateZoomState(newScale > 1.01);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_scale < 1.0) {
      // Snap back to original size, centered
      _animateTo(1.0, Offset.zero);
      _updateZoomState(false);
    } else if (_scale <= 1.01) {
      // Ensure offset is zero at original scale
      if (_offset != Offset.zero) {
        _animateTo(1.0, Offset.zero);
      }
      _updateZoomState(false);
    } else {
      // Zoomed in: always snap back to clamped position.
      // Use distance threshold instead of exact equality to handle floating-point
      // precision issues from elastic offset calculations.
      final clamped = _clampOffset(_offset, _scale);
      final double dist = (_offset - clamped).distance;
      if (dist > 0.5) {
        _animateTo(_scale, clamped);
      }
    }
  }

  // ─── Double tap ───

  void _handleDoubleTap() {
    if (_scale > 1.0 + 0.1) {
      // Currently zoomed in → reset to original
      _animateTo(1.0, Offset.zero);
      _updateZoomState(false);
    } else {
      // Zoom to 2.5x at tap position
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const double targetScale = _doubleTapZoomScale;

      // Calculate offset so the tapped point stays in the same position
      Offset targetOffset = Offset(
        position.dx - position.dx * targetScale,
        position.dy - position.dy * targetScale,
      );
      targetOffset = _clampOffset(targetOffset, targetScale);

      _animateTo(targetScale, targetOffset);
      _updateZoomState(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return ClipRect(
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onDoubleTapDown: (details) {
              _doubleTapDetails = details;
            },
            onDoubleTap: _handleDoubleTap,
            onTap: () {
              // Only allow tap-to-close when at original scale
              if (_scale <= 1.0 + 0.1) {
                widget.onTap();
              }
            },
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.transparent, // Ensure hit testing works
              child: Transform(
                transform: Matrix4.identity()
                  // ignore: deprecated_member_use
                  ..translate(_offset.dx, _offset.dy)
                  // ignore: deprecated_member_use
                  ..scale(_scale),
                child: _buildImage(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage() {
    if (File(widget.element.imagePath).existsSync()) {
      return Image.file(
        File(widget.element.imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    } else {
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 80,
        ),
      ),
    );
  }
}

/// Video item view using VideoPlayerWidget
class _VideoItemView extends StatelessWidget {
  final ImageElement element;
  final bool isDownloading;
  final bool isCurrentPage;
  final VoidCallback onDownloadTap;
  final VoidCallback onClose;

  const _VideoItemView({
    required this.element,
    required this.isDownloading,
    required this.isCurrentPage,
    required this.onDownloadTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // If video file doesn't exist, show thumbnail with download button
    if (!element.hasVideoFile) {
      return _buildThumbnailWithButton();
    }

    // Video file exists - use VideoPlayerWidget
    return VideoPlayerWidget(
      video: VideoData(
        localPath: element.videoPath,
        snapshotLocalPath: element.imagePath,
      ),
      onClose: onClose,
      showCloseButton: true,
    );
  }

  Widget _buildThumbnailWithButton() {
    return GestureDetector(
      onTap: () {
        if (!isDownloading) {
          onDownloadTap();
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _buildThumbnail()),
            Center(
              child: _PlayButtonView(
                element: element,
                isDownloading: isDownloading,
                onPlayTap: () {},
                onDownloadTap: onDownloadTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (File(element.imagePath).existsSync()) {
      return Image.file(
        File(element.imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    } else {
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.videocam,
          color: Colors.grey,
          size: 80,
        ),
      ),
    );
  }
}

class _LoadingIndicatorView extends StatelessWidget {
  final bool isShowing;

  const _LoadingIndicatorView({required this.isShowing});

  @override
  Widget build(BuildContext context) {
    if (!isShowing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'loading...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageViewerWidget extends StatefulWidget {
  final List<ImageElement> imageElements;
  final int initialIndex;
  final EventHandler onEventTriggered;

  const ImageViewerWidget({
    Key? key,
    required this.imageElements,
    this.initialIndex = 0,
    required this.onEventTriggered,
  }) : super(key: key);

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  late List<ImageElement> _imageElements;
  late int _currentIndex;
  late int _previousIndex;
  late PageController _pageController;

  bool _isLoadingOlder = false;
  bool _isLoadingNewer = false;
  bool _isUpdatingData = false;

  bool _showLoadingIndicator = false;
  Timer? _loadingTimer;

  final Set<String> _downloadingVideoElements = {};

  Timer? _overscrollToastTimer;
  DateTime? _lastOverscrollTime;

  /// Whether the current image is zoomed in (scale > 1.0).
  /// When true, PageView scrolling is disabled so the user can pan the image.
  bool _isImageZoomed = false;

  @override
  void initState() {
    super.initState();
    _imageElements = List.from(widget.imageElements);
    _currentIndex = widget.initialIndex.clamp(0, _imageElements.length - 1);
    _previousIndex = _currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loadingTimer?.cancel();
    _overscrollToastTimer?.cancel();
    super.dispose();
  }

  void _onImageTap() {
    Navigator.of(context).pop();
  }

  void _onLoadMore(bool isOlder, Function(List<ImageElement>, bool) completion) {
    widget.onEventTriggered({
      'event': 'onLoadMore',
      'param': {'isOlder': isOlder}
    }, (result) {
      if (result is Map<String, dynamic>) {
        final elements = (result['elements'] as List).cast<ImageElement>();
        final hasMoreData = result['hasMoreData'] as bool;
        completion(elements, hasMoreData);
      } else {
        completion([], false);
      }
    });
  }

  void _onDownloadVideo(String imagePath, Function(String?) completion) {
    widget.onEventTriggered({
      'event': 'onDownloadVideo',
      'param': {'path': imagePath}
    }, (result) {
      if (result is List && result.isNotEmpty) {
        completion(result.first as String?);
      } else {
        completion(null);
      }
    });
  }

  void _handleIndexChange(int newIndex) {
    _checkIfLoadMore(newIndex, _previousIndex);
    _previousIndex = newIndex;
  }

  void _checkIfLoadMore(int newIndex, int previousIndex) {
    const preloadThreshold = 1;
    final isSwipingLeft = newIndex < previousIndex;
    final isSwipingRight = newIndex > previousIndex;

    if (newIndex < preloadThreshold && isSwipingLeft && !_isLoadingOlder) {
      _isLoadingOlder = true;
      _startLoadingTimer();

      _onLoadMore(true, (newElementsData, hasMore) {
        _handleLoadMoreResponse(newElementsData, true);
      });
    } else if (newIndex >= (_imageElements.length - preloadThreshold) && isSwipingRight && !_isLoadingNewer) {
      _isLoadingNewer = true;
      _startLoadingTimer();

      _onLoadMore(false, (newElementsData, hasMore) {
        _handleLoadMoreResponse(newElementsData, false);
      });
    }
  }

  void _handleLoadMoreResponse(List<ImageElement> newElementsData, bool isOlder) {
    _cancelLoadingTimer();

    final newElements = newElementsData;

    if (newElements.isNotEmpty) {
      _updateImageElements(newElements, isOlder);
    }

    setState(() {
      if (isOlder) {
        _isLoadingOlder = false;
      } else {
        _isLoadingNewer = false;
      }
    });
  }

  void _updateImageElements(List<ImageElement> newElements, bool isOlder) {
    setState(() {
      _isUpdatingData = true;
    });

    setState(() {
      final currentElement = _imageElements[_currentIndex];
      final currentElementSignature = _getElementSignature(currentElement);

      _imageElements = newElements;

      final newIndex = _findElementIndex(newElements, currentElementSignature);
      if (newIndex != -1) {
        _currentIndex = newIndex;
        debugPrint('new position: $newIndex');
      } else {
        _currentIndex = _currentIndex.clamp(0, _imageElements.length - 1);
        debugPrint('not found，use _currentIndex: $_currentIndex');
      }

      _pageController.jumpToPage(_currentIndex);

      _isUpdatingData = false;
    });
  }

  String _getElementSignature(ImageElement element) {
    return '${element.type}_${element.imagePath}_${element.videoPath ?? ""}';
  }

  int _findElementIndex(List<ImageElement> elements, String signature) {
    for (int i = 0; i < elements.length; i++) {
      final elementSignature = _getElementSignature(elements[i]);
      if (elementSignature == signature) {
        return i;
      }
    }
    return -1;
  }

  void _startLoadingTimer() {
    _cancelLoadingTimer();
    _loadingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLoadingIndicator = true;
        });
      }
    });
  }

  void _cancelLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    setState(() {
      _showLoadingIndicator = false;
    });
  }

  void _showNoMoreDataToastWithDebounce() {
    final now = DateTime.now();

    if (_lastOverscrollTime != null && now.difference(_lastOverscrollTime!).inMilliseconds < 1000) {
      return;
    }

    _lastOverscrollTime = now;

    _overscrollToastTimer?.cancel();

    _overscrollToastTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        AtomicLocalizations atomicLocalizations = AtomicLocalizations.of(context);
        Toast.info(context, atomicLocalizations.noMore);
      }
    });
  }

  void _downloadVideo(ImageElement element) {
    if (!element.isVideo || element.hasVideoFile || _downloadingVideoElements.contains(element.imagePath)) {
      return;
    }

    setState(() {
      _downloadingVideoElements.add(element.imagePath);
    });

    _onDownloadVideo(element.imagePath, (videoPath) {
      setState(() {
        _downloadingVideoElements.remove(element.imagePath);
      });

      if (videoPath != null && videoPath.isNotEmpty) {
        final index = _imageElements.indexWhere((e) => e.imagePath == element.imagePath);
        if (index != -1) {
          setState(() {
            _imageElements[index] = ImageElement(
              type: element.type,
              imagePath: element.imagePath,
              videoPath: videoPath,
            );
          });
        }
      } else {
        debugPrint('_onDownloadVideo failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isUpdatingData && _currentIndex < _imageElements.length)
            _buildMediaItem(_imageElements[_currentIndex], _currentIndex)
          else
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is OverscrollNotification) {
                  final isAtStart = _currentIndex == 0 && notification.overscroll < 0;
                  final isAtEnd = _currentIndex == _imageElements.length - 1 && notification.overscroll > 0;

                  if (isAtStart || isAtEnd) {
                    _showNoMoreDataToastWithDebounce();
                  }
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _imageElements.length,
                physics: _isImageZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _handleIndexChange(index);
                },
                itemBuilder: (context, index) {
                  final element = _imageElements[index];
                  return _buildMediaItem(element, index);
                },
              ),
            ),
          
          // Loading indicator
          Center(
            child: _LoadingIndicatorView(isShowing: _showLoadingIndicator),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(ImageElement element, int index) {
    final isCurrentPage = index == _currentIndex;
    
    if (element.isImage) {
      return _ImageItemView(
        element: element,
        onTap: _onImageTap,
        onZoomChanged: (isZoomed) {
          if (_isImageZoomed != isZoomed) {
            setState(() {
              _isImageZoomed = isZoomed;
            });
          }
        },
      );
    } else if (element.isVideo) {
      return _VideoItemView(
        element: element,
        isDownloading: _downloadingVideoElements.contains(element.imagePath),
        isCurrentPage: isCurrentPage,
        onDownloadTap: () => _downloadVideo(element),
        onClose: _onImageTap,
      );
    }
    
    return const SizedBox.shrink();
  }
}
