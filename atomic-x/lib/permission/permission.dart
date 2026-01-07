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
        'getPermissionStatus',
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
      final permissionStrings =
          permissions.map((p) => p.platformValue).toList();
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
}
