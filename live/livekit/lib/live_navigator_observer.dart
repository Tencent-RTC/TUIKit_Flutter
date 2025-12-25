import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/index.dart';
import 'package:tencent_live_uikit/voice_room/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

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

  TUILiveKitNavigatorObserver._internal() {
    LiveKitLogger.info('TUILiveKitNavigatorObserver Init');
    Boot.instance;
  }

  BuildContext getContext() {
    return navigator!.context;
  }

  void enterLiveRoomPage(LiveInfo liveInfo) {
    if (isRepeatClick) {
      return;
    }
    isRepeatClick = true;
    GlobalFloatWindowManager floatWindowManager = GlobalFloatWindowManager.instance;
    GlobalFloatWindowState state = floatWindowManager.state;
    if (floatWindowManager.isFloating()) {
      if (state.ownerId.value == TUIRoomEngine
          .getSelfInfo()
          .userId) {
        isRepeatClick = false;
        makeToast(msg: LiveKitLocalizations.of(Global.appContext())!.livelist_exit_float_window_tip);
        return;
      }
      if (state.roomId.value == liveInfo.liveID) {
        isRepeatClick = false;
        floatWindowManager.switchToFullScreenMode();
        return;
      } else {
        floatWindowManager.overlayManager.closeOverlay();
      }
    }
    bool isOwner = liveInfo.liveOwner.userID == TUIRoomEngine
        .getSelfInfo()
        .userId;
    if (isOwner) {
      Navigator.push(
          getContext(),
          MaterialPageRoute(
            settings: const RouteSettings(name: routeLiveRoomAudience),
            builder: (context) {
              if (floatWindowManager.isEnableFloatWindowFeature()) {
                return TUILiveRoomAnchorOverlay(roomId: liveInfo.liveID, needPrepare: false);
              } else {
                return TUILiveRoomAnchorWidget(roomId: liveInfo.liveID, needPrepare: false);
              }
            },
          ));
    } else {
      Navigator.push(
          getContext(),
          MaterialPageRoute(
            settings: const RouteSettings(name: routeLiveRoomAudience),
            builder: (context) {
              if (floatWindowManager.isEnableFloatWindowFeature()) {
                return TUILiveRoomAudienceOverlay(roomId: liveInfo.liveID);
              } else {
                return TUILiveRoomAudienceWidget(roomId: liveInfo.liveID);
              }
            },
          ));
    }
    isRepeatClick = false;
  }

  void backToLiveRoomAudiencePage() {
    Navigator.popUntil(getContext(), (route) {
      if (route.settings.name == routeLiveRoomAudience) {
        return true;
      }
      return false;
    });
  }

  void enterVoiceRoomPage(LiveInfo liveInfo) {
    if (isRepeatClick) {
      return;
    }
    isRepeatClick = true;
    GlobalFloatWindowManager floatWindowManager = GlobalFloatWindowManager.instance;
    GlobalFloatWindowState state = floatWindowManager.state;
    if (floatWindowManager.isFloating()) {
      if (state.ownerId.value == TUIRoomEngine
          .getSelfInfo()
          .userId) {
        isRepeatClick = false;
        makeToast(msg: LiveKitLocalizations.of(Global.appContext())!.livelist_exit_float_window_tip);
        return;
      }
      if (state.roomId.value == liveInfo.liveID) {
        isRepeatClick = false;
        floatWindowManager.switchToFullScreenMode();
        return;
      } else {
        floatWindowManager.overlayManager.closeOverlay();
      }
    }
    Navigator.push(
        getContext(),
        MaterialPageRoute(
          settings: const RouteSettings(name: routeVoiceRoomAudience),
          builder: (context) {
            bool isOwner = liveInfo.liveOwner.userID == TUIRoomEngine
                .getSelfInfo()
                .userId;
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
  }

  void backToVoiceRoomAudiencePage() {
    Navigator.popUntil(getContext(), (route) {
      if (route.settings.name == routeVoiceRoomAudience) {
        return true;
      }
      return false;
    });
  }
}
