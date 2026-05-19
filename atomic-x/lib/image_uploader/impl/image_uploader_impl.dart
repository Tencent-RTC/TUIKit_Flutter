import 'package:flutter/material.dart';

import 'package:tuikit_atomic_x/atomicx.dart';
import 'image_uploader_platform.dart';
import 'image_crop_page.dart';
import 'image_cos_upload_manager.dart';
import '../image_uploader.dart';

class ImageUploaderImpl {
  static const String sourceCamera = 'camera';
  static const String sourceGallery = 'gallery';

  static void pick({
    required BuildContext context,
    required ImageUploaderConfig config,
    String? cosUploadURL,
    required Function(String? localPath) onPickCompleted,
    Function(int statusCode)? onCosUploadCompleted,
  }) {
    if (config.showsCameraItem) {
      _showImageSourcePicker(
        context: context,
        config: config,
        cosUploadURL: cosUploadURL,
        onPickCompleted: onPickCompleted,
        onCosUploadCompleted: onCosUploadCompleted,
      );
    } else {
      pickFromSource(
        context: context,
        source: sourceGallery,
        config: config,
        cosUploadURL: cosUploadURL,
        onPickCompleted: onPickCompleted,
        onCosUploadCompleted: onCosUploadCompleted,
      );
    }
  }

  static void _showImageSourcePicker({
    required BuildContext context,
    required ImageUploaderConfig config,
    String? cosUploadURL,
    required Function(String? localPath) onPickCompleted,
    Function(int statusCode)? onCosUploadCompleted,
  }) {
    final appLocale = AtomicLocalizations.of(context);

    ActionSheet.show(
      context,
      actions: [
        ActionSheetItem(
          title: appLocale.takeAPhoto,
          onTap: () {
            pickFromSource(
              context: context,
              source: sourceCamera,
              config: config,
              cosUploadURL: cosUploadURL,
              onPickCompleted: onPickCompleted,
              onCosUploadCompleted: onCosUploadCompleted,
            );
          },
        ),
        ActionSheetItem(
          title: appLocale.album,
          onTap: () {
            pickFromSource(
              context: context,
              source: sourceGallery,
              config: config,
              cosUploadURL: cosUploadURL,
              onPickCompleted: onPickCompleted,
              onCosUploadCompleted: onCosUploadCompleted,
            );
          },
        ),
      ],
    );
  }

  static Future<void> pickFromSource({
    required BuildContext context,
    required String source,
    required ImageUploaderConfig config,
    String? cosUploadURL,
    required Function(String? localPath) onPickCompleted,
    Function(int statusCode)? onCosUploadCompleted,
  }) async {
    try {
      final imagePath = await ImageUploaderPlatform.pickImageNative(source: source);
      if (imagePath != null && context.mounted) {
        showCropPage(
          context: context,
          imagePath: imagePath,
          config: config,
          cosUploadURL: cosUploadURL,
          onPickCompleted: onPickCompleted,
          onCosUploadCompleted: onCosUploadCompleted,
        );
      } else {
        onPickCompleted(null);
      }
    } catch (e) {
      debugPrint('ImageUploader: $source pick failed: $e');
      onPickCompleted(null);
    }
  }

  static void showCropPage({
    required BuildContext context,
    required String imagePath,
    required ImageUploaderConfig config,
    String? cosUploadURL,
    required Function(String? localPath) onPickCompleted,
    Function(int statusCode)? onCosUploadCompleted,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageCropPage(
          imagePath: imagePath,
          cropShape: config.cropOverlayShape,
          onCropCompleted: (String? croppedPath) {
            onPickCompleted(croppedPath);

            if (croppedPath != null && cosUploadURL != null) {
              uploadToCos(
                localPath: croppedPath,
                cosUploadURL: cosUploadURL,
                onCosUploadCompleted: onCosUploadCompleted,
              );
            }
          },
        ),
      ),
    );
  }

  static Future<void> uploadToCos({
    required String localPath,
    required String cosUploadURL,
    Function(int statusCode)? onCosUploadCompleted,
  }) async {
    final manager = ImageCosUploadManager();
    final statusCode = await manager.uploadFile(localPath, cosUploadURL);
    onCosUploadCompleted?.call(statusCode);
  }
}
