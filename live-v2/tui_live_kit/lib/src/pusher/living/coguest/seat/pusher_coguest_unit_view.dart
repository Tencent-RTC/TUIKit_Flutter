import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../../../common/live_kit_resources.dart';
import '../../../../common/theme/live_seat.dart';

/// 对应 iOS `Pusher/Living/CoGuest/Seat/PusherCoGuestSeatViewProvider.swift`
/// 中的 fileprivate `PusherCoGuestUnitView`：把一格 SDK 席位的 `UnitInfo` 和
/// 当前 CoGuest 舞台上下文投影成 `LiveSeat` 的 6 个入参。
///
/// 身份判定（host / guest）由 provider 预先算好传入，避免 Widget 层访问 Login
/// Store；本地摄像头状态由根 `PusherView` 经 provider 单独下发，覆盖 SDK 席位
/// 快照在本地预览已经启用但 UnitInfo 尚未同步时的滞后。
class PusherCoGuestUnitView extends StatelessWidget {
  const PusherCoGuestUnitView({
    super.key,
    required this.unitInfo,
    required this.isLiving,
    required this.showsEmptySeats,
    required this.hasGuests,
    required this.showsHostOverlay,
    required this.isHost,
    required this.localCameraStatus,
    this.volume = 0,
  });

  final UnitInfo unitInfo;
  final bool isLiving;
  final bool showsEmptySeats;
  final bool hasGuests;
  final bool showsHostOverlay;
  final bool isHost;
  final DeviceStatus? localCameraStatus;

  /// 当前音量，达到 `LiveSeat.volumeWaveThreshold` 时头像外圈显示音浪。
  final int volume;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = unitInfo.userID.isEmpty;
    if (!isLiving || (isEmpty && !showsEmptySeats)) {
      return const SizedBox.shrink();
    }
    final bool isGuest = !isEmpty && !isHost;
    final DeviceStatus? cameraStatus = isHost ? localCameraStatus : unitInfo.cameraStatus;
    final bool isGuestInBackground = isGuest && unitInfo.userSuspendStatus == SuspendStatus.inBackground;
    return LiveSeat(
      emptyTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.invite_to_seat'),
      name: unitInfo.userName.isEmpty ? unitInfo.userID : unitInfo.userName,
      avatarURL: unitInfo.avatarURL,
      microphoneOn: unitInfo.microphoneStatus == DeviceStatus.on,
      isEmpty: isEmpty,
      showsNoVideo: isGuestInBackground || (cameraStatus != null && cameraStatus != DeviceStatus.on),
      showsOverlay: (isGuest && hasGuests) || (isHost && showsHostOverlay),
      volume: volume,
    );
  }
}
