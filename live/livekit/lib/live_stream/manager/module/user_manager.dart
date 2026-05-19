import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../api/live_stream_service.dart';
import '../../state/user_state.dart';
import '../live_stream_manager.dart';

// for remote user
enum UserEnterRoomNotifyStrategy {
  always, // notify everytime
  merge, // notify once per cycle
}

class UserManager {
  LSUserState userState = LSUserState();
  late final LiveAudienceStore _liveAudienceStore;
  late final LiveAudienceListener _liveAudienceListener;
  late final Context context;
  late final LiveStreamService service;

  final int _volumeCanHeartMinLimit = 25;

  UserEnterRoomNotifyStrategy _enterRoomNotifyStrategy = UserEnterRoomNotifyStrategy.always;
  int _intervalSecondOnMerge = 60;
  final Map<String, DateTime> _enterRoomUserTimestamps = {};

  void init(Context context) {
    this.context = context;
    service = context.service;
  }

  void setLiveID(String liveID) {
    _subscribeListener();
  }

  void setUserEnterRoomNotifyStrategy(UserEnterRoomNotifyStrategy strategy, {int? intervalSecondOnMerge}) {
    _enterRoomNotifyStrategy = strategy;
    if (intervalSecondOnMerge != null) _intervalSecondOnMerge = intervalSecondOnMerge;
  }

  void dispose() {
    _unsubscribeListener();
  }

  void onLeaveLive() {
    userState = LSUserState();
  }
}

extension UserManagerCallback on UserManager {
  void onUserVoiceVolumeChanged(Map<String, int> volumeMap) {
    for (final entry in volumeMap.entries) {
      entry.value > _volumeCanHeartMinLimit
          ? userState.speakingUserList.add(entry.key)
          : userState.speakingUserList.remove(entry.key);
    }
  }

  void onRemoteUserEnterRoom(String roomId, TUIUserInfo userInfo) {
    if (roomId != context.roomManager.target?.roomState.roomId) {
      return;
    }

    if (userInfo.userId == TUIRoomEngine.getSelfInfo().userId) {
      return;
    }

    userState.userList.value.add(userInfo);
  }

  void onRemoteUserLeaveRoom(String roomId, TUIUserInfo userInfo) {
    if (roomId != context.roomManager.target?.roomState.roomId) {
      return;
    }

    userState.userList.value.removeWhere((user) => user.userId == userInfo.userId);
  }

  void onUserInfoChanged(TUIUserInfo userInfo, List<TUIUserInfoModifyFlag> modifyFlags) {
    for (var user in userState.userList.value) {
      if (user.userId == userInfo.userId && modifyFlags.contains(TUIUserInfoModifyFlag.userRole)) {
        user.userRole = user.userRole;
      }
    }

    userState.userList.value = userState.userList.value.toSet();
  }

  void onSendMessageForUserDisableChanged(String roomId, String userId, bool isDisable) {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (roomId == liveID && userId == TUIRoomEngine.getSelfInfo().userId) {
      final toast = isDisable
          ? LiveKitLocalizations.of(Global.appContext())!.common_client_error_send_message_disabled_for_current
          : LiveKitLocalizations.of(Global.appContext())!.common_send_message_enable;
      context.toastSubject.target?.add(toast);
    }
  }
}

extension on UserManager {
  String _getLiveID() {
    return context.roomManager.target!.roomState.roomId;
  }

  void _onAudienceJoined(LiveUserInfo audience) {
    if (_enterRoomNotifyStrategy == UserEnterRoomNotifyStrategy.always) {
      userState.enterUser.value = audience;
    } else if (_enterRoomNotifyStrategy == UserEnterRoomNotifyStrategy.merge) {
      final now = DateTime.now();
      final lastTime = _enterRoomUserTimestamps[audience.userID];
      if (lastTime != null && now.difference(lastTime) < Duration(seconds: _intervalSecondOnMerge)) {
        return;
      }
      _enterRoomUserTimestamps[audience.userID] = now;
      userState.enterUser.value = audience;
    }
  }

  void _subscribeListener() {
    _liveAudienceListener = LiveAudienceListener(onAudienceJoined: (audience) {
      _onAudienceJoined(audience);
    });
    _liveAudienceStore = LiveAudienceStore.create(_getLiveID());
    _liveAudienceStore.addLiveAudienceListener(_liveAudienceListener);
  }

  void _unsubscribeListener() {
    _liveAudienceStore.removeLiveAudienceListener(_liveAudienceListener);
  }
}