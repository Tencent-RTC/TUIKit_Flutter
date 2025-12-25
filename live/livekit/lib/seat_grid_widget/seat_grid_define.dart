import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

typedef SeatWidgetBuilder = Widget Function(
    BuildContext context,
    ValueNotifier<SeatInfo> seatInfoNotifier,
    ValueNotifier<int> volumeNotifier);
typedef OnSeatWidgetTap = void Function(SeatInfo);

typedef RequestOnAccepted = Function(TUIUserInfo userInfo);
typedef RequestOnRejected = Function(TUIUserInfo userInfo);
typedef RequestOnCancelled = Function(TUIUserInfo userInfo);
typedef RequestOnTimeout = Function(TUIUserInfo userInfo);
typedef RequestOnError = Function(
    TUIUserInfo userInfo, TUIError code, String message);

typedef OnRoomDismissed = void Function(String roomId);
typedef OnKickedOutOfRoom = void Function(
    String roomId, TUIKickedOutOfRoomReason reason, String message);
typedef OnSeatRequestReceived = void Function(
    RequestType type, TUIUserInfo userInfo);
typedef OnSeatRequestCancelled = void Function(
    RequestType type, TUIUserInfo userInfo);
typedef OnKickedOffSeat = void Function(TUIUserInfo userInfo);
typedef OnUserAudioStateChanged = void Function(
    TUIUserInfo userInfo, bool hasAudio, TUIChangeReason reason);

const int defaultMaxSeatCount = 10;
const int defaultTimeout = 30;

enum RequestType {
  applyToTakeSeat,
  inviteToTakeSeat,
}

enum LayoutMode {
  focus,
  grid,
  vertical,
  free,
}

enum SeatWidgetLayoutRowAlignment {
  spaceAround,
  spaceBetween,
  spaceEvenly,
  start,
  end,
  center,
}

enum RequestResultType {
  onAccepted,
  onRejected,
  onCancelled,
  onTimeout,
  onError,
}

class RequestCallback {
  TUIError code;
  String message;
  RequestResultType type;
  TUIUserInfo userInfo;

  RequestCallback(
      {required this.code,
      required this.message,
      required this.type,
      required this.userInfo});

  @override
  String toString() {
    return "RequestCallback{code:$code, message:$message, type:$type, userInfo:$userInfo}";
  }
}

class SeatWidgetLayoutRowConfig {
  final int count;
  final double seatSpacing;
  final Size seatSize;
  final SeatWidgetLayoutRowAlignment alignment;

  SeatWidgetLayoutRowConfig(
      {this.count = 5,
      this.seatSpacing = 20.0,
      this.seatSize = const Size(50.0, 72.0),
      this.alignment = SeatWidgetLayoutRowAlignment.center});

  @override
  String toString() {
    return 'SeatWidgetLayoutRowConfig{count:$count, seatSpacing:$seatSpacing, seatSize:(width:${seatSize.width}, height:${seatSize.height}), alignment:$alignment}';
  }
}

class SeatWidgetLayoutConfig {
  final List<SeatWidgetLayoutRowConfig> rowConfigs;
  final double rowSpacing;

  SeatWidgetLayoutConfig(
      {List<SeatWidgetLayoutRowConfig>? rowConfigs, this.rowSpacing = 22})
      : rowConfigs = rowConfigs ??
            [SeatWidgetLayoutRowConfig(), SeatWidgetLayoutRowConfig()];

  @override
  String toString() {
    return 'SeatWidgetLayoutConfig{rowConfigs:$rowConfigs, rowSpacing:$rowSpacing}';
  }
}

class SeatGridWidgetObserver {
  OnRoomDismissed onRoomDismissed = (String roomId) {};
  OnKickedOutOfRoom onKickedOutOfRoom =
      (String roomId, TUIKickedOutOfRoomReason reason, String message) {};
  OnSeatRequestReceived onSeatRequestReceived =
      (RequestType type, TUIUserInfo userInfo) {};
  OnSeatRequestCancelled onSeatRequestCancelled =
      (RequestType type, TUIUserInfo userInfo) {};
  OnKickedOffSeat onKickedOffSeat = (TUIUserInfo userInfo) {};
  OnUserAudioStateChanged onUserAudioStateChanged =
      (TUIUserInfo userInfo, bool hasAudio, TUIChangeReason reason) {};

  SeatGridWidgetObserver(
      {OnRoomDismissed? onRoomDismissed,
      OnKickedOutOfRoom? onKickedOutOfRoom,
      OnSeatRequestReceived? onSeatRequestReceived,
      OnSeatRequestCancelled? onSeatRequestCancelled,
      OnKickedOffSeat? onKickedOffSeat,
      OnUserAudioStateChanged? onUserAudioStateChanged}) {
    if (onRoomDismissed != null) {
      this.onRoomDismissed = onRoomDismissed;
    }
    if (onKickedOutOfRoom != null) {
      this.onKickedOutOfRoom = onKickedOutOfRoom;
    }
    if (onSeatRequestReceived != null) {
      this.onSeatRequestReceived = onSeatRequestReceived;
    }
    if (onSeatRequestCancelled != null) {
      this.onSeatRequestCancelled = onSeatRequestCancelled;
    }
    if (onKickedOffSeat != null) {
      this.onKickedOffSeat = onKickedOffSeat;
    }
    if (onUserAudioStateChanged != null) {
      this.onUserAudioStateChanged = onUserAudioStateChanged;
    }
  }
}
