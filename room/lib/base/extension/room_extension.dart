import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';

import '../index.dart';

extension RoomParticipantDisplayUtils on RoomParticipant {
  String get displayName {
    return nameCard.isEmpty ? (userName.isEmpty ? userID : userName) : nameCard;
  }
}

extension RoomUserDisplayUtils on RoomUser {
  String get displayName {
    return userName.isEmpty ? userID : userName;
  }
}

extension DeviceTypeExtension on DeviceType {
  PermissionType get toPermissionType {
    switch (this) {
      case DeviceType.camera:
        return PermissionType.camera;
      case DeviceType.microphone:
        return PermissionType.microphone;
      default:
        return PermissionType.microphone;
    }
  }
}

extension RoomIdExtension on String {
  bool get isWebinar => startsWith(RoomConstants.webinarPrefix);
}
