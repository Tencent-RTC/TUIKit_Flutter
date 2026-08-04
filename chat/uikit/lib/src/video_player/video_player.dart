import 'dart:io';
import 'package:flutter/material.dart';
import '../file_picker/file_picker_platform.dart';
import 'video_player_widget.dart';

class VideoData {
  final String? localPath;
  final String? url;
  final String? snapshotLocalPath;
  final String? snapshotUrl;
  final int duration;
  final int width;
  final int height;

  VideoData({
    this.localPath,
    this.url,
    this.snapshotLocalPath,
    this.snapshotUrl,
    this.duration = 0,
    this.width = 0,
    this.height = 0,
  });
  
  /// Get the video path (prefer local path over URL)
  String? get videoPath => localPath ?? url;
  
  /// Get the snapshot path (prefer local path over URL)
  String? get snapshotPath => snapshotLocalPath ?? snapshotUrl;
  
  /// Check if video file exists locally
  bool get hasLocalFile => localPath != null && localPath!.isNotEmpty && File(localPath!).existsSync();
  
  /// Check if snapshot file exists locally
  bool get hasSnapshotFile => snapshotLocalPath != null && snapshotLocalPath!.isNotEmpty && File(snapshotLocalPath!).existsSync();
}

class VideoPlayer {
  /// Play video in a Flutter-based full-screen player with controls
  /// 
  /// This method launches a full-screen video player using InlineVideoPlayer
  /// with Flutter controls overlay, thumbnail support, and back button.
  /// 
  /// Usage:
  /// ```dart
  /// await VideoPlayer.play(
  ///   context,
  ///   video: VideoData(
  ///     localPath: '/path/to/video.mp4',
  ///     snapshotLocalPath: '/path/to/thumbnail.jpg',
  ///     width: 1920,
  ///     height: 1080,
  ///   ),
  /// );
  /// ```
  static Future<void> play(
    BuildContext context, {
    required VideoData video,
  }) async {
    if (video.videoPath == null || video.videoPath!.isEmpty) {
      debugPrint('VideoPlayer.play: No video path available');
      return;
    }
    
    if (!video.hasLocalFile) {
      debugPrint('VideoPlayer.play: Video file does not exist: ${video.localPath}');
      return;
    }

    // HarmonyOS 上 Flutter-OH 的 PlatformView 还不成熟,VideoPlayerWidget 内部依赖
    // AndroidView / UiKitView 都无法工作。降级方案:直接把本地视频文件交给系统视频播放器
    // (复用 file_picker 已经实现的 openFile,底层是 startAbility viewData)。
    if (Platform.operatingSystem == 'ohos') {
      final opened = await FilePickerPlatform.openFile(video.localPath!);
      if (!opened) {
        debugPrint('VideoPlayer.play: system player failed to open ${video.localPath}');
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerWidget(video: video),
      ),
    );
  }
}
