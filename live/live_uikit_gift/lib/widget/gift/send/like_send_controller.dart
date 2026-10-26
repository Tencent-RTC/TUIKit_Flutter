import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

import '../../../common/constants/constants.dart';
import '../../../state/index.dart';

class PendingCount {
  int _count = 0;

  void increment() {
    _count++;
  }

  int getCount() {
    return _count;
  }

  void reset() {
    _count = 0;
  }
}

class LikeSendController {
  final String roomId;
  late LikeStore _likeStore;

  final int _minSendInterval = 6;
  int _lastSendTime = 0;
  Timer? _afterSendLikeTimer;
  final PendingCount _pendingCount = PendingCount();

  LikeSendController({required this.roomId}) {
    _likeStore = LikeStore.create(roomId);
  }

  void dispose() {
    _afterSendLikeTimer?.cancel();
  }

  void sendLike() {
    _showLikeAnimation();

    _pendingCount.increment();

    final now = DateTime
        .now()
        .millisecondsSinceEpoch ~/ 1000;
    final elapsed = now - _lastSendTime;
    _afterSendLikeTimer?.cancel();

    if (elapsed >= _minSendInterval) {
      _sendLikeInternal();
      _lastSendTime = DateTime
          .now()
          .millisecondsSinceEpoch ~/ 1000;
    } else {
      _afterSendLikeTimer = Timer(
        Duration(seconds: _minSendInterval - elapsed),
            () {
          _sendLikeInternal();
          _lastSendTime = DateTime
              .now()
              .millisecondsSinceEpoch ~/ 1000;
        },
      );
    }
  }
}

extension on LikeSendController {
  void _sendLikeInternal() {
    final countToSend = _pendingCount.getCount();
    if (countToSend <= 0) return;

    try {
      debugPrint("sendLike count: $countToSend");
      _likeStore.sendLike(countToSend);
      _pendingCount.reset();
    } catch (e) {
      debugPrint("sendLike failed: $e");
    }
  }

  void _showLikeAnimation() {
    final selfInfo = LoginStore.shared.loginState.loginUserInfo;
    if (selfInfo == null) return;
    TUIGiftStore().localLikeCount += 1;
    TUIGiftStore().showLikeStart.value = TUIGiftStore().localLikeCount;
    final sender = LiveUserInfo(
        userID: selfInfo.userID,
        userName: selfInfo.nickname ?? '',
        avatarURL: selfInfo.avatarURL ?? Constants.defaultAvatar);
    TUIGiftStore().likeDataMap.value[roomId] = TUILikeData(sender: sender);
  }
}
