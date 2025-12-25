
import 'package:atomic_x_core/api/gift/gift_store.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';

import 'package:rtc_room_engine/rtc_room_engine.dart';

typedef OnReceiveGiftMessageCallback = void Function(Gift gift, int count, LiveUserInfo sender);
typedef OnReceiveLikeMessageCallback = void Function(int totalLikesReceived, LiveUserInfo sender);

class GiftManagerFactory {
  static final Map<String, GiftManager> _giftManagerMap = {};

  static GiftManager getGiftManager(String roomId) {
    if (_giftManagerMap.containsKey(roomId)) {
      return _giftManagerMap[roomId]!;
    }

    final giftManager = GiftManager(roomId: roomId);
    _giftManagerMap[roomId] = giftManager;
    return giftManager;
  }

  static void destroyGiftManager(String roomId) {
    _giftManagerMap.remove(roomId);
  }
}

class GiftManager {
  final String roomId;
  OnReceiveGiftMessageCallback? onReceiveGiftMessageCallback;
  OnReceiveLikeMessageCallback? onReceiveLikeMessageCallback;

  final TUILiveGiftManager _giftManager = TUIRoomEngine.sharedInstance().getExtension(TUIExtensionType.liveGiftManager);
  late final GiftStore _giftStore;
  late final LikeStore _likeStore;
  late final GiftListener _giftListener;
  late final LikeListener _likeListener;

  GiftManager({required this.roomId, this.onReceiveGiftMessageCallback, this.onReceiveLikeMessageCallback}) {
    _giftStore = GiftStore.create(roomId);
    _likeStore = LikeStore.create(roomId);

    _addObserver();
  }

  void dispose() {
    _removeObserver();
  }

  Future<TUIActionCallback> sendGift(Gift gift, int count) async {
    final handler = await _giftStore.sendGift(giftID: gift.giftID, count: count);
    return TUIActionCallback(code: TUIError.fromRawValue(handler.errorCode), message: handler.errorMessage);
  }

  void setCurrentLanguage(String language) async {
    _giftStore.setLanguage(language);
  }

  Future<TUIActionCallback> getGiftList() async {
    final result = await _giftStore.refreshUsableGifts();

    if (!result.isSuccess) {
      return TUIActionCallback(code: TUIError.fromRawValue(result.errorCode), message: result.errorMessage);
    }
    final List<GiftCategory> giftCategoryList = _giftStore.giftState.usableGifts.value;
    List<Gift> giftList = List.empty(growable: true);
    for (final giftCategory in giftCategoryList) {
      giftList.addAll(giftCategory.giftList);
    }
    _updateGiftListMap(roomId, giftList);

    return TUIActionCallback(code: TUIError.fromRawValue(result.errorCode), message: result.errorMessage);
  }

  Future<TUIValueCallBack<TUIGiftCountRequestResult>> getGiftCountByAnchor() {
    return _giftManager.getGiftCountByAnchor(roomId);
  }
}

extension on GiftManager {
  void _addObserver() {
    _giftListener = GiftListener(onReceiveGift: (liveID, gift, count, sender) {
      if (liveID != roomId) {
        return;
      }
      onReceiveGiftMessageCallback?.call(gift, count, sender);
    });
    _likeListener = LikeListener(onReceiveLikesMessage: (liveID, totalLikesReceived, sender) {
      if (liveID != roomId) {
        return;
      }
      onReceiveLikeMessageCallback?.call(totalLikesReceived, sender);
    });
    _giftStore.addGiftListener(_giftListener);
    _likeStore.addLikeListener(_likeListener);
  }

  void _removeObserver() {
    _giftStore.removeGiftListener(_giftListener);
    _likeStore.removeLikeListener(_likeListener);
  }

  void _updateGiftListMap(String roomId, List<Gift> giftList) {
    final Map<String, List<Gift>> newGiftListMap = {};
    TUIGiftStore().giftListMap.value.forEach((roomId, giftList) => {newGiftListMap[roomId] = giftList});
    newGiftListMap[roomId] = giftList;
    TUIGiftStore().giftListMap.value = newGiftListMap;
  }
}
