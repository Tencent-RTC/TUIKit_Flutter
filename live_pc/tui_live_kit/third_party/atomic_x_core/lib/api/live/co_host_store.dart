// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   CoHostStore @ AtomicXCore
// Function: Live host connection management related interfaces, managing creation, joining, leaving and other operations for host-to-host connections.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
import 'live_seat_store.dart';
// <docgen-keep-end>

/// Current user's cross-room connection status.
///
/// This enum describes the current user's cross-room connection status with other hosts.
///
/// ### Response Scenarios
///
/// | Status | Value | Description |
/// |------|------|-----------|
/// | `connected` | 0 | Currently connected with other hosts |
/// | `disconnected` | 1 | Not connected with other hosts |
enum CoHostStatus {
  /// Currently connected with other hosts.
  connected(0),

  /// Not connected with other hosts.
  disconnected(1);

  final int value;
  const CoHostStatus(this.value);
}

/// Connection layout template.
///
/// This enum defines the available layout templates for cross-room connection.
///
/// ### Response Scenarios
///
/// | Layout | Value | Description |
/// |------|------|-----------|
/// | `hostVoiceConnection` | 2 | Voice chat room connection layout |
/// | `hostVideoLandscapeFixed2Seats` | 400 | Host video landscape fixed 2 seats layout |
/// | `hostDynamicGrid` | 600 | Host dynamic grid layout |
/// | `hostDynamic1v6` | 601 | Host dynamic 1v6 layout |
/// | `hostVideoLeftFocus9Seats` | 602 | Host video left focus 9 seats layout |
/// | `hostVideoUniformGrid9Seats` | 603 | Host video uniform grid 9 seats layout |
enum CoHostLayoutTemplate {
  /// Voice chat room connection layout.
  hostVoiceConnection(2),

  /// Host video landscape fixed 2 seats layout.
  hostVideoLandscapeFixed2Seats(400),

  /// Host dynamic grid layout.
  hostDynamicGrid(600),

  /// Host dynamic 1v6 layout.
  hostDynamic1v6(601),

  /// Host video left focus 9 seats layout.
  hostVideoLeftFocus9Seats(602),

  /// Host video uniform grid 9 seats layout.
  hostVideoUniformGrid9Seats(603);

  final int value;
  const CoHostLayoutTemplate(this.value);
}

/// Cross-room connection related state data provided externally by CoHostStore.
///
/// A comprehensive snapshot of the current cross-room connection session state. This structure contains all relevant information about connection status, connected hosts, pending invitations and applications.
///
/// > **Note**: State is automatically updated when hosts join/leave connection, send/cancel invitations, or receive applications. Subscribe to [coHostState] to receive real-time updates.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [coHostStatus] | `ValueListenable<CoHostStatus>` | Real-time cross-room connection status |
/// | [connected] | `ValueListenable<List<SeatUserInfo>>` | List of hosts currently connected with current live room |
/// | [invitees] | `ValueListenable<List<SeatUserInfo>>` | List of hosts to whom requests have been sent |
/// | [applicant] | `ValueListenable<SeatUserInfo?>` | Host who initiated connection request to current live room |
/// | [candidatesCursor] | `ValueListenable<String>` | Recommended user list cursor |
/// | [candidates] | `ValueListenable<List<SeatUserInfo>>` | Recommended user list |
abstract class CoHostState {
  /// Real-time cross-room connection status.
  ValueListenable<CoHostStatus> get coHostStatus;

  /// List of hosts currently connected with current live room.
  ValueListenable<List<SeatUserInfo>> get connected;

  /// List of hosts to whom requests have been sent.
  ValueListenable<List<SeatUserInfo>> get invitees;

  /// Host who initiated connection request to current live room.
  ValueListenable<SeatUserInfo?> get applicant;

  /// Recommended user list cursor.
  ValueListenable<String> get candidatesCursor;

  /// Recommended user list.
  ValueListenable<List<SeatUserInfo>> get candidates;
}

/// Connection request callback events.
class CoHostListener {
  /// This callback is triggered when a connection request is received.
  /// - [inviter] : User information of the connection request initiator.
  /// - [extensionInfo] : Extension information.
  void Function(SeatUserInfo inviter, String extensionInfo)? onCoHostRequestReceived;

  /// This callback is triggered when a connection request is cancelled.
  /// - [inviter] : User information of the connection request initiator.
  /// - [invitee] : User information of the invitee, can be null.
  void Function(SeatUserInfo inviter, SeatUserInfo? invitee)? onCoHostRequestCancelled;

  /// This callback is triggered when a connection request is accepted.
  /// - [invitee] : User information of the user accepting the connection request.
  void Function(SeatUserInfo invitee)? onCoHostRequestAccepted;

  /// This callback is triggered when a connection request is rejected.
  /// - [invitee] : User information of the user rejecting the connection request.
  void Function(SeatUserInfo invitee)? onCoHostRequestRejected;

  /// This callback is triggered when a connection request times out.
  /// - [inviter] : User information of the connection request initiator.
  /// - [invitee] : User information of the invitee.
  void Function(SeatUserInfo inviter, SeatUserInfo invitee)? onCoHostRequestTimeout;

  /// This callback is triggered when a user joins the connection.
  /// - [userInfo] : User information of the user joining the connection.
  void Function(SeatUserInfo userInfo)? onCoHostUserJoined;

  /// This callback is triggered when a user leaves the connection.
  /// - [userInfo] : User information of the user leaving the connection.
  void Function(SeatUserInfo userInfo)? onCoHostUserLeft;

  CoHostListener({
    this.onCoHostRequestReceived,
    this.onCoHostRequestCancelled,
    this.onCoHostRequestAccepted,
    this.onCoHostRequestRejected,
    this.onCoHostRequestTimeout,
    this.onCoHostUserJoined,
    this.onCoHostUserLeft,
  });
}

/// Live host connection management related interfaces, managing creation, joining, leaving and other operations for host-to-host connections.
///
/// `CoHostStore` Manages all host-to-host connection related operations, including initiating connection requests, cancelling, accepting, rejecting and exiting connections.
/// Cross-room connection feature allows hosts from different live rooms to interact in real-time. `CoHostStore` provides a comprehensive set of APIs to manage the entire cross-room connection lifecycle.
///
/// ### Key Features
///
/// - **Bidirectional Connection**：Hosts can initiate connection requests to other hosts, and also receive connection requests from other hosts.
/// - **State Management**：Real-time tracking of connection status, connected hosts, invitation list and applicants.
/// - **Event-Driven Architecture**：Provides connection event stream for monitoring various connection state changes.
/// - **Layout Templates**：Supports multiple connection layout templates, such as dynamic grid layout and 1-to-6 layout.
///
/// > **Important**: Always use the factory method [CoHostStore.create] with a valid live room ID to create a `CoHostStore` instance. Do not attempt to initialize directly.
///
/// > **Note**: Connection state updates are delivered through the [coHostState] publisher. Subscribe to it to receive real-time updates about connection status, connected hosts, invitations and applications.
///
/// ### Cross-Room Connection Workflow
///
/// The following table shows a typical cross-room connection workflow.
///
/// | Step | Role | Action | Triggered Event |
/// |------|------|------|---------------|
/// | 1 | Host A | Call [requestHostConnection] | [CoHostListener.onCoHostRequestReceived] |
/// | 2 | Host B | Call [acceptHostConnection] | [CoHostListener.onCoHostRequestAccepted] |
/// | 3 | System | Hosts connected successfully | [CoHostListener.onCoHostUserJoined] |
///
/// ### Usage Example
///
/// ```dart
/// // Create store instance
/// final store = CoHostStore.create('live_room_123');
///
/// // Define listeners
/// late final VoidCallback statusListener = _onStatusChanged;
/// late final VoidCallback connectedListener = _onConnectedChanged;
///
/// void _onStatusChanged() {
///     print('Connection status: ${store.coHostState.coHostStatus.value}');
/// }
///
/// void _onConnectedChanged() {
///     print('Connected hosts: ${store.coHostState.connected.value.length}');
/// }
///
/// // Subscribe to state changes
/// store.coHostState.coHostStatus.addListener(statusListener);
/// store.coHostState.connected.addListener(connectedListener);
///
/// // Add connection event listener
/// final coHostListener = CoHostListener(
///     onCoHostRequestReceived: (inviter, extensionInfo) {
///         print('Received connection request from ${inviter.userName}');
///         // Show accept/reject UI
///     },
///     onCoHostRequestAccepted: (invitee) {
///         print('Connection request accepted by ${invitee.userName}');
///     },
///     onCoHostUserJoined: (userInfo) {
///         print('Host ${userInfo.userName} joined connection');
///     },
/// );
/// store.addCoHostListener(coHostListener);
///
/// // Initiate connection request
/// final result = await store.requestHostConnection(
///     targetHostLiveID: 'target_live_id',
///     layoutTemplate: CoHostLayoutTemplate.hostDynamicGrid,
///     timeout: 30,
///     extraInfo: '',
/// );
/// if (result.code == 0) {
///     print('Connection request sent successfully');
/// }
///
/// // Unsubscribe when done
/// store.coHostState.coHostStatus.removeListener(statusListener);
/// store.coHostState.connected.removeListener(connectedListener);
/// store.removeCoHostListener(coHostListener);
/// ```
///
/// ## Topics
///
/// ### Creating Instance
/// - [CoHostStore.create] : Create object instance.
///
/// ### Observing State and Events
/// - [coHostState] : Reactive state containing connection status, connected hosts, invitation list and applicants.
/// - [addCoHostListener]/[removeCoHostListener] : Connection event callbacks
///
/// ### Connection Operations
/// - [requestHostConnection] : Initiate connection request.
/// - [cancelHostConnection] : Cancel connection request.
/// - [acceptHostConnection] : Accept connection request.
/// - [rejectHostConnection] : Reject connection request.
/// - [exitHostConnection] : Exit connection.
/// - [muteRemoteHostAudio] : Mute/unmute remote host's audio.
/// - [getCoHostCandidates] : Get recommended host list.
///
/// ## See Also
///
/// - [CoHostStatus]
/// - [CoHostLayoutTemplate]
/// - [CoHostState]
/// - [CoHostListener]
abstract class CoHostStore {
  /// Cross-room connection related state data provided externally by CoHostStore.
  CoHostState get coHostState;

  /// Create CoHostStore instance
  /// - [liveID] : Live room ID.
  /// Returns: CoHostStore instance.
  static CoHostStore create(String liveID) {
    return StoreFactory.shared.getStore<CoHostStore>(roomID: liveID);
  }

  /// Initiate host connection request
  ///
  /// Initiate a cross-room connection request to target host.
  ///
  /// After calling this method, a connection request is sent to the target host. The request will remain active until:
  /// • Target host accepts via ``acceptHostConnection(fromHostLiveID:completion:)``
  /// • Target host rejects via ``rejectHostConnection(fromHostLiveID:completion:)``
  /// • Timeout expires
  /// • You cancel via ``cancelHostConnection(toHostLiveID:completion:)``
  ///
  /// - [targetHostLiveID] : Target host's live room ID.
  /// - [layoutTemplate] : Connection layout template.
  /// - [timeout] : Timeout in seconds. The maximum limit is 30 seconds.
  /// - [extraInfo] : Extension information.
  Future<CompletionHandler> requestHostConnection({
    required String targetHostLiveID,
    required CoHostLayoutTemplate layoutTemplate,
    required int timeout,
    String extraInfo = '',
  });

  /// Cancel host connection request
  ///
  /// - [toHostLiveID] : Target host's live room ID.
  Future<CompletionHandler> cancelHostConnection(String toHostLiveID);

  /// Accept host connection request
  ///
  /// - [fromHostLiveID] : Live room ID of the host initiating connection request.
  Future<CompletionHandler> acceptHostConnection(String fromHostLiveID);

  /// Reject host connection request
  ///
  /// - [fromHostLiveID] : Live room ID of the host initiating connection request.
  Future<CompletionHandler> rejectHostConnection(String fromHostLiveID);

  /// Exit host connection
  ///
  Future<CompletionHandler> exitHostConnection();

  /// Get recommended host list that can connect with current host
  ///
  /// - [cursor] : Cursor.
  Future<CompletionHandler> getCoHostCandidates(String cursor);

  /// Mute or unmute the audio of a remote host
  ///
  /// - [liveID] : Live ID of the remote host.
  /// - [isMuted] : Whether to mute the remote host's audio. `true` means mute, `false` means unmute.
  Future<CompletionHandler> muteRemoteHostAudio({
    required String liveID,
    required bool isMuted,
  });

  /// Add connection callback listener
  ///
  /// - [listener] : Listener.
  void addCoHostListener(CoHostListener listener);

  /// Remove connection callback listener
  ///
  /// - [listener] : Listener.
  void removeCoHostListener(CoHostListener listener);
}
