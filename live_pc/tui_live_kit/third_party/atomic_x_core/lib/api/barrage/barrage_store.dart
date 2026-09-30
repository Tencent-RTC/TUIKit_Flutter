// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   BarrageStore @ AtomicXCore
// Function: Barrage related interfaces, managing barrage sending, barrage state synchronization, and barrage event listening in live rooms/voice chat rooms.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
import '../live/live_audience_store.dart';
// <docgen-keep-end>

/// Barrage type enumeration, used to distinguish different barrage message types.
///
/// Defines the type of barrage, including text barrage and custom barrage.
///
/// > **Note**: Use the `parse(value)` static method to convert an integer value to the corresponding enum type.
///
/// ### Barrage Type List
///
/// | Type | Value | Description |
/// |------|------|-----------|
/// | [text] | 0 | Text type barrage | contains plain text content |
/// | [custom] | 1 | Custom type barrage | supports business custom data format |
enum BarrageType {
  /// Text type barrage, contains plain text content.
  text(0),

  /// Custom type barrage, supports business custom data format (such as barrages with special effects, interactive messages, etc.).
  custom(1);

  final int value;

  const BarrageType(this.value);
}

/// Barrage data model, containing complete attribute information of a single barrage.
///
/// Contains complete information about the barrage sender, content, type, etc.
///
/// ### Property Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [liveID] | `String` | Unique identifier ID of the live room/voice chat room the barrage belongs to |
/// | [sender] | `LiveUserInfo` | User information of the barrage sender |
/// | [sequence] | `int` | Unique sequence ID of the barrage message |
/// | [timestampInSecond] | `int` | Barrage sending timestamp (unit: seconds) |
/// | [messageType] | `BarrageType` | Barrage message type (text or custom) |
/// | [textContent] | `String` | Message content of text type barrage |
/// | [extensionInfo] | `Map<String, String>` | Barrage extension information |
/// | [businessID] | `String` | Business identifier ID of custom type barrage |
/// | [data] | `String` | Specific data content of custom type barrage |
class Barrage {
  /// Unique identifier ID of the live room/voice chat room the barrage belongs to.
  String liveID;

  /// User information of the barrage sender (such as user ID, nickname, avatar, etc.).
  LiveUserInfo sender;

  /// Unique sequence ID of the barrage message, used for message sorting and deduplication.
  int sequence;

  /// Barrage sending timestamp (unit: seconds), used to display sending time order.
  int timestampInSecond;

  /// Barrage message type (text or custom).
  BarrageType messageType;

  /// Message content of text type barrage, i.e., the text content of the barrage.
  String textContent;

  /// Barrage extension information, customizable fields (such as display style, priority, etc.). Valid when messageType is TEXT.
  Map<String, String> extensionInfo;

  /// Business identifier ID of custom type barrage, used to distinguish custom barrages from different business scenarios.
  String businessID;

  /// Specific data content of custom type barrage (usually JSON format string), valid when messageType is CUSTOM.
  String data;

  Barrage({
    this.liveID = '',
    LiveUserInfo? sender,
    this.sequence = 0,
    this.timestampInSecond = 0,
    this.messageType = BarrageType.text,
    this.textContent = '',
    Map<String, String>? extensionInfo,
    this.businessID = '',
    this.data = '',
  })  : sender = sender ?? LiveUserInfo(),
        extensionInfo = extensionInfo ?? {};
}

/// Barrage state, managing the barrage data state of the current room.
///
/// Contains the barrage message list of the current room, supports real-time updates.
///
/// > **Note**: Subscribe to [barrageState] to receive real-time updates of barrage data in the room.
///
/// ### State Property Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [messageList] | `ValueListenable<List<Barrage>>` | Barrage message list of the current room |
/// | [isMessageDisable] | `ValueListenable<bool>` | Whether messages are disabled for all users in the current room |
abstract class BarrageState {
  /// Barrage message list of the current room, supports real-time updates and can be subscribed to.
  ValueListenable<List<Barrage>> get messageList;

  /// Whether messages are disabled for all users in the current room, supports real-time updates and can be subscribed to.
  ValueListenable<bool> get isMessageDisable;
}

/// Barrage event listener.
///
///
/// ### Callback Overview
///
/// | Callback | Type | Description |
/// |--------|------|-----------|
/// | [onCustomMessageReceived] | `void Function(Barrage)?` | Callback triggered when a custom barrage message is received |
class BarrageListener {
  /// Callback triggered when a custom barrage message is received.
  void Function(Barrage barrage)? onCustomMessageReceived;

  BarrageListener({this.onCustomMessageReceived});
}

/// Barrage related interfaces, managing barrage sending, barrage state synchronization, and barrage event listening in live rooms/voice chat rooms.
///
/// `BarrageStore` Barrage management class for handling barrage related business logic in live rooms/voice chat rooms.
/// `BarrageStore` provides a complete set of barrage management APIs, including sending text barrages, sending custom barrages, and adding local tip messages.
/// Through this class, you can implement barrage interaction functionality in live rooms.
///
/// ### Key Features
///
/// - **Text Barrage**：Supports sending plain text barrage messages.
/// - **Custom Barrage**：Supports sending custom format barrages (such as barrages with special effects).
/// - **Local Tips**：Supports adding tip messages visible only locally.
///
/// > **Important**: Use the [create] factory method to create a `BarrageStore` instance, which requires a valid live room ID.
///
/// > **Note**: Barrage state updates are delivered through the [barrageState] publisher. Subscribe to it to receive real-time updates of barrage data in the room.
///
/// ### Barrage Type Description
///
/// | Type | Enum Value | Description |
/// |------|----------|-----------|
/// | [BarrageType.text] | 0 | Text type barrage | contains plain text content |
/// | [BarrageType.custom] | 1 | Custom type barrage | supports business custom data format |
///
/// ## Topics
///
/// ### Creating Instance
/// - [create] : Create barrage management instance.
///
/// ### Observing State
/// - [barrageState] : Barrage state data.
///
/// ### Events Handling
/// - [addBarrageListener] : Add barrage event listener to receive custom messages.
/// - [removeBarrageListener] : Remove barrage event listener.
///
/// ### Sending Barrage
/// - [sendTextMessage] : Send text barrage.
/// - [sendCustomMessage] : Send custom barrage.
///
/// ### Message Management
/// - [setMessageDisable] : Enable or disable messages for all users in the room.
///
/// ### Local Messages
/// - [appendLocalTip] : Add local tip message.
///
/// ## See Also
///
/// - [BarrageType]
/// - [Barrage]
/// - [BarrageState]
/// - [BarrageListener]
abstract class BarrageStore {
  /// Barrage state subscription of the current room, including barrage message list and other information. By subscribing to this state, you can get real-time updates of barrage data in the room.
  BarrageState get barrageState;

  /// Barrage management core class for handling barrage related business logic in live rooms/voice chat rooms.
  /// - [liveID] : Live room ID.
  /// Returns: Barrage management instance for the specified room.
  static BarrageStore create(String liveID) {
    return StoreFactory.shared.getStore<BarrageStore>(roomID: liveID);
  }

  /// Send a text type barrage. After sending successfully, the receiver can obtain barrage messages by subscribing to messageList in BarrageState in advance.
  ///
  /// - [text] : Text barrage content.
  /// - [extensionInfo] : Extension information, can contain custom fields (such as specifying barrage color, font size, etc.).
  Future<CompletionHandler> sendTextMessage({
    required String text,
    Map<String, String>? extensionInfo,
  });

  /// Send a custom type barrage message. After sending successfully, the receiver can receive custom messages by subscribing to the addBarrageListener provided by BarrageStore.
  ///
  /// - [businessID] : Business identifier ID, used to distinguish custom barrages from different business scenarios.
  /// - [data] : Custom data content, usually JSON format string, used to pass business custom data.
  Future<CompletionHandler> sendCustomMessage({
    required String businessID,
    required String data,
  });

  /// Enable or disable messages for all users in the room. After setting successfully, the latest state can be observed by subscribing to isMessageDisable in BarrageState.
  ///
  /// - [disable] : `true` to disable messages for all users, `false` to allow them.
  Future<CompletionHandler> setMessageDisable(bool disable);

  /// Add local tip message (add tip or operation feedback message locally, visible only to the current client).
  ///
  /// > **Tip**: This message is only displayed locally and will not be sent to other users through the network.
  ///
  /// - [message] : Local barrage message (such as system tips, operation feedback, etc., visible only to the current user).
  void appendLocalTip(Barrage message);

  /// Add barrage event listener.
  ///
  /// - [listener] : Barrage event listener instance.
  void addBarrageListener(BarrageListener listener);

  /// Remove barrage event listener.
  ///
  /// - [listener] : Barrage event listener instance to be removed.
  void removeBarrageListener(BarrageListener listener);
}
