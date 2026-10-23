import 'package:atomic_x_core/atomicxcore.dart' hide LiveStatus;
import 'package:flutter/services.dart';

import '../../live_define.dart';
import '../../state/room_state.dart';
import '../live_stream_manager.dart';

class RoomManager {
  LSRoomState roomState = LSRoomState();

  late final Context context;
  late final VoidCallback _onCurrentLiveListener = _onCurrentLiveChanged;
  late final LiveListListener _liveListListener;

  void init(Context context) {
    this.context = context;
  }

  void setLiveID(String liveID) {
    roomState.roomId = liveID;
    _subscribeListener();
  }

  void dispose() {
    _unsubscribeListener();
  }

  void prepareLiveInfoBeforeEnterRoom(LiveInfo liveInfo) {
    roomState.roomId = liveInfo.liveID;
    roomState.roomName = liveInfo.liveName;
  }

  void prepareRoomIdBeforeEnterRoom(String roomId) {
    roomState.roomId = roomId;
  }

  void onStartPreview() {
    roomState.liveStatus.value = LiveStatus.previewing;
  }

  void onStartLive(bool isJoinSelf, LiveInfo liveInfo) {
    roomState.liveStatus.value = LiveStatus.pushing;
  }

  void onJoinLive(LiveInfo liveInfo) async {
    roomState.liveStatus.value = LiveStatus.playing;
  }

  void onStopLive() {
    roomState.liveStatus.value = LiveStatus.finished;
  }

  void onLeaveLive() {
    roomState.coverUrl.value = '';
    roomState.liveStatus.value = LiveStatus.none;
    roomState.roomVideoStreamIsLandscape.value = false;
  }

  String getDefaultRoomName() {
    final selfInfo = LoginStore.shared.loginState.loginUserInfo;
    if (selfInfo == null) return '';
    if (selfInfo.nickname == null || selfInfo.nickname!.isEmpty) {
      return selfInfo.userID;
    }
    return selfInfo.nickname!;
  }

  void onSetRoomName(String name) {
    roomState.roomName = name;
  }

  void onSetRoomCoverUrl(String url) {
    roomState.coverUrl.value = url;
  }

  bool isScreenShareLive() {
    // screenShare: VideoLandscape4Seats + keepOwnerOnSeat(true)
    final seatTemplate = roomState.liveInfo.seatTemplate;
    final keepOwnerOnSeat = roomState.liveInfo.keepOwnerOnSeat;
    return seatTemplate is VideoLandscape4Seats && keepOwnerOnSeat;
  }

  bool isObsLive() {
    // obs: VideoLandscape4Seats + keepOwnerOnSeat(false)
    final seatTemplate = roomState.liveInfo.seatTemplate;
    final keepOwnerOnSeat = roomState.liveInfo.keepOwnerOnSeat;
    return seatTemplate is VideoLandscape4Seats && !keepOwnerOnSeat;
  }

  void onUserVideoSizeChanged(int width, int height) {
    var isLandscape = width > height;
    if (!isLandscape && roomState.roomVideoStreamIsLandscape.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    roomState.roomVideoStreamIsLandscape.value = isLandscape;
  }
}

extension RoomManagerCallBack on RoomManager {
  void _onCurrentLiveChanged() {
    LiveInfo liveInfo = LiveListStore.shared.liveState.currentLive.value;
    if (liveInfo.liveID != roomState.roomId) return;
    roomState.liveInfo = liveInfo;
    roomState.roomName = liveInfo.liveName;
    roomState.coverUrl.value = liveInfo.coverURL;
  }
}

extension on RoomManager {
  void _subscribeListener() {
    LiveListStore.shared.liveState.currentLive.addListener(_onCurrentLiveListener);
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      if (roomState.roomId != liveID) return;
      roomState.liveStatus.value = LiveStatus.finished;
    });
    LiveListStore.shared.addLiveListListener(_liveListListener);
  }

  void _unsubscribeListener() {
    LiveListStore.shared.liveState.currentLive.removeListener(_onCurrentLiveListener);
    LiveListStore.shared.removeLiveListListener(_liveListListener);
  }
}
