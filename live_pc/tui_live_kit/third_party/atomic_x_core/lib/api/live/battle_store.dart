// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   BattleStore @ AtomicXCore
// Function: Live PK management APIs for creating, joining, and leaving PK sessions.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
import 'live_seat_store.dart';
// <docgen-keep-end>

/// Reason for PK ending received by users in an ongoing PK.
///
/// This enum describes the reasons for PK ending.
///
/// > **Note**: When the PK countdown ends or all members exit, the system will automatically trigger the PK end event.
///
/// ### Response Scenarios
///
/// | Reason | Value | Description |
/// |------|------|-----------|
/// | `timeOver` | 0 | PK countdown ended |
/// | `allMemberExit` | 1 | All PK members exited |
enum BattleEndedReason {
  /// PK countdown ended.
  timeOver(0),

  /// All PK members exited.
  allMemberExit(1);

  final int value;
  const BattleEndedReason(this.value);
}

/// PK configuration information set when sending a PK request.
///
/// PK configuration information for setting PK duration, whether response is needed, and other parameters.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [duration] | `int` | {'PK duration (unit': 'seconds)'} |
/// | [needResponse] | `bool` | Whether the invitee needs to reply with accept/reject |
/// | [extensionInfo] | `String` | Extension information |
class BattleConfig {
  /// PK duration (unit: seconds).
  int duration;

  /// Whether the invitee needs to reply with accept/reject.
  bool needResponse;

  /// Extension information.
  String extensionInfo;

  BattleConfig({
    this.duration = 0,
    this.needResponse = false,
    this.extensionInfo = '',
  });
}

/// PK information.
///
/// PK information, containing PK ID, configuration information, start time, and end time.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [battleID] | `String` | PK ID |
/// | [config] | [BattleConfig] | PK configuration information |
/// | [startTime] | `int` | {'PK start timestamp (unit': 'seconds)'} |
/// | [endTime] | `int` | {'PK end timestamp (unit': 'seconds)'} |
class BattleInfo {
  /// PK ID.
  final String battleID;

  /// PK configuration information set when sending a PK request.
  final BattleConfig config;

  /// PK start marker timestamp (unit: seconds).
  final int startTime;

  /// PK end marker timestamp (unit: seconds).
  final int endTime;

  BattleInfo({
    this.battleID = '',
    BattleConfig? config,
    this.startTime = 0,
    this.endTime = 0,
  }) : config = config ?? BattleConfig();
}

/// PK-related state data provided by BattleStore.
///
/// A comprehensive snapshot of the current PK session state. This structure contains all relevant information about current PK information, participating users, and scores.
///
/// > **Note**: State is automatically updated when PK starts/ends, users join/exit PK, or scores are updated. Subscribe to [battleState] to receive real-time updates.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [currentBattleInfo] | `ValueListenable<BattleInfo?>` | Current PK information |
/// | [battleUsers] | `ValueListenable<List<SeatUserInfo>>` | PK user list |
/// | [battleScore] | `ValueListenable<Map<String, int>>` | PK score mapping |
abstract class BattleState {
  /// Current PK information.
  ValueListenable<BattleInfo?> get currentBattleInfo;

  /// PK user list.
  ValueListenable<List<SeatUserInfo>> get battleUsers;

  /// PK score mapping.
  ValueListenable<Map<String, int>> get battleScore;
}

/// PK-related callback events received.
class BattleListener {
  /// This callback is triggered when PK officially starts, notifying all participants that PK has begun.
  /// - [battleInfo] : PK information, containing detailed configuration and status of the PK.
  /// - [inviter] : User information of the PK initiator.
  /// - [invitees] : List of users invited to participate in PK.
  final void Function(BattleInfo battleInfo, SeatUserInfo inviter, List<SeatUserInfo> invitees)? onBattleStarted;

  /// This callback is triggered when PK ends.
  /// - [battleInfo] : PK information.
  /// - [reason] : Reason for PK ending.
  final void Function(BattleInfo battleInfo, BattleEndedReason reason)? onBattleEnded;

  /// This callback is triggered when a user joins PK.
  /// - [battleID] : PK ID.
  /// - [battleUser] : User information of the user joining PK.
  final void Function(String battleID, SeatUserInfo battleUser)? onUserJoinBattle;

  /// This callback is triggered when a user exits PK.
  /// - [battleID] : PK ID.
  /// - [battleUser] : User information of the user exiting PK.
  final void Function(String battleID, SeatUserInfo battleUser)? onUserExitBattle;

  /// This callback is triggered when a PK request is received.
  /// - [battleID] : PK ID.
  /// - [inviter] : User information of the request initiator.
  /// - [invitee] : User information of the invitee.
  final void Function(String battleID, SeatUserInfo inviter, SeatUserInfo invitee)? onBattleRequestReceived;

  /// This callback is triggered when a PK request is cancelled.
  /// - [battleID] : PK ID.
  /// - [inviter] : User information of the request initiator.
  /// - [invitee] : User information of the invitee.
  final void Function(String battleID, SeatUserInfo inviter, SeatUserInfo invitee)? onBattleRequestCancelled;

  /// This callback is triggered when a PK request times out.
  /// - [battleID] : PK ID.
  /// - [inviter] : User information of the request initiator.
  /// - [invitee] : User information of the invitee.
  final void Function(String battleID, SeatUserInfo inviter, SeatUserInfo invitee)? onBattleRequestTimeout;

  /// This callback is triggered when a PK request is accepted.
  /// - [battleID] : PK ID.
  /// - [inviter] : User information of the request initiator.
  /// - [invitee] : User information of the invitee.
  final void Function(String battleID, SeatUserInfo inviter, SeatUserInfo invitee)? onBattleRequestAccept;

  /// This callback is triggered when a PK request is rejected.
  /// - [battleID] : PK ID.
  /// - [inviter] : User information of the request initiator.
  /// - [invitee] : User information of the invitee.
  final void Function(String battleID, SeatUserInfo inviter, SeatUserInfo invitee)? onBattleRequestReject;

  const BattleListener({
    this.onBattleStarted,
    this.onBattleEnded,
    this.onUserJoinBattle,
    this.onUserExitBattle,
    this.onBattleRequestReceived,
    this.onBattleRequestCancelled,
    this.onBattleRequestTimeout,
    this.onBattleRequestAccept,
    this.onBattleRequestReject,
  });
}

/// PK request completion handler.
///
/// Completion handler for PK requests in Dart, containing the result of the PK request.
class BattleRequestCompletionHandler extends CompletionHandler {
  /// PK information returned on success.
  BattleInfo? battleInfo;

  /// Response result mapping for PK request.
  Map<String, int>? resultMap;
}

/// Live PK management APIs for creating, joining, and leaving PK sessions.
///
/// `BattleStore` Manages all PK-related operations between hosts,
/// including initiating, accepting, rejecting, and exiting processes.
/// PK feature enables real-time interactive battles between hosts. `BattleStore` provides a comprehensive set of APIs to manage the entire PK lifecycle.
///
/// ### Key Features
///
/// - **PK Request Management**：Hosts can initiate PK requests, and invitees can accept or reject.
/// - **State Management**：Real-time tracking of PK information, participating users, and scores.
/// - **Event-Driven Architecture**：Provides complete PK event callbacks.
/// - **Timeout Handling**：Built-in timeout mechanism for PK requests.
///
/// > **Important**: Always use the factory method [BattleStore.create] with a valid live room ID to create a `BattleStore` instance. Do not attempt to initialize directly.
///
/// > **Note**: PK state updates are delivered through the [battleState] publisher. Subscribe to it to receive real-time updates about PK information, participating users, and scores.
///
/// ### PK Workflow
///
/// The following table shows a typical PK workflow.
///
/// | Step | Role | Action | Triggered Event |
/// |------|------|------|---------------|
/// | 1 | Host A | Call [requestBattle] | [BattleListener.onBattleRequestReceived] |
/// | 2 | Host B | Call [acceptBattle] | [BattleListener.onBattleRequestAccept] |
/// | 3 | System | PK starts | [BattleListener.onBattleStarted] |
///
/// ### Usage Example
///
/// ```dart
/// // Create store instance
/// final store = BattleStore.create('live_room_123');
///
/// // Define listeners
/// late final VoidCallback battleInfoListener = _onBattleInfoChanged;
/// late final VoidCallback battleUsersListener = _onBattleUsersChanged;
///
/// void _onBattleInfoChanged() {
///     final battleInfo = store.battleState.currentBattleInfo.value;
///     if (battleInfo != null) {
///         print('Current PK ID: ${battleInfo.battleID}');
///     }
/// }
///
/// void _onBattleUsersChanged() {
///     print('PK user count: ${store.battleState.battleUsers.value.length}');
/// }
///
/// // Subscribe to state changes
/// store.battleState.currentBattleInfo.addListener(battleInfoListener);
/// store.battleState.battleUsers.addListener(battleUsersListener);
///
/// // Add PK event listener
/// final battleListener = BattleListener(
///     onBattleStarted: (battleInfo, inviter, invitees) {
///         print('PK started, initiator: ${inviter.userName}');
///     },
///     onBattleEnded: (battleInfo, reason) {
///         print('PK ended, reason: $reason');
///     },
/// );
/// store.addBattleListener(battleListener);
///
/// // Initiate PK request
/// final config = BattleConfig(duration: 300, needResponse: true);
/// final result = await store.requestBattle(
///     config: config,
///     userIDList: ['user_456'],
///     timeout: 30,
/// );
/// if (result.code == 0) {
///     print('PK request successful: ${result.battleInfo?.battleID}');
/// } else {
///     print('PK request failed: ${result.message}');
/// }
///
/// // Unsubscribe when done
/// store.battleState.currentBattleInfo.removeListener(battleInfoListener);
/// store.battleState.battleUsers.removeListener(battleUsersListener);
/// store.removeBattleListener(battleListener);
/// ```
///
/// ## Topics
///
/// ### Creating Instance
/// - [BattleStore.create] : Create BattleStore instance.
///
/// ### Observing State and Events
/// - [battleState] : PK state data.
/// - [addBattleListener]/[removeBattleListener] : PK event callbacks.
///
/// ### PK Operations
/// - [requestBattle] : Initiate PK request.
/// - [cancelBattleRequest] : Cancel PK request.
/// - [acceptBattle] : Accept PK request.
/// - [rejectBattle] : Reject PK request.
/// - [exitBattle] : Exit PK.
///
/// ## See Also
///
/// - [BattleEndedReason]
/// - [BattleConfig]
/// - [BattleInfo]
/// - [BattleState]
/// - [BattleListener]
abstract class BattleStore {
  /// PK state.
  BattleState get battleState;

  /// Create BattleStore instance
  /// - [liveID] : Live room ID.
  /// Returns: BattleStore instance.
  static BattleStore create(String liveID) {
    return StoreFactory.shared.getStore<BattleStore>(roomID: liveID);
  }

  /// Initiate PK request
  ///
  /// - [config] : PK configuration.
  /// - [userIDList] : List of user IDs to invite for PK. Please pass in the user IDs of the other hosts you wish to PK with. Note: do not include the current user's own ID in this list.
  /// - [timeout] : Timeout in seconds. The maximum limit is 30 seconds.
  Future<BattleRequestCompletionHandler> requestBattle({
    required BattleConfig config,
    required List<String> userIDList,
    required int timeout,
  });

  /// Cancel PK request
  ///
  /// - [battleID] : PK ID.
  /// - [userIDList] : User ID list.
  Future<CompletionHandler> cancelBattleRequest({
    required String battleID,
    required List<String> userIDList,
  });

  /// Accept PK request
  ///
  /// - [battleID] : PK ID.
  Future<CompletionHandler> acceptBattle(String battleID);

  /// Reject PK request
  ///
  /// - [battleID] : PK ID.
  Future<CompletionHandler> rejectBattle(String battleID);

  /// Exit PK
  ///
  /// - [battleID] : PK ID.
  Future<CompletionHandler> exitBattle(String battleID);

  /// Add PK callback listener
  ///
  /// - [listener] : Listener.
  void addBattleListener(BattleListener listener);

  /// Remove PK callback listener
  ///
  /// - [listener] : Listener.
  void removeBattleListener(BattleListener listener);
}
