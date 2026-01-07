import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  const AlbumPickerConfig({
    this.pickMode = PickMode.all,
    this.maxCount = 9,
    this.gridCount = 4,
  });
}

class AlbumPicker {
  static final AlbumPicker instance = AlbumPicker._internal();

  AlbumPicker._internal();

  static Future<void> pickMedia({
    required BuildContext context,
    AlbumPickerConfig? config,
    required Function(AlbumPickerModel model, int index, double progress) onProgress,
  }) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final themeState = BaseThemeProvider.of(context);
    return AlbumPickerPlatform.pickMediaNative(
      config: config ?? const AlbumPickerConfig(),
      locale: localeProvider.locale,
      primaryColor: themeState.currentPrimaryColor,
      onProgress: onProgress,
    );
  }
}
