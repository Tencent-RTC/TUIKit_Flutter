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

  const ImagePickerConfig({
    this.maxCount = 9,
    this.gridCount = 4,
  });
}

class ImagePicker {
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
          maxCount: config?.maxCount,
          gridCount: config?.gridCount,
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
