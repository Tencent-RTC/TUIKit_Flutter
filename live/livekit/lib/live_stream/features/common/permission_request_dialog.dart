import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

class PermissionRequestDialog {
  static AlertHandler showCameraRequestDialog(BuildContext context, {required VoidCallback onClose}) {
    return _showPermissionRequestDialog(
      context,
      permissionType: PermissionType.camera,
      description: LiveKitLocalizations.of(Global.appContext())!.common_permission_camera_reason,
      errorTip: ErrorHandler.convertToErrorMessage(LiveError.cameraNotAuthorized.code, ''),
      onClose: onClose,
    );
  }

  static AlertHandler showMicrophoneRequestDialog(BuildContext context, {required VoidCallback onClose}) {
    return _showPermissionRequestDialog(
      context,
      permissionType: PermissionType.microphone,
      description: LiveKitLocalizations.of(Global.appContext())!.common_permission_mic_reason,
      errorTip: ErrorHandler.convertToErrorMessage(LiveError.microphoneNotAuthorized.code, ''),
      onClose: onClose,
    );
  }

  static AlertHandler _showPermissionRequestDialog(
    BuildContext context, {
    required PermissionType permissionType,
    required String description,
    required String errorTip,
    required VoidCallback onClose,
  }) {
    AlertHandler? handler;
    final alertInfo = AlertInfo(
      title: LiveKitLocalizations.of(Global.appContext())!.common_permission_request,
      description: description,
      cancelText: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
      cancelCallback: () {
        onClose.call();
        Permission.check(permissionType).then((result) {
          if (result.isUsable) return;
          if (!context.mounted) return;
          makeToast(context, errorTip, type: ToastType.error);
        });
      },
      defaultText: LiveKitLocalizations.of(Global.appContext())!.common_go_settings,
      defaultCallback: () {
        onClose.call();
        Permission.openAppSettings();
      },
    );
    handler = Alert.showAlert(alertInfo, context);
    return handler;
  }
}
