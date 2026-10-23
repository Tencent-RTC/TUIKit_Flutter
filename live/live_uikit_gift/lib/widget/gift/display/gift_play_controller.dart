import 'dart:math';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../common/constants/constants.dart';
import '../../../gift_define.dart';
import '../../../manager/cache/gift_cache_manager.dart';
import '../../../state/index.dart';

typedef OnReceiveGiftMessageCallback = void Function(Gift gift, int count, LiveUserInfo sender);
typedef OnReceiveLikeMessageCallback = void Function(int totalLikesReceived, LiveUserInfo sender);

class GiftPlayController {
  final String roomId;
  final String language;
  late final GiftListener _giftListener;
  late final LikeListener _likeListener;
  OnReceiveGiftMessageCallback? _onReceiveGiftMessageCallback;
  OnReceiveLikeMessageCallback? _onReceiveLikeMessageCallback;
  OnReceiveGiftCallback? onReceiveGiftCallback;
  int _currentLikeAnimationCount = 0;

  late final GiftStore _giftStore;
  late final LikeStore _likeStore;

  GiftPlayController({required this.roomId,
    this.language = 'en',
    bool enablePreloading = false,
    OnGiftError? onError}) {
    _giftStore = GiftStore.create(roomId);
    _likeStore = LikeStore.create(roomId);
    _giftStore.setLanguage(language);
    if (enablePreloading) {
      _preloadSvgaResource();
    }
    TUIGiftStore().onError = onError;
    _initCallback();
    _addObserver();
  }

  void dispose() {
    TUIGiftStore().reset();
    _removeObserver();
  }
}

extension on GiftPlayController {
  void _preloadSvgaResource() async {
    debugPrint("GiftPlayController _preloadSvgaResource");
    List<String> svgaList = [
      "http://dldir1.qq.com/hudongzhibo/TRTC/TUIKit/Gift/svga/cat.svga",
      "http://dldir1.qq.com/hudongzhibo/TRTC/TUIKit/Gift/svga/car.svga",
      "http://dldir1.qq.com/hudongzhibo/TRTC/TUIKit/Gift/svga/sports_car.svga"
    ];
    for (String svgaUrl in svgaList) {
      await GiftCacheManager.getCachedFile(svgaUrl);
    }
  }

  void _initCallback() {
    _onReceiveGiftMessageCallback = (giftInfo, count, sender) {
      onReceiveGiftCallback?.call(giftInfo, count, sender);
      _playGift(roomId, giftInfo, count, sender);
    };

    _onReceiveLikeMessageCallback = (totalLikesReceived, sender) {
      final localLikeCount = TUIGiftStore().localLikeCount;
      final delta = totalLikesReceived - localLikeCount;
      if (delta < 0) {
        return;
      }

      final playCount = min(Constants.likeMaxAnimationCount, delta);
      TUIGiftStore().localLikeCount = totalLikesReceived;


      for (int i = 0; i < playCount; i++) {
        int delay = i * Constants.likeMaxAnimationIntervalMS;
        Future.delayed(Duration(milliseconds: delay), () {
          _playLike(roomId, sender);
        });
      }
    };
  }

  void _playGift(String roomId, Gift gift, int giftCount, LiveUserInfo sender) {
    final giftData =
    TUIGiftData(giftCount: giftCount, gift: gift, sender: sender);
    final Map<String, TUIGiftData?> newGiftData = {};
    TUIGiftStore()
        .giftDataMap
        .value
        .forEach((roomId, giftData) => {newGiftData[roomId] = giftData});
    newGiftData[roomId] = giftData;
    TUIGiftStore().giftDataMap.value = newGiftData;
  }

  void _playLike(String roomId, LiveUserInfo sender) {
    if (_currentLikeAnimationCount >= Constants.likeMaxAnimationCount) {
      return;
    }

    final likeData = TUILikeData(sender: sender);
    final Map<String, TUILikeData?> newLikeData = {};
    TUIGiftStore()
        .likeDataMap
        .value
        .forEach((roomId, likeData) => {newLikeData[roomId] = likeData});
    newLikeData[roomId] = likeData;
    TUIGiftStore().likeDataMap.value = newLikeData;

    _currentLikeAnimationCount += 1;

    Future.delayed(const Duration(seconds: 3), () {
      _currentLikeAnimationCount -= 1;
    });
  }

  void _addObserver() {
    _giftListener = GiftListener(onReceiveGift: (liveID, gift, count, sender) {
      if (liveID != roomId) {
        return;
      }
      _onReceiveGiftMessageCallback?.call(gift, count, sender);
    });
    _likeListener = LikeListener(onReceiveLikesMessage: (liveID, totalLikesReceived, sender) {
      if (liveID != roomId) {
        return;
      }
      _onReceiveLikeMessageCallback?.call(totalLikesReceived, sender);
    });
    _giftStore.addGiftListener(_giftListener);
    _likeStore.addLikeListener(_likeListener);
  }

  void _removeObserver() {
    _giftStore.removeGiftListener(_giftListener);
    _likeStore.removeLikeListener(_likeListener);
  }
}
