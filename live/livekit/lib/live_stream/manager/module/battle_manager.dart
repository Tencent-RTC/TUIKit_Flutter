import 'dart:async';

import 'package:atomic_x_core/api/live/battle_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/cupertino.dart';

import '../../../common/widget/index.dart';
import '../../../tencent_live_uikit.dart';
import '../../api/live_stream_service.dart';
import '../../state/battle_state.dart';
import '../live_stream_manager.dart';

class BattleManager {
  LSBattleState battleState = LSBattleState();

  late final Context context;
  late final LiveStreamService service;
  Timer? _timer;
  final ValueNotifier<List<SeatUserInfo>> inviteeList = ValueNotifier([]);
  late final VoidCallback onBattleScoreListener = _onBattleScoreChanged;
  late BattleListener? battleListener;

  void init(Context context) {
    this.context = context;
    service = context.service;
  }

  void setLiveID(String liveID) {
    _subscribeListener();
  }

  void dispose() {
    _unsubscribeListener();
  }

  void resetState() {
    battleState.battleId.value = '';
    battleState.battleUsers.value = [];
    battleState.receivedBattleRequest.value = null;
    battleState.durationCountDown.value = 0;
    battleState.battleConfig = BattleConfig();
    battleState.needResponse = true;
    battleState.isInWaiting.value = false;
    battleState.isShowingStartWidget = false;
    battleState.isBattleRunning.value = false;
    battleState.isOnDisplayResult.value = false;
  }

  void onRequestBattle(String battleId, List<SeatUserInfo> battleUserList) {
    battleState.battleId.value = battleId;
    battleState.isInWaiting.value = true;
    inviteeList.value = [...battleUserList];
  }

  void onCanceledBattle() {
    battleState.battleId.value = '';
    battleState.isInWaiting.value = false;
  }

  void onResponseBattle() {
    battleState.receivedBattleRequest.value = null;
  }

  void onBattleExited() {
    battleState.battleId.value = '';
  }

  bool isBattleDraw() {
    BattleUser? firstUser = battleState.battleUsers.value.firstOrNull;
    BattleUser? lastUser = battleState.battleUsers.value.lastOrNull;
    if (firstUser == null || lastUser == null) {
      return false;
    }
    return firstUser.ranking == lastUser.ranking;
  }
}

extension BattlleManagerCallback on BattleManager {
  void _onBattleStarted(BattleInfo battleInfo, SeatUserInfo inviter, List<SeatUserInfo> invitees) {
    final liveID = _getLiveID();
    BattleStore battleStore = BattleStore.create(liveID);
    battleStore.battleState.battleScore.addListener(onBattleScoreListener);

    battleInfo.config.duration =
        battleInfo.config.duration + battleInfo.startTime - (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    battleState.battleId.value = battleInfo.battleID;
    battleState.isBattleRunning.value = true;
    battleState.isInWaiting.value = false;
    battleState.isShowingStartWidget = true;
    battleState.battleConfig = BattleConfig(
        duration: battleInfo.config.duration,
        needResponse: battleInfo.config.needResponse,
        extensionInfo: battleInfo.config.extensionInfo);
    battleState.durationCountDown.value = battleInfo.config.duration;
    final battleUsers = [
      ...invitees.map((battleUser) => BattleUser.fromSeatUserInfo(battleUser)),
      BattleUser.fromSeatUserInfo(inviter),
    ];
    battleState.battleUsers.value = battleUsers;

    _startCountDown();

    Future.delayed(const Duration(milliseconds: 500), () {
      battleState.isShowingStartWidget = false;
    });
  }

  void _onBattleEnded(BattleInfo battleInfo) {
    final liveID = _getLiveID();
    BattleStore battleStore = BattleStore.create(liveID);
    battleStore.battleState.battleScore.removeListener(onBattleScoreListener);

    battleState.durationCountDown.value = 0;
    battleState.isOnDisplayResult.value = true;
    battleState.isBattleRunning.value = false;

    _stopCountDown();

    Future.delayed(const Duration(seconds: 5), () {
      battleState.isOnDisplayResult.value = false;
      resetState();
    });
  }

  void _onUserJoinBattle(String battleId, SeatUserInfo battleUser) {
    if (battleId != battleState.battleId.value) {
      return;
    }
    final newBattleUsers = battleState.battleUsers.value.toList();
    newBattleUsers.add(BattleUser.fromSeatUserInfo(battleUser));
    battleState.battleUsers.value = newBattleUsers;
  }

  void _onUserExitBattle(String battleId, SeatUserInfo battleUser) {
    if (battleState.battleUsers.value.length == 2) {
      return;
    }

    if (battleState.battleUsers.value.any((user) => user.userId == battleUser.userID)) {
      final newBattleUsers = battleState.battleUsers.value.toList();
      newBattleUsers.removeWhere((user) => user.userId == battleUser.userID);
      battleState.battleUsers.value = newBattleUsers;
    }

    _sortedBattleUsersByScore(battleState.battleUsers.value);
  }

  void _onBattleScoreChanged() {
    final liveID = _getLiveID();
    BattleStore battleStore = BattleStore.create(liveID);
    List<SeatUserInfo> battleUsers = battleStore.battleState.battleUsers.value;
    Map<String, int> battleScore = battleStore.battleState.battleScore.value;
    _sortedBattleUsersByScore(battleUsers.map((battleUser) {
      final user = BattleUser.fromSeatUserInfo(battleUser);
      user.score = battleScore[battleUser.userID] ?? 0;
      return user;
    }).toList());
  }

  void _onBattleRequestReceived(String battleId, SeatUserInfo inviter, SeatUserInfo invitee) {
    battleState.battleId.value = battleId;
    battleState.receivedBattleRequest.value = (battleId, BattleUser.fromSeatUserInfo(inviter));
  }

  void _onBattleRequestCancelled(String battleId, SeatUserInfo inviter, SeatUserInfo invitee) {
    battleState.receivedBattleRequest.value = null;

    final toast =
        LiveKitLocalizations.of(Global.appContext())!.common_battle_inviter_cancel.replaceAll("xxx", inviter.userName);
    context.toastSubject.target?.add(toast);
  }

  void _onBattleRequestTimeout(String battleId, SeatUserInfo inviter, SeatUserInfo invitee) {
    if (battleState.receivedBattleRequest.value?.$1 == battleId) {
      battleState.receivedBattleRequest.value = null;
    }
    battleState.isInWaiting.value = false;

    final toast = LiveKitLocalizations.of(Global.appContext())!.common_battle_invitation_timeout;
    context.toastSubject.target?.add(toast);
  }

  void _onBattleRequestAccept(String battleId, SeatUserInfo inviter, SeatUserInfo invitee) {
    final newInviteeList = inviteeList.value.toList();
    newInviteeList.removeWhere((user) => user.userID == invitee.userID);
    inviteeList.value = newInviteeList;
    if (inviteeList.value.isEmpty) {
      battleState.isInWaiting.value = false;
    }
  }

  void _onBattleRequestReject(String battleId, SeatUserInfo inviter, SeatUserInfo invitee) {
    final newInviteeList = inviteeList.value.toList();
    newInviteeList.removeWhere((user) => user.userID == invitee.userID);
    inviteeList.value = newInviteeList;
    if (inviteeList.value.isEmpty) {
      battleState.isInWaiting.value = false;
    }

    final toast =
        LiveKitLocalizations.of(Global.appContext())!.common_battle_invitee_reject.replaceAll("xxx", invitee.userName);
    context.toastSubject.target?.add(toast);
  }
}

extension on BattleManager {
  void _subscribeListener() {
    final liveID = _getLiveID();
    if (liveID.isEmpty) return;
    BattleStore battleStore = BattleStore.create(liveID);
    battleListener = BattleListener(
      onBattleStarted: (BattleInfo battleInfo, SeatUserInfo inviter, List<SeatUserInfo> invitees) {
        _onBattleStarted(battleInfo, inviter, invitees);
      },
      onBattleEnded: (BattleInfo battleInfo, BattleEndedReason? reason) {
        _onBattleEnded(battleInfo);
      },
      onUserJoinBattle: (String battleID, SeatUserInfo battleUser) {
        _onUserJoinBattle(battleID, battleUser);
      },
      onUserExitBattle: (String battleID, SeatUserInfo battleUser) {
        _onUserExitBattle(battleID, battleUser);
      },
      onBattleRequestReceived: (String battleID, SeatUserInfo inviter, SeatUserInfo invitee) {
        _onBattleRequestReceived(battleID, inviter, invitee);
      },
      onBattleRequestCancelled: (String battleID, SeatUserInfo inviter, SeatUserInfo invitee) {
        _onBattleRequestCancelled(battleID, inviter, invitee);
      },
      onBattleRequestTimeout: (String battleID, SeatUserInfo inviter, SeatUserInfo invitee) {
        _onBattleRequestTimeout(battleID, inviter, invitee);
      },
      onBattleRequestAccept: (String battleID, SeatUserInfo inviter, SeatUserInfo invitee) {
        _onBattleRequestAccept(battleID, inviter, invitee);
      },
      onBattleRequestReject: (String battleID, SeatUserInfo inviter, SeatUserInfo invitee) {
        _onBattleRequestReject(battleID, inviter, invitee);
      },
    );
    battleStore.addBattleListener(battleListener!);
  }

  void _unsubscribeListener() {
    final liveID = _getLiveID();
    if (liveID.isEmpty) return;
    BattleStore battleStore = BattleStore.create(liveID);
    if (battleListener != null) battleStore.removeBattleListener(battleListener!);
  }

  void _startCountDown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (battleState.durationCountDown.value > 0) {
        battleState.durationCountDown.value -= 1;
      } else {
        _timer?.cancel();
      }
    });
  }

  void _stopCountDown() {
    _timer?.cancel();
  }

  void _sortedBattleUsersByScore(List<BattleUser> battleUsers) {
    if (battleUsers.length < 2) {
      return;
    }
    // 1. Sort with score
    battleUsers.sort((a, b) => b.score.compareTo(a.score));

    // 2. If the second and subsequent shares are the same, the ranking is the same as the previous one, otherwise it is equal to the current number + 1
    List<BattleUser> finalUsers = [];
    for (int index = 0; index < battleUsers.length; index++) {
      BattleUser updatedUser = battleUsers[index];
      if (index > 0 && updatedUser.score == battleUsers[index - 1].score) {
        updatedUser.ranking = battleUsers[index - 1].ranking;
      } else {
        updatedUser.ranking = index + 1;
      }

      finalUsers.add(updatedUser);
    }

    battleState.battleUsers.value = finalUsers;
  }

  String _getLiveID() {
    return context.roomManager.target?.roomState.roomId ?? '';
  }

  String _getSelfID() {
    return TUIRoomEngine.getSelfInfo().userId;
  }
}
