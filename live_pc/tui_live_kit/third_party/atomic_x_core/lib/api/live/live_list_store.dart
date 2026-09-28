// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveListStore @ AtomicXCore
// Function: Live list related interfaces, managing live room creation, joining, leaving and other operations.

// <docgen-keep-start>
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:atomic_x_core/impl/live/live_list_store_define.dart';
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
// <docgen-keep-end>

/// Live state.
enum LiveStatus {
  /// Scheduled.
  scheduled(1),

  /// Running.
  running(2),

  /// Suspended.
  suspended(3);

  final int value;

  const LiveStatus(this.value);
}

/// Take seat mode.
enum TakeSeatMode {
  /// Free to take seat.
  free(1),

  /// Apply to take seat.
  apply(2);

  final int value;

  const TakeSeatMode(this.value);
}

/// Seat layout template for simplifying seat configuration when creating a live room.
sealed class SeatLayoutTemplate {
  const SeatLayoutTemplate();
}

/// Portrait dynamic 9-grid layout for video live streaming.
class VideoDynamicGrid9Seats extends SeatLayoutTemplate {
  const VideoDynamicGrid9Seats();
}

/// Portrait dynamic 1v6 floating layout for video live streaming.
class VideoDynamicFloat7Seats extends SeatLayoutTemplate {
  const VideoDynamicFloat7Seats();
}

/// Portrait left focus 9-grid layout for video live streaming.
class VideoLeftFocus9Seats extends SeatLayoutTemplate {
  const VideoLeftFocus9Seats();
}

/// Portrait uniform 9-grid layout for video live streaming.
class VideoUniformGrid9Seats extends SeatLayoutTemplate {
  const VideoUniformGrid9Seats();
}

/// Portrait static 9-grid layout for video live streaming.
class VideoFixedGrid9Seats extends SeatLayoutTemplate {
  const VideoFixedGrid9Seats();
}

/// Portrait static 1v6 floating layout for video live streaming.
class VideoFixedFloat7Seats extends SeatLayoutTemplate {
  const VideoFixedFloat7Seats();
}

/// Landscape layout with 1 video seat and 3 audio seats for video live streaming.
class VideoLandscape4Seats extends SeatLayoutTemplate {
  const VideoLandscape4Seats();
}

/// Landscape layout with 1 video seat and 9 audio seats for video live streaming.
class VideoLandscape10Seats extends SeatLayoutTemplate {
  const VideoLandscape10Seats();
}

/// Portrait layout with 1 video seat and 9 audio seats for video live streaming.
class VideoPortrait10Seats extends SeatLayoutTemplate {
  const VideoPortrait10Seats();
}

/// Audio KTV layout for karaoke scenes with configurable seat count.
class Karaoke extends SeatLayoutTemplate {
  final int seatCount;
  const Karaoke(this.seatCount);
}

/// Audio salon layout for voice chat scenes with configurable seat count.
class AudioSalon extends SeatLayoutTemplate {
  final int seatCount;
  const AudioSalon(this.seatCount);
}

/// Live ended reason.
enum LiveEndedReason {
  /// Ended by host.
  endedByHost(1),

  /// Ended by server.
  endedByServer(2);

  final int value;

  const LiveEndedReason(this.value);
}

/// Kicked out of live room reason.
enum LiveKickedOutReason {
  /// Kicked out by admin.
  byAdmin(0),

  /// Logged on other device.
  byLoggedOnOtherDevice(1),

  /// Kicked out by server.
  byServer(2),

  /// Network disconnected.
  forNetworkDisconnected(3),

  /// Join room status invalid during offline.
  forJoinRoomStatusInvalidDuringOffline(4),

  /// Count of joined rooms exceed limit.
  forCountOfJoinedRoomsExceedLimit(5);

  final int value;

  const LiveKickedOutReason(this.value);
}

/// Live information.
///
/// Contains complete property information of the live room, including live ID, name, cover, owner info, etc.
class LiveInfo {
  /// Live ID.
  String liveID;

  /// Live name.
  String liveName;

  /// Live status.
  LiveStatus status;

  /// Live notice.
  String notice;

  /// Whether message is disabled.
  bool isMessageDisable;

  /// Whether publicly visible.
  bool isPublicVisible;

  /// Whether to keep owner on seat.
  bool keepOwnerOnSeat;

  /// Take seat mode.
  TakeSeatMode seatMode;

  /// Seat layout template for simplifying seat configuration.
  SeatLayoutTemplate seatTemplate;

  /// Cover URL.
  String coverURL;

  /// Background URL.
  String backgroundURL;

  /// Category list.
  List<int> categoryList;

  /// Activity status.
  int activityStatus;

  /// Live owner info.
  LiveUserInfo liveOwner;

  /// Create time.
  int createTime;

  /// Total viewer count.
  int totalViewerCount;

  /// Whether gift is enabled.
  bool isGiftEnabled;

  /// Metadata.
  Map<String, String> metaData;

  /// Whether seat is enabled.
  @Deprecated(
    'Deprecated since 3.7, use seatTemplate instead. This parameter will be automatically resolved internally.',
  )
  bool isSeatEnabled;

  /// Maximum seat count.
  @Deprecated(
    'Deprecated since 3.7, use seatTemplate instead. This parameter will be automatically resolved internally.',
  )
  int maxSeatCount;

  /// Seat layout template ID.
  @Deprecated(
    'Deprecated since 3.7, use seatTemplate instead. This parameter will be automatically resolved internally.',
  )
  int seatLayoutTemplateID;

  LiveInfo({
    this.liveID = '',
    this.liveName = '',
    this.status = LiveStatus.running,
    this.notice = '',
    this.isMessageDisable = false,
    this.isPublicVisible = true,
    bool? keepOwnerOnSeat,
    this.seatMode = TakeSeatMode.apply,
    this.seatTemplate = const VideoDynamicGrid9Seats(),
    this.coverURL = '',
    this.backgroundURL = '',
    List<int>? categoryList,
    this.activityStatus = 0,
    LiveUserInfo? liveOwner,
    this.createTime = 0,
    this.totalViewerCount = 0,
    this.isGiftEnabled = true,
    Map<String, String>? metaData,
    bool? isSeatEnabled,
    int? maxSeatCount,
    int? seatLayoutTemplateID,
  })  : isSeatEnabled = LiveInfoExtension.getSeatConfiguration(seatTemplate).isSeatEnabled,
        maxSeatCount = (maxSeatCount == null || maxSeatCount == 0)
            ? (LiveInfoExtension.getSeatConfiguration(seatTemplate).maxSeatCount ?? -1)
            : maxSeatCount,
        seatLayoutTemplateID = (seatLayoutTemplateID == null || seatLayoutTemplateID == 600)
            ? LiveInfoExtension.getSeatConfiguration(seatTemplate).seatLayoutTemplateID
            : seatLayoutTemplateID,
        keepOwnerOnSeat =
            keepOwnerOnSeat ?? LiveInfoExtension.getSeatConfiguration(seatTemplate).keepOwnerOnSeat ?? false,
        categoryList = categoryList ?? [],
        liveOwner = liveOwner ?? LiveUserInfo(),
        metaData = metaData ?? {};
}

enum ModifyFlag {
  none(0),
  liveName(1 << 0),
  notice(1 << 1),
  isMessageDisable(1 << 2),
  isPublicVisible(1 << 5),
  seatMode(1 << 6),
  coverUrl(1 << 7),
  backgroundUrl(1 << 8),
  categoryList(1 << 9),
  activityStatus(1 << 10),

  /// @Deprecated since 4.2, use [seatTemplate] instead.
  seatLayoutTemplateId(1 << 11),
  seatTemplate(1 << 11);

  final int rawValue;

  const ModifyFlag(this.rawValue);
}

/// Live list state.
///
/// Contains live list, cursor and current live info.
abstract class LiveListState {
  /// Live list.
  ValueListenable<List<LiveInfo>> get liveList;

  /// Live list cursor.
  ValueListenable<String> get liveListCursor;

  /// Current live info.
  ValueListenable<LiveInfo> get currentLive;
}

/// Live list events.
///
///
class LiveListListener {
  /// Live ended event.
  /// - [liveID] : Live ID.
  /// - [reason] : Ended reason.
  /// - [message] : Message.
  void Function(String liveID, LiveEndedReason reason, String message)? onLiveEnded;

  /// Kicked out of live room event.
  /// - [liveID] : Live ID.
  /// - [reason] : Kicked out reason.
  /// - [message] : Message.
  void Function(String liveID, LiveKickedOutReason reason, String message)? onKickedOutOfLive;

  LiveListListener({this.onLiveEnded, this.onKickedOutOfLive});
}

/// Live statistics data.
///
/// Statistics data returned after a live stream ends, including viewers, gifts, likes, messages and duration.
class LiveStatisticsData {
  /// Total Views.
  int totalViewers = 0;

  /// Total gifts sent.
  int totalGiftsSent = 0;

  /// Total gift coins.
  int totalGiftCoins = 0;

  /// Total unique gift senders.
  int totalUniqueGiftSenders = 0;

  /// Total likes received.
  int totalLikesReceived = 0;

  /// Total messages.
  int totalMessageCount = 0;

  /// Live duration.
  int liveDuration = 0;
}

/// Live info completion handler for Dart.
///
/// Completion handler for live info operations in Dart, containing the result live info.
class LiveInfoCompletionHandler extends CompletionHandler {
  /// Live info returned on success.
  LiveInfo liveInfo = LiveInfo();
}

/// Stop live completion handler for Dart.
///
/// Completion handler for stop live operations in Dart, containing the live statistics data.
class StopLiveCompletionHandler extends CompletionHandler {
  /// Live statistics data returned on success.
  LiveStatisticsData statisticsData = LiveStatisticsData();
}

/// Metadata completion handler for Dart.
///
/// Completion handler for metadata operations in Dart, containing the metadata result.
class MetaDataCompletionHandler extends CompletionHandler {
  /// Metadata returned on success.
  Map<String, String> metaData = {};
}

/// Live list related interfaces, managing live room creation, joining, leaving and other operations.
///
/// `LiveListStore` Live room list management class for managing live room related business.
/// `LiveListStore` provides a complete set of live room management APIs, including starting live, joining live, leaving live, ending live and other functions.
/// Through this class, you can manage the lifecycle of live rooms. The host calls startLive/endLive to start and dismiss a live room, while the audience calls joinLive/leaveLive to join and leave a live room.
///
/// ### Key Features
///
/// - **Live List**：Get and manage live room list.
/// - **Start Live**：Host starts broadcasting. If the live room ID is new, a new live room will be created; if the live room ID already exists on the server, the host will join and start broadcasting.
/// - **Live Joining**：Join existing live rooms.
/// - **Live Management**：Update live info, end live and other operations.
/// - **Event Listening**：Listen for live ended, kicked out and other events.
///
/// > **Important**: Use the [LiveListStore.shared] singleton object to get the `LiveListStore` instance.
///
/// > **Note**: Live state updates are delivered through the [liveState] publisher. Subscribe to it to receive real-time updates of live data.
///
/// ### Live Management Operations Overview
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Get List | [fetchLiveList] | Get live room list |
/// | Get Info | [fetchLiveInfo] | Get specified live room info |
/// | Start Live | [startLive] | Host starts broadcasting. If the live room ID is new, a new live room will be created; if the live room ID already exists on the server, the host will join and start broadcasting |
/// | Join Live | [joinLive] | Audience joins an existing live room |
/// | Leave Live | [leaveLive] | Audience leaves the current live room |
/// | End Live | [endLive] | Host ends the current live and dismisses the room |
/// | Update Info | [updateLiveInfo] | Update live room info |
///
/// ## Topics
///
/// ### Getting Instance
/// - [LiveListStore.shared] : Singleton object.
///
/// ### Observing State and Events
/// - [liveState] : Live list state.
/// - [addLiveListListener]/[removeLiveListListener] : Live list event callbacks
///
/// ### Live List
/// - [fetchLiveList] : Get live list.
/// - [fetchLiveInfo] : Get live info.
///
/// ### Live Operations
/// - [startLive] : Start live (Host only).
/// - [joinLive] : Join live (Audience only).
/// - [leaveLive] : Leave live (Audience only).
/// - [endLive] : End live (Host only).
/// - [updateLiveInfo] : Update live info.
///
/// ### Metadata Operations
/// - [queryMetaData] : Query metadata.
/// - [updateLiveMetaData] : Update metadata.
///
/// ## See Also
///
/// - [LiveInfo]
/// - [LiveListState]
/// - [LiveListListener]
/// - [TakeSeatMode]
/// - [LiveEndedReason]
/// - [LiveKickedOutReason]
abstract class LiveListStore {
  /// Singleton object.
  static LiveListStore get shared => StoreFactory.shared.getStore<LiveListStore>();

  /// Live list state.
  LiveListState get liveState;

  /// Get live list
  ///
  /// - [cursor] : Cursor.
  /// - [count] : Count.
  Future<CompletionHandler> fetchLiveList({
    required String cursor,
    required int count,
  });

  /// Get live info
  ///
  /// - [liveID] : Live room ID.
  /// - [completion] : Completion callback.
  Future<LiveInfoCompletionHandler> fetchLiveInfo(String liveID);

  /// Start live (Host only)
  ///
  /// Host starts broadcasting. If the live room ID is new, a new live room will be created; if the live room ID already exists on the server, the host will join and start broadcasting.
  ///
  /// - [liveInfo] : Live info.
  Future<LiveInfoCompletionHandler> startLive(LiveInfo liveInfo);

  /// Join live (Audience only)
  ///
  /// Called by the audience to join an existing live room.
  ///
  /// - [liveID] : Live ID.
  Future<LiveInfoCompletionHandler> joinLive(String liveID);

  /// Leave live (Audience only)
  ///
  /// Called by the audience to leave the current live room.
  /// If the host only needs to leave the room without dismissing it, this API can also be called.
  ///
  Future<CompletionHandler> leaveLive();

  /// End live (Host only)
  ///
  /// Called by the host to end the current live and dismiss the room.
  ///
  Future<StopLiveCompletionHandler> endLive();

  /// Update live info
  ///
  /// - [liveInfo] : Live info.
  /// - [modifyFlag] : Modify flag.
  Future<CompletionHandler> updateLiveInfo({
    required LiveInfo liveInfo,
    required List<ModifyFlag> modifyFlagList,
  });

  /// Query metadata
  ///
  /// - [keys] : Key list.
  Future<MetaDataCompletionHandler> queryMetaData(List<String> keys);

  /// Update live metadata
  ///
  /// - [metaData] : Metadata.
  Future<CompletionHandler> updateLiveMetaData(Map<String, String> metaData);

  /// Call experimental API
  ///
  /// - [jsonMap] : JSON parameter map.
  /// - [callback] : Called with the error code, message and the JSON string returned by the engine when the invocation completes.
  Future<void> callExperimentalAPI(Map<String, dynamic> jsonMap, {ExperimentalAPICallback? callback});

  /// Subscribe to experimental event
  ///
  /// - [event] : Event name.
  /// - [callback] : Event callback delivering (roomID, jsonStr).
  ///
  /// Returns: Subscription token for unsubscribing.
  SubscriptionToken subscribeExperimentalEvent(String event, ExperimentalEventCallback callback);

  /// Unsubscribe from experimental event
  ///
  /// - [token] : Subscription token.
  void unsubscribeExperimentalEvent(SubscriptionToken token);

  /// Reset to default state
  void reset();

  /// Add live list event listener
  ///
  /// - [listener] : Listener.
  void addLiveListListener(LiveListListener listener);

  /// Remove live list event listener
  ///
  /// - [listener] : Listener.
  void removeLiveListListener(LiveListListener listener);
}
