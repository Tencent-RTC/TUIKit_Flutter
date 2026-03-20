import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;

import 'permission_method_channel.dart';

/// Permission types supported by the plugin.
enum PermissionType {
  /// Camera permission
  camera('camera'),

  /// Microphone/audio recording permission
  microphone('microphone'),

  /// Photo library/gallery permission
  /// - iOS: Photos permission
  /// - Android 14+: READ_MEDIA_IMAGES, READ_MEDIA_VIDEO (full access)
  ///                READ_MEDIA_VISUAL_USER_SELECTED (limited access)
  /// - Android 13: READ_MEDIA_IMAGES, READ_MEDIA_VIDEO
  /// - Android <13: READ_EXTERNAL_STORAGE
  photos('photos'),

  /// Storage permission (file/external storage)
  /// - iOS: Not applicable
  /// - Android 13+: READ_EXTERNAL_STORAGE
  /// - Android <13: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
  storage('storage'),

  /// Notifications permission
  notification('notification'),

  /// System alert window permission (overlay/floating window)
  /// - iOS: Not applicable (always granted)
  /// - Android: SYSTEM_ALERT_WINDOW permission
  ///   Required for displaying floating windows over other apps
  systemAlertWindow('systemAlertWindow'),

  /// Display over other apps permission (same as systemAlertWindow)
  /// - iOS: Not applicable (always granted)
  /// - Android: SYSTEM_ALERT_WINDOW permission
  ///   Required for bringing app to foreground from background
  displayOverOtherApps('displayOverOtherApps');

  const PermissionType(this.identifier);

  /// Permission identifier
  final String identifier;

  /// Get platform-specific permission string
  /// Note: For Android, actual permissions are determined by OS version
  String get platformValue => identifier;
}

/// Permission status returned by the platform.
enum PermissionStatus {
  /// 完全授权：功能可用
  granted('granted'),

  /// 拒绝或未授权：功能不可用，包含可重试（Deny）和系统受限（Restricted/Unknown）状态
  denied('denied'),

  /// 永久拒绝：功能不可用，需引导用户至系统设置
  permanentlyDenied('permanentlyDenied'),

  /// 部分授权：功能受限可用
  /// - iOS: 相册（Photos）的部分访问权限（iOS 14+），通知的临时授权
  /// - Android: 相册（Photos）的部分访问权限（Android 14+，用户选择"仅允许访问选定的照片和视频"）
  limited('limited');

  const PermissionStatus(this.value);

  /// String value of the status
  final String value;

  /// Parse status from string
  static PermissionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'granted':
        return PermissionStatus.granted;
      case 'permanentlydenied':
      case 'permanently_denied':
        return PermissionStatus.permanentlyDenied;
      case 'limited':
        return PermissionStatus.limited;
      case 'denied':
      case 'restricted':
      case 'unknown':
      default:
        return PermissionStatus.denied;
    }
  }
}

/// Permission module for handling platform permissions.
class Permission {
  Permission._(); // Private constructor to prevent instantiation

  static final PermissionMethodChannel _channel = PermissionMethodChannel();

  /// Check permission status
  static Future<PermissionStatus> check(PermissionType permission) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'checkPermissionStatus',
        {'permission': permission.platformValue},
      );
      return PermissionStatus.fromString(result ?? 'denied');
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  /// Request permissions
  static Future<Map<PermissionType, PermissionStatus>> request(
    List<PermissionType> permissions,
  ) async {
    try {
      final permissionStrings = permissions.map((p) => p.platformValue).toList();
      final result = await _channel.invokeMethod<Map>(
        'requestPermissions',
        {'permissions': permissionStrings},
      );

      if (result == null) return {};

      final Map<PermissionType, PermissionStatus> statusMap = {};
      for (var permission in permissions) {
        final statusString = result[permission.platformValue]?.toString();
        if (statusString != null) {
          statusMap[permission] = PermissionStatus.fromString(statusString);
        }
      }
      return statusMap;
    } catch (e) {
      return {};
    }
  }

  /// Navigate to app settings
  static Future<bool> openAppSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openAppSettings');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request permissions with smart dialog behavior.
  ///
  /// Returns `true` if all requested permissions are granted or limited.
  /// Returns `false` if any permission is not granted.
  ///
  /// Behavior:
  /// 1. **Check** the current status of each permission via `checkPermissionStatus`
  ///    on the native side, which uses `!isGranted && !shouldShowRationale` without
  ///    relying on `requestedAndroidPermissions`. This may produce false positives
  ///    for "never asked" permissions (since `shouldShowRationale` returns false
  ///    for both "never asked" and "permanently denied").
  /// 2. **Request** permissions via the normal flow, which on the native side uses
  ///    `getPermissionTypeStatus` with `requestedAndroidPermissions` — only
  ///    permissions that were actually requested can be reported as
  ///    `permanentlyDenied`.
  /// 3. Show settings dialog **only when BOTH** `check` and `request` return
  ///    `permanentlyDenied`. This filters out:
  ///    - "Never asked" false positives: check → permanentlyDenied (false positive),
  ///      request → granted/denied (user made a choice) → no dialog.
  ///    - "User just chose Don't Ask Again": check → denied (shouldShow was true),
  ///      request → permanentlyDenied → no dialog (respects user's immediate choice).
  ///
  /// [context] is required for showing the permission dialog.
  /// [permissionTypes] is the list of permissions to request.
  static Future<bool> checkAndRequest(
    BuildContext context,
    List<PermissionType> permissionTypes,
  ) async {
    if (kIsWeb) {
      return true;
    }

    // Step 1: Check current status.
    bool checkReturnedPermanentlyDenied = false;
    for (final type in permissionTypes) {
      final status = await Permission.check(type);
      if (status == PermissionStatus.permanentlyDenied) {
        checkReturnedPermanentlyDenied = true;
        break;
      }
    }

    // Step 2: Always request — this serves as either the normal permission
    // request or a probe to verify a real permanentlyDenied.
    Map<PermissionType, PermissionStatus> statusMap = await Permission.request(permissionTypes);

    bool allGranted = permissionTypes.every((type) {
      final status = statusMap[type] ?? PermissionStatus.denied;
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    });

    if (allGranted) {
      return true;
    }

    // Step 3: Show settings dialog only when BOTH conditions are met:
    //   a) check() returned permanentlyDenied (pre-request signal)
    //   b) request() also returned permanentlyDenied (post-request confirmation)
    // This filters out the false-positive "never asked" case: if the permission
    // was truly never asked, request() will trigger the system dialog and return
    // granted/denied (not permanentlyDenied), so condition (b) won't be met.
    //
    // It also handles the "user just chose Don't Ask Again" case: check()
    // returned denied (shouldShow was true), so condition (a) won't be met,
    // and we return silently — respecting the user's immediate choice.
    if (checkReturnedPermanentlyDenied) {
      bool requestReturnedPermanentlyDenied = permissionTypes.any((type) {
        final status = statusMap[type] ?? PermissionStatus.denied;
        return status == PermissionStatus.permanentlyDenied;
      });

      if (requestReturnedPermanentlyDenied && context.mounted) {
        // Find the first permanently denied permission type for the dialog message.
        final permanentlyDeniedType = permissionTypes.firstWhere(
          (type) => (statusMap[type] ?? PermissionStatus.denied) == PermissionStatus.permanentlyDenied,
          orElse: () => permissionTypes.first,
        );
        final bool shouldOpenSettings = await showPermissionDialog(context, permanentlyDeniedType);
        if (shouldOpenSettings) {
          await Permission.openAppSettings();
        }
      }
    }

    return false;
  }

  /// Show a dialog informing the user that permission is needed,
  /// with options to cancel or go to app settings.
  ///
  /// The dialog content varies based on [permissionType] to show
  /// a specific message for each permission (camera, microphone, etc.).
  ///
  /// Returns `true` if the user chooses to open settings, `false` otherwise.
  static Future<bool> showPermissionDialog(BuildContext context, PermissionType permissionType) {
    final completer = Completer<bool>();
    final atomicLocal = AtomicLocalizations.of(context);

    AtomicAlertDialog.show(
      context,
      title: atomicLocal.permissionNeeded,
      content: _getPermissionDeniedText(atomicLocal, permissionType),
      cancelText: atomicLocal.cancel,
      confirmText: atomicLocal.confirm,
      barrierDismissible: false,
      onConfirm: () {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onCancel: () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    return completer.future;
  }

  /// Returns the localized permission-denied text for the given [permissionType].
  static String _getPermissionDeniedText(AtomicLocalizations l10n, PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.camera:
        return l10n.permissionDeniedCamera;
      case PermissionType.microphone:
        return l10n.permissionDeniedMicrophone;
      case PermissionType.photos:
        return l10n.permissionDeniedPhotos;
      case PermissionType.storage:
        return l10n.permissionDeniedStorage;
      case PermissionType.notification:
        return l10n.permissionDeniedNotification;
      case PermissionType.systemAlertWindow:
      case PermissionType.displayOverOtherApps:
        return l10n.permissionDeniedContent;
    }
  }
}
