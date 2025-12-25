import 'package:atomic_x_core/atomicxcore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/common/widget/float_window/float_window_controller.dart';
import 'package:tencent_live_uikit/component/gift_access/gift_barrage_item_builder.dart';
import 'package:tencent_live_uikit/live_navigator_observer.dart';
import 'package:tencent_live_uikit/seat_grid_widget/index.dart';
import 'package:tencent_live_uikit/voice_room/index.dart';
import 'package:tencent_live_uikit/voice_room/manager/index.dart';
import 'package:tencent_live_uikit/voice_room/manager/voice_room_im_store.dart';
import 'package:tencent_live_uikit/voice_room/widget/end_statistics/anchor_end_statistics_widget.dart';
import 'package:tencent_live_uikit/voice_room/widget/end_statistics/audience_end_statistics_widget.dart';
import 'package:tencent_live_uikit/voice_room/widget/end_statistics/end_statistics_widget_define.dart';
import 'package:tencent_live_uikit/voice_room/widget/panel/seat_invitation_panel_widget.dart';
import 'package:tencent_live_uikit/voice_room/widget/panel/user_management_panel_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart' hide DeviceStatus;
import '../../component/float_window/global_float_window_manager.dart';

typedef ShowEndViewCallback = void Function(Map<String, dynamic> endInfo, bool isAnchor);

class VoiceRoomRootWidget extends StatefulWidget {
  final String liveID;
  final VoiceRoomPrepareStore prepareStore;
  final ToastService toastService;
  final SeatGridController seatGridController;
  final bool isCreate;
  final FloatWindowController? floatWindowController;

  const VoiceRoomRootWidget({
    super.key,
    required this.liveID,
    required this.prepareStore,
    required this.toastService,
    required this.seatGridController,
    required this.isCreate,
    this.floatWindowController,
  });

  @override
  State<VoiceRoomRootWidget> createState() => _VoiceRoomRootWidgetState();
}

class _VoiceRoomRootWidgetState extends State<VoiceRoomRootWidget> {
  late final bool isOwner;
  final ValueNotifier<bool> enterRoomSuccess = ValueNotifier(false);
  late BarrageSendController _barrageSendController;
  BarrageDisplayController? _barrageDisplayController;
  GiftPlayController? _giftPlayController;
  final VoiceRoomViewStore _viewStore = VoiceRoomViewStore();
  bool _isShowingReceivedRequestAlert = false;
  AlertHandler? _receivedRequestAlertHandler;
  BottomSheetHandler? _takeSeatSheetHandler;
  BottomSheetHandler? _userManagementPanelSheetHandler;
  BottomSheetHandler? _seatInvitationPanelSheetHandler;
  BottomSheetHandler? _ownerEmptySeatOperationMenuSheetHandler;
  BottomSheetHandler? _normalUserLeaveHandler;
  BottomSheetHandler? _exitConfirmPanelHandler;
  LiveUserInfo? inviterUserInfo;
  late Size _screenSize;
  LiveInfo? _currentLiveInfo;
  TUILiveStatisticsData _liveStatisticsData = TUILiveStatisticsData();
  late final VoidCallback _seatListChangedListener = _onSeatListChange;
  late final VoidCallback _isLinkedListener = _onLinkStatusChanged;
  late final VoidCallback _selfAudioLockStatusListener = _onSelfAudioLockStatusChanged;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;
  final ValueNotifier<bool> _isLinked = ValueNotifier(false);
  final ValueNotifier<bool> _exitedRoom = ValueNotifier(false);
  final ValueNotifier<bool> _selfAudioLockStatus = ValueNotifier(false);
  final VoiceRoomIMStore _imStore = VoiceRoomIMStore();

  DeviceStore get _deviceStore => DeviceStore.shared;

  LiveListStore get _liveListStore => LiveListStore.shared;

  LiveAudienceStore get _audienceStore => LiveAudienceStore.create(widget.liveID);

  CoGuestStore get _coGuestStore => CoGuestStore.create(widget.liveID);

  LiveSeatStore get _liveSeatStore => LiveSeatStore.create(widget.liveID);

  BarrageStore get _barrageStore => BarrageStore.create(widget.liveID);

  late GuestListener _guestListener;
  late LiveListListener _liveListener;
  late LiveAudienceListener _liveAudienceListener;
  late final LiveListListener _liveListListener;
  late HostListener _hostListener;

  @override
  void initState() {
    super.initState();
    isOwner = widget.isCreate;
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _closeAllDialog();
    });
    if (widget.isCreate) {
      GlobalFloatWindowManager.instance.setOwnerId(TUIRoomEngine.getSelfInfo().userId);
      _start(liveID: widget.liveID);
    } else {
      _join(liveID: widget.liveID);
    }
    _addObserver();
  }

  @override
  void dispose() {
    _imStore.unInit();
    _removeObserver();
    _onDispose();
    _closeAllDialog();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      child: SizedBox(
        width: _screenSize.width,
        height: _screenSize.height,
        child: Stack(children: [
          _initBackgroundWidget(),
          _initBackgroundGradientWidget(),
          _initBarrageDisplayWidget(),
          _initSeatGridWidget(),
          _initGiftDisplayWidget(),
          _initTopWidget(),
          _initBottomMenuWidget(),
          _initBarrageInputWidget(),
          _initMuteMicrophoneWidget(),
          _buildEndStatisticsWidget()
        ]),
      ),
    );
  }

  void _onDispose() {
    _selfAudioLockStatus.dispose();
    _exitedRoom.dispose();
    _isLinked.dispose();
    enterRoomSuccess.dispose();
    if (isOwner) {
      _liveListStore.endLive();
    } else {
      _liveListStore.leaveLive();
    }
    BarrageDisplayController.resetState();
    _giftPlayController?.dispose();
  }

  void _closeAllDialog() {
    _receivedRequestAlertHandler?.close();
    _takeSeatSheetHandler?.close();
    _userManagementPanelSheetHandler?.close();
    _seatInvitationPanelSheetHandler?.close();
    _ownerEmptySeatOperationMenuSheetHandler?.close();
    _normalUserLeaveHandler?.close();
    _exitConfirmPanelHandler?.close();
  }

  Widget _initBackgroundWidget() {
    return SizedBox(
        width: _screenSize.width,
        height: _screenSize.height,
        child: ValueListenableBuilder(
            valueListenable:
                ValueSelector(_liveListStore.liveState.currentLive, (currentLive) => currentLive.backgroundURL),
            builder: (context, backgroundURL, child) {
              return CachedNetworkImage(
                  imageUrl: backgroundURL,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return Image.asset(LiveImages.defaultBackground, package: Constants.pluginName, fit: BoxFit.cover);
                  });
            }));
  }

  Widget _initBackgroundGradientWidget() {
    return Container(
        width: _screenSize.width,
        height: _screenSize.height,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          LiveColors.designStandardG1,
          LiveColors.designStandardG1.withAlpha(0x80),
          LiveColors.designStandardG1
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)));
  }

  Widget _initBarrageDisplayWidget() {
    return Positioned(
        left: 16.width,
        bottom: 84.height,
        child: SizedBox(
          width: 305.width,
          height: 224.height,
          child: ValueListenableBuilder(
              valueListenable: enterRoomSuccess,
              builder: (context, success, child) {
                if (!success) {
                  return Container();
                }

                final currentLive = _liveListStore.liveState.currentLive.value;
                final selfInfo = TUIRoomEngine.getSelfInfo();
                _barrageDisplayController ??= BarrageDisplayController(
                    roomId: currentLive.liveID,
                    ownerId: currentLive.liveOwner.userID,
                    selfUserId: selfInfo.userId,
                    selfName: selfInfo.userName ?? selfInfo.userId);
                _barrageDisplayController?.setCustomBarrageBuilder(GiftBarrageItemBuilder(selfUserId: selfInfo.userId));
                return BarrageDisplayWidget(controller: _barrageDisplayController!);
              }),
        ));
  }

  Widget _initSeatGridWidget() {
    return Positioned(
        top: 122.height,
        child: SizedBox(
            width: _screenSize.width,
            height: 245.height,
            child: SeatGridWidget(
                controller: widget.seatGridController,
                onSeatWidgetTap: (seatInfo) {
                  _onTapSeatGridWidget(engineSeatInfoFromSeatInfo(seatInfo));
                })));
  }

  Widget _initGiftDisplayWidget() {
    return ValueListenableBuilder(
      valueListenable: enterRoomSuccess,
      builder: (context, success, child) {
        if (!success) {
          return Container();
        }
        if (_giftPlayController == null) {
          _giftPlayController = GiftPlayController(
              roomId: _liveListStore.liveState.currentLive.value.liveID,
              language: DeviceLanguage.getCurrentLanguageCode(context));
          _giftPlayController?.onReceiveGiftCallback = _insertToBarrageMessage;
        }
        return GiftPlayWidget(giftPlayController: _giftPlayController!);
      },
    );
  }

  Widget _initTopWidget() {
    return ValueListenableBuilder(
      valueListenable: enterRoomSuccess,
      builder: (context, success, child) {
        return Visibility(
          visible: success,
          child: Positioned(
              top: 54.height,
              left: 12.width,
              right: 12.width,
              child: SizedBox(
                width: _screenSize.width,
                height: 40.height,
                child: TopWidget(
                    liveID: widget.liveID,
                    isOwner: widget.isCreate,
                    onTapTopWidget: (tapEvent) {
                      _onTapTopWidget(tapEvent);
                    }),
              )),
        );
      },
    );
  }

  Widget _initBottomMenuWidget() {
    return Positioned(
        right: 27.width,
        bottom: 36.height,
        child: SizedBox(
            width: isOwner ? 72.width : 152.width,
            height: 46.height,
            child: BottomMenuWidget(
                liveID: widget.liveID, viewStore: _viewStore, toastService: widget.toastService, isOwner: isOwner)));
  }

  Widget _initBarrageInputWidget() {
    return Positioned(
        left: 15.width,
        bottom: 36.height,
        child: SizedBox(
          height: 36.height,
          width: 130.width,
          child: ValueListenableBuilder(
            valueListenable: enterRoomSuccess,
            builder: (context, value, child) {
              if (!enterRoomSuccess.value) {
                return Container();
              }
              final currentLive = _liveListStore.liveState.currentLive.value;
              final selfInfo = TUIRoomEngine.getSelfInfo();
              _barrageSendController = BarrageSendController(
                  roomId: currentLive.liveID,
                  ownerId: currentLive.liveOwner.userID,
                  selfUserId: selfInfo.userId,
                  selfName: selfInfo.userName ?? selfInfo.userId);
              return BarrageSendWidget(controller: _barrageSendController);
            },
          ),
        ));
  }

  Widget _initMuteMicrophoneWidget() {
    return Positioned(
        left: 153.width,
        bottom: 38.height,
        child: Center(
          child: ListenableBuilder(
              listenable: Listenable.merge([_liveSeatStore.liveSeatState.seatList]),
              builder: (context, child) {
                final selfUserId = TUIRoomEngine.getSelfInfo().userId;
                final seatInfo = _liveSeatStore.liveSeatState.seatList.value
                    .firstWhereOrNull((seatInfo) => seatInfo.userInfo.userID == selfUserId);
                final hasAudio = seatInfo != null && seatInfo.userInfo.microphoneStatus == DeviceStatus.on;
                final imageUrl = hasAudio ? LiveImages.openMicrophone : LiveImages.closeMicrophone;
                return Visibility(
                  visible: seatInfo != null,
                  child: Container(
                    width: 32.radius,
                    height: 32.radius,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LiveColors.designStandardWhite7.withAlpha(0x1A), width: 1)),
                    child: IconButton(
                        onPressed: () {
                          _muteMicrophone(hasAudio);
                        },
                        iconSize: 20.radius,
                        padding: EdgeInsets.zero,
                        icon: Image.asset(
                          imageUrl,
                          package: Constants.pluginName,
                          width: 20.radius,
                          height: 20.radius,
                        )),
                  ),
                );
              }),
        ));
  }

  Widget _buildEndStatisticsWidget() {
    return ValueListenableBuilder(
        valueListenable: _exitedRoom,
        builder: (context, exitRoom, child) {
          if (isOwner) {
            var endInfo = AnchorEndStatisticsWidgetInfo(
                roomId: widget.liveID,
                liveDuration: _liveStatisticsData.liveDuration,
                viewCount: _liveStatisticsData.totalViewers,
                messageCount: _liveStatisticsData.totalMessageCount,
                giftTotalCoins: _liveStatisticsData.totalGiftCoins,
                giftTotalUniqueSender: _liveStatisticsData.totalUniqueGiftSenders,
                likeTotalUniqueSender: _liveStatisticsData.totalLikesReceived);
            return Visibility(visible: exitRoom, child: AnchorEndStatisticsWidget(endWidgetInfo: endInfo));
          } else {
            final roomId = widget.liveID;
            final userName = _currentLiveInfo?.liveOwner.userName ?? "";
            final avatarUrl = _currentLiveInfo?.liveOwner.avatarURL ?? "";
            return Visibility(
                visible: exitRoom,
                child: AudienceEndStatisticsWidget(roomId: roomId, userName: userName, avatarUrl: avatarUrl));
          }
        });
  }
}

extension _RoomOperation on _VoiceRoomRootWidgetState {
  void _start({required liveID}) async {
    final liveInfo = widget.prepareStore.state.liveInfo.value;
    final params = widget.prepareStore.roomParams;
    liveInfo.seatMode = params.seatMode == TUISeatMode.applyToTake ? TakeSeatMode.apply : TakeSeatMode.free;
    liveInfo.maxSeatCount = params.maxSeatCount;
    final result = await _liveListStore.createLive(liveInfo);
    if (result.isSuccess) {
      return _onStartSuccess(result.liveInfo);
    }
    _toastAndPopup();
  }

  void _join({required liveID}) async {
    final result = await _liveListStore.joinLive(liveID);
    if (result.isSuccess) {
      return _onJoinSuccess(result.liveInfo);
    }
    _toastAndPopup();
  }

  void _onStartSuccess(LiveInfo liveInfo) {
    _audienceStore.fetchAudienceList();
    final selfInfo = TUIRoomEngine.getSelfInfo();
    _addEnterBarrage(LiveUserInfo(
        userID: selfInfo.userId, userName: selfInfo.userName ?? selfInfo.userId, avatarURL: selfInfo.avatarUrl ?? ''));
    return _didEnterRoom(liveInfo);
  }

  void _addEnterBarrage(LiveUserInfo userInfo) {
    final barrage = Barrage();
    barrage.liveID = widget.liveID;
    barrage.sender = userInfo;
    barrage.textContent = LiveKitLocalizations.of(Global.appContext())!.common_entered_room;
    barrage.timestampInSecond = DateTime.now().microsecondsSinceEpoch ~/ 1000;
    _barrageStore.appendLocalTip(barrage);
  }

  void _onJoinSuccess(LiveInfo liveInfo) {
    _audienceStore.fetchAudienceList();
    _didEnterRoom(liveInfo);
    if (!isOwner) {
      _imStore.checkFollowType(liveInfo.liveOwner.userID);
    }
  }

  void _didEnterRoom(LiveInfo liveInfo) {
    _initTopWidget();
    enterRoomSuccess.value = true;
    _currentLiveInfo = liveInfo;
  }

  void _toastAndPopup() {
    widget.toastService
        .showToast(LiveKitLocalizations.of(Global.appContext())!.common_server_error_room_does_not_exist);
    _closePage();
  }
}

extension _MediaOperation on _VoiceRoomRootWidgetState {
  void _startMicrophone() async {
    var microphonePermission = await Permission.microphone.request();
    if (!microphonePermission.isGranted) {
      widget.toastService.showToast(
          ErrorHandler.convertToErrorMessage(TUIError.errPermissionDenied.rawValue, 'microphone permission denied') ??
              '');
      return;
    }

    _deviceStore.openLocalMicrophone().then((result) {
      if (!result.isSuccess) {
        widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
    });
  }

  void _stopMicrophone() {
    _deviceStore.closeLocalMicrophone();
  }

  void _muteMicrophone(bool mute) async {
    if (mute) {
      _liveSeatStore.muteMicrophone();
      return;
    }

    final result = await _liveSeatStore.unmuteMicrophone();
    if (!result.isSuccess) {
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
  }
}

extension _TopWidgetTapEventHandler on _VoiceRoomRootWidgetState {
  void _onTapTopWidget(TopWidgetTapEvent event) {
    switch (event) {
      case TopWidgetTapEvent.stop:
        isOwner ? _showExitConfirmPanel() : _normalUserLeave();
        break;
      case TopWidgetTapEvent.audienceList:
        break;
      case TopWidgetTapEvent.liveInfo:
        break;
      case TopWidgetTapEvent.floatWindow:
        widget.floatWindowController?.onTapSwitchFloatWindowInApp.call(true);
        break;
      default:
        break;
    }
  }

  void _showExitConfirmPanel() {
    const lineColor = LiveColors.designStandardWhite7;
    const textStyle = TextStyle(
      color: LiveColors.designStandardG2,
      fontSize: 16,
    );
    final List<ActionSheetModel> menuData = List.empty(growable: true);
    final takeOrMoveSeat = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_end_live,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: 1);
    menuData.add(takeOrMoveSeat);

    final cancel = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: 2);
    menuData.add(cancel);

    _exitConfirmPanelHandler = ActionSheet.show(
      menuData,
      (model) {
        if (model.bingData != 1) return;
        _roomOwnerLeave();
      },
      backgroundColor: LiveColors.designStandardFlowkitWhite,
    );
  }

  void _roomOwnerLeave() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final future = _liveListStore.endLive();
    final result = await future;
    _liveStatisticsData = result.statisticsData;
    if (!result.isSuccess) {
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
    _exitedRoom.value = true;
    _isLinked.value = false;
  }

  void _normalUserLeave() async {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    if (!_liveSeatStore.liveSeatState.seatList.value.any((seatInfo) => seatInfo.userInfo.userID == selfUserId)) {
      return _leaveRoom();
    }

    const lineColor = LiveColors.designStandardWhite7;
    const textStyle = TextStyle(
      color: LiveColors.designStandardG2,
      fontSize: 16,
    );

    const endLinkNumber = 1;
    const exitLiveNumber = 2;
    const cancelNumber = 3;
    final List<ActionSheetModel> menuData = List.empty(growable: true);
    final endLink = ActionSheetModel(
        isCenter: true,
        text: LiveKitLocalizations.of(Global.appContext())!.common_end_link,
        textStyle: const TextStyle(color: LiveColors.notStandardRed, fontSize: 16),
        lineColor: lineColor,
        bingData: endLinkNumber);
    menuData.add(endLink);

    final exitLive = ActionSheetModel(
        isCenter: true,
        text: LiveKitLocalizations.of(Global.appContext())!.common_exit_live,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: exitLiveNumber);
    menuData.add(exitLive);

    final cancel = ActionSheetModel(
        isCenter: true,
        text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: cancelNumber);
    menuData.add(cancel);

    _normalUserLeaveHandler = ActionSheet.show(
      menuData,
      (model) {
        switch (model.bingData) {
          case endLinkNumber:
            _leaveSeat();
            break;
          case exitLiveNumber:
            _leaveRoom();
            break;
          default:
            break;
        }
      },
      title: LiveKitLocalizations.of(Global.appContext())!.common_audience_end_link_tips,
      backgroundColor: LiveColors.designStandardFlowkitWhite,
    );
  }

  Future<void> _leaveSeat() async {
    _liveSeatStore.leaveSeat();
  }

  Future<void> _leaveRoom() async {
    final future = _liveListStore.leaveLive();
    _closePage();

    final result = await future;
    if (!result.isSuccess) {
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
  }

  void _closePage() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      if (isOwner) {
        if (mounted) Navigator.pop(Global.appContext());
      } else {
        TUILiveKitNavigatorObserver.instance.backToVoiceRoomAudiencePage();
      }
    }
  }
}

extension _SeatGridWidgetTapEventHandler on _VoiceRoomRootWidgetState {
  void _onTapSeatGridWidget(TUISeatInfo seatInfo) {
    showSeatOperationMenu(seatInfo);
  }

  void showSeatOperationMenu(TUISeatInfo seatInfo) {
    isOwner ? _showRoomOwnerSeatOperationMenu(seatInfo) : _showNormalUserSeatOperationMenu(seatInfo);
  }

  void _showRoomOwnerSeatOperationMenu(TUISeatInfo seatInfo) {
    if (seatInfo.userId.isEmpty) {
      return _showRoomOwnerEmptySeatOperationMenu(seatInfo);
    }

    final isSelf = seatInfo.userId == TUIRoomEngine.getSelfInfo().userId;
    if (!isSelf) {
      _showUserManagementPanel(seatInfo);
    }
  }

  void _showRoomOwnerEmptySeatOperationMenu(TUISeatInfo seatInfo) {
    const lineColor = LiveColors.designStandardWhite7;
    const textStyle = TextStyle(
      color: LiveColors.designStandardG2,
      fontSize: 16,
    );
    final List<ActionSheetModel> menuData = List.empty(growable: true);
    if (seatInfo.isLocked != null && !seatInfo.isLocked!) {
      final inviteToTakeSeat = ActionSheetModel(
          text: LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_invite,
          textStyle: textStyle,
          lineColor: lineColor,
          bingData: 1);
      menuData.add(inviteToTakeSeat);
    }

    final isSeatLocked = seatInfo.isLocked ?? false;
    final lockSeat = ActionSheetModel(
        text: isSeatLocked
            ? LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_unlock
            : LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_lock,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: 2);
    menuData.add(lockSeat);

    final cancel = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: 3);
    menuData.add(cancel);

    _ownerEmptySeatOperationMenuSheetHandler = ActionSheet.show(
      menuData,
      (model) {
        switch (model.bingData) {
          case 1:
            _showSeatInvitationPanel(seatInfo);
            break;
          case 2:
            _lockSeat(seatInfo);
          default:
            break;
        }
      },
      backgroundColor: LiveColors.designStandardFlowkitWhite,
    );
  }

  void _showSeatInvitationPanel(TUISeatInfo seatInfo) {
    _seatInvitationPanelSheetHandler = popupWidget(
        SeatInvitationPanelWidget(liveID: widget.liveID, toastService: widget.toastService, seatIndex: seatInfo.index));
  }

  void _lockSeat(TUISeatInfo seatInfo) {
    final isSeatLocked = seatInfo.isLocked ?? false;
    isSeatLocked ? _liveSeatStore.unlockSeat(seatInfo.index) : _liveSeatStore.lockSeat(seatInfo.index);
  }

  void _showUserManagementPanel(TUISeatInfo seatInfo) {
    _userManagementPanelSheetHandler = popupWidget(UserManagementPanelWidget(
        liveID: widget.liveID,
        imStore: _imStore,
        toastService: widget.toastService,
        seatInfo: seatInfo,
        onDismiss: () => _userManagementPanelSheetHandler?.close()));
  }

  void _showNormalUserSeatOperationMenu(TUISeatInfo seatInfo) {
    final isLocked = seatInfo.isLocked ?? false;
    if (seatInfo.userId.isEmpty && !isLocked) {
      return _showNormalUserEmptySeatOperationMenu(seatInfo);
    }

    if (seatInfo.userId.isNotEmpty && seatInfo.userId != TUIRoomEngine.getSelfInfo().userId) {
      _showUserManagementPanel(seatInfo);
    }
  }

  void _showNormalUserEmptySeatOperationMenu(TUISeatInfo seatInfo) {
    const lineColor = LiveColors.designStandardWhite7;
    const textStyle = TextStyle(
      color: LiveColors.designStandardG2,
      fontSize: 16,
    );
    final List<ActionSheetModel> menuData = List.empty(growable: true);
    final takeOrMoveSeat = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_take_seat,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: 1);
    menuData.add(takeOrMoveSeat);

    final cancel = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        textStyle: textStyle,
        lineColor: lineColor,
        bingData: 2);
    menuData.add(cancel);

    _takeSeatSheetHandler = ActionSheet.show(menuData, (model) {
      if (model.bingData != 1) return;
      final isOnSeat = _liveSeatStore.liveSeatState.seatList.value
          .any((seatInfo) => seatInfo.userInfo.userID == TUIRoomEngine.getSelfInfo().userId);
      isOnSeat ? _moveToSeat(seatInfo) : _takeSeat(seatInfo);
    }, backgroundColor: LiveColors.designStandardFlowkitWhite);
  }

  void _moveToSeat(TUISeatInfo seatInfo) async {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    final result = await _liveSeatStore.moveUserToSeat(
        userID: selfUserId, targetIndex: seatInfo.index, policy: MoveSeatPolicy.abortWhenOccupied);
    if (!result.isSuccess) {
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
  }

  void _takeSeat(TUISeatInfo seatInfo) async {
    if (_viewStore.state.isApplyingToTakeSeat.value) {
      return widget.toastService
          .showToast(LiveKitLocalizations.of(Global.appContext())!.common_client_error_request_id_repeat);
    }

    _viewStore.onSentTakeSeatRequest();
    const timeoutValue = 60;
    final result = await _coGuestStore.applyForSeat(seatIndex: seatInfo.index, timeout: timeoutValue);
    if (!result.isSuccess) {
      _viewStore.onRespondedTakeSeatRequest();
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
  }
}

extension _ObserverOperation on _VoiceRoomRootWidgetState {
  void _addObserver() {
    _addGuestListener();
    _addHostListener();
    _addLiveObserver();
    _addLiveAudienceObserver();
    _isLinked.addListener(_isLinkedListener);
    _selfAudioLockStatus.addListener(_selfAudioLockStatusListener);
    _liveSeatStore.liveSeatState.seatList.addListener(_seatListChangedListener);
    widget.floatWindowController?.isFullScreen.addListener(_isFloatWindowModeListener);
    LiveListStore.shared.addLiveListListener(_liveListListener);
  }

  void _removeObserver() {
    _coGuestStore.removeHostListener(_hostListener);
    _coGuestStore.removeGuestListener(_guestListener);
    _liveSeatStore.liveSeatState.seatList.removeListener(_seatListChangedListener);
    _isLinked.removeListener(_isLinkedListener);
    _selfAudioLockStatus.removeListener(_selfAudioLockStatusListener);
    _audienceStore.removeLiveAudienceListener(_liveAudienceListener);
    _liveListStore.removeLiveListListener(_liveListener);
    widget.floatWindowController?.isFullScreen.removeListener(_isFloatWindowModeListener);
    LiveListStore.shared.removeLiveListListener(_liveListListener);
  }
}

extension _SeatGridObserver on _VoiceRoomRootWidgetState {
  void _addLiveObserver() {
    _liveListener = LiveListListener(onLiveEnded: (liveID, reason, message) {
      if (isOwner) {
        if (reason == LiveEndedReason.endedByHost) return;
        widget.toastService.showToast(LiveKitLocalizations.of(Global.appContext())!.live_room_has_been_dismissed);
        _closePage();
      } else {
        _exitedRoom.value = true;
      }
    }, onKickedOutOfLive: (liveID, reason, message) {
      if (reason == LiveKickedOutReason.byLoggedOnOtherDevice) {
        return;
      }
      _closePage();
    });
    _liveListStore.addLiveListListener(_liveListener);
  }

  void _addLiveAudienceObserver() {
    _liveAudienceListener = LiveAudienceListener(onAudienceJoined: (audience) {
      _onAudienceJoinedLive(audience);
    });
    _audienceStore.addLiveAudienceListener(_liveAudienceListener);
  }

  void _handleReceivedRequest(RequestType requestType, LiveUserInfo userInfo) {
    if (requestType == RequestType.applyToTakeSeat) {
      return;
    }

    final invitorName = _liveListStore.liveState.currentLive.value.liveOwner.userName.isNotEmpty
        ? _liveListStore.liveState.currentLive.value.liveOwner.userName
        : _liveListStore.liveState.currentLive.value.liveOwner.userID;

    final alertInfo = AlertInfo(
        imageUrl: userInfo.avatarURL,
        description: LiveKitLocalizations.of(Global.appContext())!
            .common_voiceroom_receive_seat_invitation
            .replaceAll('xxx', invitorName),
        cancelActionInfo: (
          title: LiveKitLocalizations.of(Global.appContext())!.common_reject,
          titleColor: LiveColors.designStandardG3
        ),
        cancelCallback: () {
          _responseSeatInvitation(userInfo, false);
        },
        defaultActionInfo: (
          title: LiveKitLocalizations.of(Global.appContext())!.common_accept,
          titleColor: LiveColors.designStandardB1
        ),
        defaultCallback: () {
          _responseSeatInvitation(userInfo, true);
        });

    _receivedRequestAlertHandler = Alert.showAlert(alertInfo);
    _isShowingReceivedRequestAlert = true;
  }

  void _responseSeatInvitation(LiveUserInfo userInfo, bool agree) async {
    _closeReceivedRequestAlert();

    final result = agree
        ? await _coGuestStore.acceptInvitation(userInfo.userID)
        : await _coGuestStore.rejectInvitation(userInfo.userID);
    if (!result.isSuccess) {
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
  }

  void _handleCancelledRequest(RequestType requestType, LiveUserInfo userInfo) {
    if (requestType == RequestType.applyToTakeSeat) {
      return;
    }
    _closeReceivedRequestAlert();
  }

  void _closeReceivedRequestAlert() {
    if (_isShowingReceivedRequestAlert && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowingReceivedRequestAlert = false;
    }
  }
}

extension _SubscribeState on _VoiceRoomRootWidgetState {
  void _addGuestListener() {
    _guestListener = GuestListener(onHostInvitationReceived: (hostUser) {
      if (widget.floatWindowController?.isFullScreen.value == false) {
        inviterUserInfo = hostUser;
        return;
      }
      _handleReceivedRequest(RequestType.inviteToTakeSeat, hostUser);
    }, onHostInvitationCancelled: (hostUser) {
      _handleCancelledRequest(RequestType.inviteToTakeSeat, hostUser);
    }, onGuestApplicationResponded: (isAccept, hostUser) {
      _viewStore.onRespondedTakeSeatRequest();
      if (!isAccept) {
        widget.toastService
            .showToast(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_take_seat_rejected);
      }
    }, onGuestApplicationNoResponse: (reason) {
      _viewStore.onRespondedTakeSeatRequest();
      widget.toastService.showToast(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_take_seat_timeout);
    }, onKickedOffSeat: (seatIndex, hostUser) {
      widget.toastService.showToast(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_kicked_out_of_seat);
    });
    _coGuestStore.addGuestListener(_guestListener);
  }

  void _addHostListener() {
    _hostListener = HostListener(onHostInvitationResponded: (isAccept, guestUser) {
      if (!isAccept) {
        widget.toastService
            .showToast(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_invite_seat_rejected);
      }
    }, onHostInvitationNoResponse: (guestUser, reason) {
      if (reason == NoResponseReason.timeout) {
        widget.toastService
            .showToast(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_invite_seat_timeout);
      }
    });
    _coGuestStore.addHostListener(_hostListener);
  }

  void _onSeatListChange() {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    SeatInfo? seatInfo = _liveSeatStore.liveSeatState.seatList.value
        .firstWhereOrNull((seatInfo) => seatInfo.userInfo.userID == selfUserId);
    _isLinked.value = seatInfo != null;

    final liveOwnerID = LiveListStore.shared.liveState.currentLive.value.liveOwner.userID;
    if (seatInfo != null && liveOwnerID != selfUserId) {
      _selfAudioLockStatus.value = !seatInfo.userInfo.allowOpenMicrophone;
    }
  }

  void _onLinkStatusChanged() {
    if (_isLinked.value) {
      _muteMicrophone(false);
      _startMicrophone();
    } else {
      _stopMicrophone();
    }
  }

  void _onSelfAudioLockStatusChanged() {
    final isAudioLocked = _selfAudioLockStatus.value;
    final toastMessage = isAudioLocked
        ? LiveKitLocalizations.of(context)!.common_mute_audio_by_master
        : LiveKitLocalizations.of(context)!.common_un_mute_audio_by_master;
    makeToast(msg: toastMessage);
  }

  void _isFloatWindowModeChanged() {
    if (widget.floatWindowController == null) return;
    bool isFullScreen = widget.floatWindowController!.isFullScreen.value;
    if (!isFullScreen) return;
    if (inviterUserInfo == null) return;
    _handleReceivedRequest(RequestType.inviteToTakeSeat, inviterUserInfo!);
    inviterUserInfo = null;
  }
}

extension _BarrageOperation on _VoiceRoomRootWidgetState {
  void _onAudienceJoinedLive(LiveUserInfo audience) {
    _addEnterBarrage(audience);
  }

  void _insertToBarrageMessage(Gift gift, int count, LiveUserInfo sender) {
    final liveOwner = _liveListStore.liveState.currentLive.value.liveOwner;
    final receiverUserId = liveOwner.userID;
    String receiverUserName = liveOwner.userName;
    if (receiverUserId == TUIRoomEngine.getSelfInfo().userId) {
      receiverUserName = LiveKitLocalizations.of(Global.appContext())!.common_gift_me;
    }

    Barrage barrage = Barrage();
    barrage.textContent = "gift";
    barrage.sender = sender;
    barrage.extensionInfo[Constants.keyGiftViewType] = Constants.valueGiftViewType;
    barrage.extensionInfo[Constants.keyGiftName] = gift.name;
    barrage.extensionInfo[Constants.keyGiftCount] = count.toString();
    barrage.extensionInfo[Constants.keyGiftImage] = gift.iconURL;
    barrage.extensionInfo[Constants.keyGiftReceiverUserId] = receiverUserId;

    barrage.extensionInfo[Constants.keyGiftReceiverUsername] = receiverUserName;
    _barrageDisplayController?.insertMessage(barrage);
  }
}

extension _TypeConvert on _VoiceRoomRootWidgetState {
  TUISeatInfo engineSeatInfoFromSeatInfo(SeatInfo seatInfo) {
    return TUISeatInfo(
        index: seatInfo.index,
        userId: seatInfo.userInfo.userID,
        userName: seatInfo.userInfo.userName,
        avatarUrl: seatInfo.userInfo.avatarURL,
        isLocked: seatInfo.isLocked,
        isAudioLocked: !seatInfo.userInfo.allowOpenMicrophone,
        isVideoLocked: !seatInfo.userInfo.allowOpenCamera);
  }
}
