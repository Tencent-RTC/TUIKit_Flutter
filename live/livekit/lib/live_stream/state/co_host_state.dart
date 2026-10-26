import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/cupertino.dart';

class LSCoHostState {
  String currentRoomId = '';
  final ValueNotifier<List<SeatUserInfo>> recommendedUsers = ValueNotifier([]);
}

enum TUIConnectionStatus { none, inviting, connected }

final _connectionStatus = Expando<TUIConnectionStatus>();

extension SeatUserInfoWithStatus on SeatUserInfo {
  TUIConnectionStatus? get connectionStatus => _connectionStatus[this];

  set connectionStatus(TUIConnectionStatus? status) =>
      _connectionStatus[this] = status;
}
