import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart' hide LiveStatus;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/component/index.dart';
import 'package:tencent_live_uikit/component/network_info/manager/network_info_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/audience_bottom_menu_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/decorations/co_guest/co_guest_waiting_agree_widget.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/live_stream/state/co_guest_state.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/alert_dialog.dart';

import '../../../../common/widget/base_bottom_sheet.dart';
import '../../../live_define.dart';
import '../../../manager/module/user_manager.dart';
import '../panel/admin_user_management_for_audience_panel.dart';
import '../panel/audience_user_info_panel_widget.dart';
import './player_menu_widget.dart';

class AudienceLivingWidget extends StatefulWidget {
  final LiveCoreController liveCoreController;
  final LiveStreamManager liveStreamManager;
  final VoidCallback? onTapEnterFloatWindowInApp;

  const AudienceLivingWidget(
      {super.key, required this.liveCoreController, required this.liveStreamManager, this.onTapEnterFloatWindowInApp});

  @override
  State<StatefulWidget> createState() => _AudienceLivingWidgetState();
}

class _AudienceLivingWidgetState extends State<AudienceLivingWidget> {
  BarrageDisplayController? _barrageDisplayController;
  GiftPlayController? _giftPlayController;
  late NetworkInfoManager _networkInfoManager;
  late final VoidCallback _userEnterRoomListener = _onRemoteUserEnterRoom;
  late final VoidCallback _playbackVideoQualityChangedListener = _onPlaybackVideoQualityChanged;
  VideoQuality? playbackQuality;
  AlertHandler? _closePanelSheetHandler;
  BottomSheetHandler? _adminUserManagementPanelHandler;
  BottomSheetHandler? _audienceUserInfoPanelHandler;
  BottomSheetHandler? _playerMenuPanelHandler;

  late final LiveListListener _liveListListener;
  late final LiveAudienceStore _liveAudienceStore;
  late final LiveAudienceListener _liveAudienceListener;
  late final VoidCallback _loginStatusListener = _onLoginStatusChanged;
  late final StreamSubscription<LoginEvent> _loginEventSubscription;

  @override
  void initState() {
    super.initState();
    LiveKitLogger.info("AudienceLivingWidget init, ${widget.liveStreamManager.roomState.roomId}");
    _networkInfoManager = NetworkInfoManager(widget.liveStreamManager.roomState.roomId);
    widget.liveStreamManager.setUserEnterRoomNotifyStrategy(UserEnterRoomNotifyStrategy.always);
    widget.liveStreamManager.userState.enterUser.addListener(_userEnterRoomListener);
    widget.liveStreamManager.mediaState.playbackQuality.addListener(_playbackVideoQualityChangedListener);
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _closeAllDialog();
    });
    LiveListStore.shared.addLiveListListener(_liveListListener);
    LoginStore.shared.addListener(_loginStatusListener);
    _loginEventSubscription = LoginStore.shared.loginEventStream.listen((event) {
      switch (event) {
        case LoginEvent.kickedOffline:
        case LoginEvent.loginExpired:
          LiveKitLogger.warning("LoginEvent => $event");
          _closePage();
          break;
      }
    });
    _liveAudienceListener = LiveAudienceListener(
      onAudienceMessageDisabled: (LiveUserInfo audience, bool isDisable) {
        LiveKitLogger.info("onAudienceMessageDisabled: userId:${audience.userID}, isDisable=$isDisable");
        if (audience.userID != LoginStore.shared.loginState.loginUserInfo?.userID) {
          return;
        }
        final message = isDisable
            ? LiveKitLocalizations.of(Global.appContext())!.common_send_message_disabled
            : LiveKitLocalizations.of(Global.appContext())!.common_send_message_enable;
        makeToast(context, message);
      },
    );
    _liveAudienceStore = LiveAudienceStore.create(widget.liveStreamManager.roomState.roomId);
    _liveAudienceStore.addLiveAudienceListener(_liveAudienceListener);
  }

  @override
  void dispose() {
    LiveKitLogger.info("AudienceLivingWidget dispose, ${widget.liveStreamManager.roomState.roomId}");
    _closeAllDialog();
    _loginEventSubscription.cancel();
    LoginStore.shared.removeListener(_loginStatusListener);
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    _liveAudienceStore.removeLiveAudienceListener(_liveAudienceListener);
    _giftPlayController?.dispose();
    _networkInfoManager.dispose();
    widget.liveStreamManager.mediaState.playbackQuality.removeListener(_playbackVideoQualityChangedListener);
    widget.liveStreamManager.userState.enterUser.removeListener(_userEnterRoomListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = 1.screenWidth;
    final screenHeight = 1.screenHeight;
    return ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
        builder: (context, isFloatWindowMode, child) {
          return Visibility(
            visible: !isFloatWindowMode,
            child: GestureDetector(
              onTap: () => onTapAudienceLivingWidget(),
              child: Stack(
                children: [
                  _buildTopMeanWidget(context),
                  _buildNetworkInfoButtonWidget(),
                  _buildCoGuestWaitingAgreeWidget(),
                  _buildBarrageDisplayWidget(screenWidth, context),
                  _buildGiftDisplayWidget(screenWidth, screenHeight),
                  _buildBottomMenuWidget(screenWidth, context),
                  _buildRotateScreenButton(context),
                  _buildNetworkToastWidget()
                ],
              ),
            ),
          );
        });
  }

  Widget _buildTopMeanWidget(BuildContext context) {
    return Positioned(
      left: 16.width,
      top: MediaQuery.orientationOf(context) == Orientation.portrait ? 54.height : 20.width,
      right: 16.width,
      child: SizedBox(
        height: 40.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LiveInfoWidget(
              roomId: widget.liveStreamManager.roomState.roomId,
              isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
            ),
            Row(
              children: [
                AudienceListWidget(
                  roomId: widget.liveStreamManager.roomState.roomId,
                  onClickUserItem: (user) {
                    final isSelf = LoginStore.shared.loginState.loginUserInfo?.userID == user.userID;
                    if (!isSelf) {
                      _audienceUserInfoPanelHandler = popupWidget(
                          AudienceUserInfoPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
                          context: context,
                          backgroundColor: LiveColors.designStandardTransparent);
                    }
                  },
                ),
                Visibility(
                    visible: GlobalFloatWindowManager.instance.isEnableFloatWindowFeature(),
                    child: SizedBox(width: 8.width)), // Add spacing between widgets
                ValueListenableBuilder(
                    valueListenable: widget.liveStreamManager.mediaState.isRemoteVideoStreamPaused,
                    builder: (context, isRemoteVideoStreamPaused, _) {
                      return Visibility(
                        visible: GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() &&
                            !isRemoteVideoStreamPaused,
                        child: SizedBox(
                          width: 24.width,
                          height: 24.height,
                          child: GestureDetector(
                            onTap: () {
                              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                                widget.onTapEnterFloatWindowInApp?.call();
                              } else {
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                ]).then((value) {
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    widget.onTapEnterFloatWindowInApp?.call();
                                  });
                                });
                              }
                            },
                            child: Image.asset(
                              LiveImages.floatWindow,
                              package: Constants.pluginName,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    }),
                ValueListenableBuilder(
                    valueListenable: widget.liveStreamManager.mediaState.isRemoteVideoStreamPaused,
                    builder: (context, isRemoteVideoStreamPaused, _) {
                      return Visibility(visible: !isRemoteVideoStreamPaused, child: SizedBox(width: 8.width));
                    }),
                SizedBox(
                  width: 24.width,
                  height: 24.height,
                  child: GestureDetector(
                    onTap: () {
                      _onCloseIconTap();
                    },
                    child: Image.asset(
                      LiveImages.audienceClose,
                      package: Constants.pluginName,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfoButtonWidget() {
    return Positioned(
        right: 12.width,
        top: 100.height,
        height: 20.height,
        child: ListenableBuilder(
            listenable: Listenable.merge(
                [widget.liveStreamManager.roomState.liveStatus, widget.liveStreamManager.coGuestState.coGuestStatus]),
            builder: (context, _) {
              final liveStatus = widget.liveStreamManager.roomState.liveStatus.value;
              if (liveStatus != LiveStatus.playing) {
                return Container();
              }
              final isOnSeat = widget.liveStreamManager.coGuestState.coGuestStatus.value == CoGuestStatus.linking;
              return NetworkInfoButton(
                manager: _networkInfoManager,
                isAudience: !isOnSeat,
                isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
              );
            }));
  }

  Widget _buildNetworkToastWidget() {
    return ValueListenableBuilder(
        valueListenable: _networkInfoManager.state.showToast,
        builder: (context, showToast, _) {
          return Center(
              child: Visibility(visible: showToast, child: NetworkStatusToastWidget(manager: _networkInfoManager)));
        });
  }

  Widget _buildCoGuestWaitingAgreeWidget() {
    return Positioned(
        right: 8.width, top: 116.height, child: CoGuestWaitingAgreeWidget(liveStreamManager: widget.liveStreamManager));
  }

  Widget _buildBarrageDisplayWidget(double screenWidth, BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    return Positioned(
      left: orientation == Orientation.portrait ? 16.width : 35.height,
      bottom: orientation == Orientation.portrait ? 80.height : 20.width,
      height: 182.height,
      width: screenWidth - 146.width,
      child: ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.roomState.liveStatus,
        builder: (BuildContext context, value, Widget? child) {
          if (widget.liveStreamManager.roomState.liveStatus.value != LiveStatus.playing) {
            return const SizedBox.shrink();
          }

          _initBarrageDisPlayController();
          return BarrageDisplayWidget(
            controller: _barrageDisplayController!,
            onClickBarrageItem: (barrage) => _onClickBarrageItem(barrage),
          );
        },
      ),
    );
  }

  void _onClickBarrageItem(Barrage barrage) {
    final currentLive = LiveListStore.shared.liveState.currentLive.value;
    final selfID = LoginStore.shared.loginState.loginUserInfo?.userID;
    final isSelf = selfID == barrage.sender.userID;
    if (currentLive.liveID.isEmpty || barrage.sender.userID.isEmpty || isSelf) {
      return;
    }
    final user = LiveUserInfo(
        userID: barrage.sender.userID,
        userName: barrage.sender.userName,
        avatarURL: barrage.sender.avatarURL);
    final adminList = LiveAudienceStore.create(currentLive.liveID).liveAudienceState.adminList.value;
    final selfIsAdmin = adminList.any((user) => user.userID == selfID);
    final senderIsAdmin = adminList.any((user) => user.userID == barrage.sender.userID);
    final senderIsOwner = currentLive.liveOwner.userID == barrage.sender.userID;
    if (selfIsAdmin && !senderIsAdmin && !senderIsOwner) {
      _adminUserManagementPanelHandler = popupWidget(
          AdminUserManagementForAudiencePanel(
            user: user,
            liveStreamManager: widget.liveStreamManager,
            closeCallback: () => _adminUserManagementPanelHandler?.close(),
          ),
          context: context);
    } else {
      _audienceUserInfoPanelHandler = popupWidget(
          AudienceUserInfoPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
          context: context,
          backgroundColor: LiveColors.designStandardTransparent);
    }
  }

  Widget _buildGiftDisplayWidget(double screenWidth, double screenHeight) {
    return Positioned(
      left: 0,
      top: 0,
      width: screenWidth,
      height: screenHeight,
      child: ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.roomState.liveStatus,
        builder: (BuildContext context, value, Widget? child) {
          if (widget.liveStreamManager.roomState.liveStatus.value != LiveStatus.playing) {
            return const SizedBox.shrink();
          }

          _initGiftDisPlayController();
          return GiftPlayWidget(giftPlayController: _giftPlayController!);
        },
      ),
    );
  }

  void onTapAudienceLivingWidget() {
    if (!isPureViewingMode()) {
      return;
    }
    final orientation = MediaQuery.orientationOf(context);
    if (widget.liveStreamManager.roomState.roomVideoStreamIsLandscape.value && orientation == Orientation.landscape) {
      _playerMenuPanelHandler = popupWidget(
        PlayerMenuWidget(liveStreamManager: widget.liveStreamManager),
        context: context,
        barrierColor: LiveColors.designStandardTransparent,
        backgroundColor: LiveColors.designStandardTransparent,
      );
    }
  }

  Widget _buildBottomMenuWidget(double screenWidth, BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.liveStreamManager.roomState.liveStatus,
        widget.liveStreamManager.roomState.roomVideoStreamIsLandscape,
      ]),
      builder: (BuildContext context, Widget? child) {
        if (widget.liveStreamManager.roomState.liveStatus.value != LiveStatus.playing) {
          return const SizedBox.shrink();
        }
        bool enableCoGuest = widget.liveStreamManager.roomManager.isScreenShareLive() ||
            !widget.liveStreamManager.roomState.roomVideoStreamIsLandscape.value;
        return Positioned(
          left: 0,
          bottom: 34.height,
          height: 36.height,
          width: screenWidth,
          child: Visibility(
            visible: MediaQuery.orientationOf(context) == Orientation.portrait,
            child: AudienceBottomMenuWidget(
              liveStreamManager: widget.liveStreamManager,
              enableCoGuest: enableCoGuest,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotateScreenButton(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    return Positioned(
      right: orientation == Orientation.portrait ? 10.width : 20.height,
      top: orientation == Orientation.portrait ? 475.height : 185.width,
      height: 32.radius,
      width: 32.radius,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.liveStreamManager.roomState.roomVideoStreamIsLandscape,
          widget.liveStreamManager.mediaState.isRemoteVideoStreamPaused,
          widget.liveStreamManager.roomState.liveStatus,
        ]),
        builder: (context, _) {
          final roomVideoStreamIsLandscape = widget.liveStreamManager.roomState.roomVideoStreamIsLandscape.value;
          final isRemoteVideoStreamPaused = widget.liveStreamManager.mediaState.isRemoteVideoStreamPaused.value;
          bool visible = !isRemoteVideoStreamPaused && roomVideoStreamIsLandscape;
          if (visible &&
              widget.liveStreamManager.roomState.liveStatus.value == LiveStatus.playing &&
              widget.liveStreamManager.roomManager.isScreenShareLive()) {
            visible = false;
          }
          return Visibility(
            visible: visible,
            child: IconButton(
              icon: Image.asset(
                LiveImages.rotateScreen,
                package: Constants.pluginName,
                width: 32.radius,
                height: 32.radius,
                fit: BoxFit.fill,
              ),
              iconSize: 32.radius,
              padding: EdgeInsets.zero,
              onPressed: () => _onRotateButtonTapped(orientation),
            ),
          );
        },
      ),
    );
  }
}

extension on _AudienceLivingWidgetState {
  void _initBarrageDisPlayController() {
    if (_barrageDisplayController == null) {
      _barrageDisplayController = BarrageDisplayController(
          roomId: widget.liveStreamManager.roomState.roomId,
          ownerId: widget.liveStreamManager.roomState.liveInfo.liveOwner.userID,
      );
      _onRemoteUserEnterRoom();
    }
  }

  void _initGiftDisPlayController() {
    if (_giftPlayController != null) {
      return;
    }

    _initBarrageDisPlayController();

    _barrageDisplayController?.setCustomBarrageBuilder(GiftBarrageItemBuilder(
      selfUserId: LoginStore.shared.loginState.loginUserInfo?.userID ?? '',
      onClickItem: (barrage) => _onClickBarrageItem(barrage),
    ));

    _giftPlayController = GiftPlayController(
        roomId: widget.liveStreamManager.roomState.roomId, language: DeviceLanguage.getCurrentLanguageCode(context));
    _giftPlayController?.onReceiveGiftCallback = _insertToBarrageMessage;
  }

  void _onRemoteUserEnterRoom() {
    final sender = widget.liveStreamManager.userState.enterUser.value;
    if (sender.userID.isEmpty) return;
    Barrage barrage = Barrage();
    barrage.liveID = widget.liveStreamManager.roomState.roomId;
    barrage.sender = sender;
    barrage.textContent = LiveKitLocalizations.of(Global.appContext())!.common_entered_room;
    _barrageDisplayController?.insertMessage(barrage);
  }

  void _insertToBarrageMessage(Gift gift, int count, LiveUserInfo sender) {
    final receiver = widget.liveStreamManager.roomState.liveInfo.liveOwner;
    if (receiver.userID == LoginStore.shared.loginState.loginUserInfo?.userID) {
      receiver.userName = LiveKitLocalizations.of(Global.appContext())!.common_gift_me;
    }

    Barrage barrage = Barrage();
    barrage.liveID = widget.liveStreamManager.roomState.roomId;
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

  void _onPlaybackVideoQualityChanged() {
    final playbackVideoQuality = widget.liveStreamManager.mediaState.playbackQuality.value;
    if (playbackVideoQuality != null && playbackQuality != null) {
      final toast = LiveKitLocalizations.of(context)!.live_video_resolution_changed +
          _getVideoQualityString(playbackVideoQuality);
      widget.liveStreamManager.toastSubject.add(toast);
    }
    playbackQuality = playbackVideoQuality;
  }

  void _onLoginStatusChanged() {
    final loginStatus = LoginStore.shared.loginState.loginStatus;
    if (loginStatus == LoginStatus.unlogin) {
      LiveKitLogger.warning("LoginStatus => unlogin");
      _closePage();
    }
  }

  void _leaveRoom() {
    widget.liveStreamManager.leaveLive().then((result) {
      widget.liveStreamManager.onLeaveLive();
      _closePage();
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _closePage() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _onCloseIconTap() {
    if (widget.liveStreamManager.coGuestState.coGuestStatus.value != CoGuestStatus.linking) {
      _leaveRoom();
      return;
    }

    _closePanelSheetHandler = Alert.showAlert(
      AlertInfo(
        description: LiveKitLocalizations.of(context)!.common_audience_end_link_tips,
        itemList: [
          ButtonConfig(
            text: LiveKitLocalizations.of(context)!.common_end_link,
            type: TextColorPreset.red,
            onClick: () {
              _closePanelSheetHandler?.close();
              CoGuestStore coGuestStore = CoGuestStore.create(widget.liveStreamManager.roomState.roomId);
              coGuestStore.disconnect();
            },
          ),
          ButtonConfig(
            text: LiveKitLocalizations.of(context)!.common_exit_live,
            onClick: () {
              _closePanelSheetHandler?.close();
             _leaveRoom();
            },
          ),
          ButtonConfig(
            text: LiveKitLocalizations.of(context)!.common_cancel,
            onClick: () => _closePanelSheetHandler?.close(),
          ),
        ],
      ),
      context,
    );
  }

  void _onRotateButtonTapped(Orientation currentOrientation) {
    if (currentOrientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  String _getVideoQualityString(VideoQuality videoQuality) {
    switch (videoQuality) {
      case VideoQuality.quality1080P:
        return '1080P';
      case VideoQuality.quality720P:
        return '720P';
      case VideoQuality.quality540P:
        return '540P';
      case VideoQuality.quality360P:
        return '360P';
    }
  }

  bool isPureViewingMode() {
    final selfUserId = LoginStore.shared.loginState.loginUserInfo?.userID;
    LiveSeatStore liveSeatStore = LiveSeatStore.create(widget.liveStreamManager.roomState.roomId);
    return !liveSeatStore.liveSeatState.seatList.value.any((seat) => seat.userInfo.userID == selfUserId);
  }

  void _closeAllDialog() {
    _closePanelSheetHandler?.close();
    _adminUserManagementPanelHandler?.close();
    _audienceUserInfoPanelHandler?.close();
    _playerMenuPanelHandler?.close();
  }
}
