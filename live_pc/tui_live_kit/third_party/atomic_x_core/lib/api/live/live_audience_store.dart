// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveAudienceStore @ AtomicXCore
// Function: Live audience related interfaces, managing audience list, permission settings and other operations.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
// <docgen-keep-end>

/// User role.
enum Role {
  /// Room owner.
  owner(0),

  /// Administrator.
  admin(1),

  /// General user.
  generalUser(2);

  final int value;

  const Role(this.value);
}

/// Live user information.
///
/// Contains basic user information including unique user ID, name, and avatar URL.
class LiveUserInfo {
  /// User unique identifier ID.
  String userID;

  /// User name.
  String userName;

  /// User avatar URL.
  String avatarURL;

  /// User level.
  int level;

  LiveUserInfo({
    this.userID = '',
    this.userName = '',
    this.avatarURL = '',
    this.level = 0,
  });
}

/// Live audience state.
///
/// Contains audience list, audience count, admin list, and muted user list information.
abstract class LiveAudienceState {
  /// Audience list.
  ValueListenable<List<LiveUserInfo>> get audienceList;

  /// Audience count.
  ValueListenable<int> get audienceCount;

  /// Administrator list.
  ValueListenable<List<LiveUserInfo>> get adminList;

  /// List of users banned from sending messages.
  ValueListenable<List<LiveUserInfo>> get messageBannedUserList;
}

/// Live audience events.
///
/// This listener is used to receive dynamic events for all roles (owner, admin, audience) in the live room.
///
/// > **Note**: Corresponding callbacks will be triggered when an owner, admin, or audience joins, leaves, or is muted.
///
/// ### Event Description
///
/// | Event | Trigger Condition | Callback Parameters |
/// |------|-----------------|-------------------|
/// | `onOwnerJoined` | Owner joins the room | owner |
/// | `onOwnerLeft` | Owner leaves the room | owner |
/// | `onAdminJoined` | Admin joins the room | admin |
/// | `onAdminLeft` | Admin leaves the room | admin |
/// | `onAudienceJoined` | Audience joins the room | audience |
/// | `onAudienceLeft` | Audience leaves the room | audience |
/// | `onAudienceMessageDisabled` | Audience is muted/unmuted | audience, isDisable |
class LiveAudienceListener {
  /// Owner joined event.
  /// - [owner] : Information of the joined owner.
  void Function(LiveUserInfo owner)? onOwnerJoined;

  /// Owner left event.
  /// - [owner] : Information of the left owner.
  void Function(LiveUserInfo owner)? onOwnerLeft;

  /// Admin joined event.
  /// - [admin] : Information of the joined admin.
  void Function(LiveUserInfo admin)? onAdminJoined;

  /// Admin left event.
  /// - [admin] : Information of the left admin.
  void Function(LiveUserInfo admin)? onAdminLeft;

  /// Audience joined event.
  /// - [audience] : Information of the joined audience.
  void Function(LiveUserInfo audience)? onAudienceJoined;

  /// Audience left event.
  /// - [audience] : Information of the left audience.
  void Function(LiveUserInfo audience)? onAudienceLeft;

  /// Audience message disabled event.
  /// - [audience] : Audience information.
  /// - [isDisable] : Whether message sending is disabled.
  void Function(LiveUserInfo audience, bool isDisable)? onAudienceMessageDisabled;

  LiveAudienceListener({
    this.onOwnerJoined,
    this.onOwnerLeft,
    this.onAdminJoined,
    this.onAdminLeft,
    this.onAudienceJoined,
    this.onAudienceLeft,
    this.onAudienceMessageDisabled,
  });
}

/// Live audience related interfaces, managing audience list, permission settings and other operations.
///
/// `LiveAudienceStore` Live audience management class for managing audience list, permission settings and related business.
/// `LiveAudienceStore` provides a complete set of audience management APIs, including fetching audience list, setting administrators, kicking users, muting, etc.
/// Through this class, you can implement audience management functions in live rooms.
///
/// ### Key Features
///
/// - **Audience List**：Get and manage the audience list of the current room.
/// - **Permission Management**：Set and revoke administrator permissions.
/// - **User Management**：Kick users, mute, and other operations.
/// - **Event Listening**：Listen for owner, admin, and audience join/leave events.
///
/// > **Important**: Use the [LiveAudienceStore.create] factory method to create a `LiveAudienceStore` instance, which requires a valid live room ID.
///
/// > **Note**: Audience state updates are delivered through the [liveAudienceState] publisher. Subscribe to it to receive real-time updates of audience data in the room.
///
/// ### Audience Management Operations Overview
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Fetch Audience List | [fetchAudienceList] | Get the audience list of the current room |
/// | Set Administrator | [setAdministrator] | Set a user as administrator |
/// | Revoke Administrator | [revokeAdministrator] | Revoke user's administrator permission |
/// | Kick User | [kickUserOutOfRoom] | Kick a user out of the room |
/// | Mute User | [disableSendMessage] | Disable/enable user message sending |
///
/// ## Topics
///
/// ### Creating Instance
/// - [LiveAudienceStore.create] : Create audience management instance.
///
/// ### Observing State and Events
/// - [liveAudienceState] : Current room's audience state.
/// - [addLiveAudienceListener]/[removeLiveAudienceListener] : Audience event callbacks
///
/// ### Audience Management
/// - [fetchAudienceList] : Fetch audience list.
/// - [setAdministrator] : Set administrator.
/// - [revokeAdministrator] : Revoke administrator.
/// - [kickUserOutOfRoom] : Kick user.
/// - [disableSendMessage] : Mute/unmute user.
///
/// ## See Also
///
/// - [LiveAudienceState]
/// - [LiveAudienceListener]
/// - [LiveUserInfo]
/// - [Role]
abstract class LiveAudienceStore {
  /// Current room's audience state.
  LiveAudienceState get liveAudienceState;

  /// Create audience management instance
  /// - [liveID] : Live room ID.
  /// Returns: Audience management instance for the specified room.
  static LiveAudienceStore create(String liveID) {
    return StoreFactory.shared.getStore<LiveAudienceStore>(roomID: liveID);
  }

  /// Fetch audience list
  ///
  Future<CompletionHandler> fetchAudienceList();

  /// Set administrator
  ///
  /// - [userID] : User ID to be set as administrator.
  Future<CompletionHandler> setAdministrator(String userID);

  /// Revoke administrator
  ///
  /// - [userID] : User ID to revoke administrator permission.
  Future<CompletionHandler> revokeAdministrator(String userID);

  /// Kick user out of room
  ///
  /// - [userID] : User ID to be kicked out.
  Future<CompletionHandler> kickUserOutOfRoom(String userID);

  /// Disable/enable user message sending
  ///
  /// - [userID] : Target user ID.
  /// - [isDisable] : true to disable message sending, false to enable.
  Future<CompletionHandler> disableSendMessage({
    required String userID,
    required bool isDisable,
  });

  /// Add audience event listener
  ///
  /// - [listener] : Listener.
  void addLiveAudienceListener(LiveAudienceListener listener);

  /// Remove audience event listener
  ///
  /// - [listener] : Listener.
  void removeLiveAudienceListener(LiveAudienceListener listener);
}
