import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../../manager/live_stream_manager.dart';
import 'single_battle_score_widget.dart';

class BattleInfoWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final bool isOwner;
  final ValueListenable<bool> isFloatWindowMode;

  const BattleInfoWidget({
    super.key,
    required this.liveStreamManager,
    required this.isOwner,
    required this.isFloatWindowMode,
  });

  @override
  State<BattleInfoWidget> createState() => _BattleInfoWidgetState();
}

class _BattleInfoWidgetState extends State<BattleInfoWidget> {
  final ValueNotifier<bool> _startImageVisibilityNotifier = ValueNotifier(false);

  late final LiveStreamManager liveStreamManager;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.isFloatWindowMode,
      builder: (context, isFloatWindowMode, child) {
        return Visibility(visible: !isFloatWindowMode, child: buildContent(context));
      },
    );
  }

  Widget buildContent(BuildContext context) {
    LiveListStore liveListStore = LiveListStore.shared;
    final liveID = liveListStore.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    CoHostStore coHostStore = CoHostStore.create(liveID);
    return ListenableBuilder(
      listenable: Listenable.merge([
        liveStreamManager.battleState.isBattleRunning,
        liveStreamManager.battleState.isOnDisplayResult,
        liveStreamManager.battleState.battleUsers,
        coHostStore.coHostState.connected
      ]),
      builder: (context, _) {
        final isBattleRunning = liveStreamManager.battleState.isBattleRunning.value;
        final isOnDisplayResult = liveStreamManager.battleState.isOnDisplayResult.value;
        if (!isBattleRunning && !isOnDisplayResult) return const SizedBox.shrink();
        if (isBattleRunning && widget.isOwner && liveStreamManager.battleState.isShowingStartWidget) {
          _startImageVisibilityNotifier.value = true;
          Future.delayed(const Duration(seconds: 1), () {
            _startImageVisibilityNotifier.value = false;
          });
        }
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Visibility(visible: isBattleRunning || isOnDisplayResult, child: _buildSingleBattleScoreWidget()),
            Visibility(visible: isBattleRunning || isOnDisplayResult, child: _buildBattleTimerWidget()),
            Visibility(visible: isBattleRunning, child: _buildStartImageWidget()),
            Visibility(
                visible: liveStreamManager.battleState.isOnDisplayResult.value, child: _buildResultImageWidget()),
          ],
        );
      },
    );
  }

  Widget _buildSingleBattleScoreWidget() {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    final coHostState = CoHostStore.create(liveID).coHostState;
    final battleUserMap = {for (var user in liveStreamManager.battleState.battleUsers.value) user.userId: user};
    LiveSeatState liveSeatState = LiveSeatStore.create(liveID).liveSeatState;
    List<SeatInfo> seatInfos = liveSeatState.seatList.value;
    final seatMap = {for (var seat in seatInfos) seat.userInfo.userID: seat};

    final connectedBattleUsers = coHostState.connected.value
        .where((user) => battleUserMap.containsKey(user.userID))
        .map((user) => battleUserMap[user.userID]!)
        .toList();

    if (coHostState.connected.value.length != 2 || connectedBattleUsers.length != 2) {
      return const SizedBox.shrink();
    }
    if (seatMap.length != 2 ||
        !seatMap.keys.contains(connectedBattleUsers[0].userId) ||
        !seatMap.keys.contains(connectedBattleUsers[1].userId)) {
      return const SizedBox.shrink();
    }

    // 1v1 battle

    connectedBattleUsers.sort((a, b) => seatMap[a.userId]!.region.x.compareTo(seatMap[b.userId]!.region.x));
    return SingleBattleScoreWidget(
      leftScore: connectedBattleUsers[0].score.toInt(),
      rightScore: connectedBattleUsers[1].score.toInt(),
    );
  }

  Widget _buildBattleTimerWidget() {
    LiveListStore liveListStore = LiveListStore.shared;
    final liveID = liveListStore.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    CoHostStore coHostStore = CoHostStore.create(liveID);
    return ValueListenableBuilder(
      valueListenable: liveStreamManager.battleState.durationCountDown,
      builder: (context, durationCount, _) {
        final isMultipleBattleMode = coHostStore.coHostState.connected.value.length >= 3;
        return Container(
          alignment: Alignment.topCenter,
          height: 40.height,
          padding: EdgeInsets.only(top: isMultipleBattleMode ? 0 : 18.height),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Image.asset(LiveImages.battleTimeBackground,
                  package: Constants.pluginName, width: 72.width, height: 22.height),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(LiveImages.battleClock,
                      package: Constants.pluginName, width: 12.width, height: 12.height),
                  SizedBox(width: 3.width),
                  Text(
                      durationCount == 0
                          ? LiveKitLocalizations.of(Global.appContext())!.common_battle_pk_end
                          : _getFormatTime(durationCount),
                      style: const TextStyle(fontSize: 14, color: LiveColors.designStandardFlowkitWhite))
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartImageWidget() {
    return ValueListenableBuilder(
      valueListenable: _startImageVisibilityNotifier,
      builder: (context, startImageVisibility, _) {
        return Visibility(
          visible: startImageVisibility,
          child: Align(
              alignment: Alignment.center,
              child: Image.asset(LiveImages.battleStart,
                  package: Constants.pluginName, width: 240.width, height: 125.height)),
        );
      },
    );
  }

  Widget _buildResultImageWidget() {
    if (!widget.isOwner) {
      return Align(
        alignment: Alignment.center,
        child: Image.asset(
          _getResultImageName(),
          package: Constants.pluginName,
          width: 234.width,
        ),
      );
    }
    final ownerUserId = LiveListStore.shared.liveState.currentLive.value.liveOwner.userID;
    final isAnchorInBattle =
        widget.liveStreamManager.battleState.battleUsers.value.any((user) => user.userId == ownerUserId);

    return isAnchorInBattle
        ? Center(
            child: Image.asset(
              _getResultImageName(),
              package: Constants.pluginName,
              width: 234.width,
            ),
          )
        : const SizedBox.shrink();
  }

  String _getResultImageName() {
    if (liveStreamManager.battleState.battleUsers.value.isEmpty) {
      return LiveImages.battleResultDraw;
    }
    final ownerId = LiveListStore.shared.liveState.currentLive.value.liveOwner.userID;
    final owner = liveStreamManager.battleState.battleUsers.value.firstWhere(
      (user) => user.userId == ownerId,
      orElse: () => liveStreamManager.battleState.battleUsers.value.first,
    );

    BattleResultType resultType = BattleResultType.draw;
    if (liveStreamManager.battleManager.isBattleDraw()) {
      resultType = BattleResultType.draw;
    } else {
      resultType = owner.ranking == 1 ? BattleResultType.victory : BattleResultType.defeat;
    }
    String imageName = LiveImages.battleResultDraw;
    switch (resultType) {
      case BattleResultType.draw:
        imageName = LiveImages.battleResultDraw;
        break;
      case BattleResultType.victory:
        imageName = LiveImages.battleResultWin;
        break;
      case BattleResultType.defeat:
        imageName = LiveImages.battleResultLose;
        break;
    }
    return imageName;
  }

  String _getFormatTime(int time) {
    return '${time ~/ 60}:${(time % 60).toString().padLeft(2, '0')}';
  }
}

enum BattleResultType { draw, victory, defeat }
