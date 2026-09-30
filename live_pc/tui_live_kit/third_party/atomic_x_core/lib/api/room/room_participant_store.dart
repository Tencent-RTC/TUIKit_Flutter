// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   RoomParticipantStore @ AtomicXCore
// Function: Room participant management related interfaces, managing participant permissions, device control, message muting and other operations.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
import '../device/device_store.dart';
import 'room_store.dart';
// <docgen-keep-end>

/// Participant role.
enum ParticipantRole {
  /// Owner.
  owner(0),

  /// Admin.
  admin(1),

  /// General user.
  generalUser(2);

  final int value;
  const ParticipantRole(this.value);
}

/// Participant status.
enum RoomParticipantStatus {
  scheduled(1),
  inCalling(2),
  callTimeout(3),
  callRejected(4),
  inRoom(5);

  final int value;

  const RoomParticipantStatus(this.value);
}

/// Reason for being kicked out of room.
enum KickedOutOfRoomReason {
  kickedByAdmin(0),
  replacedByAnotherDevice(1),
  kickedByServer(2),
  connectionTimeout(3),
  invalidStatusOnReconnect(4),
  roomLimitExceeded(5);

  final int value;

  const KickedOutOfRoomReason(this.value);
}

/// Room participant info.
///
/// Represents complete information of a participant in the room, including basic info and device status.
class RoomParticipant {
  String userID;
  String userName;
  String avatarURL;
  String nameCard;
  ParticipantRole role;
  RoomParticipantStatus roomStatus;
  DeviceStatus microphoneStatus;
  DeviceStatus screenShareStatus;
  DeviceStatus cameraStatus;
  bool isMessageDisabled;
  Map<String, String> metaData;

  RoomParticipant({
    this.userID = '',
    this.userName = '',
    this.avatarURL = '',
    this.nameCard = '',
    this.role = ParticipantRole.generalUser,
    this.roomStatus = RoomParticipantStatus.scheduled,
    this.microphoneStatus = DeviceStatus.off,
    this.screenShareStatus = DeviceStatus.off,
    this.cameraStatus = DeviceStatus.off,
    this.isMessageDisabled = false,
    Map<String, String>? metaData,
  }) : metaData = metaData ?? {};
}

/// Device request info.
///
/// Represents device request or invitation information.
class DeviceRequestInfo {
  final int timestamp;
  final String senderUserID;
  final String senderUserName;
  final String senderNameCard;
  final String senderAvatarURL;
  final String content;
  final DeviceType device;

  DeviceRequestInfo({
    this.timestamp = 0,
    this.senderUserID = '',
    this.senderUserName = '',
    this.senderNameCard = '',
    this.senderAvatarURL = '',
    this.content = '',
    this.device = DeviceType.microphone,
  });
}

/// Participant related state data provided by RoomParticipantStore.
///
/// Comprehensive snapshot of current room participant state. This structure contains all relevant information about participant list, device requests, etc.
abstract class RoomParticipantState {
  /// Participant list.
  ValueListenable<List<RoomParticipant>> get participantList;

  /// Participant list cursor.
  ValueListenable<String> get participantListCursor;

  /// Audience list (for webinar room).
  ValueListenable<List<RoomUser>> get audienceList;

  /// Audience list cursor.
  ValueListenable<String> get audienceListCursor;

  /// Admin list.
  ValueListenable<List<RoomUser>> get adminList;

  /// Message disabled user list.
  ValueListenable<List<RoomUser>> get messageDisabledUserList;

  /// Participant list with video.
  ValueListenable<List<RoomParticipant>> get participantListWithVideo;

  /// Participant sharing screen.
  ValueListenable<RoomParticipant?> get participantWithScreen;

  /// Pending device application list.
  ValueListenable<List<DeviceRequestInfo>> get pendingDeviceApplications;

  /// Pending device invitation list.
  ValueListenable<List<DeviceRequestInfo>> get pendingDeviceInvitations;

  /// Speaking users and their volume.
  ValueListenable<Map<String, int>> get speakingUsers;

  /// User network quality info.
  ValueListenable<Map<String, NetworkInfo>> get networkQualities;

  /// Pending participant list.
  ValueListenable<List<RoomParticipant>> get pendingParticipantList;

  /// Local participant info.
  ValueListenable<RoomParticipant?> get localParticipant;
}

/// Participant event callback.
class RoomParticipantListener {
  /// Triggered when a participant joins the room.
  /// - [participant] : Joined participant info.
  void Function(RoomUser participant)? onParticipantJoined;

  /// Triggered when a participant leaves the room.
  /// - [participant] : Left participant info.
  void Function(RoomUser participant)? onParticipantLeft;

  /// Triggered when an audience is promoted to participant.
  /// - [userInfo] : Promoted user info.
  void Function(RoomUser userInfo)? onAudiencePromotedToParticipant;

  /// Triggered when a participant is demoted to audience.
  /// - [userInfo] : Demoted user info.
  void Function(RoomUser userInfo)? onParticipantDemotedToAudience;

  /// Triggered when the owner changes.
  /// - [newOwner] : New owner info.
  /// - [oldOwner] : Old owner info.
  void Function(RoomUser newOwner, RoomUser oldOwner)? onOwnerChanged;

  /// Triggered when an admin is set.
  /// - [userInfo] : User info set as admin.
  void Function(RoomUser userInfo)? onAdminSet;

  /// Triggered when an admin is revoked.
  /// - [userInfo] : User info revoked from admin.
  void Function(RoomUser userInfo)? onAdminRevoked;

  /// Triggered when kicked from the room.
  /// - [reason] : Reason for being kicked.
  /// - [message] : Additional message.
  void Function(KickedOutOfRoomReason reason, String message)? onKickedFromRoom;

  /// Triggered when a participant's device is closed.
  /// - [device] : Device type.
  /// - [operator] : Operator info.
  void Function(DeviceType device, RoomUser operator)? onParticipantDeviceClosed;

  /// Triggered when a user is muted.
  /// - [disable] : Whether muted.
  /// - [operator] : Operator info.
  void Function(bool disable, RoomUser operator)? onUserMessageDisabled;

  /// Triggered when all devices are disabled.
  /// - [device] : Device type.
  /// - [disable] : Whether disabled.
  /// - [operator] : Operator info.
  void Function(DeviceType device, bool disable, RoomUser operator)? onAllDevicesDisabled;

  /// Triggered when all users are muted.
  /// - [disable] : Whether muted.
  /// - [operator] : Operator info.
  void Function(bool disable, RoomUser operator)? onAllMessagesDisabled;

  /// Triggered when a device request is received.
  /// - [request] : Device request info.
  void Function(DeviceRequestInfo request)? onDeviceRequestReceived;

  /// Triggered when a device request is cancelled.
  /// - [request] : Device request info.
  void Function(DeviceRequestInfo request)? onDeviceRequestCancelled;

  /// Triggered when a device request times out.
  /// - [request] : Device request info.
  void Function(DeviceRequestInfo request)? onDeviceRequestTimeout;

  /// Triggered when a device request is approved.
  /// - [request] : Device request info.
  /// - [operator] : Operator info.
  void Function(DeviceRequestInfo request, RoomUser operator)? onDeviceRequestApproved;

  /// Triggered when a device request is rejected.
  /// - [request] : Device request info.
  /// - [operator] : Operator info.
  void Function(DeviceRequestInfo request, RoomUser operator)? onDeviceRequestRejected;

  /// Triggered when a device request is processed.
  /// - [request] : Device request info.
  /// - [operator] : Operator info.
  void Function(DeviceRequestInfo request, RoomUser operator)? onDeviceRequestProcessed;

  /// Triggered when a device invitation is received.
  /// - [invitation] : Device invitation info.
  void Function(DeviceRequestInfo invitation)? onDeviceInvitationReceived;

  /// Triggered when a device invitation is cancelled.
  /// - [invitation] : Device invitation info.
  void Function(DeviceRequestInfo invitation)? onDeviceInvitationCancelled;

  /// Triggered when a device invitation times out.
  /// - [invitation] : Device invitation info.
  void Function(DeviceRequestInfo invitation)? onDeviceInvitationTimeout;

  /// Triggered when a device invitation is accepted.
  /// - [invitation] : Device invitation info.
  /// - [operator] : Operator info.
  void Function(DeviceRequestInfo invitation, RoomUser operator)? onDeviceInvitationAccepted;

  /// Triggered when a device invitation is declined.
  /// - [invitation] : Device invitation info.
  /// - [operator] : Operator info.
  void Function(DeviceRequestInfo invitation, RoomUser operator)? onDeviceInvitationDeclined;

  RoomParticipantListener({
    this.onParticipantJoined,
    this.onParticipantLeft,
    this.onAudiencePromotedToParticipant,
    this.onParticipantDemotedToAudience,
    this.onOwnerChanged,
    this.onAdminSet,
    this.onAdminRevoked,
    this.onKickedFromRoom,
    this.onParticipantDeviceClosed,
    this.onUserMessageDisabled,
    this.onAllDevicesDisabled,
    this.onAllMessagesDisabled,
    this.onDeviceRequestReceived,
    this.onDeviceRequestCancelled,
    this.onDeviceRequestTimeout,
    this.onDeviceRequestApproved,
    this.onDeviceRequestRejected,
    this.onDeviceRequestProcessed,
    this.onDeviceInvitationReceived,
    this.onDeviceInvitationCancelled,
    this.onDeviceInvitationTimeout,
    this.onDeviceInvitationAccepted,
    this.onDeviceInvitationDeclined,
  });
}

/// Room participant management related interfaces, managing participant permissions, device control, message muting and other operations.
///
/// `RoomParticipantStore` Manage participant permissions, device control, message muting and other operations in the room.
/// Room participant management provides complete participant lifecycle management, including permission management, device control, message muting and other features. `RoomParticipantStore` provides a comprehensive set of APIs to manage room participant related operations.
///
/// ### Key Features
///
/// - **Permission Management**：Supports transferring owner, setting/revoking admin, kicking users and other operations.
/// - **Device Control**：Supports closing participant devices, disabling all devices and other operations.
/// - **Message Muting**：Supports muting individual users or all users.
/// - **Device Request/Invitation**：Supports requesting to open device, inviting to open device and other bidirectional interactions.
///
/// > **Note**: Participant status updates are delivered through [state] publisher. Subscribe to it to receive real-time updates about participant list.
///
/// ## Topics
///
/// ### Creating Instance
/// - [create] : Create object instance.
///
/// ### Observing State and Events
/// - [state] : Reactive state containing participant list and device request info.
/// - [addRoomParticipantListener]/[removeRoomParticipantListener] : Participant event callback
///
/// ### Participant List
/// - [getParticipantList] : Get participant list.
/// - [getAudienceList] : Get audience list (for webinar room).
/// - [searchUsers] : Search users by keyword.
///
/// ### Audience/Participant Role Management
/// - [promoteAudienceToParticipant] : Promote audience to participant (for webinar room).
/// - [demoteParticipantToAudience] : Demote participant to audience (for webinar room).
///
/// ### Permission Management
/// - [transferOwner] : Transfer owner.
/// - [setAdmin] : Set admin.
/// - [revokeAdmin] : Revoke admin.
/// - [kickUser] : Kick user.
/// - [updateParticipantNameCard] : Update participant name card.
/// - [updateParticipantMetaData] : Update participant metadata.
///
/// ### Local Microphone Control
/// - [muteMicrophone] : Mute microphone.
/// - [unmuteMicrophone] : Unmute microphone.
///
/// ### Device Control
/// - [closeParticipantDevice] : Close participant device.
/// - [disableUserMessage] : Mute user.
/// - [disableAllDevices] : Disable all devices.
/// - [disableAllMessages] : Mute all users.
///
/// ### Device Request Operations
/// - [requestToOpenDevice] : Request to open device.
/// - [cancelOpenDeviceRequest] : Cancel open device request.
/// - [approveOpenDeviceRequest] : Approve open device request.
/// - [rejectOpenDeviceRequest] : Reject open device request.
///
/// ### Device Invitation Operations
/// - [inviteToOpenDevice] : Invite to open device.
/// - [cancelOpenDeviceInvitation] : Cancel open device invitation.
/// - [acceptOpenDeviceInvitation] : Accept open device invitation.
/// - [declineOpenDeviceInvitation] : Decline open device invitation.
///
/// ## See Also
///
/// - [ParticipantRole]
/// - [RoomParticipant]
/// - [RoomParticipantListener]
/// - [DeviceRequestInfo]
abstract class RoomParticipantStore {
  /// Participant related state data provided by RoomParticipantStore.
  RoomParticipantState get state;

  /// Create RoomParticipantStore instance
  /// - [roomID] : Room ID.
  /// Returns: RoomParticipantStore instance.
  static RoomParticipantStore create(String roomID) {
    return StoreFactory.shared.getStore<RoomParticipantStore>(roomID: roomID);
  }

  /// Add participant event callback listener
  ///
  /// - [listener] : Listener.
  void addRoomParticipantListener(RoomParticipantListener listener);

  /// Remove participant event callback listener
  ///
  /// - [listener] : Listener.
  void removeRoomParticipantListener(RoomParticipantListener listener);

  /// Get participant list
  ///
  /// - [cursor] : Pagination cursor.
  ///
  /// Returns: Operation result containing participant list.
  Future<ListResultCompletionHandler<RoomParticipant>> getParticipantList(String? cursor);

  /// Get audience list (for webinar room)
  ///
  /// - [cursor] : Pagination cursor.
  ///
  /// Returns: Operation result containing audience list.
  Future<ListResultCompletionHandler<RoomUser>> getAudienceList(String? cursor);

  /// Search users by keyword
  ///
  /// - [keyword] : Search keyword.
  ///
  /// Returns: Operation result containing user list.
  Future<ListResultCompletionHandler<RoomUser>> searchUsers(String keyword);

  /// Promote audience to participant (for webinar room)
  ///
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> promoteAudienceToParticipant(String userID);

  /// Demote participant to audience (for webinar room)
  ///
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> demoteParticipantToAudience(String userID);

  /// Transfer owner
  ///
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> transferOwner(String userID);

  /// Set admin
  ///
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> setAdmin(String userID);

  /// Revoke admin
  ///
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> revokeAdmin(String userID);

  /// Kick user
  ///
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> kickUser(String userID);

  /// Update participant name card
  ///
  /// - [userID] : User ID.
  /// - [nameCard] : Name card.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> updateParticipantNameCard({
    required String userID,
    required String nameCard,
  });

  /// Update participant metadata
  ///
  /// - [userID] : User ID.
  /// - [metaData] : Metadata.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> updateParticipantMetaData({
    required String userID,
    required Map<String, String> metaData,
  });

  /// Mute microphone
  void muteMicrophone();

  /// Unmute microphone
  ///
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> unmuteMicrophone();

  /// Close participant device
  ///
  /// - [userID] : User ID.
  /// - [device] : Device type.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> closeParticipantDevice({
    required String userID,
    required DeviceType device,
  });

  /// Mute user
  ///
  /// - [userID] : User ID.
  /// - [disable] : Whether to mute.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> disableUserMessage({
    required String userID,
    required bool disable,
  });

  /// Disable all devices
  ///
  /// - [device] : Device type.
  /// - [disable] : Whether to disable.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> disableAllDevices({
    required DeviceType device,
    required bool disable,
  });

  /// Mute all users
  ///
  /// - [disable] : Whether to mute.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> disableAllMessages(bool disable);

  /// Request to open device
  ///
  /// - [device] : Device type.
  /// - [timeout] : Timeout (in seconds).
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> requestToOpenDevice({
    required DeviceType device,
    int timeout = 0,
  });

  /// Cancel open device request
  ///
  /// - [device] : Device type.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> cancelOpenDeviceRequest(DeviceType device);

  /// Approve open device request
  ///
  /// - [device] : Device type.
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> approveOpenDeviceRequest({
    required DeviceType device,
    required String userID,
  });

  /// Reject open device request
  ///
  /// - [device] : Device type.
  /// - [userID] : User ID.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> rejectOpenDeviceRequest({
    required DeviceType device,
    required String userID,
  });

  /// Invite to open device
  ///
  /// - [userID] : User ID.
  /// - [device] : Device type.
  /// - [timeout] : Timeout (in seconds).
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> inviteToOpenDevice({
    required String userID,
    required DeviceType device,
    int timeout = 0,
  });

  /// Cancel open device invitation
  ///
  /// - [userID] : User ID.
  /// - [device] : Device type.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> cancelOpenDeviceInvitation({
    required String userID,
    required DeviceType device,
  });

  /// Accept open device invitation
  ///
  /// - [userID] : User ID.
  /// - [device] : Device type.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> acceptOpenDeviceInvitation({
    required String userID,
    required DeviceType device,
  });

  /// Decline open device invitation
  ///
  /// - [userID] : User ID.
  /// - [device] : Device type.
  ///
  /// Returns: Operation result.
  Future<CompletionHandler> declineOpenDeviceInvitation({
    required String userID,
    required DeviceType device,
  });
}
