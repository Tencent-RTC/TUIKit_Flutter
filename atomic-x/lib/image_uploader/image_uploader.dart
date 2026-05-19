import 'package:flutter/material.dart';

import 'impl/image_uploader_impl.dart';

enum CropOverlayShape {
  circle,
  rectangle1_1,
  rectangle4_3,
  rectangle3_4,
  rectangle16_9,
  rectangle9_16,
}

class ImageUploaderConfig {
  final bool showsCameraItem;
  final CropOverlayShape cropOverlayShape;

  const ImageUploaderConfig({
    this.showsCameraItem = false,
    this.cropOverlayShape = CropOverlayShape.circle,
  });
}

class ImageUploader {
  ImageUploader._();

  /// Pick an image with optional cropping and COS upload.
  ///
  /// [context] - BuildContext for navigation and UI.
  /// [config] - Configuration for camera/crop options.
  /// [cosUploadURL] - Optional COS pre-signed URL for upload.
  /// [onPickCompleted] - Called with the local path of the cropped image, or null if cancelled.
  /// [onCosUploadCompleted] - Called with HTTP status code after COS upload completes.
  static Future<void> pick({
    required BuildContext context,
    ImageUploaderConfig? config,
    String? cosUploadURL,
    required Function(String? localPath) onPickCompleted,
    Function(int statusCode)? onCosUploadCompleted,
  }) async {
    ImageUploaderImpl.pick(
      context: context,
      config: config ?? const ImageUploaderConfig(),
      cosUploadURL: cosUploadURL,
      onPickCompleted: onPickCompleted,
      onCosUploadCompleted: onCosUploadCompleted,
    );
  }
}
