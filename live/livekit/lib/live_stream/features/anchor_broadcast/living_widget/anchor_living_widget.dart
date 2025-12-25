import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/component/network_info/index.dart';
import 'package:tencent_live_uikit/component/network_info/manager/network_info_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/co_guest/anchor_co_guest_float_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/living_widget/anchor_user_management_panel_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import '../../../../common/index.dart';
import '../../../../component/index.dart';
import '../../../live_define.dart';
import '../../../manager/live_stream_manager.dart';
import 'anchor_bottom_menu_widget.dart';

class AnchorLivingWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final VoidCallback? onTapEnterFloatWindowInApp;
  final void Function(TUILiveStatisticsData data) onEndLive;

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
  BottomSheetHandler? _closePanelSheetHandler;
  final NetworkInfoManager _networkInfoManager = NetworkInfoManager();
  late final VoidCallback _userEnterRoomListener = _onRemoteUserEnterRoom;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;
  late final LiveListListener _liveListListener;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    liveListStore = LiveListStore.shared;
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      if (reason == LiveEndedReason.endedByServer) {
        _closePage();
      }
    });
    liveSeatStore = LiveSeatStore.create(liveStreamManager.roomState.roomId);
    coHostStore = CoHostStore.create(liveStreamManager.roomState.roomId);
    battleStore = BattleStore.create(liveStreamManager.roomState.roomId);
    _addObserver();
  }

  @override
  void dispose() {
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

  void _closePage() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      if (mounted) Navigator.pop(Global.appContext());
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
              _buildPureBroadcastTapWidget(),
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

  Widget _buildPureBroadcastTapWidget() {
    return ListenableBuilder(
        listenable: Listenable.merge([liveSeatStore.liveSeatState.seatList, coHostStore.coHostState.connected]),
        builder: (context, _) {
          return _isPureAnchorBroadcast()
              ? GestureDetector(onTap: () => onTapPureBroadcastTapWidget(), child: Container(color: Colors.transparent))
              : Container();
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
    return Visibility(
      visible: GlobalFloatWindowManager.instance.isEnableFloatWindowFeature(),
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
  }

  Widget _buildAudienceListWidget() {
    return Positioned(
        right: GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() ? 66.width : 38.width,
        top: 68.height,
        child: Container(
          constraints: BoxConstraints(maxWidth: 107.width),
          child: ValueListenableBuilder(
              valueListenable: liveStreamManager.roomState.liveStatus,
              builder: (context, liveStatus, _) {
                return Visibility(
                  visible: liveStatus == LiveStatus.pushing,
                  child: AudienceListWidget(
                    roomId: liveStreamManager.roomState.roomId,
                    onClickUserItem: (user) {
                      _userManagementPanelSheetHandler = popupWidget(AnchorUserManagementPanelWidget(
                        panelType: AnchorUserManagementPanelType.messageAndKickOut,
                        user: user,
                        liveStreamManager: liveStreamManager,
                        closeCallback: () => _userManagementPanelSheetHandler?.close(),
                      ));
                    },
                  ),
                );
              }),
        ));
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
        width: 78.width,
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
        bottom: 84.height,
        height: 224.height,
        width: 305.width,
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
                  selfName: TUIRoomEngine.getSelfInfo().userName);
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
                _userManagementPanelSheetHandler = popupWidget(AnchorUserManagementPanelWidget(
                  panelType: AnchorUserManagementPanelType.messageAndKickOut,
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
    return Positioned(
        left: 0,
        bottom: 36.height,
        child: SizedBox(
            width: 1.screenWidth,
            height: 46.height,
            child: AnchorBottomMenuWidget(liveStreamManager: liveStreamManager)));
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
    liveListStore.addLiveListListener(_liveListListener);
    liveStreamManager.userState.enterUser.addListener(_userEnterRoomListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_isFloatWindowModeListener);
  }

  void _removeObserver() {
    liveListStore.removeLiveListListener(_liveListListener);
    liveStreamManager.userState.enterUser.removeListener(_userEnterRoomListener);
    liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_isFloatWindowModeListener);
  }

  void _onRemoteUserEnterRoom() {
    final userInfo = liveStreamManager.userState.enterUser.value;
    LiveUserInfo barrageUser = LiveUserInfo();
    barrageUser.userID = userInfo.userId;
    barrageUser.userName = userInfo.userName;
    barrageUser.avatarURL = userInfo.avatarUrl;

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
    String title = '';
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    final isSelfInBattle = liveStreamManager.battleState.battleUsers.value.any((user) => user.userId == selfUserId);
    final isSelfInCoHost = coHostStore.coHostState.connected.value.length > 1;
    final isSelfInCoGuest = liveSeatStore.liveSeatState.seatList.value
        .where((user) => user.userInfo.userID.isNotEmpty && user.userInfo.userID != selfUserId)
        .toList()
        .isNotEmpty;

    const endBattleNumber = 1;
    const endCoHostNumber = 2;
    const endLiveNumber = 3;
    const cancelNumber = 4;
    final List<ActionSheetModel> menuData = List.empty(growable: true);

    const lineColor = LiveColors.designStandardG8;
    if (isSelfInBattle) {
      title = LiveKitLocalizations.of(context)!.common_end_pk_tips;
      final endBattle = ActionSheetModel(
          isCenter: true,
          text: LiveKitLocalizations.of(context)!.common_battle_end_pk,
          textStyle: const TextStyle(color: LiveColors.notStandardRed, fontSize: 16),
          lineColor: lineColor,
          bingData: endBattleNumber);
      menuData.add(endBattle);
    } else if (isSelfInCoHost) {
      title = LiveKitLocalizations.of(context)!.common_end_connection_tips;
      final endCoHost = ActionSheetModel(
          isCenter: true,
          text: LiveKitLocalizations.of(context)!.common_end_connect,
          textStyle: const TextStyle(color: LiveColors.notStandardRed, fontSize: 16),
          lineColor: lineColor,
          bingData: endCoHostNumber);
      menuData.add(endCoHost);
    } else if (isSelfInCoGuest) {
      title = LiveKitLocalizations.of(context)!.common_anchor_end_link_tips;
    }

    final isObsBroadcast = !liveStreamManager.roomState.liveInfo.keepOwnerOnSeat;
    final leaveLiveText = isObsBroadcast
        ? LiveKitLocalizations.of(context)!.common_exit_live
        : LiveKitLocalizations.of(context)!.common_end_live;

    final endLive = ActionSheetModel(
        isCenter: true,
        text: leaveLiveText,
        textStyle: const TextStyle(color: LiveColors.designStandardG2, fontSize: 16),
        lineColor: lineColor,
        bingData: endLiveNumber);
    menuData.add(endLive);

    final cancel = ActionSheetModel(
        isCenter: true,
        text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        textStyle: const TextStyle(color: LiveColors.designStandardG2, fontSize: 16),
        lineColor: lineColor,
        bingData: cancelNumber);
    menuData.add(cancel);

    _closePanelSheetHandler = ActionSheet.show(menuData, (model) {
      switch (model.bingData) {
        case endBattleNumber:
          _exitBattle();
          break;
        case endCoHostNumber:
          _exitCoHost();
          break;
        case endLiveNumber:
          _stopLiveStream();
          break;
        default:
          break;
      }
    }, backgroundColor: LiveColors.designStandardFlowkitWhite, title: title);
  }

  void _exitBattle() {
    battleStore.exitBattle(liveStreamManager.battleState.battleId.value);
  }

  void _exitCoHost() {
    coHostStore.exitHostConnection();
  }

  void _stopLiveStream() async {
    battleStore.exitBattle(liveStreamManager.battleState.battleId.value);
    final isObsBroadcast = !liveStreamManager.roomState.liveInfo.keepOwnerOnSeat;
    if (isObsBroadcast) {
      liveListStore.leaveLive();
      if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
        GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      final future = liveListStore.endLive();
      BarrageDisplayController.resetState();
      _giftPlayController?.dispose();

      final result = await future;
      if (result.errorCode != TUIError.success.rawValue) {
        liveStreamManager.toastSubject
            .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
      widget.onEndLive.call(result.statisticsData);
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

  void onTapPureBroadcastTapWidget() {
    _userManagementPanelSheetHandler = popupWidget(AnchorUserManagementPanelWidget(
      panelType: AnchorUserManagementPanelType.pureMedia,
      user: liveStreamManager.roomState.liveInfo.liveOwner,
      liveStreamManager: liveStreamManager,
      closeCallback: () => _userManagementPanelSheetHandler?.close(),
    ));
  }

  bool _isPureAnchorBroadcast() {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    return liveSeatStore.liveSeatState.seatList.value
            .where((seat) => seat.userInfo.userID.isNotEmpty && seat.userInfo.userID != selfUserId)
            .isEmpty &&
        coHostStore.coHostState.connected.value.isEmpty;
  }
}
