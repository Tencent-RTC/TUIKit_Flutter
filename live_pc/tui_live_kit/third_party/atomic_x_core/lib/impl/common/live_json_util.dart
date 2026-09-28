import '../../api/device/device_store.dart';
import '../../api/live/live_audience_store.dart';
import '../../api/live/live_seat_store.dart';

class LiveJsonUtil {
  static DeviceControlPolicy intToDeviceControlPolicy(int? value) {
    return DeviceControlPolicy.values.firstWhere(
      (e) => e.value == (value ?? DeviceControlPolicy.unlockOnly.value),
      orElse: () => DeviceControlPolicy.unlockOnly,
    );
  }

  static DeviceStatus intToDeviceStatus(int? value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == (value ?? DeviceStatus.off.value),
      orElse: () => DeviceStatus.off,
    );
  }

  static SeatInfo mapToSeatInfo(Map<String, dynamic>? map) {
    if (map == null) return SeatInfo();
    return SeatInfo(
      index: (map['index'] as int?) ?? 0,
      isLocked: (map['isLocked'] as bool?) ?? false,
      userInfo: mapToSeatUserInfo(map['userInfo']),
      region: mapToRegionInfo(map['region']),
      isFeaturedHost: (map['isFeaturedHost'] as bool?) ?? false,
    );
  }

  static SeatUserInfo mapToSeatUserInfo(Map<String, dynamic>? map) {
    if (map == null) return SeatUserInfo();
    final roleValue = (map['role'] as int?) ?? Role.generalUser.value;
    final role = Role.values.firstWhere(
      (e) => e.value == roleValue,
      orElse: () => Role.generalUser,
    );
    return SeatUserInfo(
      userID: (map['userID'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      avatarURL: (map['avatarURL'] as String?) ?? '',
      role: role,
      liveID: (map['liveID'] as String?) ?? '',
      microphoneStatus: intToDeviceStatus(map['microphoneStatus'] as int?),
      allowOpenMicrophone: (map['allowOpenMicrophone'] as bool?) ?? true,
      cameraStatus: intToDeviceStatus(map['cameraStatus'] as int?),
      allowOpenCamera: (map['allowOpenCamera'] as bool?) ?? true,
      userSuspendStatus: SuspendStatus.fromValue(map['userSuspendStatus'] as int? ?? 0),
    );
  }

  static RegionInfo mapToRegionInfo(Map<String, dynamic>? map) {
    if (map == null) return RegionInfo();
    return RegionInfo(
      x: (map['x'] as num?)?.toInt() ?? 0,
      y: (map['y'] as num?)?.toInt() ?? 0,
      w: (map['w'] as num?)?.toInt() ?? 0,
      h: (map['h'] as num?)?.toInt() ?? 0,
      zorder: (map['zorder'] as num?)?.toInt() ?? 0,
    );
  }

  static LiveCanvas mapToLiveCanvas(Map<String, dynamic>? map) {
    if (map == null) return LiveCanvas();
    return LiveCanvas(
      w: (map['w'] as num?)?.toInt() ?? 0,
      h: (map['h'] as num?)?.toInt() ?? 0,
      templateID: (map['templateID'] as num?)?.toInt() ?? 600,
    );
  }

  static AVStatistics mapToAVStatistics(Map<String, dynamic>? map) {
    if (map == null) return AVStatistics();
    return AVStatistics(
      userID: (map['userID'] as String?) ?? '',
      videoBitrate: (map['videoBitrate'] as int?) ?? 0,
      videoWidth: (map['videoWidth'] as int?) ?? 0,
      videoHeight: (map['videoHeight'] as int?) ?? 0,
      frameRate: (map['frameRate'] as int?) ?? 0,
      audioSampleRate: (map['audioSampleRate'] as int?) ?? 0,
      audioBitrate: (map['audioBitrate'] as int?) ?? 0,
    );
  }
}
