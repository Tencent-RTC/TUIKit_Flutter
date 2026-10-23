import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../common/live_kit_resources.dart';
import '../../common/theme/live_seat.dart';
import '../player_view.dart';

/// 对应 iOS `Player/Video/UnitView.swift`：观众端一格席位的 SDK 投影。
///
/// 把 `UnitInfo` + `LiveInfo?` 的身份/设备状态翻译成 `LiveSeat` 的入参；主播席位
/// 不显示挂件，与 iOS 对齐。`playerStatus` 作为房间阶段门控，`inRoom` / `coGuest`
/// 之外不展示 overlay，与 iOS、Android 对齐。
class UnitView extends StatelessWidget {
  const UnitView({
    super.key,
    required this.unitInfo,
    this.liveInfo,
    this.playerStatus = PlayerStatus.idle,
    this.volume = 0,
  });

  final UnitInfo unitInfo;
  final LiveInfo? liveInfo;
  final PlayerStatus playerStatus;

  /// 当前音量，达到 `LiveSeat.volumeWaveThreshold` 时头像外圈显示音浪。
  final int volume;

  @override
  Widget build(BuildContext context) {
    final String ownerID = liveInfo?.liveOwner.userID ?? '';
    final bool isOwner = ownerID.isNotEmpty && ownerID == unitInfo.userID;
    final bool roomActive = playerStatus == PlayerStatus.inRoom ||
        playerStatus == PlayerStatus.coGuest;
    return LiveSeat(
      emptyTitle:
          LiveKitResources.localizedString('tuilivekit.player.coguest.apply'),
      name: unitInfo.userName.isEmpty ? unitInfo.userID : unitInfo.userName,
      avatarURL: unitInfo.avatarURL,
      microphoneOn: unitInfo.microphoneStatus == DeviceStatus.on,
      isEmpty: unitInfo.userID.isEmpty,
      showsNoVideo: unitInfo.cameraStatus != DeviceStatus.on ||
          unitInfo.userSuspendStatus == SuspendStatus.inBackground,
      showsOverlay: !isOwner && roomActive,
      volume: volume,
    );
  }
}
