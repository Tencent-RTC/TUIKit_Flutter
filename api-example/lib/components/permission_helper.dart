import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission helper utility
///
/// Encapsulates the runtime permission request flow for Android 6.0+ and iOS, including:
/// - Camera permission checking and requesting
/// - Microphone permission checking and requesting
/// - Requesting camera and microphone permissions together
/// - Showing a dialog that guides the user to system settings after permission is denied, including permanent denial
class PermissionHelper {
  PermissionHelper._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Request camera permission and execute [onGranted] after it is granted
  static Future<bool> requestCameraPermission(
    BuildContext context, {
    VoidCallback? onGranted,
  }) async {
    return _requestSingle(
      context,
      permission: Permission.camera,
      permissionName: 'Camera',
      permissionNameCN: '摄像头',
      onGranted: onGranted,
    );
  }

  /// Request microphone permission and execute [onGranted] after it is granted
  static Future<bool> requestMicrophonePermission(
    BuildContext context, {
    VoidCallback? onGranted,
  }) async {
    return _requestSingle(
      context,
      permission: Permission.microphone,
      permissionName: 'Microphone',
      permissionNameCN: '麦克风',
      onGranted: onGranted,
    );
  }

  /// Request both camera and microphone permissions and execute [onGranted] after both are granted
  static Future<bool> requestCameraAndMicrophonePermissions(
    BuildContext context, {
    VoidCallback? onGranted,
  }) async {
    final permissions = [Permission.camera, Permission.microphone];
    final statuses = await permissions.request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (cameraGranted && micGranted) {
      onGranted?.call();
      return true;
    }

    // Check which permissions are permanently denied
    final cameraPermanent =
        statuses[Permission.camera]?.isPermanentlyDenied ?? false;
    final micPermanent =
        statuses[Permission.microphone]?.isPermanentlyDenied ?? false;

    if (context.mounted && (cameraPermanent || micPermanent)) {
      final denied = <String>[];
      if (!cameraGranted) denied.add('Camera / 摄像头');
      if (!micGranted) denied.add('Microphone / 麦克风');
      await _showSettingsDialog(context, denied.join(', '));
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Common flow for requesting a single permission
  static Future<bool> _requestSingle(
    BuildContext context, {
    required Permission permission,
    required String permissionName,
    required String permissionNameCN,
    VoidCallback? onGranted,
  }) async {
    // 1. Check the current status first, and execute directly if already granted
    var status = await permission.status;
    if (status.isGranted) {
      onGranted?.call();
      return true;
    }

    // 2. Request permission
    status = await permission.request();

    if (status.isGranted) {
      onGranted?.call();
      return true;
    }

    // 3. Permanently denied -> guide the user to system settings
    if (status.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(
        context,
        '$permissionName / $permissionNameCN',
      );
    }

    return false;
  }

  /// Show a dialog that guides the user to system settings
  static Future<void> _showSettingsDialog(
    BuildContext context,
    String permissionDescription,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permissionDescription permission has been denied. '
          'Please go to Settings to enable it.\n\n'
          '$permissionDescription 权限已被拒绝，请前往系统设置中手动开启。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
