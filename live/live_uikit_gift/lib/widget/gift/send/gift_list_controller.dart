import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';

class GiftListController {
  final String roomId;
  final String language;
  late PageController pageController = PageController();
  OnSendGiftCallback? onSendGiftCallback;
  final ValueNotifier<bool> isFloatWindowMode = ValueNotifier(false);

  GiftListController({required this.roomId, this.language = 'en', OnGiftError? onError}) {
    TUIGiftStore().onError = onError;
    _getGiftList();
  }

  Future<CompletionHandler> sendGift(Gift gift, int count) async {
    final result = await GiftStore.create(roomId).sendGift(giftID: gift.giftID, count: count);
    if (result.errorCode != 0) {
      TUIGiftStore().onError?.call(result.errorCode, result.errorMessage ?? '');
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
    GiftStore.create(roomId).setLanguage(language);
    GiftStore.create(roomId).refreshUsableGifts().then((result) {
      if (result.errorCode != 0) {
        TUIGiftStore().onError?.call(result.errorCode, result.errorMessage ?? '');
      }
    });
  }
}
