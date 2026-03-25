import 'dart:async';

import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/live_navigator_observer.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/audience_empty_seat_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/audience_living_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/audience_user_info_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/audience_user_management_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/co_guest_type_select_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/decorations/index.dart';
import 'package:tencent_live_uikit/live_stream/features/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';

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

  const AudienceWidget(
      {super.key,
      required this.roomId,
      required this.liveCoreController,
      required this.liveStreamManager,
      this.onTapEnterFloatWindowInApp});

  @override
  State<AudienceWidget> createState() => _AudienceWidgetState();
}

class _AudienceWidgetState extends State<AudienceWidget> {
  late final VoidCallback _liveStatusListener = _onLiveStatusChange;
  late final VoidCallback _audioLockedListener = _onAudioLockedStatusChanged;
  late final VoidCallback _videoLockedListener = _onVideoLockedStatusChanged;
  late final StreamSubscription<void> _kickedOutSubscription;
  BottomSheetHandler? _audienceUserInfoPanelHandler;
  BottomSheetHandler? _audienceUserManagementPanelHandler;

  late final LiveListListener _liveListListener;

  @override
  void initState() {
    LiveKitLogger.info("AudienceWidget init");
    super.initState();
    _init();
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
        ),
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
        double height = isPortrait ? 9 / 16.0 * screenWidth : screenHeight;
        double top = isFloating ? (screenHeight - height) / 2 : (isPortrait ? 120.height : 0);
        return Container(
          color: Colors.black,
          margin: EdgeInsets.only(top: top),
          width: screenWidth,
          height: height,
          child: LiveCoreWidget(controller: widget.liveCoreController),
        );
      });
    } else {
      return LiveCoreWidget(
        controller: widget.liveCoreController,
        videoWidgetBuilder: VideoWidgetBuilder(
            coGuestWidgetBuilder: _createCoGuestWidgetBuilder(),
            coHostWidgetBuilder: (context, seatInfo, viewLayer) {
              if (viewLayer == ViewLayer.background) {
                return CoHostBackgroundWidget(
                    seatInfo: seatInfo, isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
              } else {
                return CoHostForegroundWidget(
                    seatInfo: seatInfo, isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
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
      );
    }
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
                      AudienceUserManagementPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
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
    return (context, seatInfo, viewLayer) {
      if (seatInfo.userInfo.userID.isEmpty) {
        if (viewLayer == ViewLayer.background) {
          return AudienceEmptySeatWidget(seatInfo: seatInfo, liveStreamManager: widget.liveStreamManager);
        }
        return Container();
      }
      if (viewLayer == ViewLayer.background) {
        return CoGuestBackgroundWidget(
            seatInfo: seatInfo, isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode);
      } else {
        return GestureDetector(
          onTap: () {
            final isSelf = TUIRoomEngine.getSelfInfo().userId == seatInfo.userInfo.userID;
            final user = LiveUserInfo(
                userID: seatInfo.userInfo.userID,
                userName: seatInfo.userInfo.userName,
                avatarURL: seatInfo.userInfo.avatarURL);
            if (!isSelf) {
              _audienceUserInfoPanelHandler = popupWidget(
                  AudienceUserInfoPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
                  context: context,
                  backgroundColor: LiveColors.designStandardTransparent);
            } else {
              _audienceUserManagementPanelHandler = popupWidget(
                  AudienceUserManagementPanelWidget(user: user, liveStreamManager: widget.liveStreamManager),
                  context: context);
            }
          },
          child: Container(
            color: Colors.transparent,
            child: CoGuestForegroundWidget(
                seatInfo: seatInfo, isFloatWindowMode: widget.liveStreamManager.floatWindowState.isFloatWindowMode),
          ),
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
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _closeAllDialog();
    });
    LiveListStore.shared.addLiveListListener(_liveListListener);
    _kickedOutSubscription = widget.liveStreamManager.kickedOutSubject.stream.listen((_) => _handleKickedOut());
    _joinLiveStream();
    _addLiveStatusListener();
    _addMediaLockedListener();
  }

  void _dispose() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    _closeAllDialog();
    _kickedOutSubscription.cancel();
    _removeMediaLockedListener();
    _removeLiveStatusListener();
    _leaveLiveStream();
    _resetControllers();
  }

  void _handleKickedOut() {
    makeToast(msg: LiveKitLocalizations.of(Global.appContext())!.common_kicked_out_of_room_by_owner);
    _closePage();
  }

  void _closeAllDialog() {
    _audienceUserInfoPanelHandler?.close();
    _audienceUserManagementPanelHandler?.close();
  }

  void _closePage() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _joinLiveStream() async {
    LiveListStore liveListStore = LiveListStore.shared;
    var result = await liveListStore.joinLive(widget.roomId);
    if (result.errorCode != TUIError.success.rawValue) {
      makeToast(msg: ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      _closePage();
      return;
    }
    widget.liveStreamManager.onJoinLive(result.liveInfo);
    widget.liveStreamManager.resumeByAudience();
  }

  void _leaveLiveStream() {
    LiveListStore liveListStore = LiveListStore.shared;
    liveListStore.leaveLive();
  }

  void _addLiveStatusListener() {
    widget.liveStreamManager.roomState.liveStatus.addListener(_liveStatusListener);
  }

  void _removeLiveStatusListener() {
    widget.liveStreamManager.roomState.liveStatus.removeListener(_liveStatusListener);
  }

  void _addMediaLockedListener() {
    widget.liveStreamManager.mediaState.isAudioLocked.addListener(_audioLockedListener);
    widget.liveStreamManager.mediaState.isVideoLocked.addListener(_videoLockedListener);
  }

  void _removeMediaLockedListener() {
    widget.liveStreamManager.mediaState.isAudioLocked.removeListener(_audioLockedListener);
    widget.liveStreamManager.mediaState.isVideoLocked.removeListener(_videoLockedListener);
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

  void _onAudioLockedStatusChanged() {
    final isAudioLocked = widget.liveStreamManager.mediaState.isAudioLocked.value;
    final toastMessage = isAudioLocked
        ? LiveKitLocalizations.of(context)!.common_mute_audio_by_master
        : LiveKitLocalizations.of(context)!.common_un_mute_audio_by_master;
    makeToast(msg: toastMessage);
  }

  void _onVideoLockedStatusChanged() {
    final isVideoLocked = widget.liveStreamManager.mediaState.isVideoLocked.value;
    final toastMessage = isVideoLocked
        ? LiveKitLocalizations.of(context)!.common_mute_video_by_owner
        : LiveKitLocalizations.of(context)!.common_un_mute_video_by_master;
    makeToast(msg: toastMessage);
  }
}
