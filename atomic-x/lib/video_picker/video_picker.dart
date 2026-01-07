import 'package:flutter/material.dart';

import '../album_picker/album_picker.dart';

class VideoPickerModel {
  final int id;
  final String mediaPath;
  final int fileSize;
  final String fileExtension;
  final bool isOrigin;
  final String? videoThumbnailPath;

  VideoPickerModel({
    required this.id,
    required this.mediaPath,
    required this.fileSize,
    required this.fileExtension,
    this.isOrigin = false,
    this.videoThumbnailPath,
  });

  @override
  String toString() {
    return 'VideoPickerModel(id: $id, mediaPath: $mediaPath, fileSize: $fileSize, fileExtension: $fileExtension, isOrigin: $isOrigin, videoThumbnailPath: $videoThumbnailPath)';
  }
}

class VideoPickerConfig {
  final int? maxCount;
  final int? gridCount;

  const VideoPickerConfig({
    this.maxCount,
    this.gridCount,
  });
}

class VideoPicker {
  static final VideoPicker instance = VideoPicker._internal();

  VideoPicker._internal();

  static Future<void> pickVideos({
    required BuildContext context,
    VideoPickerConfig? config,
    required Function(VideoPickerModel model, int index, double progress) onProgress,
  }) async {
    try {
      await AlbumPicker.pickMedia(
        context: context,
        config: AlbumPickerConfig(
          pickMode: PickMode.video,
          maxCount: config?.maxCount,
          gridCount: config?.gridCount,
        ),
        onProgress: (albumModel, index, progress) {
          // 只处理视频类型
          if (albumModel.mediaType == PickMediaType.video) {
            final videoModel = VideoPickerModel(
              id: albumModel.id,
              mediaPath: albumModel.mediaPath,
              fileSize: albumModel.fileSize,
              fileExtension: albumModel.fileExtension,
              isOrigin: albumModel.isOrigin,
              videoThumbnailPath: albumModel.videoThumbnailPath,
            );
            onProgress(videoModel, index, progress);
          }
        },
      );
    } catch (e) {
      debugPrint('VideoPicker.pickVideos error: $e');
      rethrow;
    }
  }
}
