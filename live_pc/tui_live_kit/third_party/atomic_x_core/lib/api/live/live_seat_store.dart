// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveSeatStore @ AtomicXCore
// Function: Live seat management related interfaces, managing seat operations such as taking seat, leaving seat, locking seat, and releasing seat.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../device/device_store.dart';
import '../define.dart';
import 'live_audience_store.dart';
// <docgen-keep-end>

/// Move seat policy.
enum MoveSeatPolicy {
  /// Abort when occupied.
  abortWhenOccupied(0),

  /// Force replace.
  forceReplace(1),

  /// Swap position.
  swapPosition(2);

  final int value;

  const MoveSeatPolicy(this.value);
}

/// Device control policy.
enum DeviceControlPolicy {
  /// Unlock only.
  unlockOnly(1);

  final int value;

  const DeviceControlPolicy(this.value);
}

/// User suspend status.
enum SuspendStatus {
  /// Not suspended.
  none(value: 0),

  /// User suspended in background.
  inBackground(value: 1),

  /// User is on a phone call.
  inCalling(value: 2);

  final int value;
  const SuspendStatus({required this.value});

  static SuspendStatus fromValue(int value) {
    return values.firstWhere((element) => element.value == value, orElse: () => none);
  }
}

/// Take seat mode.
enum SeatMode {
  /// Free to take seat.
  free(value: 1),

  /// Apply to take seat.
  apply(value: 2);

  final int value;
  const SeatMode({required this.value});

  static SeatMode fromValue(int value) {
    return values.firstWhere((element) => element.value == value, orElse: () => free);
  }
}

/// Seat user information.
///
/// Contains basic information of the seat user, such as user ID, user name, avatar URL, role, device status, etc.
class SeatUserInfo {
  /// User ID.
  final String userID;

  /// User name.
  final String userName;

  /// Avatar URL.
  final String avatarURL;

  /// User role.
  final Role role;

  /// Live room ID.
  final String liveID;

  /// Microphone status.
  final DeviceStatus microphoneStatus;

  /// Whether microphone can be opened.
  final bool allowOpenMicrophone;

  /// Camera status.
  final DeviceStatus cameraStatus;

  /// Whether camera can be opened.
  final bool allowOpenCamera;

  /// User suspend status.
  final SuspendStatus userSuspendStatus;

  SeatUserInfo({
    this.userID = '',
    this.userName = '',
    this.avatarURL = '',
    this.role = Role.generalUser,
    this.liveID = '',
    this.microphoneStatus = DeviceStatus.off,
    this.allowOpenMicrophone = true,
    this.cameraStatus = DeviceStatus.off,
    this.allowOpenCamera = true,
    this.userSuspendStatus = SuspendStatus.none,
  });
}

/// Seat view coordinate information.
///
/// Contains the coordinate information of the seat view, such as X coordinate, Y coordinate, width, height, z-order.
class RegionInfo {
  /// X coordinate.
  int x;

  /// Y coordinate.
  int y;

  /// Width.
  int w;

  /// Height.
  int h;

  /// Z-order.
  int zorder;

  RegionInfo({
    this.x = 0,
    this.y = 0,
    this.w = 0,
    this.h = 0,
    this.zorder = 0,
  });
}

/// Audio and video statistics information.
///
/// Contains audio and video related statistics, such as user ID, video bitrate, video width and height, frame rate, audio sample rate, audio bitrate, etc.
class AVStatistics {
  /// User ID.
  String userID;

  /// Local video bitrate.
  int videoBitrate;

  /// Local video width.
  int videoWidth;

  /// Local video height.
  int videoHeight;

  /// Local video frame rate.
  int frameRate;

  /// Audio sample rate.
  int audioSampleRate;

  /// Audio bitrate.
  int audioBitrate;

  AVStatistics({
    this.userID = '',
    this.videoBitrate = 0,
    this.videoWidth = 0,
    this.videoHeight = 0,
    this.frameRate = 0,
    this.audioSampleRate = 0,
    this.audioBitrate = 0,
  });
}

/// Seat information.
///
/// Contains basic information of the seat, such as seat index, whether locked, user information, region information.
class SeatInfo {
  /// Seat index.
  int index;

  /// Whether locked.
  bool isLocked;

  /// User information.
  SeatUserInfo userInfo;

  /// Region information.
  RegionInfo region;

  /// Whether the user on this seat is currently a featured host. Can only be true in templates that support featured host slots.
  bool isFeaturedHost;

  SeatInfo({
    this.index = 0,
    this.isLocked = false,
    SeatUserInfo? userInfo,
    RegionInfo? region,
    this.isFeaturedHost = false,
  })  : userInfo = userInfo ?? SeatUserInfo(),
        region = region ?? RegionInfo();
}

/// Live canvas.
///
/// Contains basic information of the live canvas, such as width, height, template ID.
class LiveCanvas {
  /// Width.
  int w;

  /// Height.
  int h;

  /// Template ID.
  int templateID;

  LiveCanvas({
    this.w = 0,
    this.h = 0,
    this.templateID = 600,
  });
}

/// Seat state data provided by LiveSeatStore.
///
/// Contains seat list, canvas information, speaking users, audio and video statistics, etc.
abstract class LiveSeatState {
  /// Seat list.
  ValueListenable<List<SeatInfo>> get seatList;

  /// Canvas information.
  ValueListenable<LiveCanvas> get canvas;

  /// Speaking users.
  ValueListenable<Map<String, int>> get speakingUsers;

  /// Audio and video statistics.
  ValueListenable<List<AVStatistics>> get avStatistics;

  /// Take seat mode of the current room, supports real-time updates and can be subscribed to.
  ValueListenable<SeatMode> get seatMode;
}

/// Seat related callback events.
class LiveSeatListener {
  /// Triggered when the local camera is opened by an admin.
  /// - [policy] : Device control policy.
  void Function(DeviceControlPolicy policy)? onLocalCameraOpenedByAdmin;

  /// Triggered when the local camera is closed by an admin.
  void Function()? onLocalCameraClosedByAdmin;

  /// Triggered when the local microphone is opened by an admin.
  /// - [policy] : Device control policy.
  void Function(DeviceControlPolicy policy)? onLocalMicrophoneOpenedByAdmin;

  /// Triggered when the local microphone is closed by an admin.
  void Function()? onLocalMicrophoneClosedByAdmin;

  LiveSeatListener({
    this.onLocalCameraClosedByAdmin,
    this.onLocalCameraOpenedByAdmin,
    this.onLocalMicrophoneClosedByAdmin,
    this.onLocalMicrophoneOpenedByAdmin,
  });
}

/// Live seat management related interfaces, managing seat operations such as taking seat, leaving seat, locking seat, and releasing seat.
///
/// `LiveSeatStore` Live seat management class for managing seat operations such as taking seat, leaving seat, locking seat, and releasing seat.
/// `LiveSeatStore` provides a complete set of seat management APIs, including taking seat, leaving seat, locking seat, unlocking seat, kicking user off seat, remote device control, etc.
/// Through this class, seat management functionality can be implemented in the live room.
///
/// ### Key Features
///
/// - **Seat Management**：Take seat, leave seat, lock seat, unlock seat operations.
/// - **User Management**：Kick user off seat, move user to specified seat.
/// - **Featured Host Management**：In templates that support a featured host slot, set a seated user as a featured host or remove a featured host.
/// - **Device Control**：Remote control of user's camera and microphone.
/// - **Event Listening**：Listen to seat-related events.
///
/// > **Important**: Use the [LiveSeatStore.create] factory method to create a `LiveSeatStore` instance, passing a valid live room ID.
///
/// > **Note**: Seat state updates are delivered through the [liveSeatState] publisher. Subscribe to it to receive real-time updates of seat data in the room.
///
/// ### Seat Management Operations Overview
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Take Seat | [takeSeat] | User takes seat |
/// | Leave Seat | [leaveSeat] | User leaves seat |
/// | Lock Seat | [lockSeat] | Lock seat |
/// | Unlock | [unlockSeat] | Unlock seat |
/// | Kick | [kickUserOutOfSeat] | Kick user off seat |
/// | Move | [moveUserToSeat] | Move user to specified seat |
///
/// ### Seat Mode
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Set Seat Mode | [setSeatMode] | Set the take seat mode of the room |
///
/// ### Featured Host Management
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Set Featured Host | [setFeaturedHost] | Set a seated user as a featured host |
/// | Revoke Featured Host | [revokeFeaturedHost] | Revoke a user's featured host status |
///
/// ### Remote Device Control
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Open Camera | [openRemoteCamera] | Remotely open user's camera |
/// | Close Camera | [closeRemoteCamera] | Remotely close user's camera |
/// | Open Microphone | [openRemoteMicrophone] | Remotely open user's microphone |
/// | Close Microphone | [closeRemoteMicrophone] | Remotely close user's microphone |
///
/// ## Topics
///
/// ### Creating Instance
/// - [LiveSeatStore.create] : Create seat management instance.
///
/// ### Observing State and Events
/// - [liveSeatState] : Current room seat state.
/// - [addLiveSeatEventListener]/[removeLiveSeatEventListener] : Seat event callbacks
///
/// ### Seat Operations
/// - [takeSeat] : Take seat.
/// - [leaveSeat] : Leave seat.
/// - [lockSeat] : Lock seat.
/// - [unlockSeat] : Unlock seat.
///
/// ### User Management
/// - [kickUserOutOfSeat] : Kick user off seat.
/// - [moveUserToSeat] : Move user.
///
/// ### Seat Mode
/// - [setSeatMode] : Set the take seat mode.
///
/// ### Featured Host Management
/// - [setFeaturedHost] : Set a featured host.
/// - [revokeFeaturedHost] : Revoke a featured host.
///
/// ### Remote Device Control
/// - [openRemoteCamera] : Open remote camera.
/// - [closeRemoteCamera] : Close remote camera.
/// - [openRemoteMicrophone] : Open remote microphone.
/// - [closeRemoteMicrophone] : Close remote microphone.
///
/// ## See Also
///
/// - [LiveSeatState]
/// - [LiveSeatListener]
/// - [SeatInfo]
/// - [SeatUserInfo]
/// - [MoveSeatPolicy]
/// - [DeviceControlPolicy]
abstract class LiveSeatStore {
  /// Seat state data provided by LiveSeatStore.
  LiveSeatState get liveSeatState;

  /// Create LiveSeatStore instance
  /// - [liveID] : Live room ID.
  /// Returns: LiveSeatStore instance.
  static LiveSeatStore create(String liveID) {
    return StoreFactory.shared.getStore<LiveSeatStore>(roomID: liveID);
  }

  /// Take seat
  ///
  /// - [seatIndex] : Seat index.
  Future<CompletionHandler> takeSeat(int seatIndex);

  /// Leave seat
  ///
  Future<CompletionHandler> leaveSeat();

  /// Mute microphone
  void muteMicrophone();

  /// Unmute microphone
  ///
  Future<CompletionHandler> unmuteMicrophone();

  /// Kick user off seat
  ///
  /// - [userID] : User ID.
  Future<CompletionHandler> kickUserOutOfSeat(String userID);

  /// Move user to seat
  ///
  /// - [userID] : User ID.
  /// - [targetIndex] : Target seat index.
  /// - [policy] : Move policy.
  Future<CompletionHandler> moveUserToSeat({
    required String userID,
    required int targetIndex,
    MoveSeatPolicy policy = MoveSeatPolicy.abortWhenOccupied,
  });

  /// Set the take seat mode of the current room. After setting successfully, the [LiveSeatState.seatMode] state will be updated. Subscribe to it to receive real-time updates.
  ///
  /// - [mode] : Take seat mode ([SeatMode.free] free to take seat / [SeatMode.apply] apply to take seat).
  Future<CompletionHandler> setSeatMode(SeatMode mode);

  /// Set featured host
  ///
  /// - [userID] : User ID.
  Future<CompletionHandler> setFeaturedHost(String userID);

  /// Revoke featured host
  ///
  /// - [userID] : User ID.
  Future<CompletionHandler> revokeFeaturedHost(String userID);

  /// Lock seat
  ///
  /// - [seatIndex] : Seat index.
  Future<CompletionHandler> lockSeat(int seatIndex);

  /// Unlock seat
  ///
  /// - [seatIndex] : Seat index.
  Future<CompletionHandler> unlockSeat(int seatIndex);

  /// Open remote camera
  ///
  /// - [userID] : User ID.
  /// - [policy] : Device control policy.
  Future<CompletionHandler> openRemoteCamera({
    required String userID,
    required DeviceControlPolicy policy,
  });

  /// Close remote camera
  ///
  /// - [userID] : User ID.
  Future<CompletionHandler> closeRemoteCamera(String userID);

  /// Open remote microphone
  ///
  /// - [userID] : User ID.
  /// - [policy] : Device control policy.
  Future<CompletionHandler> openRemoteMicrophone({
    required String userID,
    required DeviceControlPolicy policy,
  });

  /// Close remote microphone
  ///
  /// - [userID] : User ID.
  Future<CompletionHandler> closeRemoteMicrophone(String userID);

  /// Add seat event listener
  ///
  /// - [listener] : Listener.
  void addLiveSeatEventListener(LiveSeatListener listener);

  /// Remove seat event listener
  ///
  /// - [listener] : Listener.
  void removeLiveSeatEventListener(LiveSeatListener listener);
}
