import 'dart:ui';

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../api/live_stream_service.dart';
import '../../state/co_guest_state.dart';
import '../live_stream_manager.dart';

class CoGuestManager {
  LSCoGuestState coGuestState = LSCoGuestState();

  late final Context context;
  late final LiveStreamService service;

  late final VoidCallback _onSeatListListener = _onSeatListChanged;
  late GuestListener? guestListener;

  void init(Context context) {
    this.context = context;
    service = context.service;
  }

  void setLiveID(String liveID) {
    _subscribeListener();
  }

  void updateOpenCameraAfterTakeSeat(bool open) {
    coGuestState.openCameraAfterTakeSeat.value = open;
  }

  void dispose() {
    _unSubscribeListener();
  }

  Future<TUIActionCallback> onLockMediaStatusBtnClicked(String userId, TUISeatLockParams params) async {
    final liveID = _getLiveID();
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    final seatIndex =
        liveSeatStore.liveSeatState.seatList.value.where((seat) => seat.userInfo.userID == userId).firstOrNull?.index;

    return seatIndex != null
        ? service.lockSeatByAdmin(seatIndex, params)
        : TUIActionCallback(code: TUIError.errUserNotInSeat, message: 'Not on the seat');
  }

  void onStartRequestIntraRoomConnection() {
    coGuestState.coGuestStatus.value = CoGuestStatus.applying;
  }

  void onRequestIntraRoomConnectionFailed() {
    coGuestState.coGuestStatus.value = CoGuestStatus.none;
  }

  void _onGuestApplicationResponded(bool isAccept) async {
    if (!isAccept) {
      context.toastSubject.target
          ?.add(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_take_seat_rejected);
      coGuestState.coGuestStatus.value = CoGuestStatus.none;
      return;
    }
    await context.mediaManager.target?.openLocalMicrophone();
    if (coGuestState.openCameraAfterTakeSeat.value) {
      context.mediaManager.target?.openLocalCamera(DeviceStore.shared.state.isFrontCamera.value);
    }
  }

  void _onGuestApplicationNoResponse(NoResponseReason reason) {
    if (reason == NoResponseReason.timeout) {
      context.toastSubject.target
          ?.add(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_take_seat_timeout);
      coGuestState.coGuestStatus.value = CoGuestStatus.none;
    }
  }

  void _onKickedOffSeat() {
    context.toastSubject.target?.add(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_kicked_out_of_seat);
    coGuestState.coGuestStatus.value = CoGuestStatus.none;
  }

  void onStartCancelIntraRoomConnection() {
    coGuestState.coGuestStatus.value = CoGuestStatus.none;
  }

  void onCancelIntraRoomConnection() {
    coGuestState.coGuestStatus.value = CoGuestStatus.none;
  }
}

extension on CoGuestManager {
  void _subscribeListener() {
    final liveID = _getLiveID();
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    liveSeatStore.liveSeatState.seatList.addListener(_onSeatListListener);

    guestListener = GuestListener(
      onHostInvitationReceived: (LiveUserInfo hostUser) {},
      onHostInvitationCancelled: (LiveUserInfo hostUser) {},
      onGuestApplicationResponded: (bool isAccept, LiveUserInfo hostUser) {
        _onGuestApplicationResponded(isAccept);
      },
      onGuestApplicationNoResponse: (NoResponseReason reason) {
        _onGuestApplicationNoResponse(reason);
      },
      onKickedOffSeat: (int seatIndex, LiveUserInfo hostUser) {
        _onKickedOffSeat();
      },
    );

    CoGuestStore coGuestStore = CoGuestStore.create(liveID);
    coGuestStore.addGuestListener(guestListener!);
  }

  void _unSubscribeListener() {
    final liveID = _getLiveID();
    if (liveID.isEmpty) return;
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    liveSeatStore.liveSeatState.seatList.removeListener(_onSeatListListener);
    CoGuestStore coGuestStore = CoGuestStore.create(liveID);
    if (guestListener != null) coGuestStore.removeGuestListener(guestListener!);
  }

  void _onSeatListChanged() {
    final liveID = _getLiveID();
    LiveSeatStore liveSeatStore = LiveSeatStore.create(liveID);
    final seatList = liveSeatStore.liveSeatState.seatList.value;
    _updateCoGuestStatusBySeatList(seatList);
    _updateMediaLockStatus(seatList);
    if (!seatList.any((seat) => seat.userInfo.userID == _getSelfID())) {
      context.mediaManager.target?.onSelfLeaveSeat();
    }
  }

  void _updateCoGuestStatusBySeatList(List<SeatInfo> seatList) {
    final linkSeatList =
        seatList.where((seat) => seat.userInfo.liveID == _getLiveID() && seat.userInfo.userID.isNotEmpty).toList();
    final isLinking = linkSeatList.any((seat) => seat.userInfo.userID == _getSelfID());
    if (isLinking) {
      coGuestState.coGuestStatus.value = CoGuestStatus.linking;
    } else {
      if (coGuestState.coGuestStatus.value != CoGuestStatus.applying) {
        coGuestState.coGuestStatus.value = CoGuestStatus.none;
      }
    }
  }

  void _updateMediaLockStatus(List<SeatInfo> seatList) {
    final newLockAudioUserList = coGuestState.lockAudioUserList.value.toSet();
    final newLockVideoUSerList = coGuestState.lockVideoUserList.value.toSet();
    for (final seatInfo in seatList) {
      if (seatInfo.userInfo.userID.isEmpty) {
        continue;
      }
      bool isAudioLocked = !seatInfo.userInfo.allowOpenMicrophone;
      isAudioLocked
          ? newLockAudioUserList.add(seatInfo.userInfo.userID)
          : newLockAudioUserList.remove(seatInfo.userInfo.userID);
      coGuestState.lockAudioUserList.value = newLockAudioUserList;

      bool isVideoLocked = !seatInfo.userInfo.allowOpenCamera;
      isVideoLocked
          ? newLockVideoUSerList.add(seatInfo.userInfo.userID)
          : newLockVideoUSerList.remove(seatInfo.userInfo.userID);
      coGuestState.lockVideoUserList.value = newLockVideoUSerList;

      if (seatInfo.userInfo.userID == _getSelfID()) {
        context.mediaManager.target?.onSelfMediaDeviceStateChanged(seatInfo);
      }
    }
  }

  String _getLiveID() {
    return context.roomManager.target!.roomState.roomId;
  }

  String _getSelfID() {
    return TUIRoomEngine.getSelfInfo().userId;
  }
}
