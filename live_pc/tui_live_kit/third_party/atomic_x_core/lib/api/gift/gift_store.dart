// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   GiftStore @ AtomicXCore
// Function: Gift-related interface, managing gift sending, gift state synchronization, and gift event listening in live rooms/voice chat rooms.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/common/store_factory.dart';
// <docgen-keep-end>

/// Gift data model, containing complete attribute information of a single gift.
///
/// Contains complete information about the gift including ID, name, description, icon, animation resource, etc.
///
/// ### Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [giftID] | `String` | Gift ID |
/// | [name] | `String` | Gift name |
/// | [desc] | `String` | Gift description |
/// | [iconURL] | `String` | Network URL of the gift icon image |
/// | [resourceURL] | `String` | Network URL of the gift animation resource file |
/// | [level] | `int` | Gift level |
/// | [coins] | `int` | Gift price (coins) |
/// | [extensionInfo] | `Map<String, String>` | Gift extension information |
class Gift {
  /// Gift ID.
  final String giftID;

  /// Gift name.
  final String name;

  /// Gift description.
  final String desc;

  /// Network URL of the gift icon image, used to load gift thumbnails.
  final String iconURL;

  /// Network URL of the gift animation resource file, used to load gift display animations.
  final String resourceURL;

  /// Gift level, used to distinguish gift rarity or value tier.
  final int level;

  /// Gift price (coins).
  final int coins;

  /// Gift extension information, customizable fields (such as effect type, sending restrictions, etc.).
  final Map<String, String> extensionInfo;

  Gift({
    this.giftID = '',
    this.name = '',
    this.desc = '',
    this.iconURL = '',
    this.resourceURL = '',
    this.level = 0,
    this.coins = 0,
    this.extensionInfo = const {},
  });
}

/// Gift category.
///
/// Contains gift category ID, name, description, and the gift list under this category.
///
/// ### Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [categoryID] | `String` | Category unique identifier ID |
/// | [name] | `String` | Category display name |
/// | [desc] | `String` | Category description information |
/// | [extensionInfo] | `Map<String, String>` | Category extension information |
/// | [giftList] | `List<Gift>` | All gifts under the current category |
class GiftCategory {
  /// Category unique identifier ID, used to distinguish different gift categories.
  final String categoryID;

  /// Category display name, used for UI category display (such as "Popular Gifts", "Premium Gifts").
  final String name;

  /// Category description information, used to explain the characteristics of this category.
  final String desc;

  /// Category extension information, containing custom fields (such as sorting weight, display style, etc.).
  final Map<String, String> extensionInfo;

  /// All gifts under the current category.
  final List<Gift> giftList;

  GiftCategory({
    this.categoryID = '',
    this.name = '',
    this.desc = '',
    this.extensionInfo = const {},
    this.giftList = const [],
  });
}

/// Gift statistics information, containing gift sending statistics for a receiver.
///
/// Contains the total gifts sent, total coins, and unique sender count for a specific receiver.
///
/// ### Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [receiver] | `String` | Receiver account ID |
/// | [totalGiftCount] | `int` | Total number of gifts sent |
/// | [totalGiftCoins] | `int` | Total gift coins value |
/// | [totalGiftSendersCount] | `int` | Total number of unique gift senders |
class GiftStatisticInfo {
  /// Receiver account ID.
  final String receiver;

  /// Total number of gifts sent to this receiver.
  final int totalGiftCount;

  /// Total gift coins value.
  final int totalGiftCoins;

  /// Total number of unique gift senders.
  final int totalGiftSendersCount;

  GiftStatisticInfo({
    this.receiver = '',
    this.totalGiftCount = 0,
    this.totalGiftCoins = 0,
    this.totalGiftSendersCount = 0,
  });
}

/// Gift state, managing the gift data state of the current room, supporting real-time updates and subscription listening.
///
/// Contains all gift categories and gift lists available in the current room, supporting real-time updates.
///
/// > **Note**: Gift state is automatically updated. Subscribe to [giftState] to receive real-time updates.
///
/// ### Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [usableGifts] | `ValueListenable<List<GiftCategory>>` | All gift categories and gift lists available in the current room |
/// | [isGiftEnabled] | `ValueListenable<bool>` | Whether the gift feature is enabled in the current room |
/// | [userGiftStatisticsList] | `ValueListenable<List<GiftStatisticInfo>>` | Gift statistics list for all receivers |
abstract class GiftState {
  /// All gift categories and gift lists available in the current room.
  ValueListenable<List<GiftCategory>> get usableGifts;

  /// Whether the gift feature is enabled in the current room, supports real-time updates and can be subscribed to.
  ValueListenable<bool> get isGiftEnabled;

  /// Gift statistics list for all receivers.
  ValueListenable<List<GiftStatisticInfo>> get userGiftStatisticsList;
}

/// Gift event, used to receive gift dynamics in live rooms/voice chat rooms.
class GiftListener {
  /// Event callback when receiving a new gift message. This event is triggered when other viewers send gifts in the live room/voice chat room, returning relevant information.
  /// - [liveID] : Live room ID.
  /// - [gift] : Gift information.
  /// - [count] : Gift count.
  /// - [sender] : Gift sender information.
  @Deprecated('Use onReceiveGiftWithReceiver instead.')
  void Function(String liveID, Gift gift, int count, LiveUserInfo sender)? onReceiveGift;

  /// Event callback when receiving a new gift message, including the gift receiver. This event is triggered when other viewers send gifts in the live room/voice chat room, returning relevant information.
  /// - [liveID] : Live room ID.
  /// - [gift] : Gift information.
  /// - [count] : Gift count.
  /// - [sender] : Gift sender information.
  /// - [receiver] : Gift receiver information.
  void Function(String liveID, Gift gift, int count, LiveUserInfo sender, LiveUserInfo? receiver)?
      onReceiveGiftWithReceiver;

  GiftListener({this.onReceiveGift, this.onReceiveGiftWithReceiver});
}

/// Gift-related interface, managing gift sending, gift state synchronization, and gift event listening in live rooms/voice chat rooms.
///
/// `GiftStore` Gift management class for handling gift-related business logic in live rooms/voice chat rooms.
/// `GiftStore` provides a complete set of gift management APIs, including sending gifts, refreshing gift lists, setting language, and listening to gift events.
/// Through this class, gift interaction features can be implemented in live rooms.
///
/// ### Key Features
///
/// - **Gift Sending**：Support sending specified gifts to the current room.
/// - **Gift List**：Get and refresh the available gift list in the current room.
/// - **Language Setting**：Set the display language for gift information.
/// - **Event Listening**：Listen to gift receiving events.
///
/// > **Important**: Use the [GiftStore.create] factory method to create a `GiftStore` instance, passing a valid live room ID.
///
/// > **Note**: Gift state updates are delivered through the [giftState] publisher. Subscribe to it to receive real-time updates of gift data in the room.
///
/// ### Gift Operations Overview
///
/// | Feature | Method | Description |
/// |-------|------|-----------|
/// | Create Instance | [GiftStore.create] | Create a gift management instance for the specified room |
/// | Send Gift | [sendGift] | Send a specified gift to the current room |
/// | Refresh List | [refreshUsableGifts] | Manually refresh the available gift list in the current room |
/// | Language Setting | [setLanguage] | Set the display language for gift information |
/// | Event Listening | [addGiftListener]/[removeGiftListener] | Add/remove gift event listeners |
///
/// ## Topics
///
/// ### Creating Instance
/// - [GiftStore.create] : Create gift management instance.
///
/// ### Observing State and Events
/// - [giftState] : Reactive state containing available gift list.
/// - [addGiftListener]/[removeGiftListener] : Gift event callbacks
///
/// ### Gift Operations
/// - [sendGift] : Send gift.
/// - [refreshUsableGifts] : Refresh available gift list.
/// - [setLanguage] : Set display language.
///
/// ## See Also
///
/// - [Gift]
/// - [GiftCategory]
/// - [GiftState]
/// - [GiftStatisticInfo]
/// - [GiftListener]
abstract class GiftStore {
  /// Gift state subscription for the current room, containing information such as available gift list. By subscribing to this state, real-time updates of gift data in the room can be obtained.
  GiftState get giftState;

  /// Gift event publisher. Through this publisher, you can subscribe to/remove gift events in live rooms/voice chat rooms. After subscribing, you will receive corresponding notifications when viewers send gifts.
  void addGiftListener(GiftListener listener);

  void removeGiftListener(GiftListener listener);

  /// Create gift management instance.
  /// - [liveID] : Live room ID.
  /// Returns: Gift management instance for the specified room.
  static GiftStore create(String liveID) {
    return StoreFactory.shared.getStore<GiftStore>(roomID: liveID);
  }

  /// Set the display language for gift information.
  ///
  /// - [language] : Language code ("zh-CN" for Chinese, "en" for English). After setting, gift names, descriptions, etc. will be updated to the corresponding language when the display interface is refreshed.
  void setLanguage(String language);

  /// Manually refresh the available gift list in the current room.
  ///
  Future<CompletionHandler> refreshUsableGifts();

  /// Send a specified gift to the current room
  ///
  /// - [giftID] : Unique identifier ID of the gift to send.
  /// - [count] : Number of gifts to send at once.
  /// - [receiver] : Receiver's user ID.
  Future<CompletionHandler> sendGift({
    required String giftID,
    required int count,
    String receiver = '',
  });

  /// Enable or disable the gift feature in the current room.
  ///
  /// - [enabled] : `true` to enable the gift feature, `false` to disable it. The latest value can be observed through [GiftState.isGiftEnabled].
  Future<CompletionHandler> setGiftEnabled(bool enabled);
}
