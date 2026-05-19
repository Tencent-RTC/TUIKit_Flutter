import 'package:flutter/material.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';
import 'package:atomic_x_core/atomicxcore.dart';

class LSUserState {
  final ValueNotifier<Set<TUIUserInfo>> userList = ValueNotifier({});
  Set<String> speakingUserList = {};
  Set<TUIUserInfo> myFollowingUserList = {};
  ValueNotifier<LiveUserInfo> enterUser = ValueNotifier(LiveUserInfo());
}
