import 'dart:async';
import 'dart:math';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/co_guest/anchor_empty_seat_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/index.dart';
import 'package:tencent_live_uikit/live_stream/state/battle_state.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../../common/widget/base_bottom_sheet.dart';
import '../../manager/live_stream_manager.dart';
import '../decorations/co_guest/co_guest_seat_list_widget.dart';
import '../decorations/index.dart';
import 'battle/battle_count_down_widget.dart';
import 'co_guest/anchor_co_guest_user_management_panel.dart';
import 'co_host/co_host_user_management_panel.dart';
import 'living_widget/anchor_living_widget.dart';

class AnchorBroadcastWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final LiveCoreController liveCoreController;
  final VoidCallback? onTapEnterFloatWindowInApp;

  const AnchorBroadcastWidget(
      {super.key, required this.liveStreamManager, required this.liveCoreController, this.onTapEnterFloatWindowInApp});

  @override
  State<AnchorBroadcastWidget> createState() => _AnchorBroadcastWidgetState();
}

class _AnchorBroadcastWidgetState extends State<AnchorBroadcastWidget> {
  final ValueNotifier<TUILiveStatisticsData?> liveStatisticsData = ValueNotifier(null);
  final ValueNotifier<LiveEndedReason?> liveEndedReason = ValueNotifier(null);
  late final LiveStreamManager liveStreamManager;
  late final LiveCoreController liveCoreController;
  late final StreamSubscription<String> _toastSubscription;
  late final VoidCallback _connectionRequestListener = _handleConnectionRequest;
  late final VoidCallback _battleRequestListener = _handleBattleRequest;
  late final VoidCallback _battleWaitingStatusListener = _handleBattleWaitingStatusChanged;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;
  AlertHandler? _connectRequestAlertHandler;
  AlertHandler? _battleRequestAlertHandler;
  AlertHandler? _battleWaitingSheetHandler;
  BottomSheetHandler? _userManagementPanelSheetHandler;

  late final CoHostStore coHostStore;
  late final BattleStore battleStore;
  late final CoGuestStore coGuestStore;
  late final LiveListListener _liveListListener;
  late final HostListener _hostListener;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    liveCoreController = widget.liveCoreController;
    coHostStore = CoHostStore.create(widget.liveStreamManager.roomState.roomId);
    battleStore = BattleStore.create(widget.liveStreamManager.roomState.roomId);
    coGuestStore = CoGuestStore.create(widget.liveStreamManager.roomState.roomId);
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _closeAllDialog();
    });
    _hostListener = HostListener(onGuestApplicationReceived: (guestUser) {
      _rejectCoGuestApplicationIfNeeded(guestUser);
    });
    _addObserver();
  }

  @override
  void dispose() {
    _removeObserver();
    super.dispose();
  }

  void _closeAllDialog() {
    _connectRequestAlertHandler?.close();
    _battleRequestAlertHandler?.close();
    _battleWaitingSheetHandler?.close();
    _userManagementPanelSheetHandler?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        child: Container(
          color: LiveColors.notStandardPureBlack,
          child: Stack(
            children: [
              _buildMainWidget(),
              _buildLivingWidget(),
              _buildSeatListWidget(),
              _buildDashboardWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainWidget() {
    if (liveStreamManager.roomState.liveInfo.seatTemplate is VideoLandscape4Seats) {
      if (liveStreamManager.roomState.liveInfo.keepOwnerOnSeat) {
        return SizedBox(
          width: 1.screenWidth,
          height: 1.screenHeight,
          child: Stack(
            children: [
              SizedBox(
                width: 1.screenWidth,
                height: 1.screenHeight,
                child: Image.asset(LiveImages.defaultBackground, fit: BoxFit.cover, package: Constants.pluginName),
              ),
              Container(
                margin: EdgeInsets.only(top: 120.height),
                height: 200.height,
                child: Center(
                  child: Text(
                    LiveKitLocalizations.of(Global.appContext())!.common_live_game,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return LayoutBuilder(builder: (context, constraints) {
        final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isFloating = widget.liveStreamManager.floatWindowState.isFloatWindowMode.value;
        double height = isFloating ? screenHeight : (isPortrait ? 9 / 16.0 * screenWidth : screenHeight);
        double top = isFloating ? 0 : (isPortrait ? 120.height : 0);
        return Container(
          color: isFloating ? Colors.transparent : Colors.black,
          margin: EdgeInsets.only(top: top),
          width: screenWidth,
          height: height,
          child: LiveCoreWidget(controller: widget.liveCoreController),
        );
      });
    } else {
      return _buildCoreWidget();
    }
  }

  Widget _buildCoreWidget() {
    final isFloatWindowMode = liveStreamManager.floatWindowState.isFloatWindowMode;
    return Padding(
      padding: isFloatWindowMode.value ? EdgeInsets.zero : EdgeInsets.only(top: 44.height, bottom: 96.height),
      child: ClipRRect(
        borderRadius: isFloatWindowMode.value ? BorderRadius.zero : BorderRadius.circular(16.radius),
        child: LiveCoreWidget(
          controller: liveCoreController,
          videoWidgetBuilder: VideoWidgetBuilder(
              coGuestWidgetBuilder: _createCoGuestWidgetBuilder(),
              coHostWidgetBuilder: _createCoHostWidgetBuilder(),
              battleWidgetBuilder: (context, seatInfo) {
                return BattleMemberInfoWidget(
                  liveStreamManager: liveStreamManager,
                  battleUserId: seatInfo.userInfo.userID,
                  isFloatWindowMode: isFloatWindowMode,
                );
              },
              battleContainerWidgetBuilder: (context) {
                return BattleInfoWidget(
                  liveStreamManager: liveStreamManager,
                  isOwner: true,
                  isFloatWindowMode: isFloatWindowMode,
                );
              }),
        ),
      ),
    );
  }

  Widget _buildSeatListWidget() {
    if (widget.liveStreamManager.roomManager.isScreenShareLive()) {
      return Center(
        child: CoGuestSeatListWidget(
          liveID: widget.liveStreamManager.roomState.roomId,
          onTapSeat: (seatInfo) {
            if (seatInfo.userInfo.userID.isEmpty) return;
            _onTapCoGuestForegroundWidget(seatInfo);
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  CoGuestWidgetBuilder _createCoGuestWidgetBuilder() {
    final isFloatWindowMode = liveStreamManager.floatWindowState.isFloatWindowMode;
    return (context, seatInfo, viewLayer) {
      if (seatInfo.userInfo.userID.isEmpty) {
        if (viewLayer == ViewLayer.background) {
          return AnchorEmptySeatWidget(seatInfo: seatInfo, liveStreamManager: liveStreamManager);
        } else {
          return Container();
        }
      }
      if (viewLayer == ViewLayer.background) {
        return CoGuestBackgroundWidget(seatInfo: seatInfo, isFloatWindowMode: isFloatWindowMode);
      } else {
        return CoGuestForegroundWidget(
          seatInfo: seatInfo,
          isFloatWindowMode: isFloatWindowMode,
          onTap: () => _onTapCoGuestForegroundWidget(seatInfo),
        );
      }
    };
  }

  CoHostWidgetBuilder _createCoHostWidgetBuilder() {
    final isFloatWindowMode = liveStreamManager.floatWindowState.isFloatWindowMode;
    return (context, seatInfo, viewLayer) {
      if (viewLayer == ViewLayer.background) {
        return CoHostBackgroundWidget(seatInfo: seatInfo, isFloatWindowMode: isFloatWindowMode);
      } else {
        return CoHostForegroundWidget(
          seatInfo: seatInfo,
          isFloatWindowMode: isFloatWindowMode,
          onTap: () => _onTapCoHostForegroundWidget(seatInfo),
        );
      }
    };
  }

  Widget _buildLivingWidget() {
    return AnchorLivingWidget(
      liveStreamManager: liveStreamManager,
      onEndLive: (data, reason) {
        liveStatisticsData.value = data;
        liveEndedReason.value = reason;
      },
      onTapEnterFloatWindowInApp: widget.onTapEnterFloatWindowInApp,
    );
  }

  Widget _buildDashboardWidget() {
    return ValueListenableBuilder(
        valueListenable: liveStatisticsData,
        builder: (context, statisticsData, _) {
          if (statisticsData == null) return const SizedBox.shrink();
          var endInfo = AnchorEndStatisticsWidgetInfo(
              roomId: liveStreamManager.roomState.roomId,
              liveDuration: statisticsData.liveDuration,
              viewCount: max(statisticsData.totalViewers - 1, 0),
              messageCount: statisticsData.totalMessageCount,
              giftIncome: statisticsData.totalGiftCoins,
              giftSenderCount: statisticsData.totalUniqueGiftSenders,
              likeCount: statisticsData.totalLikesReceived,
              liveEndedReason: liveEndedReason.value ?? LiveEndedReason.endedByHost);
          return AnchorEndStatisticsWidget(endWidgetInfo: endInfo);
        });
  }
}

extension on _AnchorBroadcastWidgetState {
  void _addObserver() {
    LiveListStore.shared.addLiveListListener(_liveListListener);
    coHostStore.coHostState.applicant.addListener(_connectionRequestListener);
    coGuestStore.addHostListener(_hostListener);
    liveStreamManager.battleState.receivedBattleRequest.addListener(_battleRequestListener);
    liveStreamManager.battleState.isInWaiting.addListener(_battleWaitingStatusListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_isFloatWindowModeListener);

    _toastSubscription = liveStreamManager.toastSubject.stream.listen((toast) {
      if (!mounted) return;
      makeToast(context, toast);
    });
  }

  void _removeObserver() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    coHostStore.coHostState.applicant.removeListener(_connectionRequestListener);
    coGuestStore.removeHostListener(_hostListener);
    liveStreamManager.battleState.receivedBattleRequest.removeListener(_battleRequestListener);
    liveStreamManager.battleState.isInWaiting.removeListener(_battleWaitingStatusListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_isFloatWindowModeListener);

    _toastSubscription.cancel();
  }

  void _handleConnectionRequest() {
    if (coHostStore.coHostState.applicant.value == null && _connectRequestAlertHandler?.isShowing() == true) {
      _connectRequestAlertHandler?.close();
      return;
    }

    if (coHostStore.coHostState.applicant.value != null && _connectRequestAlertHandler?.isShowing() != true) {
      final inviter = coHostStore.coHostState.applicant.value!;
      if (!_canAcceptCoHostInvitation()) {
        _responseCoHostInvitation(inviter, false);
        return;
      }
      final alertInfo = AlertInfo(
          description: LiveKitLocalizations.of(Global.appContext())!
              .common_connect_inviting_append
              .replaceAll("xxx", inviter.userName),
          cancelText: LiveKitLocalizations.of(Global.appContext())!.common_reject,
          cancelCallback: () {
            _responseCoHostInvitation(inviter, false);
          },
          defaultText: LiveKitLocalizations.of(Global.appContext())!.common_accept,
          defaultCallback: () {
            _responseCoHostInvitation(inviter, true);
          });
      bool showContent = !liveStreamManager.floatWindowState.isFloatWindowMode.value;
      _connectRequestAlertHandler = Alert.showAlert(alertInfo, context, showContent: showContent);
    }
  }

  void _responseCoHostInvitation(SeatUserInfo inviter, bool isAccepted) async {
    _connectRequestAlertHandler?.close();

    if (isAccepted) {
      coHostStore.acceptHostConnection(inviter.liveID).then((result) {
        if (result.errorCode != TUIError.success.rawValue) {
          liveStreamManager.toastSubject
              .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        }
      });
    } else {
      coHostStore.rejectHostConnection(inviter.liveID).then((result) {
        if (result.errorCode != TUIError.success.rawValue) {
          liveStreamManager.toastSubject
              .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        }
      });
    }
  }

  bool _canAcceptCoHostInvitation() {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    final coGuestState = coGuestStore.coGuestState;
    if (coGuestState.applicants.value.isNotEmpty ||
        coGuestState.connected.value.where((user) => user.userID != selfUserId).isNotEmpty ||
        coGuestState.invitees.value.isNotEmpty) {
      return false;
    }
    return true;
  }

  void _handleBattleRequest() {
    if (liveStreamManager.battleState.receivedBattleRequest.value == null &&
        _battleRequestAlertHandler?.isShowing() == true) {
      _battleRequestAlertHandler?.close();
      return;
    }

    if (liveStreamManager.battleState.receivedBattleRequest.value != null &&
        _battleRequestAlertHandler?.isShowing() != true) {
      final battleId = liveStreamManager.battleState.receivedBattleRequest.value!.$1;
      final inviter = liveStreamManager.battleState.receivedBattleRequest.value!.$2;
      final alertInfo = AlertInfo(
          description:
              LiveKitLocalizations.of(Global.appContext())!.common_battle_inviting.replaceAll("xxx", inviter.userName),
          cancelText: LiveKitLocalizations.of(Global.appContext())!.common_reject,
          cancelCallback: () {
            _responseBattleInvitation(battleId, false);
          },
          defaultText: LiveKitLocalizations.of(Global.appContext())!.common_receive,
          defaultCallback: () {
            _responseBattleInvitation(battleId, true);
          });

      bool showContent = !liveStreamManager.floatWindowState.isFloatWindowMode.value;
      _battleRequestAlertHandler = Alert.showAlert(alertInfo, context, showContent: showContent);
    }
  }

  void _responseBattleInvitation(String battleId, bool isAccepted) async {
    _battleRequestAlertHandler?.close();
    liveStreamManager.onResponseBattle();
    if (isAccepted) {
      battleStore.acceptBattle(battleId).then((result) {
        if (result.errorCode != TUIError.success.rawValue) {
          liveStreamManager.toastSubject
              .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        }
      });
    } else {
      battleStore.rejectBattle(battleId).then((result) {
        if (result.errorCode != TUIError.success.rawValue) {
          liveStreamManager.toastSubject
              .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        }
      });
    }
  }

  void _handleBattleWaitingStatusChanged() {
    if (!liveStreamManager.battleState.isInWaiting.value && _battleWaitingSheetHandler?.isShowing() == true) {
      _battleWaitingSheetHandler?.close();
      return;
    }

    if (liveStreamManager.battleState.isInWaiting.value && _battleWaitingSheetHandler?.isShowing() != true) {
      _battleWaitingSheetHandler = Alert.showAlertWidget(
        context: context,
        builder:(_) {
          return BattleCountDownWidget(
            countdownTime: LSBattleState.battleRequestTime,
            onCancel: () async {
              final inviteeIdList = coHostStore.coHostState.connected.value
                  .map((user) => user.userID)
                  .where((userID) => userID != TUIRoomEngine.getSelfInfo().userId)
                  .toList();
              battleStore.cancelBattleRequest(
                  battleID: liveStreamManager.battleState.battleId.value, userIDList: inviteeIdList);
              liveStreamManager.onCanceledBattle();
            },
            onTimeEnd: () {
              liveStreamManager.onCanceledBattle();
            },
          );
        } ,
      );
    }
  }

  void _isFloatWindowModeChanged() {
    bool isFloatWindowMode = liveStreamManager.floatWindowState.isFloatWindowMode.value;
    _connectRequestAlertHandler?.setContentVisible(!isFloatWindowMode);
    _battleRequestAlertHandler?.setContentVisible(!isFloatWindowMode);
    _battleWaitingSheetHandler?.setContentVisible(!isFloatWindowMode);
  }

  void _onTapCoGuestForegroundWidget(SeatInfo seatInfo) {
    _userManagementPanelSheetHandler = popupWidget(
        context: context,
        AnchorCoGuestUserManagementPanel(
          seatInfo: seatInfo,
          liveStreamManager: liveStreamManager,
          closeCallback: () => _userManagementPanelSheetHandler?.close(),
        ));
  }

  void _onTapCoHostForegroundWidget(SeatInfo seatInfo) {
    _userManagementPanelSheetHandler = popupWidget(
        context: context,
        CoHostUserManagementPanel(
          seatInfo: seatInfo,
          liveStreamManager: liveStreamManager,
          closeCallback: () => _userManagementPanelSheetHandler?.close(),
        ));
  }

  bool _canAcceptCoGuestApplication() {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    if (coHostStore.coHostState.invitees.value.isNotEmpty ||
        coHostStore.coHostState.applicant.value != null ||
        coHostStore.coHostState.connected.value.any((user) => user.userID == selfUserId)) {
      return false;
    }
    return true;
  }

  void _rejectCoGuestApplicationIfNeeded(LiveUserInfo guestUser) {
    if (_canAcceptCoGuestApplication()) {
      return;
    }
    coGuestStore.rejectApplication(guestUser.userID);
  }
}
