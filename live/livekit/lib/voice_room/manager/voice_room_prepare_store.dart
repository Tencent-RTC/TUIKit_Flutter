import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_live_uikit/common/constants/constants.dart';

import '../voice_room_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

enum PrivacyStatus { public, privacy }

class VoiceRoomPrepareState {
  ValueNotifier<LiveInfo> liveInfo;

  VoiceRoomPrepareState({
    LiveInfo? liveInfo,
  }) : liveInfo = liveInfo != liveInfo
            ? ValueNotifier(liveInfo!)
            : ValueNotifier(LiveInfo(
                coverURL: Constants.defaultCoverUrl,
                backgroundURL: Constants.defaultBackgroundUrl,
                isSeatEnabled: true,
                keepOwnerOnSeat: true,
                seatLayoutTemplateID: 70));
}

class VoiceRoomPrepareStore {
  VoiceRoomPrepareState state = VoiceRoomPrepareState();

  late RoomParams roomParams = RoomParams();

  void prepareLiveIdBeforeEnterRoom({
    required String liveID,
    RoomParams? params,
  }) {
    state.liveInfo.value = state.liveInfo.value.copyWith(liveID: liveID);
    if (params != null) {
      roomParams = params;
    }
  }

  void onSetRoomName(String name) {
    state.liveInfo.value = state.liveInfo.value.copyWith(liveName: name);
  }

  void onSetRoomPrivacy(PrivacyStatus mode) {
    state.liveInfo.value = state.liveInfo.value.copyWith(isPublicVisible: mode == PrivacyStatus.public);
  }

  void onSetRoomCoverUrl(String coverUrl) {
    state.liveInfo.value = state.liveInfo.value.copyWith(coverURL: coverUrl);
  }

  void onSetRoomBackgroundUrl(String backgroundUrl) {
    state.liveInfo.value = state.liveInfo.value.copyWith(backgroundURL: backgroundUrl);
  }

  void onChangedSeatMode(TUISeatMode seatMode) {
    state.liveInfo.value = state.liveInfo.value
        .copyWith(seatMode: seatMode == TUISeatMode.applyToTake ? TakeSeatMode.apply : TakeSeatMode.free);
    roomParams.seatMode = seatMode;
  }

  void dispose() {
    state.liveInfo.value = LiveInfo();
  }
}

extension on LiveInfo {
  LiveInfo copyWith(
      {String? liveID,
      String? liveName,
      String? notice,
      bool? isMessageDisable,
      bool? isPublicVisible,
      bool? isSeatEnabled,
      bool? keepOwnerOnSeat,
      int? maxSeatCount,
      TakeSeatMode? seatMode,
      int? seatLayoutTemplateID,
      String? coverURL,
      String? backgroundURL,
      List<int>? categoryList,
      int? activityStatus,
      LiveUserInfo? liveOwner,
      int? createTime,
      int? totalViewerCount,
      bool? isGiftEnabled,
      Map<String, String>? metaData}) {
    return LiveInfo(
        liveID: liveID ?? this.liveID,
        liveName: liveName ?? this.liveName,
        notice: notice ?? this.notice,
        isMessageDisable: isMessageDisable ?? this.isMessageDisable,
        isPublicVisible: isPublicVisible ?? this.isPublicVisible,
        isSeatEnabled: isSeatEnabled ?? this.isSeatEnabled,
        keepOwnerOnSeat: keepOwnerOnSeat ?? this.keepOwnerOnSeat,
        maxSeatCount: maxSeatCount ?? this.maxSeatCount,
        seatMode: seatMode ?? this.seatMode,
        seatLayoutTemplateID: seatLayoutTemplateID ?? this.seatLayoutTemplateID,
        coverURL: coverURL ?? this.coverURL,
        backgroundURL: backgroundURL ?? this.backgroundURL,
        categoryList: categoryList ?? this.categoryList,
        activityStatus: activityStatus ?? this.activityStatus,
        liveOwner: liveOwner ?? this.liveOwner,
        createTime: createTime ?? this.createTime,
        totalViewerCount: totalViewerCount ?? this.totalViewerCount,
        isGiftEnabled: isGiftEnabled ?? this.isGiftEnabled,
        metaData: metaData ?? this.metaData);
  }
}
