import 'package:atomic_x_core/api/live/battle_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';

class LSBattleState {
  static const int battleDuration = 30;
  static const int battleRequestTime = 10;
  static const int battleEndInfoDuration = 5;

  final ValueNotifier<String> battleId = ValueNotifier('');
  final ValueNotifier<List<BattleUser>> battleUsers = ValueNotifier([]);
  final ValueNotifier<ReceivedBattleRequest?> receivedBattleRequest = ValueNotifier(null);
  final ValueNotifier<int> durationCountDown = ValueNotifier(0);
  BattleConfig battleConfig = BattleConfig();
  bool needResponse = true;

  final ValueNotifier<bool> isInWaiting = ValueNotifier(false);
  bool isShowingStartWidget = false;
  final ValueNotifier<bool> isBattleRunning = ValueNotifier(false);
  final ValueNotifier<bool> isOnDisplayResult = ValueNotifier(false);
}

typedef ReceivedBattleRequest = (String battleId, BattleUser inviter);

class BattleUser {
  String roomId;
  String userId;
  String avatarUrl;
  String userName;
  int score;
  int ranking;

  BattleUser(
      {this.roomId = '',
      this.userId = '',
      this.avatarUrl = '',
      this.userName = '',
      this.score = 0,
      this.ranking = 1});

  BattleUser.fromSeatUserInfo(SeatUserInfo battleUser)
      : roomId = battleUser.liveID,
        userId = battleUser.userID,
        avatarUrl = battleUser.avatarURL,
        userName = battleUser.userName,
        score = 0,
        ranking = 1;

  @override
  String toString() {
    return 'BattleUser{roomId: $roomId, userId: $userId, avatarUrl: $avatarUrl, userName: $userName, score: $score, ranking: $ranking}';
  }
}
