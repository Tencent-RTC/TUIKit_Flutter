import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../common/live_kit_resources.dart';
import '../../common/theme/live_seat.dart';
import '../player_view.dart';

class PlayerUnitView extends StatelessWidget {
  const PlayerUnitView({
    super.key,
    required this.unitInfo,
    this.liveInfo,
    this.playerStatus = PlayerStatus.idle,
    this.volume = 0,
    this.isCoHostConnected = false,
  });

  final bool isCoHostConnected;
  final UnitInfo unitInfo;
  final LiveInfo? liveInfo;
  final PlayerStatus playerStatus;

  /// 当前音量，达到 `LiveSeat.volumeWaveThreshold` 时头像外圈显示音浪。
  final int volume;

  @override
  Widget build(BuildContext context) {
    final String ownerID = liveInfo?.liveOwner.userID ?? '';
    final bool isOwner = ownerID.isNotEmpty && ownerID == unitInfo.userID;
    final bool roomActive = playerStatus == PlayerStatus.inRoom || playerStatus == PlayerStatus.coGuest;
    return LiveSeat(
      emptyTitle: LiveKitResources.localizedString('tuilivekit.player.coguest.apply'),
      name: unitInfo.userName.isEmpty ? unitInfo.userID : unitInfo.userName,
      avatarURL: unitInfo.avatarURL,
      microphoneOn: unitInfo.microphoneStatus == DeviceStatus.on,
      isEmpty: unitInfo.userID.isEmpty,
      showsNoVideo:
          unitInfo.cameraStatus != DeviceStatus.on || unitInfo.userSuspendStatus == SuspendStatus.inBackground,
      showsOverlay: (!isOwner || isCoHostConnected) && roomActive,
      volume: volume,
    );
  }
}
