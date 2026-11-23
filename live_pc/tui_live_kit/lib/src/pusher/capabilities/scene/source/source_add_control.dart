import 'package:flutter/widgets.dart';

import '../../../../common/widget/toast.dart';
import '../../../../l10n/language_store.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_image_utils.dart';
import '../scene_localization.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import 'dialog/camera_source_dialog.dart';
import 'dialog/image_source_dialog.dart';
import 'dialog/online_video_source_dialog.dart';
import 'dialog/screen_source_dialog.dart';
import 'dialog/video_file_source_dialog.dart';

Future<void> addSourceByKind(BuildContext context, SceneController controller, MediaSourceKind kind) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  String? error;
  try {
    switch (kind) {
      case MediaSourceKind.camera:
        final config = await showCameraSourceDialog(context, occupiedDeviceIds: controller.occupiedCameraDeviceIds());
        error =
            config == null || !context.mounted ? null : await controller.addCameraSource(config.device, config.capture);
      case MediaSourceKind.image:
        final config = await showImageSourceDialog(context);
        if (config == null || !context.mounted) {
          error = null;
        } else {
          final size = await decodeImageSize(config.path);
          final sizeError = imageSizeError(const LiveKitSceneStrings(), size);
          if (sizeError != null) {
            if (overlay != null) {
              showToastOnOverlay(overlay, sizeError, duration: errorToastDuration);
            }
            return;
          }
          error = await controller.addImageSource(config, knownSize: size);
        }
      case MediaSourceKind.videoFile:
        final config = await showVideoFileSourceDialog(context);
        error = config == null || !context.mounted ? null : await controller.addVideoFileSource(config);
      case MediaSourceKind.onlineVideo:
        final config = await showOnlineVideoSourceDialog(context);
        error = config == null || !context.mounted ? null : await controller.addOnlineVideoSource(config);
      case MediaSourceKind.screen:
        final config = await showScreenSourceDialog(context, occupiedSourceIds: controller.occupiedScreenSourceIds());
        error = config == null || !context.mounted ? null : await controller.addScreenSource(config);
    }
  } catch (e, stack) {
    debugPrint('addSourceByKind($kind) failed: $e\n$stack');
    error = currentLiveKitStrings().errorOperationFailed;
  }
  if (error != null && overlay != null) {
    showToastOnOverlay(overlay, error, duration: errorToastDuration);
  }
}
