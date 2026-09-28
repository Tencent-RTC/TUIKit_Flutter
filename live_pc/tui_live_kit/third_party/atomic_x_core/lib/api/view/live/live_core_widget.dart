// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveCoreView @ AtomicXCore
// Function: Live core view component, providing view container for live streaming push and playback, supporting multi-person co-guest, PK and other features.

// <docgen-keep-start>
// import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:atomic_x_core/impl/view/live/live_stream_widget_container.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/impl/live/live_list_store_impl.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:atomic_x_core/impl/view/live/media_mixing/media_mixing_canvas.dart';
part 'package:atomic_x_core/impl/view/live/live_core_widget_impl.dart';
// <docgen-keep-end>

/// Core view type.
enum CoreViewType {
  /// Play view.
  playView,

  /// Push view.
  pushView,
}

/// View layer.
enum ViewLayer {
  /// Foreground layer.
  foreground,

  /// Background layer.
  background,
}

typedef CoGuestWidgetBuilder = Widget Function(BuildContext context, SeatInfo seatInfo, ViewLayer viewPlayer);
typedef CoHostWidgetBuilder = Widget Function(BuildContext context, SeatInfo seatInfo, ViewLayer viewPlayer);
typedef BattleWidgetBuilder = Widget Function(BuildContext context, SeatInfo seatInfo);
typedef BattleContainerWidgetBuilder = Widget Function(BuildContext context);

typedef OnPlaying = void Function(String userId);
typedef OnLoading = void Function(String userId);
typedef OnPlayError = void Function(String userId, int code, String message);

class PlayCallback {
  OnPlaying onPlaying = (String userId) {};
  OnLoading onLoading = (String userId) {};
  OnPlayError onPlayError = (String userId, int code, String message) {};

  PlayCallback({
    required this.onPlaying,
    required this.onLoading,
    required this.onPlayError,
  });
}

/// Live core widget controller protocol.
abstract class LiveCoreController {
  /// Create LiveCoreController.
  /// - [type] : Core view type.
  static LiveCoreController create(CoreViewType type) {
    return LiveCoreControllerImpl(type);
  }

  /// Set live ID. Should set live ID before using other interfaces.
  /// - [liveID] : Live ID.
  void setLiveID(String liveID);

  /// Preview outside room.
  /// - [liveID] : Live ID.
  /// - [isMuteAudio] : Whether to mute audio.
  /// - [playCallback] : Play callback.
  void startPreviewLiveStream(String liveID, bool isMuteAudio, PlayCallback? playCallback);

  /// Stop preview outside room.
  /// - [liveID] : Live ID.
  void stopPreviewLiveStream(String liveID);

  /// Call experimental API.
  static void callExperimentalAPI(String jsonStr) {
    LiveCoreControllerImpl.callExperimentalAPI(jsonStr);
  }
}

/// Video view adapter protocol.
class VideoWidgetBuilder {
  /// Create co-guest view.
  /// - [seatInfo] : Co-guest user seat information.
  /// - [viewLayer] : View layer, foreground or background.
  CoGuestWidgetBuilder coGuestWidgetBuilder = (BuildContext context, SeatInfo seatInfo, ViewLayer viewPlayer) {
    return Container();
  };

  /// Create cross-room co-host view.
  /// - [seatInfo] : Cross-room co-host user seat information.
  /// - [viewLayer] : View layer, foreground or background.
  CoHostWidgetBuilder coHostWidgetBuilder = (BuildContext context, SeatInfo seatInfo, ViewLayer viewPlayer) {
    return Container();
  };

  /// Create PK view.
  /// - [seatInfo] : PK user seat information.
  BattleWidgetBuilder battleWidgetBuilder = (BuildContext context, SeatInfo seatInfo) {
    return Container();
  };

  /// Create PK container view.
  BattleContainerWidgetBuilder battleContainerWidgetBuilder = (BuildContext context) {
    return Container();
  };

  VideoWidgetBuilder({
    CoGuestWidgetBuilder? coGuestWidgetBuilder,
    CoHostWidgetBuilder? coHostWidgetBuilder,
    BattleWidgetBuilder? battleWidgetBuilder,
    BattleContainerWidgetBuilder? battleContainerWidgetBuilder,
  }) {
    if (coGuestWidgetBuilder != null) this.coGuestWidgetBuilder = coGuestWidgetBuilder;
    if (coHostWidgetBuilder != null) this.coHostWidgetBuilder = coHostWidgetBuilder;
    if (battleWidgetBuilder != null) this.battleWidgetBuilder = battleWidgetBuilder;
    if (battleContainerWidgetBuilder != null) this.battleContainerWidgetBuilder = battleContainerWidgetBuilder;
  }
}

/// Live core view component, providing view container for live streaming push and playback, supporting multi-person co-guest, PK and other features.
///
/// `LiveCoreWidget` provides view container for live streaming push and playback, supporting multi-person co-guest, PK and other features.
/// Through this component, video rendering and interaction in live rooms can be implemented.
///
/// ### Key Features
///
/// - **Video Rendering**: Provides view container for live streaming push and playback
/// - **Co-guest Support**: Supports multi-person co-guest feature
/// - **PK Support**: Supports anchor PK feature
/// - **Preview Outside Room**: Supports previewing live stream before entering the room
/// - **Desktop Mixing**: On desktop platforms (macOS / Windows), renders the media mixing
///   canvas driven by MediaMixingStore instead of the seat container, with tap / drag /
///   resize editing layered on top of the mixed preview.
///
/// > **Important**: Before using, you need to call [LiveCoreController.setLiveID] to set the live room ID first.
///
class LiveCoreWidget extends StatefulWidget {
  final LiveCoreController controller;
  final VideoWidgetBuilder? videoWidgetBuilder;

  const LiveCoreWidget({super.key, required this.controller, this.videoWidgetBuilder});

  @override
  State<StatefulWidget> createState() => _LiveCoreWidgetState();
}
