import 'package:flutter/material.dart';

import '../album_picker/album_picker.dart';

class ImagePickerModel {
  final int id;
  final String mediaPath;
  final int fileSize;
  final String fileExtension;
  final bool isOrigin;

  ImagePickerModel({
    required this.id,
    required this.mediaPath,
    required this.fileSize,
    required this.fileExtension,
    this.isOrigin = false,
  });

  @override
  String toString() {
    return 'ImagePickerModel(id: $id, mediaPath: $mediaPath, fileSize: $fileSize, fileExtension: $fileExtension, isOrigin: $isOrigin)';
  }
}

class ImagePickerConfig {
  final int? maxCount;
  final int? gridCount;
  final Color? primaryColor;
  final Locale? locale;

  const ImagePickerConfig({
    this.maxCount,
    this.gridCount,
    this.primaryColor,
    this.locale,
  });
}

class ImagePicker {
  static const int defaultMaxCount = 9;
  static const int defaultGridCount = 4;

  static final ImagePicker instance = ImagePicker._internal();
  ImagePicker._internal();

  static Future<void> pickImages({
    required BuildContext context,
    ImagePickerConfig? config,
    required Function(ImagePickerModel model, int index, double progress) onProgress,
  }) async {
    try {
      await AlbumPicker.pickMedia(
        context: context,
        config: AlbumPickerConfig(
          pickMode: PickMode.image,
          maxCount: config?.maxCount ?? defaultMaxCount,
          gridCount: config?.gridCount ?? defaultGridCount,
          primaryColor: config?.primaryColor,
          locale: config?.locale,
        ),
        onProgress: (albumModel, index, progress) {
          if (albumModel.mediaType == PickMediaType.image) {
            final imageModel = ImagePickerModel(
              id: albumModel.id,
              mediaPath: albumModel.mediaPath,
              fileSize: albumModel.fileSize,
              fileExtension: albumModel.fileExtension,
              isOrigin: albumModel.isOrigin,
            );
            onProgress(imageModel, index, progress);
          }
        },
      );
    } catch (e) {
      debugPrint('ImagePicker.pickImages error: $e');
      rethrow;
    }
  }
}
