import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
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

import '../../../component/float_window/global_float_window_manager.dart';
import '../../live_define.dart';
import '../../state/co_guest_state.dart';
import '../decorations/co_guest/co_guest_seat_list_widget.dart';
import 'living_widget/background_image_widget.dart';

class AudienceWidget extends StatefulWidget {
  final String roomId;
  final LiveCoreController liveCoreController;
  final LiveStreamManager liveStreamManager;
  final VoidCallback? onTapEnterFloatWindowInApp;

  final ValueChanged<bool>? onJoinLiveStateChanged;
  final ValueChanged<bool>? onCoGuestStateChanged;
  final VoidCallback? onDispose;

  const AudienceWidget(
      {super.key,
      required this.roomId,
      required this.liveCoreController,
      required this.liveStreamManager,
      this.onTapEnterFloatWindowInApp,
      this.onJoinLiveStateChanged,
      this.onCoGuestStateChanged,
      this.onDispose});

  @override
  State<AudienceWidget> createState() => _AudienceWidgetState();
}

class _AudienceWidgetState extends State<AudienceWidget> {
  late final VoidCallback _liveStatusListener = _onLiveStatusChange;
  late final VoidCallback _coGuestStatusListener = _onCoGuestStatusChanged;
  late final VoidCallback _isFloatWindowModeListener = _isFloatWindowModeChanged;

  BottomSheetHandler? _audienceUserInfoPanelHandler;
  BottomSheetHandler? _audienceUserManagementPanelHandler;

  late final LiveListListener _liveListListener;
  late final LiveSeatListener _liveSeatListener;

  @override
  void initState() {
    LiveKitLogger.info("AudienceWidget init");
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiveColors.notStandardPureBlack,
      child: Stack(
        children: [
          _buildBackgroundImageWidget(),
          _buildMainWidget(),
          AudienceLivingWidget(
            liveCoreController: widget.liveCoreController,
            liveStreamManager: widget.liveStreamManager,
            onTapEnterFloatWindowInApp: widget.onTapEnterFloatWindowInApp,
          ),
          ValueListenableBuilder(
            valueListenable: widget.liveStreamManager.roomState.liveStatus,
            builder: (BuildContext context, value, Widget? child) {
              return Visibility(
                visible: widget.liveStreamManager.roomState.liveStatus.value == LiveStatus.finished,
                child: AudienceEndStatisticsWidget(
                  roomId: widget.roomId,
                  avatarUrl: widget.liveStreamManager.roomState.liveInfo.liveOwner.avatarURL,
                  userName: widget.liveStreamManager.roomState.liveInfo.liveOwner.userName,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainWidget() {
    return ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.roomState.liveStatus,
        builder: (BuildContext context, LiveStatus liveStatus, Widget? child) {
          if (liveStatus == LiveStatus.none) {
            return const SizedBox.shrink();
          } else {
            return Stack(
              children: [
                _buildLiveCoreWidget(),
                _buildSeatListWidget(),
              ],
            );
          }
        });
  }

  Widget _buildLiveCoreWidget() {
    final seatTemplate = widget.liveStreamManager.roomState.liveInfo.seatTemplate;
    if (seatTemplate is VideoLandscape4Seats) {
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
          child: Stack(
            children: [
              LiveCoreWidget(controller: widget.liveCoreController),
              HostAbsentWidget(liveStreamManager: widget.liveStreamManager),
            ],
          ),
        );
      });
    } else {
      return Stack(
        children: [
          LiveCoreWidget(
            controller: widget.liveCoreController,
            videoWidgetBuilder: VideoWidgetBuilder(
                coGuestWidgetBuilder: _createCoGuestWidgetBuilder(),
                coHostWidgetBuilder: (context, seatInfo, viewLayer) {
                  if (viewLayer == ViewLayer.background) {
                    return CoHostBackgroundWidget(
                        seatInfo: seatInfo,
                        isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
                  } else {
                    return CoHostForegroundWidget(
                      seatInfo: seatInfo,
                      isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
                      onTap: () => _onTapCoHostForegroundWidget(seatInfo),
                    );
                  }
                },
                battleWidgetBuilder: (context, seatInfo) {
                  return BattleMemberInfoWidget(
                      liveStreamManager: widget.liveStreamManager,
                      battleUserId: seatInfo.userInfo.userID,
                      isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
                },
                battleContainerWidgetBuilder: (context) {
                  return BattleInfoWidget(
                      liveStreamManager: widget.liveStreamManager,
                      isOwner: false,
                      isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
                }),
          ),
          HostAbsentWidget(liveStreamManager: widget.liveStreamManager),
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
          liveStreamManager: widget.liveStreamManager,
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
    if (!widget.liveStreamManager.roomManager.isScreenShareLive()) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: widget.liveStreamManager.floatWindowState.isFloatWindowMode,
      builder: (context, isFloatWindowMode, child) {
        return Visibility(
          visible: !isFloatWindowMode,
          child: Center(
            child: CoGuestSeatListWidget(
              liveID: widget.liveStreamManager.roomState.roomId,
              onTapSeat: (seatInfo) {
                if (seatInfo.userInfo.userID.isEmpty) {
                  final coGuestStatus = widget.liveStreamManager.coGuestState.coGuestStatus.value;
                  if (coGuestStatus == CoGuestStatus.applying || coGuestStatus == CoGuestStatus.linking) {
                    LiveKitLogger.info("can't link, coGuestStatus:$coGuestStatus");
                  } else {
                    bool enableCamera = !widget.liveStreamManager.roomManager.isScreenShareLive();
                    popupWidget(
                        CoGuestTypeSelectPanelWidget(
                          liveStreamManager: widget.liveStreamManager,
                          seatIndex: seatInfo.index,
                          enableCamera: enableCamera,
                        ),
                        context: context);
                  }
                  return;
                }
                final isSelf = TUIRoomEngine.getSelfInfo().userId == seatInfo.userInfo.userID;
                final user = LiveUserInfo(
                    userID: seatInfo.userInfo.userID,
                    userName: seatInfo.userInfo.userName,
                    avatarURL: seatInfo.userInfo.avatarURL);
                if (isSelf) {
                  _audienceUserManagementPanelHandler = popupWidget(
                      AudienceUserManagementPanelWidget(
                        user: user,
                        liveStreamManager: widget.liveStreamManager,
                        closeCallback: () {
                          _audienceUserManagementPanelHandler?.close();
                        },
                      ),
                      context: context);
                } else {
                  _audienceUserInfoPanelHandler = popupWidget(
                      AudienceUserInfoPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
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
    final isFloatWindowMode = widget.liveStreamManager.floatWindowState.isFloatWindowMode;
    return (context, seatInfo, viewLayer) {
      if (seatInfo.userInfo.userID.isEmpty) {
        if (viewLayer == ViewLayer.background) {
          return AudienceEmptySeatWidget(seatInfo: seatInfo, liveStreamManager: widget.liveStreamManager);
        }
        return Container();
      }
      if (viewLayer == ViewLayer.background) {
        return CoGuestBackgroundWidget(seatInfo: seatInfo, isFloatWindowMode: isFloatWindowMode);
      } else {
        return CoGuestForegroundWidget(
          seatInfo: seatInfo,
          isFloatWindowMode: isFloatWindowMode,
          onTap: () {
            final isSelf = TUIRoomEngine.getSelfInfo().userId == seatInfo.userInfo.userID;
            final user = LiveUserInfo(
                userID: seatInfo.userInfo.userID,
                userName: seatInfo.userInfo.userName,
                avatarURL: seatInfo.userInfo.avatarURL);
            if (isSelf) {
              _audienceUserManagementPanelHandler = popupWidget(
                  AudienceUserManagementPanelWidget(
                    user: user,
                    liveStreamManager: widget.liveStreamManager,
                    closeCallback: () {
                      _audienceUserManagementPanelHandler?.close();
                    },
                  ),
                  context: context);
            } else {
              _audienceUserInfoPanelHandler = popupWidget(
                  AudienceUserInfoPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
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
          if (LiveListStore.shared.liveState.currentLive.value.liveID.isEmpty) {
            return const SizedBox.shrink();
          }
          return BackgroundImageWidget(backgroundURL: LiveListStore.shared.liveState.currentLive.value.backgroundURL);
        });
  }

  @override
  void dispose() {
    LiveKitLogger.info("AudienceWidget dispose");
    _dispose();
    super.dispose();
  }
}

extension on _AudienceWidgetState {
  void _init() {
    _liveListListener = LiveListListener(
      onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
        _closeAllDialog();
      },
      onKickedOutOfLive: (String liveID, LiveKickedOutReason reason, String message) {
        _handleKickedOut();
      },
    );
    LiveListStore.shared.addLiveListListener(_liveListListener);
    // Defer _joinLiveStream to avoid setState() during build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _joinLiveStream();
    });
    _addLiveStatusListener();
    _addCoGuestStatusListener();
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_isFloatWindowModeListener);
    _liveSeatListener = LiveSeatListener(onLocalCameraClosedByAdmin: () {
      widget.liveStreamManager.mediaManager.closeLocalCamera();
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
    LiveSeatStore.create(widget.roomId).addLiveSeatEventListener(_liveSeatListener);
  }

  void _dispose() {
    widget.onDispose?.call();
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    _closeAllDialog();
    _removeCoGuestStatusListener();
    _removeLiveStatusListener();
    // Reset liveStatus to prevent stale state when PageResources are reused.
    // Without this, a cached page returning to current index would see
    // liveStatus == playing and render LiveCoreWidget before joinLive completes.
    widget.liveStreamManager.roomState.liveStatus.value = LiveStatus.none;
    // Defer _leaveLiveStream to avoid setState() when widget tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leaveLiveStream();
    });
    _resetControllers();
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_isFloatWindowModeListener);
    LiveSeatStore.create(widget.roomId).removeLiveSeatEventListener(_liveSeatListener);
  }

  void _handleKickedOut() {
    makeToast(context, LiveKitLocalizations.of(context)!.common_kicked_out_of_room_by_owner);
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

  void _joinLiveStream() async {
    KeyMetrics.reportKeyMetrics(KeyMetrics.kLiveIntegrationSuccessful);
    widget.onJoinLiveStateChanged?.call(true);
    try {
      LiveListStore liveListStore = LiveListStore.shared;
      var result = await liveListStore.joinLive(widget.roomId);
      widget.onJoinLiveStateChanged?.call(false);
      if (!mounted) return;
      if (result.errorCode != TUIError.success.rawValue) {
        makeToast(context, ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '',
            type: ToastType.error, useRootOverlay: true);
        _closePage();
        return;
      }
      widget.liveStreamManager.onJoinLive(result.liveInfo);
    } catch (e) {
      if (!mounted) return;
      widget.onJoinLiveStateChanged?.call(false);
      LiveKitLogger.error('AudienceWidget _joinLiveStream error: $e');
      makeToast(context, ErrorHandler.convertToErrorMessage(-1, e.toString()) ?? '',
          type: ToastType.error, useRootOverlay: true);
      _closePage();
    }
  }

  void _leaveLiveStream() {
    LiveListStore liveListStore = LiveListStore.shared;
    if (liveListStore.liveState.currentLive.value.liveID.isEmpty) {
      LiveKitLogger.warning('AudienceWidget _leaveLiveStream currentLive is Empty');
      return;
    }
    liveListStore.leaveLive();
  }

  void _addLiveStatusListener() {
    widget.liveStreamManager.roomState.liveStatus.addListener(_liveStatusListener);
  }

  void _removeLiveStatusListener() {
    widget.liveStreamManager.roomState.liveStatus.removeListener(_liveStatusListener);
  }

  void _resetControllers() {
    BarrageDisplayController.resetState();
  }

  void _onLiveStatusChange() {
    final status = widget.liveStreamManager.roomState.liveStatus.value;
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
    widget.liveStreamManager.coGuestState.coGuestStatus.addListener(_coGuestStatusListener);
  }

  void _removeCoGuestStatusListener() {
    widget.liveStreamManager.coGuestState.coGuestStatus.removeListener(_coGuestStatusListener);
    widget.onCoGuestStateChanged?.call(false);
  }

  void _onCoGuestStatusChanged() {
    final status = widget.liveStreamManager.coGuestState.coGuestStatus.value;
    final shouldDisableScroll = status == CoGuestStatus.applying || status == CoGuestStatus.linking;
    widget.onCoGuestStateChanged?.call(shouldDisableScroll);
  }

  void _isFloatWindowModeChanged() {
    if (widget.liveStreamManager.floatWindowState.isFloatWindowMode.value) {
      _closeAllDialog();
    }
  }
}
