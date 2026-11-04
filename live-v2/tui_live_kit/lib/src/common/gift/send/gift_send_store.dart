library;

import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';

import '../../live_kit_resources.dart';

@immutable
class GiftSendState {
  const GiftSendState({
    this.liveID,
    this.categories = const <GiftCategory>[],
    this.isLoading = false,
  });

  final String? liveID;
  final List<GiftCategory> categories;
  final bool isLoading;
}

/// Owns the gift catalog subscription and send requests for one live session.
class GiftSendStore {
  GiftSendStore({GiftStore Function(String liveID)? giftStoreFactory})
      : _giftStoreFactory = giftStoreFactory ?? GiftStore.create;

  ValueChanged<GiftSendState>? onStateChanged;

  GiftSendState _state = const GiftSendState();
  GiftSendState get state => _state;

  final GiftStore Function(String liveID) _giftStoreFactory;
  GiftStore? _giftStore;
  VoidCallback? _usableGiftsListener;
  int _activationID = 0;

  void activate(String liveID) {
    if (_state.liveID == liveID) return;
    deactivate();
    if (liveID.isEmpty) return;
    final int activationID = _activationID;
    _updateState(GiftSendState(liveID: liveID, isLoading: true));

    final GiftStore store = _giftStoreFactory(liveID);
    _giftStore = store;
    store.setLanguage(LiveKitResources.giftLanguageCode);

    void syncUsableGifts() {
      if (_activationID != activationID) return;
      final categories = store.giftState.usableGifts.value;
      _updateState(GiftSendState(
        liveID: liveID,
        categories: _snapshotCategories(categories),
        isLoading: categories.isEmpty && _state.isLoading,
      ));
    }

    _usableGiftsListener = syncUsableGifts;
    store.giftState.usableGifts.addListener(syncUsableGifts);
    syncUsableGifts();
    unawaited(_refreshUsableGifts(store, activationID));
  }

  Future<void> _refreshUsableGifts(GiftStore store, int activationID) async {
    try {
      await store.refreshUsableGifts();
    } on Object {
      // A failed refresh keeps any previously received catalog.
    } finally {
      if (_activationID == activationID) {
        _updateState(GiftSendState(
          liveID: _state.liveID,
          categories: _state.categories,
          isLoading: false,
        ));
      }
    }
  }

  Future<void> sendGift({
    required String id,
    int count = 1,
    ValueChanged<bool>? completion,
  }) async {
    final GiftStore? store = _giftStore;
    if (store == null) {
      completion?.call(false);
      return;
    }
    final int activationID = _activationID;
    bool isSuccess;
    try {
      final result = await store.sendGift(
        giftID: id,
        count: count < 1 ? 1 : count,
      );
      isSuccess = result.isSuccess;
    } on Object {
      isSuccess = false;
    }
    // An old session must not confirm a new session's local presentation.
    if (_activationID != activationID) return;
    completion?.call(isSuccess);
  }

  void deactivate() {
    _activationID += 1;
    final listener = _usableGiftsListener;
    if (listener != null) {
      _giftStore?.giftState.usableGifts.removeListener(listener);
    }
    _giftStore = null;
    _usableGiftsListener = null;
    _updateState(const GiftSendState());
  }

  void dispose() {
    onStateChanged = null;
    deactivate();
  }

  void _updateState(GiftSendState next) {
    if (_state.liveID == next.liveID &&
        _state.isLoading == next.isLoading &&
        listEquals(_state.categories, next.categories)) {
      return;
    }
    _state = next;
    onStateChanged?.call(next);
  }

  // SDK model fields are final, but their collection members can be mutated.
  static List<GiftCategory> _snapshotCategories(List<GiftCategory> categories) {
    return List<GiftCategory>.unmodifiable(categories.map((category) {
      return GiftCategory(
        categoryID: category.categoryID,
        name: category.name,
        desc: category.desc,
        extensionInfo: Map<String, String>.unmodifiable(category.extensionInfo),
        giftList: List<Gift>.unmodifiable(category.giftList.map((gift) => Gift(
              giftID: gift.giftID,
              name: gift.name,
              desc: gift.desc,
              iconURL: gift.iconURL,
              resourceURL: gift.resourceURL,
              level: gift.level,
              coins: gift.coins,
              extensionInfo:
                  Map<String, String>.unmodifiable(gift.extensionInfo),
            ))),
      );
    }));
  }
}
