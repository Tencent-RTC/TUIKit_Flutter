import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'index.dart';

typedef OnGiftError = void Function(int code, String message);

class TUIGiftStore {
  static TUIGiftStore? _instance;

  TUIGiftStore._internal();

  factory TUIGiftStore() {
    _instance ??= TUIGiftStore._internal();
    return _instance!;
  }

  OnGiftError? onError;
  final ValueNotifier<Map<String, List<Gift>>> giftListMap = ValueNotifier({});
  final ValueNotifier<Map<String, TUIGiftData?>> giftDataMap = ValueNotifier({});
  final ValueNotifier<Map<String, TUILikeData?>> likeDataMap = ValueNotifier({});
  final ValueNotifier<int> showLikeStart = ValueNotifier(0);
  int localLikeCount = 0;

  void reset() {
    likeDataMap.value.clear();
    giftDataMap.value.clear();
    giftListMap.value.clear();
    showLikeStart.value = 0;
    localLikeCount = 0;
  }
}
