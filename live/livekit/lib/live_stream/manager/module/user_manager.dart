import 'package:atomic_x_core/atomicxcore.dart';

import '../../state/user_state.dart';
import '../live_stream_manager.dart';

// for remote user
enum UserEnterRoomNotifyStrategy {
  always, // notify everytime
  merge, // notify once per cycle
}

class UserManager {
  LSUserState userState = LSUserState();
  LiveAudienceStore? _liveAudienceStore;
  LiveAudienceListener? _liveAudienceListener;
  late final Context context;

  UserEnterRoomNotifyStrategy _enterRoomNotifyStrategy = UserEnterRoomNotifyStrategy.always;
  int _intervalSecondOnMerge = 60;
  final Map<String, DateTime> _enterRoomUserTimestamps = {};

  void init(Context context) {
    this.context = context;
  }

  void setLiveID(String liveID) {
    _subscribeListener();
  }

  void resetStore() {
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
    userState.enterUser.value = LiveUserInfo();
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
    _liveAudienceListener ??= LiveAudienceListener(onAudienceJoined: (audience) {
        _onAudienceJoined(audience);
      });
    _liveAudienceStore = LiveAudienceStore.create(_getLiveID());
    _liveAudienceStore!.addLiveAudienceListener(_liveAudienceListener!);
  }

  void _unsubscribeListener() {
    if (_liveAudienceStore != null) {
      _liveAudienceStore!.removeLiveAudienceListener(_liveAudienceListener!);
    }
  }
}