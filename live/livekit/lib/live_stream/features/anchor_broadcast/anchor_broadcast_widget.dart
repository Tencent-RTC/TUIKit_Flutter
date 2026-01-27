import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/co_guest/anchor_empty_seat_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/living_widget/anchor_user_management_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/index.dart';
import 'package:tencent_live_uikit/live_stream/state/battle_state.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../../common/widget/base_bottom_sheet.dart';
import '../../manager/live_stream_manager.dart';
import '../decorations/index.dart';
import 'battle/battle_count_down_widget.dart';
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
  late final LiveStreamManager liveStreamManager;
  late final LiveCoreController liveCoreController;
  late final StreamSubscription<String> _toastSubscription;
  late final StreamSubscription<void> _kickedOutSubscription;
  late final VoidCallback _connectionRequestListener = _handleConnectionRequest;
  late final VoidCallback _battleRequestListener = _handleBattleRequest;
  late final VoidCallback _battleWaitingStatusListener = _handleBattleWaitingStatusChanged;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;
  bool _isShowingConnectRequestAlert = false;
  bool _isShowingBattleRequestAlert = false;
  AlertHandler? _connectRequestAlertHandler;
  AlertHandler? _battleRequestAlertHandler;
  BottomSheetHandler? _battleWaitingSheetHandler;
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
            children: [_buildCoreWidget(), _buildLivingWidget(), _buildDashboardWidget()],
          ),
        ),
      ),
    );
  }

  Widget _buildCoreWidget() {
    final isFloatWindowMode = liveStreamManager.floatWindowState.isFloatWindowMode.value;
    return Padding(
      padding: isFloatWindowMode ? EdgeInsets.zero : EdgeInsets.only(top: 44.height, bottom: 96.height),
      child: ClipRRect(
        borderRadius: isFloatWindowMode ? BorderRadius.zero : BorderRadius.circular(16.radius),
        child: LiveCoreWidget(
          controller: liveCoreController,
          videoWidgetBuilder: VideoWidgetBuilder(coGuestWidgetBuilder: (context, seatInfo, viewLayer) {
            if (seatInfo.userInfo.userID.isEmpty) {
              if (viewLayer == ViewLayer.background) {
                return AnchorEmptySeatWidget(seatInfo: seatInfo, liveStreamManager: liveStreamManager);
              } else {
                return Container();
              }
            }
            if (viewLayer == ViewLayer.background) {
              return CoGuestBackgroundWidget(
                  seatInfo: seatInfo, isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode);
            } else {
              return GestureDetector(
                  onTap: () => _onTapCoGuestForegroundWidget(seatInfo),
                  child: Container(
                      color: Colors.transparent,
                      child: CoGuestForegroundWidget(
                          seatInfo: seatInfo,
                          isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode)));
            }
          }, coHostWidgetBuilder: (context, seatInfo, viewLayer) {
            if (viewLayer == ViewLayer.background) {
              return CoHostBackgroundWidget(
                  seatInfo: seatInfo, isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode);
            } else {
              return CoHostForegroundWidget(
                  seatInfo: seatInfo, isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
            }
          }, battleWidgetBuilder: (context, seatInfo) {
            return BattleMemberInfoWidget(
                liveStreamManager: liveStreamManager,
                battleUserId: seatInfo.userInfo.userID,
                isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
          }, battleContainerWidgetBuilder: (context) {
            return BattleInfoWidget(
                liveStreamManager: liveStreamManager,
                isOwner: true,
                isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
          }),
        ),
      ),
    );
  }

  Widget _buildLivingWidget() {
    return AnchorLivingWidget(
      liveStreamManager: liveStreamManager,
      onEndLive: (data) => liveStatisticsData.value = data,
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
              viewCount: statisticsData.totalViewers,
              messageCount: statisticsData.totalMessageCount,
              giftTotalCoins: statisticsData.totalGiftCoins,
              giftTotalUniqueSender: statisticsData.totalGiftsSent,
              likeTotalUniqueSender: statisticsData.totalLikesReceived);
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

    _toastSubscription = liveStreamManager.toastSubject.stream.listen((toast) => makeToast(msg: toast));
    _kickedOutSubscription = liveStreamManager.kickedOutSubject.stream.listen((_) => _handleKickedOut());
  }

  void _removeObserver() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    coHostStore.coHostState.applicant.removeListener(_connectionRequestListener);
    coGuestStore.removeHostListener(_hostListener);
    liveStreamManager.battleState.receivedBattleRequest.removeListener(_battleRequestListener);
    liveStreamManager.battleState.isInWaiting.removeListener(_battleWaitingStatusListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_isFloatWindowModeListener);

    _toastSubscription.cancel();
    _kickedOutSubscription.cancel();
  }

  void _handleConnectionRequest() {
    if (coHostStore.coHostState.applicant.value == null && _isShowingConnectRequestAlert) {
      _closeConnectRequestAlert();
      return;
    }
    if (liveStreamManager.floatWindowState.isFloatWindowMode.value) {
      return;
    }

    if (coHostStore.coHostState.applicant.value != null && !_isShowingConnectRequestAlert) {
      final inviter = coHostStore.coHostState.applicant.value!;
      if (!_canAcceptCoHostInvitation()) {
        _responseCoHostInvitation(inviter, false);
        return;
      }
      final alertInfo = AlertInfo(
          imageUrl: inviter.avatarURL,
          description: LiveKitLocalizations.of(Global.appContext())!
              .common_connect_inviting_append
              .replaceAll("xxx", inviter.userName),
          cancelActionInfo: (
            title: LiveKitLocalizations.of(Global.appContext())!.common_reject,
            titleColor: LiveColors.designStandardG3
          ),
          cancelCallback: () {
            _responseCoHostInvitation(inviter, false);
          },
          defaultActionInfo: (
            title: LiveKitLocalizations.of(Global.appContext())!.common_accept,
            titleColor: LiveColors.designStandardB1
          ),
          defaultCallback: () {
            _responseCoHostInvitation(inviter, true);
          });
      _connectRequestAlertHandler = Alert.showAlert(alertInfo);
      _isShowingConnectRequestAlert = true;
    }
  }

  void _responseCoHostInvitation(SeatUserInfo inviter, bool isAccepted) async {
    _closeConnectRequestAlert();

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

  void _closeConnectRequestAlert() {
    if (_isShowingConnectRequestAlert && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowingConnectRequestAlert = false;
    }
  }

  void _handleBattleRequest() {
    if (liveStreamManager.battleState.receivedBattleRequest.value == null && _isShowingBattleRequestAlert) {
      _closeBattleRequestAlert();
      return;
    }

    if (liveStreamManager.floatWindowState.isFloatWindowMode.value) {
      return;
    }
    if (liveStreamManager.battleState.receivedBattleRequest.value != null &&
        _battleRequestAlertHandler?.isShowing() != true) {
      final battleId = liveStreamManager.battleState.receivedBattleRequest.value!.$1;
      final inviter = liveStreamManager.battleState.receivedBattleRequest.value!.$2;
      final alertInfo = AlertInfo(
          imageUrl: inviter.avatarUrl,
          description:
              LiveKitLocalizations.of(Global.appContext())!.common_battle_inviting.replaceAll("xxx", inviter.userName),
          cancelActionInfo: (
            title: LiveKitLocalizations.of(Global.appContext())!.common_reject,
            titleColor: LiveColors.designStandardG3
          ),
          cancelCallback: () {
            _responseBattleInvitation(battleId, false);
          },
          defaultActionInfo: (
            title: LiveKitLocalizations.of(Global.appContext())!.common_receive,
            titleColor: LiveColors.designStandardB1
          ),
          defaultCallback: () {
            _responseBattleInvitation(battleId, true);
          });

      _battleRequestAlertHandler = Alert.showAlert(alertInfo);
      _isShowingBattleRequestAlert = true;
    }
  }

  void _responseBattleInvitation(String battleId, bool isAccepted) async {
    _closeBattleRequestAlert();

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

  void _closeBattleRequestAlert() {
    if (_isShowingBattleRequestAlert && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowingBattleRequestAlert = false;
    }
  }

  void _handleBattleWaitingStatusChanged() {
    if (!liveStreamManager.battleState.isInWaiting.value && _battleWaitingSheetHandler?.isShowing() == true) {
      _battleWaitingSheetHandler?.close();
      return;
    }

    if (liveStreamManager.battleState.isInWaiting.value && _battleWaitingSheetHandler?.isShowing() != true) {
      _battleWaitingSheetHandler = popupWidget(
        BattleCountDownWidget(
          isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode,
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
        ),
        backgroundColor: Colors.transparent,
        isDismissible: false,
      );
    }
  }

  void _handleKickedOut() {}

  void _isFloatWindowModeChanged() {
    if (liveStreamManager.floatWindowState.isFloatWindowMode.value) {
      _connectRequestAlertHandler?.close();
      _battleRequestAlertHandler?.close();
      _userManagementPanelSheetHandler?.close();
    } else {
      _handleConnectionRequest();
      _handleBattleRequest();
    }
  }

  void _onTapCoGuestForegroundWidget(SeatInfo seatInfo) {
    final isSelf = TUIRoomEngine.getSelfInfo().userId == seatInfo.userInfo.userID;
    final user = LiveUserInfo(
        userID: seatInfo.userInfo.userID, userName: seatInfo.userInfo.userName, avatarURL: seatInfo.userInfo.avatarURL);
    _userManagementPanelSheetHandler = popupWidget(AnchorUserManagementPanelWidget(
      panelType: isSelf ? AnchorUserManagementPanelType.pureMedia : AnchorUserManagementPanelType.mediaAndSeat,
      user: user,
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
