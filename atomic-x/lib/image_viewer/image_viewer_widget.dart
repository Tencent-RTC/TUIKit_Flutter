import 'dart:async';
import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'image_element.dart';

typedef EventHandler = void Function(Map<String, dynamic> eventData, Function(dynamic) callback);

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

class _MediaItemView extends StatelessWidget {
  final ImageElement element;
  final bool isDownloading;
  final VoidCallback onPlayButtonTap;
  final VoidCallback onDownloadButtonTap;
  final VoidCallback onImageTap;

  const _MediaItemView({
    required this.element,
    required this.isDownloading,
    required this.onPlayButtonTap,
    required this.onDownloadButtonTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (element.isImage) {
          onImageTap();
        } else if (element.isVideo) {
          if (element.hasVideoFile) {
            onPlayButtonTap();
          } else if (!isDownloading) {
            onDownloadButtonTap();
          }
        }
      },
      onDoubleTap: () {
        onImageTap();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
          if (element.isVideo)
            Center(
              child: _PlayButtonView(
                element: element,
                isDownloading: isDownloading,
                onPlayTap: onPlayButtonTap,
                onDownloadTap: onDownloadButtonTap,
              ),
            ),
        ],
      ),
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
      child: Center(
        child: Icon(
          element.isImage ? Icons.image : Icons.videocam,
          color: Colors.grey,
          size: 80,
        ),
      ),
    );
  }
}

class _ToastView extends StatelessWidget {
  final String message;
  final bool isShowing;

  const _ToastView({
    required this.message,
    required this.isShowing,
  });

  @override
  Widget build(BuildContext context) {
    if (!isShowing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
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

class _VideoPlayerView extends StatefulWidget {
  final String videoPath;
  final VoidCallback onClose;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool hasPrevious;
  final bool hasNext;

  const _VideoPlayerView({
    required this.videoPath,
    required this.onClose,
    required this.onPrevious,
    required this.onNext,
    required this.hasPrevious,
    required this.hasNext,
  });

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      _startHideControlsTimer();
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            if (widget.hasPrevious) {
              widget.onPrevious();
            }
          } else if (details.primaryVelocity! < 0) {
            if (widget.hasNext) {
              widget.onNext();
            }
          }
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
            ),
            if (_showControls) ...[
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    widget.onClose();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
            if (_showControls && _isInitialized)
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                    _startHideControlsTimer();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
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

  bool _isShowingVideoPlayer = false;
  String? _currentVideoPath;
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
    if (_isShowingVideoPlayer) {
      setState(() {
        _isShowingVideoPlayer = false;
        _currentVideoPath = null;
      });
      return;
    }

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
    if (_isShowingVideoPlayer) {
      setState(() {
        _isShowingVideoPlayer = false;
        _currentVideoPath = null;
      });
    }

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

  void _playVideo(String videoPath) {
    setState(() {
      _currentVideoPath = videoPath;
      _isShowingVideoPlayer = true;
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
            _MediaItemView(
              element: _imageElements[_currentIndex],
              isDownloading: _downloadingVideoElements.contains(_imageElements[_currentIndex].imagePath),
              onPlayButtonTap: () {
                final element = _imageElements[_currentIndex];
                if (element.hasVideoFile) {
                  _playVideo(element.videoPath!);
                }
              },
              onDownloadButtonTap: () {
                _downloadVideo(_imageElements[_currentIndex]);
              },
              onImageTap: _onImageTap,
            )
          else
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is OverscrollNotification) {
                  // Detecting overscroll (boundary sliding)
                  final isAtStart = _currentIndex == 0 && notification.overscroll < 0;
                  final isAtEnd = _currentIndex == _imageElements.length - 1 && notification.overscroll > 0;

                  if (isAtStart || isAtEnd) {
                    _showNoMoreDataToastWithDebounce();
                  }
                }
                return false; // Do not prevent notifications from continuing to be delivered
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
                  return _MediaItemView(
                    element: element,
                    isDownloading: _downloadingVideoElements.contains(element.imagePath),
                    onPlayButtonTap: () {
                      if (element.hasVideoFile) {
                        _playVideo(element.videoPath!);
                      }
                    },
                    onDownloadButtonTap: () {
                      _downloadVideo(element);
                    },
                    onImageTap: _onImageTap,
                  );
                },
              ),
            ),
          if (_isShowingVideoPlayer && _currentVideoPath != null)
            _VideoPlayerView(
              videoPath: _currentVideoPath!,
              onClose: () {
                Navigator.of(context).pop();
              },
              onPrevious: () {
                if (_currentIndex > 0) {
                  setState(() {
                    _currentIndex--;
                    _pageController.animateToPage(
                      _currentIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                }
              },
              onNext: () {
                if (_currentIndex < _imageElements.length - 1) {
                  setState(() {
                    _currentIndex++;
                    _pageController.animateToPage(
                      _currentIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                }
              },
              hasPrevious: _currentIndex > 0,
              hasNext: _currentIndex < _imageElements.length - 1,
            ),
          Center(
            child: _LoadingIndicatorView(isShowing: _showLoadingIndicator),
          ),
        ],
      ),
    );
  }
}
