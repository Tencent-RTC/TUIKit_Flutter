import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:flutter/material.dart';

class DeviceOperator {
  static Future<void> openCamera(BuildContext context) async {
    final deviceStore = DeviceStore.shared;
    final hasPermission = await _checkAndRequestPermission(
      context: context,
      permissionType: PermissionType.camera,
      deniedMessage: RoomLocalizations.of(context)!.roomkit_err_n1101_camera_no_permission,
    );

    if (!hasPermission) return;

    final result = await deviceStore.openLocalCamera(deviceStore.state.isFrontCamera.value);
    if (!result.isSuccess && context.mounted) {
      Toast.error(
        context,
        ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
        useRootOverlay: true,
      );
    }
  }

  static void closeCamera() async {
    DeviceStore.shared.closeLocalCamera();
  }

  static Future<void> unmuteMicrophone({
    required BuildContext context,
    required RoomParticipantStore participantStore,
  }) async {
    final deviceStore = DeviceStore.shared;

    if (deviceStore.state.microphoneStatus.value == DeviceStatus.off) {
      final hasPermission = await _checkAndRequestPermission(
        context: context,
        permissionType: PermissionType.microphone,
        deniedMessage: RoomLocalizations.of(context)!.roomkit_err_n1105_mic_no_permission,
      );

      if (!hasPermission) return;

      final deviceResult = await deviceStore.openLocalMicrophone();
      if (!deviceResult.isSuccess && context.mounted) {
        Toast.error(
          context,
          ErrorLocalized.convertToErrorMessage(deviceResult.errorCode, deviceResult.errorMessage),
          useRootOverlay: true,
        );
        return;
      }
    }

    final result = await participantStore.unmuteMicrophone();
    if (!result.isSuccess && context.mounted) {
      Toast.error(
        context,
        ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
        useRootOverlay: true,
      );
    }
  }

  static Future<void> muteMicrophone(RoomParticipantStore participantStore) async {
    participantStore.muteMicrophone();
  }

  static Future<bool> _checkAndRequestPermission({
    required BuildContext context,
    required PermissionType permissionType,
    required String deniedMessage,
  }) async {
    final permissionStatus = await Permission.check(permissionType);

    if (permissionStatus == PermissionStatus.granted) {
      return true;
    }

    final result = await Permission.request([permissionType]);

    if (result[permissionType] == PermissionStatus.granted) {
      return true;
    }

    if (context.mounted) {
      Toast.error(
        context,
        deniedMessage,
        useRootOverlay: true,
      );
    }

    return false;
  }
}
