// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   RoomStore @ AtomicXCore
// Function: Room management related interfaces, managing room creation, joining, leaving, scheduling and other operations.

// <docgen-keep-start>
import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
// <docgen-keep-end>

/// Room type.
enum RoomType {
  /// Standard room.
  standard(1),

  /// Webinar room.
  webinar(2);

  final int value;
  const RoomType(this.value);
}

/// Room status.
enum RoomStatus {
  /// Scheduled.
  scheduled(1),

  /// Running.
  running(2);

  final int value;
  const RoomStatus(this.value);
}

/// Room call status.
enum RoomCallStatus {
  /// No call.
  none(0),

  /// Calling.
  calling(1),

  /// Call timeout.
  timeout(2),

  /// Call rejected.
  rejected(3);

  final int value;
  const RoomCallStatus(this.value);
}

/// Call user to room result.
enum RoomCallResult {
  /// Call success.
  success(0),

  /// User already in calling.
  alreadyInCalling(1),

  /// User already in room.
  alreadyInRoom(2);

  final int value;
  const RoomCallResult(this.value);
}

/// Call rejection reason.
enum CallRejectionReason {
  /// User actively rejected.
  rejected(0),

  /// User in another room.
  inOtherRoom(1);

  final int value;
  const CallRejectionReason(this.value);
}

/// Recording status.
enum RecordingStatus {
  /// Not recording.
  none(0),

  /// Recording in progress.
  recording(1);

  final int value;
  const RecordingStatus(this.value);
}

/// Recording stop reason.
enum RecordingStopReason {
  /// Manually stopped by user.
  stoppedByUser(0),

  /// The recording bot has left the room.
  recorderLeftRoom(1);

  final int value;
  const RecordingStopReason(this.value);
}

/// Room user info.
///
/// Represents basic information of a user in the room.
class RoomUser {
  /// User ID.
  String userID;

  /// User name.
  String userName;

  /// User avatar URL.
  String avatarURL;
  RoomUser({
    this.userID = '',
    this.userName = '',
    this.avatarURL = '',
  });
}

/// Recording info.
///
/// Represents recording state of the current room.
class RecordingInfo {
  /// Recording status.
  RecordingStatus status;

  /// User who started the recording.
  RoomUser operatorUser;

  /// Recording start timestamp, in milliseconds.
  int startTime;
  RecordingInfo({
    this.status = RecordingStatus.none,
    RoomUser? operatorUser,
    this.startTime = 0,
  }) : operatorUser = operatorUser ?? RoomUser();
}

/// Room info.
///
/// Represents complete room information, including basic info and configuration options.
///
/// ### Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [roomID] | `String` | Room ID |
/// | [roomName] | `String` | Room name |
/// | [roomOwner] | `RoomUser` | Room owner |
/// | [participantCount] | `int` | Participant count |
/// | [roomStatus] | `RoomStatus` | Room status |
class RoomInfo {
  /// Room ID.
  String roomID;

  /// Room name.
  String roomName;

  /// Room owner.
  RoomUser roomOwner;

  /// Room type.
  RoomType roomType;

  /// Participant count.
  int participantCount;

  /// Audience count (for webinar room).
  int audienceCount;

  /// Create time, in milliseconds.
  int createTime;

  /// Room status.
  RoomStatus roomStatus;

  /// Scheduled start time, in seconds.
  int scheduledStartTime;

  /// Scheduled end time, in seconds.
  int scheduledEndTime;

  /// Reminder seconds before start.
  int startReminderInSeconds;

  /// Scheduled attendees list.
  List<RoomUser> scheduleAttendees;

  /// Room password.
  String? password;

  /// Whether all microphones are disabled.
  bool isAllMicrophoneDisabled;

  /// Whether all cameras are disabled.
  bool isAllCameraDisabled;

  /// Whether all messages are disabled.
  bool isAllMessageDisabled;

  /// Whether all screen sharing is disabled.
  bool isAllScreenShareDisabled;

  /// Recording info.
  RecordingInfo recordingInfo;
  RoomInfo({
    this.roomID = '',
    this.roomName = '',
    RoomUser? roomOwner,
    this.roomType = RoomType.standard,
    this.participantCount = 0,
    this.audienceCount = 0,
    this.createTime = 0,
    this.roomStatus = RoomStatus.scheduled,
    this.scheduledStartTime = 0,
    this.scheduledEndTime = 0,
    this.startReminderInSeconds = 0,
    List<RoomUser>? scheduleAttendees,
    this.password,
    this.isAllMicrophoneDisabled = false,
    this.isAllCameraDisabled = false,
    this.isAllMessageDisabled = false,
    this.isAllScreenShareDisabled = false,
    RecordingInfo? recordingInfo,
  })  : roomOwner = roomOwner ?? RoomUser(),
        scheduleAttendees = scheduleAttendees ?? [],
        recordingInfo = recordingInfo ?? RecordingInfo();
}

/// Schedule room options modify flag.
///
/// Flags for specifying which fields to modify when updating scheduled room options.
enum ScheduleRoomOptionsModifyFlag {
  roomName(1 << 0),
  scheduleStartTime(1 << 1),
  scheduleEndTime(1 << 2);

  final int value;

  const ScheduleRoomOptionsModifyFlag(this.value);
}

/// Schedule room options.
///
/// Configuration options when scheduling a room.
class ScheduleRoomOptions {
  /// Room name.
  String roomName;

  /// Room password.
  String password;

  /// Scheduled start time, in seconds.
  int scheduleStartTime;

  /// Scheduled end time, in seconds.
  int scheduleEndTime;

  /// Reminder seconds before start.
  int reminderSecondsBeforeStart;

  /// Scheduled attendee ID list.
  List<String> scheduleAttendees;

  /// Whether all microphones are disabled.
  bool isAllMicrophoneDisabled;

  /// Whether all cameras are disabled.
  bool isAllCameraDisabled;

  /// Whether all screen sharing is disabled.
  bool isAllScreenShareDisabled;

  /// Whether all messages are disabled.
  bool isAllMessageDisabled;
  ScheduleRoomOptions({
    this.roomName = '',
    this.password = '',
    this.scheduleStartTime = 0,
    this.scheduleEndTime = 0,
    this.reminderSecondsBeforeStart = 0,
    List<String>? scheduleAttendees,
    this.isAllMicrophoneDisabled = false,
    this.isAllCameraDisabled = false,
    this.isAllScreenShareDisabled = false,
    this.isAllMessageDisabled = false,
  }) : scheduleAttendees = scheduleAttendees ?? [];
}

/// Create room options.
///
/// Configuration options when creating an instant room.
class CreateRoomOptions {
  /// Room name.
  String roomName;

  /// Room password.
  String password;

  /// Whether all microphones are disabled.
  bool isAllMicrophoneDisabled;

  /// Whether all cameras are disabled.
  bool isAllCameraDisabled;

  /// Whether all screen sharing is disabled.
  bool isAllScreenShareDisabled;

  /// Whether all messages are disabled.
  bool isAllMessageDisabled;
  CreateRoomOptions({
    this.roomName = '',
    this.password = '',
    this.isAllMicrophoneDisabled = false,
    this.isAllCameraDisabled = false,
    this.isAllScreenShareDisabled = false,
    this.isAllMessageDisabled = false,
  });
}

/// Update room options modify flag.
///
/// Flags for specifying which fields to modify when updating room options.
enum UpdateRoomOptionsModifyFlag {
  roomName(1 << 3),
  password(1 << 13);

  final int value;

  const UpdateRoomOptionsModifyFlag(this.value);
}

/// Update room options.
///
/// Configuration options when updating room info.
class UpdateRoomOptions {
  /// Room name.
  String roomName;

  /// Room password.
  String password;
  UpdateRoomOptions({
    this.roomName = '',
    this.password = '',
  });
}

/// Start recording options.
///
/// Configuration options when starting cloud recording.
class StartRecordingOptions {
  StartRecordingOptions();
}

/// Room call info.
///
/// Represents room call information, including caller, callee and call status.
class RoomCall {
  /// Caller info.
  RoomUser caller;

  /// Callee info.
  RoomUser callee;

  /// Call status.
  RoomCallStatus status;
  RoomCall({
    RoomUser? caller,
    RoomUser? callee,
    this.status = RoomCallStatus.none,
  })  : caller = caller ?? RoomUser(),
        callee = callee ?? RoomUser();
}

/// Room related state data provided by RoomStore.
///
/// Comprehensive snapshot of current room session state. This structure contains all relevant information about current room and scheduled room list.
///
/// > **Note**: State is automatically updated when room status changes. Subscribe to [state] to receive real-time updates.
///
/// ### State Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [scheduledRoomList] | `ValueListenable<List<RoomInfo>>` | Scheduled room list |
/// | [scheduledRoomListCursor] | `ValueListenable<String>` | Scheduled room list cursor |
/// | [currentRoom] | `ValueListenable<RoomInfo?>` | Current room info |
abstract class RoomState {
  /// Scheduled room list.
  ValueListenable<List<RoomInfo>> get scheduledRoomList;

  /// Scheduled room list cursor.
  ValueListenable<String> get scheduledRoomListCursor;

  /// Current room info.
  ValueListenable<RoomInfo?> get currentRoom;
}

/// Room event callback.
class RoomListener {
  /// Triggered when added to a scheduled room.
  /// - [roomInfo] : Room info.
  void Function(RoomInfo roomInfo)? onAddedToScheduledRoom;

  /// Triggered when removed from a scheduled room.
  /// - [roomInfo] : Room info.
  /// - [operator] : Operator info.
  void Function(RoomInfo roomInfo, RoomUser operator)? onRemovedFromScheduledRoom;

  /// Triggered when a scheduled room is cancelled.
  /// - [roomInfo] : Room info.
  /// - [operator] : Operator info.
  void Function(RoomInfo roomInfo, RoomUser operator)? onScheduledRoomCancelled;

  /// Triggered when a scheduled room is about to start.
  /// - [roomInfo] : Room info.
  void Function(RoomInfo roomInfo)? onScheduledRoomStartingSoon;

  /// Triggered when a room ends.
  /// - [roomInfo] : Room info.
  void Function(RoomInfo roomInfo)? onRoomEnded;

  /// Triggered when a room call is received.
  /// - [roomInfo] : Room info.
  /// - [call] : Call info.
  /// - [extensionInfo] : Extension info.
  void Function(RoomInfo roomInfo, RoomCall call, String extensionInfo)? onCallReceived;

  /// Triggered when a room call is cancelled.
  /// - [roomInfo] : Room info.
  /// - [call] : Call info.
  void Function(RoomInfo roomInfo, RoomCall call)? onCallCancelled;

  /// Triggered when a room call times out.
  /// - [roomInfo] : Room info.
  /// - [call] : Call info.
  void Function(RoomInfo roomInfo, RoomCall call)? onCallTimeout;

  /// Triggered when a room call is accepted.
  /// - [roomInfo] : Room info.
  /// - [call] : Call info.
  void Function(RoomInfo roomInfo, RoomCall call)? onCallAccepted;

  /// Triggered when a room call is rejected.
  /// - [roomInfo] : Room info.
  /// - [call] : Call info.
  /// - [reason] : Rejection reason.
  void Function(RoomInfo roomInfo, RoomCall call, CallRejectionReason reason)? onCallRejected;

  /// Triggered when a room call is handled by another device.
  /// - [roomInfo] : Room info.
  /// - [isAccepted] : Whether accepted.
  void Function(RoomInfo roomInfo, bool isAccepted)? onCallHandledByOtherDevice;

  /// Triggered when a room call is revoked by admin.
  /// - [roomInfo] : Room info.
  /// - [call] : Call info.
  /// - [operator] : Operator info.
  void Function(RoomInfo roomInfo, RoomCall call, RoomUser operator)? onCallRevokedByAdmin;

  /// Triggered when recording starts.
  /// - [roomInfo] : Room info.
  /// - [operator] : The user who started the recording.
  void Function(RoomInfo roomInfo, RoomUser operator)? onRecordingStarted;

  /// Triggered when recording stops.
  /// - [roomInfo] : Room info.
  /// - [operator] : The user who stopped the recording.
  /// - [reason] : Recording stop reason.
  void Function(RoomInfo roomInfo, RoomUser operator, RecordingStopReason reason)? onRecordingStopped;

  RoomListener({
    this.onAddedToScheduledRoom,
    this.onRemovedFromScheduledRoom,
    this.onScheduledRoomCancelled,
    this.onScheduledRoomStartingSoon,
    this.onRoomEnded,
    this.onCallReceived,
    this.onCallCancelled,
    this.onCallTimeout,
    this.onCallAccepted,
    this.onCallRejected,
    this.onCallHandledByOtherDevice,
    this.onCallRevokedByAdmin,
    this.onRecordingStarted,
    this.onRecordingStopped,
  });
}

/// List result completion callback.
///
/// Completion handler for list result operations.
class ListResultCompletionHandler<T> extends CompletionHandler {
  List<T>? data;
  String? cursor;
}

/// Call user to room completion callback.
class CallUserToRoomCompletionHandler extends CompletionHandler {
  Map<String, RoomCallResult>? data;
}

/// Get room info completion callback.
class GetRoomInfoCompletionHandler extends CompletionHandler {
  RoomInfo? roomInfo;
}

/// Room management related interfaces, managing room creation, joining, leaving, scheduling and other operations.
///
/// `RoomStore` Manage room creation, joining, leaving, scheduling and other operations.
/// Room management provides complete room lifecycle management, including instant rooms and scheduled rooms. `RoomStore` provides a comprehensive set of APIs to manage room-related operations.
///
/// ### Key Features
///
/// - **Instant Room**：Supports creating and joining instant rooms.
/// - **Scheduled Room**：Supports scheduling rooms, modifying schedules, canceling schedules and other operations.
/// - **Room Call**：Supports calling users to join rooms, accepting/rejecting calls and other operations.
/// - **State Management**：Real-time tracking of current room status and scheduled room list.
///
/// > **Note**: Room status updates are delivered through [state] publisher. Subscribe to it to receive real-time updates about current room and scheduled room list.
///
/// ## Topics
///
/// ### Getting Instance
/// - [shared] : Get singleton object.
///
/// ### Observing State and Events
/// - [state] : Reactive state containing current room and scheduled room list.
/// - [addRoomListener]/[removeRoomListener] : Room event callback
///
/// ### Scheduled Room Operations
/// - [getScheduledRoomList] : Get scheduled room list.
/// - [getScheduledAttendees] : Get scheduled room attendees.
/// - [scheduleRoom] : Schedule a room.
/// - [updateScheduledRoom] : Update scheduled room.
/// - [addScheduledAttendees] : Add scheduled attendees.
/// - [removeScheduledAttendees] : Remove scheduled attendees.
/// - [cancelScheduledRoom] : Cancel scheduled room.
///
/// ### Instant Room Operations
/// - [createAndJoinRoom] : Create and join room.
/// - [joinRoom] : Join room.
/// - [leaveRoom] : Leave room.
/// - [endRoom] : End room.
/// - [updateRoomInfo] : Update room info.
/// - [getRoomInfo] : Get room info.
///
/// ### Room Call Operations
/// - [getPendingCalls] : Get pending calls list.
/// - [callUserToRoom] : Call user to join room.
/// - [cancelCall] : Cancel call.
/// - [acceptCall] : Accept call.
/// - [rejectCall] : Reject call.
///
/// ### Recording Operations
/// - [startRecording] : Start cloud recording.
/// - [stopRecording] : Stop cloud recording.
///
/// ## See Also
///
/// - [RoomStatus]
/// - [RoomInfo]
/// - [RoomUser]
/// - [RoomListener]
/// - [RoomCall]
abstract class RoomStore {
  /// Singleton object.
  static RoomStore get shared => StoreFactory.shared.getStore<RoomStore>();

  /// Room related state data provided by RoomStore.
  RoomState get state;

  /// Add room event callback listener
  ///
  /// - [listener] : Listener.
  void addRoomListener(RoomListener listener);

  /// Remove room event callback listener
  ///
  /// - [listener] : Listener.
  void removeRoomListener(RoomListener listener);

  /// Get scheduled room list
  ///
  /// - [cursor] : Pagination cursor.
  ///
  /// Returns: Operation result containing scheduled room list.
  Future<ListResultCompletionHandler<RoomInfo>> getScheduledRoomList(String? cursor);

  /// Get scheduled room attendees
  ///
  /// - [roomID] : Room ID.
  /// - [cursor] : Pagination cursor.
  ///
  /// Returns: Operation result containing attendees list.
  Future<ListResultCompletionHandler<RoomUser>> getScheduledAttendees({
    required String roomID,
    required String? cursor,
  });

  /// Schedule a room
  ///
  /// - [roomID] : Room ID.
  /// - [options] : Schedule options.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> scheduleRoom({
    required String roomID,
    required ScheduleRoomOptions options,
  });

  /// Update scheduled room
  ///
  /// - [roomID] : Room ID.
  /// - [options] : Schedule options.
  /// - [modifyFlagList] : Modify flag list.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> updateScheduledRoom({
    required String roomID,
    required ScheduleRoomOptions options,
    required List<ScheduleRoomOptionsModifyFlag> modifyFlagList,
  });

  /// Add scheduled attendees
  ///
  /// - [roomID] : Room ID.
  /// - [userIDList] : User ID list.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> addScheduledAttendees({
    required String roomID,
    required List<String> userIDList,
  });

  /// Remove scheduled attendees
  ///
  /// - [roomID] : Room ID.
  /// - [userIDList] : User ID list.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> removeScheduledAttendees({
    required String roomID,
    required List<String> userIDList,
  });

  /// Cancel scheduled room
  ///
  /// - [roomID] : Room ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> cancelScheduledRoom(String roomID);

  /// Create and join room
  ///
  /// - [roomID] : Room ID.
  /// - [roomType] : Room type (standard or webinar).
  /// - [options] : Create options.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> createAndJoinRoom({
    required String roomID,
    required RoomType roomType,
    required CreateRoomOptions options,
  });

  /// Join room
  ///
  /// - [roomID] : Room ID.
  /// - [roomType] : Room type (standard or webinar).
  /// - [password] : Room password.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> joinRoom({
    required String roomID,
    required RoomType roomType,
    String? password = "",
  });

  /// Leave room
  ///
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> leaveRoom();

  /// End room
  ///
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> endRoom();

  /// Update room info
  ///
  /// - [roomID] : Room ID.
  /// - [options] : Update options.
  /// - [modifyFlagList] : Modify flag list.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> updateRoomInfo({
    required String roomID,
    required UpdateRoomOptions options,
    required List<UpdateRoomOptionsModifyFlag> modifyFlagList,
  });

  /// Get room info
  ///
  /// - [roomID] : Room ID.
  ///
  /// Returns: Operation result containing room info.
  Future<GetRoomInfoCompletionHandler> getRoomInfo(String roomID);

  /// Get pending calls list
  ///
  /// - [roomID] : Room ID.
  /// - [cursor] : Pagination cursor.
  ///
  /// Returns: Operation result containing call list.
  Future<ListResultCompletionHandler<RoomCall>> getPendingCalls({
    required String roomID,
    required String? cursor,
  });

  /// Call user to join room
  ///
  /// - [roomID] : Room ID.
  /// - [userIDList] : User ID list.
  /// - [timeout] : Timeout (in seconds).
  /// - [extensionInfo] : Extension info.
  ///
  /// Returns: Operation result containing call result.
  Future<CallUserToRoomCompletionHandler> callUserToRoom({
    required String roomID,
    required List<String> userIDList,
    int timeout = 0,
    String? extensionInfo,
  });

  /// Cancel call
  ///
  /// - [roomID] : Room ID.
  /// - [userIDList] : User ID list.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> cancelCall({
    required String roomID,
    required List<String> userIDList,
  });

  /// Accept call
  ///
  /// - [roomID] : Room ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> acceptCall(String roomID);

  /// Reject call
  ///
  /// - [roomID] : Room ID.
  /// - [reason] : Rejection reason.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> rejectCall({
    required String roomID,
    required CallRejectionReason reason,
  });

  /// Start cloud recording
  ///
  /// Only Owner and Admin have permission to call.
  ///
  /// - [options] : Recording options, reserved for future extensions.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> startRecording({
    StartRecordingOptions? options,
  });

  /// Stop cloud recording
  ///
  /// Only Owner and Admin have permission to call.
  ///
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> stopRecording();

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

  /// Reset room state
  ///
  /// Reset all state data of RoomStore, clear current room info and scheduled room list. Usually called when user logs out or needs to clean up state.
  void reset();
}
