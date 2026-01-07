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

/// Image item view (for images only)
class _ImageItemView extends StatelessWidget {
  final ImageElement element;
  final VoidCallback onTap;

  const _ImageItemView({
    required this.element,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
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
