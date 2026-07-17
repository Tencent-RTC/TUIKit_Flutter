import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/network_info/manager/network_info_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/co_guest/anchor_co_guest_float_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart' hide DeviceStatus;
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import '../../../../common/index.dart';
import '../../../../component/index.dart';
import '../../../live_define.dart';
import '../../../manager/live_stream_manager.dart';
import '../../../manager/module/user_manager.dart';
import 'anchor_bottom_menu_widget.dart';
import 'anchor_user_management_for_audience_panel.dart';

class AnchorLivingWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final VoidCallback? onTapEnterFloatWindowInApp;
  final void Function(TUILiveStatisticsData data, LiveEndedReason reason) onEndLive;

  const AnchorLivingWidget({
    super.key,
    required this.liveStreamManager,
    required this.onEndLive,
    this.onTapEnterFloatWindowInApp,
  });

  @override
  State<AnchorLivingWidget> createState() => _AnchorLivingWidgetState();
}

class _AnchorLivingWidgetState extends State<AnchorLivingWidget> {
  late final LiveStreamManager liveStreamManager;
  late final LiveListStore liveListStore;
  late final LiveSeatStore liveSeatStore;
  late final CoHostStore coHostStore;
  late final BattleStore battleStore;
  BarrageDisplayController? _barrageDisplayController;
  GiftPlayController? _giftPlayController;
  BottomSheetHandler? _userManagementPanelSheetHandler;
  AlertHandler? _closePanelSheetHandler;
  final NetworkInfoManager _networkInfoManager = NetworkInfoManager();
  late final VoidCallback _userEnterRoomListener = _onRemoteUserEnterRoom;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;
  late final LiveListListener _liveListListener;
  late final LiveSummaryStore _liveSummaryStore;
  late final VoidCallback _onScreenShareStatusListener = _onScreenShareStatusChanged;
  late final VoidCallback _loginStatusListener = _onLoginStatusChanged;
  late final StreamSubscription<LoginEvent> _loginEventSubscription;
  bool _isLiveEndedByServer = false;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    liveStreamManager.setUserEnterRoomNotifyStrategy(UserEnterRoomNotifyStrategy.always);
    liveListStore = LiveListStore.shared;
    _liveSummaryStore = LiveSummaryStore.create(liveStreamManager.roomState.roomId);
    _liveListListener = LiveListListener(
      onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
        if (liveID != liveStreamManager.roomState.roomId) return;
        if (reason == LiveEndedReason.endedByServer) {
          _isLiveEndedByServer = true;
          widget.onEndLive.call(_buildStatisticsFromSummary(), LiveEndedReason.endedByServer);
          liveStreamManager.onStopLive();
        }
      },
      onKickedOutOfLive: (String liveID, LiveKickedOutReason reason, String message) {
        if (liveID != liveStreamManager.roomState.roomId) return;
        _closePage();
      },
    );
    liveSeatStore = LiveSeatStore.create(liveStreamManager.roomState.roomId);
    coHostStore = CoHostStore.create(liveStreamManager.roomState.roomId);
    battleStore = BattleStore.create(liveStreamManager.roomState.roomId);
    _addObserver();
    _loginEventSubscription = LoginStore.shared.loginEventStream.listen((event) {
      switch (event) {
        case LoginEvent.kickedOffline:
        case LoginEvent.loginExpired:
          LiveKitLogger.warning("LoginEvent => $event");
          _closePage();
          break;
      }
    });
  }

  @override
  void dispose() {
    _loginEventSubscription.cancel();
    _giftPlayController?.dispose();
    _networkInfoManager.dispose();
    _removeObserver();
    enablePictureInPicture(false);
    _onDispose();
    _closeAllDialog();
    super.dispose();
  }

  void enablePictureInPicture(bool enable) {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      final roomId = widget.liveStreamManager.roomState.roomId;
      widget.liveStreamManager.enablePictureInPicture(roomId, enable).then((result) {
        LiveKitLogger.info("enablePictureInPicture,enable=$enable,result=$result");
        liveStreamManager.enablePipMode(enable && result);
      });
    }
  }

  void _closeAllDialog() {
    _userManagementPanelSheetHandler?.close();
    _closePanelSheetHandler?.close();
  }

  void _onLoginStatusChanged() {
    final loginStatus = LoginStore.shared.loginState.loginStatus;
    if (loginStatus == LoginStatus.unlogin) {
      LiveKitLogger.warning("LoginStatus => unlogin");
      _closePage();
    }
  }

  void _closePage() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
        builder: (context, isFloatWindowMode, child) {
          return Visibility(
            visible: !isFloatWindowMode,
            child: Stack(children: [
              _buildCloseWidget(),
              _buildFloatWindowWidget(),
              _buildAudienceListWidget(),
              _buildLiveInfoWidget(),
              _buildNetworkInfoButtonWidget(),
              _buildBarrageDisplayWidget(),
              _buildGiftDisplayWidget(),
              _buildAnchorBottomMenuWidget(),
              _buildApplyLinkAudienceWidget(),
              _buildNetworkToastWidget()
            ]),
          );
        });
  }

  Widget _buildCloseWidget() {
    return Positioned(
      right: 10.width,
      top: 68.height,
      width: 24.width,
      height: 24.width,
      child: GestureDetector(
        onTap: () {
          _closeButtonClick();
        },
        child: Image.asset(
          LiveImages.close,
          package: Constants.pluginName,
        ),
      ),
    );
  }

  Widget _buildFloatWindowWidget() {
    return ValueListenableBuilder(
        valueListenable: liveStreamManager.roomState.liveStatus,
        builder: (context, liveStatus, _) {
          if (liveStatus != LiveStatus.pushing) {
            return const SizedBox.shrink();
          }
          bool visible = GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() &&
              !widget.liveStreamManager.roomManager.isScreenShareLive();
          return Visibility(
            visible: visible,
            child: Positioned(
              right: 38.width,
              top: 68.height,
              width: 24.width,
              height: 24.width,
              child: GestureDetector(
                onTap: () {
                  widget.onTapEnterFloatWindowInApp?.call();
                },
                child: Image.asset(
                  LiveImages.floatWindow,
                  package: Constants.pluginName,
                ),
              ),
            ),
          );
        });
  }

  Widget _buildAudienceListWidget() {
    return ValueListenableBuilder(
        valueListenable: liveStreamManager.roomState.liveStatus,
        builder: (context, liveStatus, _) {
          if (liveStatus != LiveStatus.pushing) {
            return const SizedBox.shrink();
          }
          bool enableFloat = GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() &&
              !widget.liveStreamManager.roomManager.isScreenShareLive();
          return Visibility(
            child: Positioned(
                right: enableFloat ? 66.width : 38.width,
                top: 68.height,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 107.width),
                  child: AudienceListWidget(
                    roomId: liveStreamManager.roomState.roomId,
                    onClickUserItem: (user) {
                      _userManagementPanelSheetHandler = popupWidget(
                          context: context,
                          AnchorUserManagementForAudiencePanel(
                            user: user,
                            liveStreamManager: liveStreamManager,
                            closeCallback: () => _userManagementPanelSheetHandler?.close(),
                          ));
                    },
                  ),
                )),
          );
        });
  }

  Widget _buildLiveInfoWidget() {
    return Positioned(
        left: 16.width,
        top: 60.height,
        child: Container(
          constraints: BoxConstraints(maxHeight: 40.height, maxWidth: 200.width),
          child: ValueListenableBuilder(
              valueListenable: liveStreamManager.roomState.liveStatus,
              builder: (context, liveStatus, _) {
                return Visibility(
                  visible: liveStatus == LiveStatus.pushing,
                  child: LiveInfoWidget(
                    roomId: liveStreamManager.roomState.roomId,
                    isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
                  ),
                );
              }),
        ));
  }

  Widget _buildNetworkInfoButtonWidget() {
    return Positioned(
        right: 12.width,
        top: 100.height,
        height: 20.height,
        child: ValueListenableBuilder(
            valueListenable: liveStreamManager.roomState.liveStatus,
            builder: (context, liveStatus, _) {
              if (liveStatus != LiveStatus.pushing) {
                return Container();
              }
              return NetworkInfoButton(
                manager: _networkInfoManager,
                createTime: liveStreamManager.roomState.createTime,
                isAudience: !liveStreamManager.roomState.liveInfo.keepOwnerOnSeat,
                isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode,
              );
            }));
  }

  Widget _buildNetworkToastWidget() {
    return ValueListenableBuilder(
      valueListenable: _networkInfoManager.state.showToast,
      builder: (context, showToast, _) {
        return Center(
            child: Visibility(
                visible: showToast,
                child: NetworkStatusToastWidget(
                  manager: _networkInfoManager,
                )));
      },
    );
  }

  Widget _buildBarrageDisplayWidget() {
    return Positioned(
        left: 16.height,
        bottom: 108.height,
        height: 214.height,
        width: 1.screenWidth - 146.width,
        child: ValueListenableBuilder(
          valueListenable: liveStreamManager.roomState.liveStatus,
          builder: (context, liveStatus, _) {
            if (liveStatus != LiveStatus.pushing) {
              return Container();
            }
            if (_barrageDisplayController == null) {
              _barrageDisplayController = BarrageDisplayController(
                  roomId: liveStreamManager.roomState.roomId,
                  ownerId: liveStreamManager.roomState.liveInfo.liveOwner.userID,
                  selfUserId: TUIRoomEngine.getSelfInfo().userId,
                  selfName: TUIRoomEngine.getSelfInfo().userName,
                  onError: (code, message) {
                    makeToast(context, ErrorHandler.convertToErrorMessage(code, message) ?? '', type: ToastType.error);
                  });
              _barrageDisplayController
                  ?.setCustomBarrageBuilder(GiftBarrageItemBuilder(selfUserId: TUIRoomEngine.getSelfInfo().userId));
            }
            return BarrageDisplayWidget(
              controller: _barrageDisplayController!,
              onClickBarrageItem: (barrage) {
                final isOwner = liveStreamManager.roomState.liveInfo.liveOwner.userID == barrage.sender.userID;
                if (isOwner) {
                  return;
                }
                final user = LiveUserInfo(
                    userID: barrage.sender.userID,
                    userName: barrage.sender.userName,
                    avatarURL: barrage.sender.avatarURL);
                _userManagementPanelSheetHandler = popupWidget(
                    context: context,
                    AnchorUserManagementForAudiencePanel(
                      user: user,
                      liveStreamManager: liveStreamManager,
                      closeCallback: () => _userManagementPanelSheetHandler?.close(),
                    ));
              },
            );
          },
        ));
  }

  Widget _buildGiftDisplayWidget() {
    return Positioned(
        width: 1.screenWidth,
        height: 1.screenHeight,
        child: ValueListenableBuilder(
          valueListenable: liveStreamManager.roomState.liveStatus,
          builder: (context, liveStatus, _) {
            if (liveStatus != LiveStatus.pushing) {
              return Container();
            }
            if (_giftPlayController == null) {
              _giftPlayController = GiftPlayController(
                  roomId: liveStreamManager.roomState.roomId, language: DeviceLanguage.getCurrentLanguageCode(context));
              _giftPlayController?.onReceiveGiftCallback = _insertToBarrageMessage;
            }
            return GiftPlayWidget(giftPlayController: _giftPlayController!);
          },
        ));
  }

  Widget _buildAnchorBottomMenuWidget() {
    return ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.roomState.liveStatus,
        builder: (context, liveStatus, _) {
          if (liveStatus != LiveStatus.pushing) {
            return const SizedBox.shrink();
          }
          bool enableCoGuest = true;
          bool enableCoHost = true;
          bool enableBattle = true;
          bool enableMore = true;
          if (widget.liveStreamManager.roomState.liveInfo.seatTemplate is VideoLandscape4Seats) {
            enableCoGuest = widget.liveStreamManager.roomState.liveInfo.keepOwnerOnSeat;
            enableCoHost = false;
            enableBattle = false;
            enableMore = false;
          }
          return Positioned(
              left: 0,
              bottom: 36.height,
              child: SizedBox(
                  width: 1.screenWidth,
                  height: 46.height,
                  child: AnchorBottomMenuWidget(
                    liveStreamManager: liveStreamManager,
                    enableCoGuest: enableCoGuest,
                    enableCoHost: enableCoHost,
                    enableBattle: enableBattle,
                    enableMore: enableMore,
                  )));
        });
  }

  Widget _buildApplyLinkAudienceWidget() {
    return Positioned(
      right: 8.width,
      top: 116.height,
      height: 86.height,
      width: 114.width,
      child: AnchorCoGuestFloatWidget(liveStreamManager: liveStreamManager),
    );
  }
}

extension on _AnchorLivingWidgetState {
  void _addObserver() {
    LoginStore.shared.addListener(_loginStatusListener);
    DeviceStore.shared.state.screenStatus.addListener(_onScreenShareStatusListener);
    liveListStore.addLiveListListener(_liveListListener);
    liveStreamManager.userState.enterUser.addListener(_userEnterRoomListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_isFloatWindowModeListener);
  }

  void _removeObserver() {
    LoginStore.shared.removeListener(_loginStatusListener);
    DeviceStore.shared.state.screenStatus.removeListener(_onScreenShareStatusListener);
    liveListStore.removeLiveListListener(_liveListListener);
    liveStreamManager.userState.enterUser.removeListener(_userEnterRoomListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_isFloatWindowModeListener);
  }

  void _onRemoteUserEnterRoom() {
    LiveUserInfo barrageUser = liveStreamManager.userState.enterUser.value;
    Barrage barrage = Barrage();
    barrage.sender = barrageUser;
    barrage.textContent = LiveKitLocalizations.of(Global.appContext())!.common_entered_room;
    _barrageDisplayController?.insertMessage(barrage);
  }

  void _isFloatWindowModeChanged() {
    if (liveStreamManager.floatWindowState.isFloatWindowMode.value) {
      _closeAllDialog();
    }
  }

  void _closeButtonClick() {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    final isSelfInBattle = liveStreamManager.battleState.battleUsers.value.any((user) => user.userId == selfUserId);
    final isSelfInCoHost = coHostStore.coHostState.connected.value.length > 1;
    final isSelfInCoGuest = liveSeatStore.liveSeatState.seatList.value
        .where((user) => user.userInfo.userID.isNotEmpty && user.userInfo.userID != selfUserId)
        .toList()
        .isNotEmpty;
    closeAlert() => _closePanelSheetHandler?.close();
    if (isSelfInBattle) {
      final alertInfo = AlertInfo(
        description: LiveKitLocalizations.of(context)!.common_end_pk_tips,
        itemList: [
          ButtonConfig(
              text: LiveKitLocalizations.of(context)!.common_battle_end_pk,
              type: TextColorPreset.red,
              onClick: () {
                closeAlert();
                _exitBattle();
              }),
          ButtonConfig(
              text: LiveKitLocalizations.of(context)!.common_end_live,
              onClick: () {
                closeAlert.call();
                _stopLiveStream();
              }),
          ButtonConfig(
            text: LiveKitLocalizations.of(context)!.common_cancel,
            onClick: closeAlert,
          ),
        ],
      );
      _closePanelSheetHandler = Alert.showAlert(alertInfo, context);
    } else if (isSelfInCoHost) {
      final alertInfo = AlertInfo(
        description: LiveKitLocalizations.of(context)!.common_end_connection_tips,
        itemList: [
          ButtonConfig(
              text: LiveKitLocalizations.of(context)!.common_end_connect,
              type: TextColorPreset.red,
              onClick: () {
                closeAlert();
                _exitCoHost();
              }),
          ButtonConfig(
              text: LiveKitLocalizations.of(context)!.common_end_live,
              onClick: () {
                closeAlert();
                _stopLiveStream();
              }),
          ButtonConfig(
            text: LiveKitLocalizations.of(context)!.common_cancel,
            onClick: closeAlert,
          ),
        ],
      );
      _closePanelSheetHandler = Alert.showAlert(alertInfo, context);
    } else if (isSelfInCoGuest) {
      final alertInfo = AlertInfo(
        isDestructive: true,
        description: LiveKitLocalizations.of(context)!.common_anchor_end_link_tips,
        cancelText: LiveKitLocalizations.of(context)!.common_cancel,
        defaultText: LiveKitLocalizations.of(context)!.common_end_live,
        defaultCallback: () => _stopLiveStream(),
      );
      _closePanelSheetHandler = Alert.showAlert(alertInfo, context);
    } else {
      final isObsBroadcast = !liveStreamManager.roomState.liveInfo.keepOwnerOnSeat;
      final leaveLiveText = isObsBroadcast
          ? LiveKitLocalizations.of(context)!.common_exit_live
          : LiveKitLocalizations.of(context)!.common_end_live;
      final alertInfo = AlertInfo(
        isDestructive: true,
        description: isObsBroadcast
            ? LiveKitLocalizations.of(context)!.live_exit_live_tips
            : LiveKitLocalizations.of(context)!.live_end_live_tips,
        cancelText: LiveKitLocalizations.of(context)!.common_cancel,
        defaultText: leaveLiveText,
        defaultCallback: () => _stopLiveStream(),
      );
      _closePanelSheetHandler = Alert.showAlert(alertInfo, context);
    }
  }

  void _exitBattle() {
    battleStore.exitBattle(liveStreamManager.battleState.battleId.value);
  }

  void _exitCoHost() {
    coHostStore.exitHostConnection();
  }

  void _stopLiveStream() async {
    if (_isLiveEndedByServer) return;
    battleStore.exitBattle(liveStreamManager.battleState.battleId.value);
    final isObsBroadcast = !liveStreamManager.roomState.liveInfo.keepOwnerOnSeat;
    if (isObsBroadcast) {
      liveListStore.leaveLive();
      _closePage();
    } else {
      if (liveStreamManager.roomState.videoStreamSource == VideoStreamSource.screenShare) {
        liveStreamManager.mediaManager.stopScreenShare();
      }
      final future = liveListStore.endLive();
      BarrageDisplayController.resetState();
      _giftPlayController?.dispose();

      final result = await future;
      if (_isLiveEndedByServer) return;
      if (result.errorCode != TUIError.success.rawValue) {
        liveStreamManager.toastSubject
            .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
      widget.onEndLive.call(result.statisticsData, LiveEndedReason.endedByHost);
      liveStreamManager.onStopLive();
    }
  }

  void _onDispose() {
    if (liveListStore.liveState.currentLive.value.liveID.isEmpty) {
      return;
    }
    battleStore.exitBattle(liveStreamManager.battleState.battleId.value);
    final isObsBroadcast = !liveStreamManager.roomState.liveInfo.keepOwnerOnSeat;
    if (isObsBroadcast) {
      liveListStore.leaveLive();
    } else {
      liveListStore.endLive();
      BarrageDisplayController.resetState();
      _giftPlayController?.dispose();
    }
  }

  void _insertToBarrageMessage(Gift gift, int count, LiveUserInfo sender) {
    final receiver = widget.liveStreamManager.roomState.liveInfo.liveOwner;
    if (receiver.userID == TUIRoomEngine.getSelfInfo().userId) {
      receiver.userName = LiveKitLocalizations.of(Global.appContext())!.common_gift_me;
    }

    Barrage barrage = Barrage();
    barrage.textContent = "gift";
    barrage.sender = sender;
    barrage.extensionInfo[Constants.keyGiftViewType] = Constants.valueGiftViewType;
    barrage.extensionInfo[Constants.keyGiftName] = gift.name;
    barrage.extensionInfo[Constants.keyGiftCount] = count.toString();
    barrage.extensionInfo[Constants.keyGiftImage] = gift.iconURL;
    barrage.extensionInfo[Constants.keyGiftReceiverUserId] = receiver.userID;

    barrage.extensionInfo[Constants.keyGiftReceiverUsername] = receiver.userName;
    _barrageDisplayController?.insertMessage(barrage);
  }

  void _onScreenShareStatusChanged() {
    if (!widget.liveStreamManager.roomManager.isScreenShareLive()) return;
    DeviceStatus deviceStatus = DeviceStore.shared.state.screenStatus.value;
    LiveKitLogger.info("_onScreenShareStatusChanged, deviceStatus=$deviceStatus");
    if (deviceStatus == DeviceStatus.off) {
      _stopLiveStream();
    }
  }

  TUILiveStatisticsData _buildStatisticsFromSummary() {
    final summary = _liveSummaryStore.liveSummaryState.summaryData.value;
    return TUILiveStatisticsData()
      ..liveDuration = summary.totalDuration
      ..totalViewers = summary.totalViewers
      ..totalGiftsSent = summary.totalGiftsSent
      ..totalUniqueGiftSenders = summary.totalGiftUniqueSenders
      ..totalGiftCoins = summary.totalGiftCoins
      ..totalLikesReceived = summary.totalLikesReceived
      ..totalMessageCount = summary.totalMessageSent;
  }
}
