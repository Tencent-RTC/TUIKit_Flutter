import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:live_uikit_gift/manager/gift_manager.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

class GiftListController {
  final String roomId;
  final String language;
  late PageController pageController = PageController();
  late GiftManager giftManager;
  OnSendGiftCallback? onSendGiftCallback;
  final ValueNotifier<bool> isFloatWindowMode = ValueNotifier(false);

  GiftListController({required this.roomId, this.language = 'en', OnGiftError? onError}) {
    giftManager = GiftManagerFactory.getGiftManager(roomId);
    _getGiftList();
    TUIGiftStore().onError = onError;
  }

  Future<TUIActionCallback> sendGift(Gift gift, int count) async {
    final result = await giftManager.sendGift(gift, count);
    if (result.code != TUIError.success) {
      TUIGiftStore().onError?.call(result.code.rawValue, result.message ?? '');
      return result;
    }
    onSendGiftCallback?.call(gift, count);
    return result;
  }

  void setFloatWindowMode(bool isFloatWindow) {
    isFloatWindowMode.value = isFloatWindow;
  }
}

extension on GiftListController {
  void _getGiftList() {
    giftManager.setCurrentLanguage(language);
    giftManager.getGiftList().then((result) {
      if (result.code != TUIError.success) {
        TUIGiftStore().onError?.call(result.code.rawValue, result.message ?? '');
      }
    });
  }

  void _playGift(String roomId, Gift gift, int giftCount, LiveUserInfo sender) {
    final giftData = TUIGiftData(giftCount: giftCount, gift: gift, sender: sender);
    final Map<String, TUIGiftData?> newGiftData = {};
    TUIGiftStore().giftDataMap.value.forEach((roomId, giftData) => {newGiftData[roomId] = giftData});
    newGiftData[roomId] = giftData;
    TUIGiftStore().giftDataMap.value = newGiftData;
  }
}
