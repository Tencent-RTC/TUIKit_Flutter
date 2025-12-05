import 'package:flutter/material.dart';

import 'album_picker_platform.dart';

enum PickMode {
  image,
  video,
  all,
}

enum PickMediaType {
  image,
  video,
  gif,
}

class AlbumPickerModel {
  final int id;
  final PickMediaType mediaType;
  final String mediaPath;
  final String fileExtension;
  final int fileSize;
  final bool isOrigin;
  final String? videoThumbnailPath;

  AlbumPickerModel({
    required this.id,
    required this.mediaType,
    required this.mediaPath,
    required this.fileExtension,
    required this.fileSize,
    this.isOrigin = false,
    this.videoThumbnailPath,
  });

  @override
  String toString() {
    return 'AlbumPickerModel(id: $id, mediaType: $mediaType, mediaPath: $mediaPath, fileExtension: $fileExtension, fileSize: $fileSize, isOrigin: $isOrigin, videoThumbnailPath: $videoThumbnailPath)';
  }
}

class AlbumPickerConfig {
  final PickMode pickMode;
  final int? maxCount;
  final int? gridCount;
  final Color? primaryColor;
  final Locale? locale;

  const AlbumPickerConfig({
    this.pickMode = PickMode.all,
    this.maxCount,
    this.gridCount,
    this.primaryColor,
    this.locale,
  });
}

class AlbumPicker {
  static const int defaultMaxCount = 9;
  static const int defaultGridCount = 4;

  static final AlbumPicker instance = AlbumPicker._internal();

  AlbumPicker._internal();

  static Future<void> pickMedia({
    required BuildContext context,
    AlbumPickerConfig? config,
    required Function(AlbumPickerModel model, int index, double progress) onProgress,
  }) async {
    return AlbumPickerPlatform.pickMediaNative(
      config: config ?? const AlbumPickerConfig(),
      onProgress: onProgress,
    );
  }
}
