import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'inline_video_player.dart';
import 'video_player.dart';

/// Full-screen video player widget with controls
/// 
/// This widget uses InlineVideoPlayer with Flutter controls overlay,
/// thumbnail support, and back button.
class VideoPlayerWidget extends StatefulWidget {
  final VideoData video;
  final VoidCallback? onClose;
  /// Whether to show the close button (default: true)
  final bool showCloseButton;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late InlineVideoPlayerController _controller;
  bool _showControls = true;
  bool _showThumbnail = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = InlineVideoPlayerController(
      videoPath: widget.video.localPath!,
      width: widget.video.width,
      height: widget.video.height,
    );
    _controller.addListener(_onPlayerUpdate);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.removeListener(_onPlayerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (!mounted) return;
    
    setState(() {
      // Hide thumbnail when playing, show when paused/completed
      if (_controller.isPlaying) {
        _showThumbnail = false;
      } else if (_controller.position == Duration.zero && !_controller.isPlaying) {
        // Show thumbnail when at start and not playing (completed or initial state)
        _showThumbnail = true;
      }
    });
  }

  void _togglePlayPause() {
    _controller.togglePlayPause();
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onTap() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _controller.isPlaying) {
      _hideControlsTimer?.cancel();
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video player - centered with padding for controls
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 50, // Space for close button
                bottom: 80, // Space for progress bar
              ),
              child: InlineVideoPlayer(controller: _controller),
            ),
          ),
          
          // Thumbnail overlay (shown before playing and after completion)
          if (_showThumbnail)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 50,
                  bottom: 80,
                ),
                child: _buildThumbnail(),
              ),
            ),
          
          // Controls overlay - handles its own tap events
          if (_showControls)
            Positioned.fill(child: _buildControlsOverlay()),
          
          // Tap area when controls are hidden
          if (!_showControls)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _onTap,
                child: Container(color: Colors.transparent),
              ),
            ),
          
          // Close button overlay (conditionally visible)
          if (widget.showCloseButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: GestureDetector(
                onTap: _onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
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
      ),
    );
  }

  Widget _buildThumbnail() {
    // Prefer snapshot file if available
    if (widget.video.hasSnapshotFile) {
      return Image.file(
        File(widget.video.snapshotLocalPath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
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

  Widget _buildControlsOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onTap,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            
            // Center play/pause button
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            
            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Current time
              Text(
                _formatDuration(_controller.position),
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
                _formatDuration(_controller.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbPosition = (_controller.progress * width).clamp(0.0, width);
        
        return GestureDetector(
          onTapDown: (details) {
            final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);
            _controller.seekToProgress(progress);
            _showControlsTemporarily();
          },
          onHorizontalDragUpdate: (details) {
            final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);
            _controller.seekToProgress(progress);
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
                Container(
                  height: 4,
                  width: thumbPosition,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Thumb
                Positioned(
                  left: (thumbPosition - 6).clamp(0.0, width - 12),
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
      },
    );
  }
}
