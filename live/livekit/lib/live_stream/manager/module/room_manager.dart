import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/services.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../api/live_stream_service.dart';
import '../../live_define.dart';
import '../../state/room_state.dart';
import '../live_stream_manager.dart';

class RoomManager {
  LSRoomState roomState = LSRoomState();

  late final Context context;
  late final LiveStreamService service;
  late final VoidCallback _onLiveCanvasListener = _onLiveCanvasChanged;
  late final VoidCallback _onCurrentLiveListener = _onCurrentLiveChanged;

  void init(Context context) {
    this.context = context;
    service = context.service;
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
    roomState.createTime = liveInfo.createTime;
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
    roomState = LSRoomState();
  }

  String getDefaultRoomName() {
    final selfInfo = TUIRoomEngine.getSelfInfo();
    if (selfInfo.userName == null || selfInfo.userName!.isEmpty) {
      return selfInfo.userId;
    }
    return selfInfo.userName!;
  }

  Future<TUIValueCallBack<TUILiveInfo>> fetchLiveInfo(String roomId) async {
    final result = await service.fetchLiveInfo(roomId);
    if (result.code != TUIError.success || result.data == null) {
      return TUIValueCallBack(code: result.code, message: result.message);
    }
    return result;
  }

  void onSetRoomName(String name) {
    roomState.roomName = name;
  }

  void onSetRoomPrivacy(LiveStreamPrivacyStatus mode) {
    roomState.liveExtraInfo.liveMode = mode;
  }

  void onSetRoomCoverUrl(String url) {
    roomState.coverUrl.value = url;
  }

  void onReceiveGift(int price, String senderUserId) {
    roomState.liveExtraInfo.giftIncome += price;
    roomState.liveExtraInfo.giftPeopleSet.add(senderUserId);
  }
}

extension RoomManagerCallBack on RoomManager {
  void onLiveEnd(String roomId) {
    if (roomId != roomState.roomId) {
      return;
    }
    roomState.liveStatus.value = LiveStatus.finished;
  }

  void onKickedOutOfRoom(String roomId, TUIKickedOutOfRoomReason reason, String message) {
    if (roomId != roomState.roomId) {
      return;
    }
    context.kickedOutSubject.target?.add(null);
  }

  void onRoomUserCountChanged(String roomId, int userCount) {
    if (roomId != roomState.roomId) {
      return;
    }
    if (userCount > 0) {
      roomState.userCount = userCount - 1;
      if (userCount > roomState.liveExtraInfo.maxAudienceCount) {
        roomState.liveExtraInfo.maxAudienceCount = userCount - 1;
      }
    }
  }

  void _onCurrentLiveChanged() {
    LiveInfo liveInfo = LiveListStore.shared.liveState.currentLive.value;
    if (liveInfo.liveID.isEmpty) {
      roomState.liveStatus.value = LiveStatus.finished;
      return;
    }
    roomState.liveInfo = liveInfo;
    roomState.roomId = liveInfo.liveID;
    roomState.createTime = liveInfo.createTime;
    roomState.roomName = liveInfo.liveName;
    roomState.coverUrl.value = liveInfo.coverURL;
    roomState.liveExtraInfo.liveMode =
        liveInfo.isPublicVisible ? LiveStreamPrivacyStatus.public : LiveStreamPrivacyStatus.privacy;
    roomState.liveExtraInfo.activeStatus = liveInfo.activityStatus;
  }

  void _onLiveCanvasChanged() {
    final liveID = roomState.roomId;
    if (liveID.isEmpty || LiveListStore.shared.liveState.currentLive.value.liveID != liveID) return;
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    final canvas = liveSeatStore.liveSeatState.canvas.value;
    var isLandscape = canvas.w >= canvas.h;
    if (!isLandscape && roomState.roomVideoStreamIsLandscape.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    roomState.roomVideoStreamIsLandscape.value = isLandscape;
  }
}

extension on RoomManager {
  void _subscribeListener() {
    final liveID = roomState.roomId;
    if (liveID.isEmpty) return;
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    liveSeatStore.liveSeatState.canvas.addListener(_onLiveCanvasListener);
    LiveListStore.shared.liveState.currentLive.addListener(_onCurrentLiveListener);
  }

  void _unsubscribeListener() {
    final liveID = roomState.roomId;
    if (liveID.isEmpty) return;
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    liveSeatStore.liveSeatState.canvas.removeListener(_onLiveCanvasListener);
    LiveListStore.shared.liveState.currentLive.removeListener(_onCurrentLiveListener);
  }
}
