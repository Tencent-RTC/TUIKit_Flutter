import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/index.dart';
import 'package:tencent_live_uikit/voice_room/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/toast.dart';

import '../../common/index.dart';
import 'component/float_window/global_float_window_state.dart';

class TUILiveKitNavigatorObserver extends RouteObserver {
  static final TUILiveKitNavigatorObserver instance = TUILiveKitNavigatorObserver._internal();

  factory TUILiveKitNavigatorObserver() {
    return instance;
  }

  static const String routeLiveRoomAudience = "route_live_room_audience";
  static const String routeVoiceRoomAudience = "route_voice_room_audience";

  static bool isRepeatClick = false;

  final ValueNotifier<String> enteringRoomID = ValueNotifier<String>('');
  late final VoidCallback _onCurrentLiveListener = _onCurrentLiveChanged;

  TUILiveKitNavigatorObserver._internal() {
    LiveKitLogger.info('TUILiveKitNavigatorObserver Init');
    Boot.instance;
    LiveListStore.shared.liveState.currentLive.addListener(_onCurrentLiveListener);
  }

  BuildContext getContext() {
    return navigator!.context;
  }

  Future<bool> enterLiveRoomPage(BuildContext context, LiveInfo liveInfo) async {
    LiveKitLogger.info('enterLiveRoomPage called, roomId: ${liveInfo.liveID}, isRepeatClick: $isRepeatClick');
    if (isRepeatClick) {
      LiveKitLogger.info('enterLiveRoomPage blocked by isRepeatClick');
      return false;
    }
    isRepeatClick = true;
    try {
      GlobalFloatWindowManager floatWindowManager = GlobalFloatWindowManager.instance;
      GlobalFloatWindowState state = floatWindowManager.state;
      if (floatWindowManager.isFloating()) {
        if (state.roomId.value == liveInfo.liveID) {
          floatWindowManager.switchToFullScreenMode();
          return false;
        } else {
          if (state.ownerId.value == TUIRoomEngine.getSelfInfo().userId) {
            makeToast(context, LiveKitLocalizations.of(Global.appContext())!.livelist_exit_float_window_tip,
                type: ToastType.warning);
            return false;
          }
          floatWindowManager.overlayManager.closeOverlay();
        }
      }
      bool isOwner = liveInfo.liveOwner.userID == TUIRoomEngine.getSelfInfo().userId;
      if (isOwner) {
        try {
          final result = await LiveListStore.shared.fetchLiveInfo(liveInfo.liveID);
          if (result.errorCode == TUIError.success.value()) {
            liveInfo.keepOwnerOnSeat = result.liveInfo.keepOwnerOnSeat;
          }
        } on Exception catch (e) {
          LiveKitLogger.error(e.toString());
        }
        Navigator.push(
            getContext(),
            MaterialPageRoute(
              settings: const RouteSettings(name: routeLiveRoomAudience),
              builder: (context) {
                if (floatWindowManager.isEnableFloatWindowFeature()) {
                  return TUILiveRoomAnchorOverlay(roomId: liveInfo.liveID, liveInfo: liveInfo, needPrepare: false);
                } else {
                  return TUILiveRoomAnchorWidget(roomId: liveInfo.liveID, liveInfo: liveInfo, needPrepare: false);
                }
              },
            ));
        return true;
      } else {
        enteringRoomID.value = liveInfo.liveID;
        Navigator.push(
            getContext(),
            MaterialPageRoute(
              settings: const RouteSettings(name: routeLiveRoomAudience),
              builder: (context) {
                if (floatWindowManager.isEnableFloatWindowFeature()) {
                  return TUILiveRoomAudienceOverlay(roomId: liveInfo.liveID, liveInfo: liveInfo);
                } else {
                  return TUILiveRoomAudienceWidget(roomId: liveInfo.liveID, liveInfo: liveInfo);
                }
              },
            ));
      }
      return true;
    } finally {
      isRepeatClick = false;
    }
  }

  void backToLiveRoomAudiencePage() {
    Navigator.popUntil(getContext(), (route) {
      if (route.settings.name == routeLiveRoomAudience) {
        return true;
      }
      return false;
    });
  }

  Future<bool> enterVoiceRoomPage(BuildContext context, LiveInfo liveInfo) async {
    if (isRepeatClick) {
      return false;
    }
    isRepeatClick = true;
    GlobalFloatWindowManager floatWindowManager = GlobalFloatWindowManager.instance;
    GlobalFloatWindowState state = floatWindowManager.state;
    if (floatWindowManager.isFloating()) {
      if (state.roomId.value == liveInfo.liveID) {
        isRepeatClick = false;
        floatWindowManager.switchToFullScreenMode();
        return false;
      } else {
        if (state.ownerId.value == TUIRoomEngine.getSelfInfo().userId) {
          isRepeatClick = false;
          makeToast(context, LiveKitLocalizations.of(Global.appContext())!.livelist_exit_float_window_tip,
              type: ToastType.warning);
          return false;
        }
        floatWindowManager.overlayManager.closeOverlay();
      }
    }
    enteringRoomID.value = liveInfo.liveID;
    Navigator.push(
        getContext(),
        MaterialPageRoute(
          settings: const RouteSettings(name: routeVoiceRoomAudience),
          builder: (context) {
            bool isOwner = liveInfo.liveOwner.userID == TUIRoomEngine.getSelfInfo().userId;
            if (floatWindowManager.isEnableFloatWindowFeature()) {
              return TUIVoiceRoomOverlay(
                  roomId: liveInfo.liveID, behavior: isOwner ? RoomBehavior.autoCreate : RoomBehavior.join);
            } else {
              return TUIVoiceRoomWidget(
                  roomId: liveInfo.liveID, behavior: isOwner ? RoomBehavior.autoCreate : RoomBehavior.join);
            }
          },
        ));
    isRepeatClick = false;
    return true;
  }

  void backToVoiceRoomAudiencePage() {
    Navigator.popUntil(getContext(), (route) {
      if (route.settings.name == routeVoiceRoomAudience) {
        return true;
      }
      return false;
    });
  }

  void _onCurrentLiveChanged() {
    final liveInfo = LiveListStore.shared.liveState.currentLive.value;
    if (liveInfo.liveID.isNotEmpty) {
      LiveKitLogger.info("currentLive is ${liveInfo.liveID}, clear enteringRoomID(${enteringRoomID.value})");
      enteringRoomID.value = "";
    }
  }
}
