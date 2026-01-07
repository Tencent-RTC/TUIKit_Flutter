import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controller for inline video player
/// Allows Flutter to control the native video player
class InlineVideoPlayerController extends ChangeNotifier {
  final String videoPath;
  final int width;
  final int height;
  
  MethodChannel? _channel;
  int? _viewId;
  
  bool _isPlaying = false;
  bool _isReady = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDisposed = false;
  
  bool get isPlaying => _isPlaying;
  bool get isReady => _isReady;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0 
      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) 
      : 0.0;
  
  InlineVideoPlayerController({
    required this.videoPath,
    this.width = 0,
    this.height = 0,
  });
  
  void _onViewCreated(int viewId) {
    _viewId = viewId;
    _channel = MethodChannel('io.trtc.tuikit.atomicx/inline_video_player_$viewId');
    _channel!.setMethodCallHandler(_handleMethodCall);
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (_isDisposed) return;
    
    switch (call.method) {
      case 'onReady':
        _isReady = true;
        final args = call.arguments as Map?;
        if (args != null) {
          _duration = Duration(milliseconds: (args['duration'] as num?)?.toInt() ?? 0);
        }
        notifyListeners();
        break;
      case 'onPlayingChanged':
        _isPlaying = call.arguments as bool? ?? false;
        notifyListeners();
        break;
      case 'onPositionChanged':
        final positionMs = call.arguments as int? ?? 0;
        _position = Duration(milliseconds: positionMs);
        notifyListeners();
        break;
      case 'onDurationChanged':
        final durationMs = call.arguments as int? ?? 0;
        _duration = Duration(milliseconds: durationMs);
        notifyListeners();
        break;
      case 'onCompleted':
        _isPlaying = false;
        _position = Duration.zero;
        notifyListeners();
        break;
      case 'onVideoSizeChanged':
        // Video size changed - can be used for aspect ratio if needed
        notifyListeners();
        break;
    }
  }
  
  Future<void> play() async {
    if (_channel == null || _isDisposed) return;
    try {
      await _channel!.invokeMethod('play');
    } catch (e) {
      debugPrint('InlineVideoPlayerController.play error: $e');
    }
  }
  
  Future<void> pause() async {
    if (_channel == null || _isDisposed) return;
    try {
      await _channel!.invokeMethod('pause');
    } catch (e) {
      debugPrint('InlineVideoPlayerController.pause error: $e');
    }
  }
  
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
  
  Future<void> seekTo(Duration position) async {
    if (_channel == null || _isDisposed) return;
    try {
      await _channel!.invokeMethod('seekTo', position.inMilliseconds);
      _position = position;
      notifyListeners();
    } catch (e) {
      debugPrint('InlineVideoPlayerController.seekTo error: $e');
    }
  }
  
  Future<void> seekToProgress(double progress) async {
    final targetPosition = Duration(
      milliseconds: (progress * _duration.inMilliseconds).toInt(),
    );
    await seekTo(targetPosition);
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}

/// Inline video player widget - only renders video, no controls
/// Controls are handled by Flutter layer
class InlineVideoPlayer extends StatefulWidget {
  final InlineVideoPlayerController controller;
  final BoxFit fit;
  
  const InlineVideoPlayer({
    super.key,
    required this.controller,
    this.fit = BoxFit.contain,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _buildAndroidView();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildIOSView();
    } else {
      return const Center(
        child: Text(
          'Platform not supported',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
  
  Widget _buildAndroidView() {
    const String viewType = 'io.trtc.tuikit.atomicx/inline_video_player';
    
    final Map<String, dynamic> creationParams = {
      'videoPath': widget.controller.videoPath,
      'width': widget.controller.width.toDouble(),
      'height': widget.controller.height.toDouble(),
    };

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: widget.controller._onViewCreated,
    );
  }
  
  Widget _buildIOSView() {
    const String viewType = 'io.trtc.tuikit.atomicx/inline_video_player';
    
    final Map<String, dynamic> creationParams = {
      'videoPath': widget.controller.videoPath,
      'width': widget.controller.width.toDouble(),
      'height': widget.controller.height.toDouble(),
    };

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: widget.controller._onViewCreated,
    );
  }
}

/// Video player with Flutter controls overlay
class InlineVideoPlayerWithControls extends StatefulWidget {
  final InlineVideoPlayerController controller;
  final bool showControls;
  final VoidCallback? onTap;
  
  const InlineVideoPlayerWithControls({
    super.key,
    required this.controller,
    this.showControls = true,
    this.onTap,
  });

  @override
  State<InlineVideoPlayerWithControls> createState() => _InlineVideoPlayerWithControlsState();
}

class _InlineVideoPlayerWithControlsState extends State<InlineVideoPlayerWithControls> {
  bool _showControlsOverlay = true;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
  
  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _toggleControls() {
    setState(() {
      _showControlsOverlay = !_showControlsOverlay;
    });
    widget.onTap?.call();
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          InlineVideoPlayer(controller: widget.controller),
          
          // Controls overlay
          if (widget.showControls && _showControlsOverlay)
            _buildControlsOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.5),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top spacer
          const SizedBox(height: 50),
          
          // Center play/pause button
          GestureDetector(
            onTap: () => widget.controller.togglePlayPause(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.controller.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          
          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }
  
  Widget _buildBottomControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Play/Pause button
            GestureDetector(
              onTap: () => widget.controller.togglePlayPause(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Current time
            Text(
              _formatDuration(widget.controller.position),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            
            // Progress bar
            Expanded(
              child: _buildProgressBar(),
            ),
            const SizedBox(width: 8),
            
            // Total time
            Text(
              _formatDuration(widget.controller.duration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        // Pause while dragging
      },
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        // Calculate progress based on the progress bar width
        // This is a simplified version - you may need to adjust based on actual layout
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final width = box.size.width - 120; // Approximate width excluding buttons and text
        final tapX = details.localPosition.dx - 60; // Offset for left controls
        final progress = (tapX / width).clamp(0.0, 1.0);
        widget.controller.seekToProgress(progress);
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background track
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Progress track
            FractionallySizedBox(
              widthFactor: widget.controller.progress,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: widget.controller.progress * (MediaQuery.of(context).size.width - 200),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
