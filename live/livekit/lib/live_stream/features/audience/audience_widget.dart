import 'dart:async';

import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart' hide LiveStatus;
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/live_navigator_observer.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/audience_empty_seat_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/audience_living_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/host_absent_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/audience_user_info_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/audience_user_management_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/co_guest_type_select_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/decorations/index.dart';
import 'package:tencent_live_uikit/live_stream/features/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/toast.dart';

import '../../../common/widget/float_window/float_window_mode.dart';
import '../../../component/float_window/global_float_window_manager.dart';
import '../../live_define.dart';
import '../../state/co_guest_state.dart';
import '../decorations/co_guest/co_guest_seat_list_widget.dart';
import 'living_widget/background_image_widget.dart';

class AudienceController {
  final String roomId;
  final LiveCoreController liveCoreController = LiveCoreController.create(CoreViewType.playView);
  final LiveStreamManager liveStreamManager = LiveStreamManager();
  ValueChanged<bool>? onKeepLiveChanged;
  ValueChanged<bool>? onSwitchFloatWindowOutOfApp;
  VoidCallback? onTapEnterFloatWindowInApp;

  AudienceController({required this.roomId}) {
    liveCoreController.setLiveID(roomId);
    liveStreamManager.setLiveID(roomId);
  }

  _AudienceWidgetState? _state;

  void _attach(_AudienceWidgetState state) {
    _state = state;
  }

  void _detach(_AudienceWidgetState state) {
    if (_state == state) {
      _state = null;
    }
  }

  void joinLive() {
    _state?._joinLiveStream();
  }

  void leaveLive() {
    _state?._leaveLiveStream(reset: true);
  }

  void startPreload() {
    _state?._startPreload();
  }

  void stopPreload() {
    _state?._stopPreload();
  }

  void setFullScreenChanged(bool isFullScreen) {
    _state?._setFullScreenChanged(isFullScreen);
  }

  void dispose() {}
}

class AudienceWidget extends StatefulWidget {
  final LiveInfo liveInfo;
  final AudienceController audienceController;
  final VoidCallback? onTapEnterFloatWindowInApp;

  final ValueChanged<bool>? onCoGuestStateChanged;
  final VoidCallback? onInitState;
  final VoidCallback? onDispose;

  const AudienceWidget({
    super.key,
    required this.liveInfo,
    required this.audienceController,
    this.onTapEnterFloatWindowInApp,
    this.onCoGuestStateChanged,
    this.onInitState,
    this.onDispose,
  });

  @override
  State<AudienceWidget> createState() => _AudienceWidgetState();
}

class _AudienceWidgetState extends State<AudienceWidget> {
  late final String roomId;
  late final AudienceController audienceController;
  late final LiveCoreController liveCoreController;
  late final LiveStreamManager liveStreamManager;

  late final VoidCallback _liveStatusListener = _onLiveStatusChange;
  late final VoidCallback _coGuestStatusListener = _onCoGuestStatusChanged;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;
  late final VoidCallback _floatWindowModeListener = _onFloatWindowModeChanged;

  BottomSheetHandler? _audienceUserInfoPanelHandler;
  BottomSheetHandler? _audienceUserManagementPanelHandler;

  final ValueNotifier<int> _joinLiveVersion = ValueNotifier(0);

  late final LiveListListener _liveListListener;
  late final LiveSeatListener _liveSeatListener;
  LiveSeatStore? _liveSeatStore;

  late final StreamSubscription? _toastSubscription;

  @override
  void initState() {
    roomId = widget.liveInfo.liveID;
    LiveKitLogger.info("AudienceWidget init, liveID=$roomId");
    super.initState();
    audienceController = widget.audienceController;
    liveCoreController = widget.audienceController.liveCoreController;
    liveStreamManager = widget.audienceController.liveStreamManager;
    liveStreamManager.roomState.roomId = roomId;
    liveStreamManager.roomState.liveInfo = widget.liveInfo;
    widget.audienceController._attach(this);
    _init();
    widget.onInitState?.call();
  }

  @override
  void didUpdateWidget(covariant AudienceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audienceController != widget.audienceController) {
      oldWidget.audienceController._detach(this);
      widget.audienceController._attach(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiveColors.notStandardPureBlack,
      child: Stack(
        children: [
          _buildBackgroundImageWidget(),
          _buildMainWidget(),
          ValueListenableBuilder(
            valueListenable: _joinLiveVersion,
            builder: (BuildContext context, joinLiveVersion, Widget? child) {
              return  AudienceLivingWidget(
                key: ValueKey('AudienceLivingWidget_${roomId}_$joinLiveVersion'),
                liveCoreController: liveCoreController,
                liveStreamManager: liveStreamManager,
                onTapEnterFloatWindowInApp: () {
                  widget.onTapEnterFloatWindowInApp?.call();
                  audienceController.onTapEnterFloatWindowInApp?.call();
                },
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: liveStreamManager.roomState.liveStatus,
            builder: (BuildContext context, value, Widget? child) {
              return Visibility(
                visible: liveStreamManager.roomState.liveStatus.value == LiveStatus.finished,
                child: AudienceEndStatisticsWidget(
                  roomId: roomId,
                  avatarUrl: liveStreamManager.roomState.liveInfo.liveOwner.avatarURL,
                  userName: liveStreamManager.roomState.liveInfo.liveOwner.userName,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainWidget() {
    return Stack(
      children: [
        _buildLiveCoreWidget(),
        ValueListenableBuilder(
            valueListenable: liveStreamManager.roomState.liveStatus,
            builder: (BuildContext context, LiveStatus liveStatus, Widget? child) {
              if (liveStatus == LiveStatus.none) {
                return const SizedBox.shrink();
              } else {
                return _buildSeatListWidget();
              }
            }),
      ],
    );
  }

  Widget _buildLiveCoreWidget() {
    final seatTemplate = liveStreamManager.roomState.liveInfo.seatTemplate;
    if (seatTemplate is VideoLandscape4Seats) {
      return LayoutBuilder(builder: (context, constraints) {
        final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isFloating = liveStreamManager.floatWindowState.isFloatWindowMode.value;
        double height = isFloating ? screenHeight : (isPortrait ? 9 / 16.0 * screenWidth : screenHeight);
        double top = isFloating ? 0 : (isPortrait ? 120.height : 0);
        return Container(
          color: isFloating ? Colors.transparent : Colors.black,
          margin: EdgeInsets.only(top: top),
          width: screenWidth,
          height: height,
          child: Stack(
            children: [
              LiveCoreWidget(controller: liveCoreController),
              HostAbsentWidget(liveStreamManager: liveStreamManager),
            ],
          ),
        );
      });
    } else {
      return Stack(
        children: [
          LiveCoreWidget(
            controller: liveCoreController,
            videoWidgetBuilder: VideoWidgetBuilder(
                coGuestWidgetBuilder: _createCoGuestWidgetBuilder(),
                coHostWidgetBuilder: (context, seatInfo, viewLayer) {
                  if (viewLayer == ViewLayer.background) {
                    return CoHostBackgroundWidget(
                        seatInfo: seatInfo, isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode);
                  } else {
                    return CoHostForegroundWidget(
                      seatInfo: seatInfo,
                      isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode,
                      onTap: () => _onTapCoHostForegroundWidget(seatInfo),
                    );
                  }
                },
                battleWidgetBuilder: (context, seatInfo) {
                  return BattleMemberInfoWidget(
                      liveStreamManager: liveStreamManager,
                      battleUserId: seatInfo.userInfo.userID,
                      isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode);
                },
                battleContainerWidgetBuilder: (context) {
                  return BattleInfoWidget(
                      liveStreamManager: liveStreamManager,
                      isOwner: false,
                      isFloatWindowMode: liveStreamManager.floatWindowState.isFloatWindowMode);
                }),
          ),
          HostAbsentWidget(liveStreamManager: liveStreamManager),
        ],
      );
    }
  }

  void _onTapCoHostForegroundWidget(SeatInfo seatInfo) {
    LiveUserInfo userInfo = LiveUserInfo();
    userInfo.userID = seatInfo.userInfo.userID;
    userInfo.userName = seatInfo.userInfo.userName;
    userInfo.avatarURL = seatInfo.userInfo.avatarURL;
    _audienceUserInfoPanelHandler = popupWidget(
        AudienceUserInfoPanelWidget(
          user: userInfo,
          liveID: seatInfo.userInfo.liveID,
          liveStreamManager: liveStreamManager,
          enableEnterRoom: LiveListStore.shared.liveState.currentLive.value.liveID != seatInfo.userInfo.liveID,
          onClose: () {
            _audienceUserInfoPanelHandler?.close();
            _audienceUserInfoPanelHandler = null;
          },
          onExitRoom: () {
            _audienceUserInfoPanelHandler?.close();
            _audienceUserInfoPanelHandler = null;
            _closePage();
          },
        ),
        context: context,
        backgroundColor: LiveColors.designStandardTransparent);
  }

  Widget _buildSeatListWidget() {
    if (!liveStreamManager.roomManager.isScreenShareLive()) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: liveStreamManager.floatWindowState.isFloatWindowMode,
      builder: (context, isFloatWindowMode, child) {
        return Visibility(
          visible: !isFloatWindowMode,
          child: Center(
            child: CoGuestSeatListWidget(
              liveID: liveStreamManager.roomState.roomId,
              onTapSeat: (seatInfo) {
                if (seatInfo.userInfo.userID.isEmpty) {
                  final coGuestStatus = liveStreamManager.coGuestState.coGuestStatus.value;
                  if (coGuestStatus == CoGuestStatus.applying || coGuestStatus == CoGuestStatus.linking) {
                    LiveKitLogger.info("can't link, coGuestStatus:$coGuestStatus");
                  } else {
                    bool enableCamera = !liveStreamManager.roomManager.isScreenShareLive();
                    BottomSheetHandler? sheetHandler;
                    sheetHandler = popupWidget(
                        CoGuestTypeSelectPanelWidget(
                          parentContext: context,
                          liveStreamManager: liveStreamManager,
                          seatIndex: seatInfo.index,
                          enableCamera: enableCamera,
                          onClose: () {
                            sheetHandler?.close();
                          },
                        ),
                        context: context);
                  }
                  return;
                }
                final isSelf = LoginStore.shared.loginState.loginUserInfo?.userID == seatInfo.userInfo.userID;
                final user = LiveUserInfo(
                    userID: seatInfo.userInfo.userID,
                    userName: seatInfo.userInfo.userName,
                    avatarURL: seatInfo.userInfo.avatarURL);
                if (isSelf) {
                  _audienceUserManagementPanelHandler = popupWidget(
                      AudienceUserManagementPanelWidget(
                        user: user,
                        liveStreamManager: liveStreamManager,
                        closeCallback: () {
                          _audienceUserManagementPanelHandler?.close();
                        },
                      ),
                      context: context);
                } else {
                  _audienceUserInfoPanelHandler = popupWidget(
                      AudienceUserInfoPanelWidget(user: user, liveStreamManager: liveStreamManager),
                      context: context,
                      backgroundColor: LiveColors.designStandardTransparent);
                }
              },
            ),
          ),
        );
      },
    );
  }

  CoGuestWidgetBuilder _createCoGuestWidgetBuilder() {
    final isFloatWindowMode = liveStreamManager.floatWindowState.isFloatWindowMode;
    return (context, seatInfo, viewLayer) {
      if (seatInfo.userInfo.userID.isEmpty) {
        if (viewLayer == ViewLayer.background) {
          return AudienceEmptySeatWidget(seatInfo: seatInfo, liveStreamManager: liveStreamManager);
        }
        return Container();
      }
      if (viewLayer == ViewLayer.background) {
        final isVideoDynamicFloat7SeatsTemplate =
            LiveListStore.shared.liveState.currentLive.value.seatTemplate is VideoDynamicFloat7Seats;
        if (!isVideoDynamicFloat7SeatsTemplate) {
          return CoGuestBackgroundWidget(seatInfo: seatInfo, isFloatWindowMode: isFloatWindowMode);
        }

        final isOwner = LiveListStore.shared.liveState.currentLive.value.liveOwner.userID == seatInfo.userInfo.userID;
        final isFeaturedHost = seatInfo.isFeaturedHost;
        return (isOwner || isFeaturedHost)
            ? SizedBox.shrink()
            : CoGuestBackgroundWidget(seatInfo: seatInfo, isFloatWindowMode: isFloatWindowMode);
      } else {
        return CoGuestForegroundWidget(
          seatInfo: seatInfo,
          isFloatWindowMode: isFloatWindowMode,
          onTap: () {
            final isSelf = LoginStore.shared.loginState.loginUserInfo?.userID == seatInfo.userInfo.userID;
            final user = LiveUserInfo(
                userID: seatInfo.userInfo.userID,
                userName: seatInfo.userInfo.userName,
                avatarURL: seatInfo.userInfo.avatarURL);
            if (isSelf) {
              _audienceUserManagementPanelHandler = popupWidget(
                  AudienceUserManagementPanelWidget(
                    user: user,
                    liveStreamManager: liveStreamManager,
                    closeCallback: () {
                      _audienceUserManagementPanelHandler?.close();
                    },
                  ),
                  context: context);
            } else {
              _audienceUserInfoPanelHandler = popupWidget(
                  AudienceUserInfoPanelWidget(user: user, liveStreamManager: liveStreamManager),
                  context: context,
                  backgroundColor: LiveColors.designStandardTransparent);
            }
          },
        );
      }
    };
  }

  Widget _buildBackgroundImageWidget() {
    return ListenableBuilder(
        listenable: LiveListStore.shared.liveState.currentLive,
        builder: (BuildContext context, Widget? child) {
          final liveInfo = LiveListStore.shared.liveState.currentLive.value;
          if (liveInfo.liveID.isEmpty || liveInfo.liveID != widget.liveInfo.liveID) {
            return const SizedBox.shrink();
          }
          final url = liveInfo.backgroundURL.isEmpty ? liveInfo.coverURL : liveInfo.backgroundURL;
          if (url.isEmpty) return SizedBox.shrink();
          return BackgroundImageWidget(backgroundURL: url);
        });
  }

  @override
  void dispose() {
    LiveKitLogger.info("AudienceWidget dispose, roomId=$roomId");
    _dispose();
    liveStreamManager.dispose();
    audienceController._detach(this);
    super.dispose();
  }
}

extension on _AudienceWidgetState {
  void _init() {
    _toastSubscription = liveStreamManager.toastSubject.stream.listen((toast) {
      if (!mounted) return;
      makeToast(context, toast);
    });
    _liveListListener = LiveListListener(
      onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
        _closeAllDialog();
      },
      onKickedOutOfLive: (String liveID, LiveKickedOutReason reason, String message) {
        _handleKickedOut();
      },
    );
    LiveListStore.shared.addLiveListListener(_liveListListener);
    _addLiveStatusListener();
    _addCoGuestStatusListener();
    liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_isFloatWindowModeListener);
    liveStreamManager.floatWindowState.floatWindowMode.addListener(_floatWindowModeListener);
    _liveSeatListener = LiveSeatListener(onLocalCameraClosedByAdmin: () {
      liveStreamManager.mediaManager.closeLocalCamera();
      if (!mounted) return;
      final toastMessage = LiveKitLocalizations.of(context)!.common_mute_video_by_owner;
      makeToast(context, toastMessage);
    }, onLocalCameraOpenedByAdmin: (DeviceControlPolicy policy) {
      if (policy == DeviceControlPolicy.unlockOnly) {
        if (!mounted) return;
        final toastMessage = LiveKitLocalizations.of(context)!.common_un_mute_video_by_master;
        makeToast(context, toastMessage);
      }
    }, onLocalMicrophoneClosedByAdmin: () {
      if (!mounted) return;
      final toastMessage = LiveKitLocalizations.of(context)!.common_mute_audio_by_master;
      makeToast(context, toastMessage);
    }, onLocalMicrophoneOpenedByAdmin: (DeviceControlPolicy policy) {
      if (policy == DeviceControlPolicy.unlockOnly) {
        if (!mounted) return;
        final toastMessage = LiveKitLocalizations.of(context)!.common_un_mute_audio_by_master;
        makeToast(context, toastMessage);
      }
    });
    _addStoreObserver();
  }

  void _dispose() {
    _toastSubscription?.cancel();
    widget.onDispose?.call();
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    _closeAllDialog();
    _removeCoGuestStatusListener();
    _removeLiveStatusListener();
    // Defer _leaveLiveStream to avoid setState() when widget tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leaveLiveStream();
    });
    liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_isFloatWindowModeListener);
    liveStreamManager.floatWindowState.floatWindowMode.removeListener(_floatWindowModeListener);
    _removeStoreObserver();
  }

  void _handleKickedOut() {
    makeToast(context, LiveKitLocalizations.of(context)!.common_kicked_out_of_room_by_owner, useRootOverlay: true);
    _closePage();
  }

  void _closeAllDialog() {
    _audienceUserInfoPanelHandler?.close();
    _audienceUserInfoPanelHandler = null;
    _audienceUserManagementPanelHandler?.close();
    _audienceUserManagementPanelHandler = null;
  }

  void _closePage() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _startPreload() {
    LiveKitLogger.info('AudienceWidget _startPreload: $roomId');
    liveCoreController.startPreviewLiveStream(roomId, true, null);
  }

  void _stopPreload() {
    LiveKitLogger.info('AudienceWidget _stopPreload: $roomId');
    liveCoreController.stopPreviewLiveStream(roomId);
  }

  void _onKeepLiveChanged(bool keepLive) {
    LiveKitLogger.info("onKeepLiveChanged: $keepLive, roomId=$roomId");
    audienceController.onKeepLiveChanged?.call(keepLive);
  }

  Future<void> _joinLiveStream() async {
    LiveKitLogger.info('AudienceWidget _joinLiveStream: $roomId');
    KeyMetrics.reportKeyMetrics(KeyMetrics.kLiveIntegrationSuccessful);
    _addStoreObserver();
    try {
      _onKeepLiveChanged(true);
      var result = await liveStreamManager.joinLive(roomId);
      LiveKitLogger.info("joinLive:$roomId, code=${result.errorCode}, mounted=$mounted");
      if (!mounted) return;
      if (result.errorCode != 0) {
        makeToast(context, ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage),
            type: ToastType.error, useRootOverlay: true);
        _closePage();
        return;
      }
      _onKeepLiveChanged(false);
      liveStreamManager.onJoinLive(result.liveInfo);
    } catch (e) {
      if (!mounted) return;
      LiveKitLogger.error('AudienceWidget _joinLiveStream error: $e');
      makeToast(context, ErrorHandler.convertToErrorMessage(-1, e.toString()),
          type: ToastType.error, useRootOverlay: true);
      _closePage();
    }
  }

  // The old Store is cleared on leave; reset the Store to prepare for the next join on slide-in.
  void _leaveLiveStream({bool reset = false}) {
    LiveKitLogger.info('AudienceWidget _leaveLiveStream: $roomId, reset=$reset');
    _removeStoreObserver();
    liveStreamManager.leaveLive().then((result) {
      if (!mounted) return;
      if (result.isSuccess) {
        liveStreamManager.onLeaveLive();
        if (reset) {
          LiveKitLogger.info("resetManagerStore, roomId=$roomId, joinLiveVersion=${_joinLiveVersion.value}");
          liveStreamManager.resetManagerStore();
          _joinLiveVersion.value++;
        }
      } else {
        LiveKitLogger.error("leaveLive, error=${result.errorCode} ${result.errorMessage}");
      }
    });
  }
  
  void _addStoreObserver() {
    _liveSeatStore = LiveSeatStore.create(roomId);
    _liveSeatStore!.addLiveSeatEventListener(_liveSeatListener);
  }

  void _removeStoreObserver() {
    if (_liveSeatStore == null) return;
    _liveSeatStore!.removeLiveSeatEventListener(_liveSeatListener);
    _liveSeatStore = null;
  }

  void _addLiveStatusListener() {
    liveStreamManager.roomState.liveStatus.addListener(_liveStatusListener);
  }

  void _removeLiveStatusListener() {
    liveStreamManager.roomState.liveStatus.removeListener(_liveStatusListener);
  }

  void _onLiveStatusChange() {
    final status = liveStreamManager.roomState.liveStatus.value;
    if (status == LiveStatus.finished) {
      GlobalFloatWindowManager floatWindowManager = GlobalFloatWindowManager.instance;
      if (floatWindowManager.isEnableFloatWindowFeature()) {
        if (floatWindowManager.isFloating()) {
          floatWindowManager.overlayManager.closeOverlay();
        }
      } else {
        TUILiveKitNavigatorObserver.instance.backToLiveRoomAudiencePage();
      }
    }
  }

  void _addCoGuestStatusListener() {
    liveStreamManager.coGuestState.coGuestStatus.addListener(_coGuestStatusListener);
  }

  void _removeCoGuestStatusListener() {
    liveStreamManager.coGuestState.coGuestStatus.removeListener(_coGuestStatusListener);
    widget.onCoGuestStateChanged?.call(false);
    audienceController.onKeepLiveChanged?.call(false);
  }

  void _onCoGuestStatusChanged() {
    final status = liveStreamManager.coGuestState.coGuestStatus.value;
    final shouldDisableScroll = status == CoGuestStatus.applying || status == CoGuestStatus.linking;
    widget.onCoGuestStateChanged?.call(shouldDisableScroll);
    audienceController.onKeepLiveChanged?.call(shouldDisableScroll);
  }

  void _isFloatWindowModeChanged() {
    if (liveStreamManager.floatWindowState.isFloatWindowMode.value) {
      _closeAllDialog();
    }
  }

  void _onFloatWindowModeChanged() {
    FloatWindowMode floatWindowMode = liveStreamManager.floatWindowState.floatWindowMode.value;
    if (floatWindowMode == FloatWindowMode.outOfApp) {
      widget.audienceController.onSwitchFloatWindowOutOfApp?.call(true);
    } else if (floatWindowMode == FloatWindowMode.none) {
      widget.audienceController.onSwitchFloatWindowOutOfApp?.call(false);
    }
  }

  void _setFullScreenChanged(bool isFullScreen) {
    FloatWindowMode floatWindowMode = liveStreamManager.floatWindowState.floatWindowMode.value;
    if (isFullScreen) {
      if (floatWindowMode != FloatWindowMode.outOfApp) {
        liveStreamManager.setFloatWindowMode(FloatWindowMode.none);
      }
    } else {
      liveStreamManager.setFloatWindowMode(FloatWindowMode.inApp);
    }
  }
}
