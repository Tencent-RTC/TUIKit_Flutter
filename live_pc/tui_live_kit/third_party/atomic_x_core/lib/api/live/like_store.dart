// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LikeStore @ AtomicXCore
// Function: Like related interfaces, managing like sending, like state synchronization, and like event listening operations in live rooms/voice chat rooms.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
import 'live_audience_store.dart';
// <docgen-keep-end>

/// Like state, used to display and subscribe to like information in live rooms/voice chat rooms.
///
/// Contains the total accumulated like count of the current live room/voice chat room, supporting real-time updates.
///
/// > **Note**: Like count updates automatically. Subscribe to [likeState] to receive real-time updates.
///
/// ### State Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [totalLikeCount] | `ValueListenable<int>` | Total accumulated like count of the current room |
abstract class LikeState {
  /// Total accumulated like count of the current live room/voice chat room, supporting real-time updates and subscription listening.
  ValueListenable<int> get totalLikeCount;
}

/// Like event, used to receive like dynamics in live rooms/voice chat rooms.
///
/// This listener is used to receive like dynamics in live rooms/voice chat rooms.
///
/// > **Note**: When an audience sends likes, the [onReceiveLikesMessage] callback will be triggered.
///
/// ### Event Description
///
/// | Event | Trigger Condition | Callback Parameters |
/// |------|-----------------|-------------------|
/// | `onReceiveLikesMessage` | Received new like message | liveID, totalLikesReceived, sender |
class LikeListener {
  /// Event callback for receiving new like messages. When other audiences send likes in the live room/voice chat room, this event will be triggered and return relevant information.
  /// - [liveID] : Live room ID.
  /// - [totalLikesReceived] : Number of new likes received this time.
  /// - [sender] : Like sender information.
  void Function(String liveID, int totalLikesReceived, LiveUserInfo sender)? onReceiveLikesMessage;

  LikeListener({this.onReceiveLikesMessage});
}

/// Like related interfaces, managing like sending, like state synchronization, and like event listening operations in live rooms/voice chat rooms.
///
/// `LikeStore` Like management class for handling like-related business logic in live rooms/voice chat rooms.
/// `LikeStore` provides a complete set of like management APIs, including sending likes, listening to like events, and getting like states. Through this class, you can implement like interaction features in live rooms.
///
/// ### Key Features
///
/// - **Like Sending**：Support sending likes to the current room.
/// - **Like State**：Get the accumulated like count of the current room.
/// - **Event Listening**：Listen to like receiving events.
///
/// > **Important**: Use the [create] factory method to create a `LikeStore` instance, which requires a valid live room ID.
///
/// > **Note**: Like state updates are delivered through the [likeState] publisher. Subscribe to it to receive real-time updates of like data in the room.
///
/// ### Like Operations Overview
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Send Like | [sendLike] | Send likes to the current room |
/// | Get State | [likeState] | Get the like state of the current room |
/// | Add Listener | [addLikeListener] | Add like event listener |
/// | Remove Listener | [removeLikeListener] | Remove like event listener |
///
/// ## Topics
///
/// ### Creating Instance
/// - [create] - Create like management instance
///
/// ### Observing State and Events
/// - [likeState] - Like state of the current room
/// - [addLikeListener]/[removeLikeListener] - Like event callbacks
///
/// ### Like Operations
/// - [sendLike] - Send likes
///
/// ## See Also
///
/// - [LikeState]
/// - [LikeListener]
abstract class LikeStore {
  /// Like state subscription for the current room, containing information such as accumulated like count. By subscribing to this state, you can get real-time updates of like data in the room.
  LikeState get likeState;

  /// Create a like management instance.
  /// - [liveID] : Live room ID.
  /// Returns: Like management instance for the specified room.
  static LikeStore create(String liveID) {
    return StoreFactory.shared.getStore<LikeStore>(roomID: liveID);
  }

  /// Send likes to the current room. All users who have subscribed to like events will receive this like notification.
  ///
  /// - [count] : Like count, default is 1.
  Future<CompletionHandler> sendLike(int count);

  /// Add like event listener
  ///
  /// - [listener] : Listener.
  void addLikeListener(LikeListener listener);

  /// Remove like event listener
  ///
  /// - [listener] : Listener.
  void removeLikeListener(LikeListener listener);
}
