library;

import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../live_kit_resources.dart';

/// Settles received gift combos into local barrages for both live entries.
class GiftBarrageStore with WidgetsBindingObserver {
  GiftBarrageStore({required this.liveID, GiftStore? giftStore})
      : _providedGiftStore = giftStore;

  final String liveID;
  final GiftStore? _providedGiftStore;
  ValueChanged<LiveGiftBarrage>? onGiftBarrageSettled;

  GiftStore? _giftStore;
  GiftListener? _listener;
  bool _isEnabled = false;
  bool _isApplicationActive = false;
  int _collectionID = 0;
  final Map<(String, String), _PendingGiftBarrage> _pendingBarrages = {};

  void activate() {
    if (_giftStore != null || liveID.isEmpty) return;
    _giftStore = _providedGiftStore ?? GiftStore.create(liveID);
    _giftStore!.setLanguage(LiveKitResources.giftLanguageCode);
    _isEnabled = true;
    final state = WidgetsBinding.instance.lifecycleState;
    _isApplicationActive = state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden &&
        state != AppLifecycleState.detached;
    WidgetsBinding.instance.addObserver(this);
    _updateCollection();
  }

  void deactivate() {
    WidgetsBinding.instance.removeObserver(this);
    _isEnabled = false;
    _isApplicationActive = false;
    _updateCollection();
    _giftStore = null;
  }

  void setEnabled(bool enabled) {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    _updateCollection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setApplicationActive(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _setApplicationActive(false);
    }
  }

  void _setApplicationActive(bool active) {
    if (_isApplicationActive == active) return;
    _isApplicationActive = active;
    _updateCollection();
  }

  void dispose() {
    onGiftBarrageSettled = null;
    deactivate();
  }

  void _updateCollection() {
    _collectionID += 1;
    final oldListener = _listener;
    if (oldListener != null) _giftStore?.removeGiftListener(oldListener);
    _listener = null;
    for (final pending in _pendingBarrages.values) {
      pending.timer?.cancel();
    }
    _pendingBarrages.clear();
    if (!_isEnabled || !_isApplicationActive || _giftStore == null) return;

    final collectionID = _collectionID;
    final listener =
        GiftListener(onReceiveGift: (eventLiveID, gift, count, sender) {
      if (_collectionID != collectionID ||
          eventLiveID != liveID ||
          count <= 0) {
        return;
      }
      _receive(gift, count, sender);
    });
    _listener = listener;
    _giftStore!.addGiftListener(listener);
  }

  void _receive(Gift gift, int count, LiveUserInfo sender) {
    final key = (sender.userID, gift.giftID);
    final pending = _pendingBarrages[key] ?? _PendingGiftBarrage(gift, sender);
    const maxInt = 0x7FFFFFFFFFFFFFFF;
    pending.count =
        pending.count > maxInt - count ? maxInt : pending.count + count;
    pending.timer?.cancel();
    pending.timer = Timer(const Duration(seconds: 2), () {
      _pendingBarrages.remove(key);
      onGiftBarrageSettled?.call(LiveGiftBarrage(
        giftID: pending.gift.giftID,
        giftName: pending.gift.name,
        giftIconURL: pending.gift.iconURL,
        count: pending.count,
        senderID: pending.senderID,
        senderName: pending.senderName,
        senderLevel: pending.senderLevel,
      ));
    });
    _pendingBarrages[key] = pending;
  }
}

class _PendingGiftBarrage {
  _PendingGiftBarrage(this.gift, LiveUserInfo sender)
      : senderID = sender.userID,
        senderName = sender.userName,
        senderLevel = sender.level;

  final Gift gift;
  final String senderID;
  final String senderName;
  final int senderLevel;
  int count = 0;
  Timer? timer;
}

/// AtomicXCore 礼物事件在本地结算后生成的弹幕。
///
/// 该模型只存在于当前客户端，不编码，也不向房间发送。
@immutable
class LiveGiftBarrage {
  LiveGiftBarrage({
    String? id,
    required this.giftID,
    required this.giftName,
    required this.giftIconURL,
    required this.count,
    required this.senderID,
    required this.senderName,
    required this.senderLevel,
  }) : id = id ?? _generateID();

  final String id;
  final String giftID;
  final String giftName;
  final String giftIconURL;
  final int count;
  final String senderID;
  final String senderName;
  final int? senderLevel;

  static int _nextID = 0;

  static String _generateID() {
    _nextID += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_nextID';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is LiveGiftBarrage &&
        other.id == id &&
        other.giftID == giftID &&
        other.giftName == giftName &&
        other.giftIconURL == giftIconURL &&
        other.count == count &&
        other.senderID == senderID &&
        other.senderName == senderName &&
        other.senderLevel == senderLevel;
  }

  @override
  int get hashCode => Object.hash(
        id,
        giftID,
        giftName,
        giftIconURL,
        count,
        senderID,
        senderName,
        senderLevel,
      );
}
