/// 两端共用的评论 Store，对应 iOS `Common/Barrage/BarrageStore.swift` 的 `BarrageUIStore`。
///
/// 负责 AtomicXCore `BarrageStore` 的创建、订阅、发送与释放，以 SDK 消息为业务事实来源，
/// 把已结算的本地礼物评论与普通文本按时间合并为最近 100 条时间线。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';

import '../gift/gift_barrage_store.dart';
import '../live_kit_resources.dart';
import 'barrage_stream_view.dart' show LiveMessage;

class BarrageUIStore {
  BarrageUIStore({
    BarrageStore Function(String liveID)? storeFactory,
    bool Function()? isMessageBanned,
  })  : _storeFactory = storeFactory ?? BarrageStore.create,
        _isMessageBanned = isMessageBanned;

  final BarrageStore Function(String liveID) _storeFactory;
  final bool Function()? _isMessageBanned;

  static const int _maximumCommentCount = 100;

  static const int _mutedErrorCode = 10017;

  /// 评论时间线变化回调。
  VoidCallback? onStateChanged;

  /// 发送失败回调，文案已按错误码映射为中英文本地化文案。
  void Function(String message)? onSendError;

  List<BarrageComment> get comments => _comments;
  List<BarrageComment> _comments = const <BarrageComment>[];

  String _liveID = '';
  String _hostUserID = '';
  BarrageStore? _barrageStore;
  VoidCallback? _messageListListener;
  final Set<int> _pendingSendIDs = <int>{};
  final Set<String> _pendingTexts = <String>{};
  int _generation = 0;
  int _sendRequestSeed = 0;

  final List<BarrageComment> _textComments = <BarrageComment>[];
  final List<BarrageComment> _giftComments = <BarrageComment>[];

  void activate({required String liveID, required String hostUserID}) {
    if (liveID.isEmpty) {
      deactivate();
      return;
    }
    if (_liveID == liveID &&
        _hostUserID == hostUserID &&
        _barrageStore != null) {
      return;
    }
    deactivate();
    _liveID = liveID;
    _hostUserID = hostUserID;
    final int generation = _generation;
    final BarrageStore store = _storeFactory(liveID);
    _barrageStore = store;
    _messageListListener = () {
      if (generation != _generation) return;
      _apply(store.barrageState.messageList.value);
    };
    store.barrageState.messageList.addListener(_messageListListener!);
    _apply(store.barrageState.messageList.value);
  }

  void deactivate() {
    _generation += 1;
    _pendingSendIDs.clear();
    _pendingTexts.clear();
    final BarrageStore? store = _barrageStore;
    final VoidCallback? listener = _messageListListener;
    if (store != null && listener != null) {
      store.barrageState.messageList.removeListener(listener);
    }
    _barrageStore = null;
    _messageListListener = null;
    _liveID = '';
    _hostUserID = '';
    _textComments.clear();
    _giftComments.clear();
    _rebuildComments();
  }

  Future<void> sendComment(String text) async {
    final String value = text.trim();
    if (value.isEmpty || _pendingTexts.contains(value)) return;
    final BarrageStore? store = _barrageStore;
    if (store == null) return;
    if (isSelfMessageBanned()) {
      onSendError?.call(sendErrorMessage(_mutedErrorCode));
      return;
    }
    final int generation = _generation;
    final int requestID = ++_sendRequestSeed;
    _pendingSendIDs.add(requestID);
    _pendingTexts.add(value);
    int? errorCode;
    try {
      final CompletionHandler result = await store.sendTextMessage(text: value);
      if (!result.isSuccess) errorCode = result.errorCode;
    } on Object {
      errorCode = -1;
    }
    if (generation != _generation || !_pendingSendIDs.remove(requestID)) return;
    _pendingTexts.remove(value);
    if (errorCode != null) {
      debugPrint('[TUILiveKit][Barrage] send failed code=$errorCode');
      onSendError?.call(sendErrorMessage(errorCode));
    }
  }

  bool isSelfMessageBanned() {
    if (_liveID.isEmpty) return false;
    if (_isMessageBanned != null) return _isMessageBanned();
    final String? userID = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (userID == null || userID.isEmpty) return false;
    return LiveAudienceStore.create(_liveID)
        .liveAudienceState
        .messageBannedUserList
        .value
        .any((LiveUserInfo user) => user.userID == userID);
  }

  void appendGiftComment(LiveGiftBarrage gift) {
    if (_liveID.isEmpty) return;
    final String id = 'gift-${gift.id}';
    if (_giftComments.any((BarrageComment comment) => comment.id == id)) {
      return;
    }
    _giftComments.add(BarrageComment(
      id: id,
      userName: _resolvedSenderName(
        senderID: gift.senderID,
        senderName: gift.senderName,
      ),
      content: '',
      level: gift.senderLevel,
      isHost: false,
      gift: gift,
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000,
    ));
    _trimToLimit(_giftComments);
    _rebuildComments();
  }

  static String sendErrorMessage(int code) {
    final String key;
    switch (code) {
      case 10017:
      case -2381:
        key = 'muted';
      case -2380:
        key = 'all_muted';
      case 10023:
      case 10006:
      case 7008:
      case 9506:
      case -2:
        key = 'too_frequent';
      case 7015:
      case 80001:
        key = 'content_rejected';
      case 8001:
      case 80002:
        key = 'too_long';
      case 6014:
      case 6206:
      case -1002:
        key = 'login_expired';
      case 6208:
        key = 'login_elsewhere';
      case -2101:
        key = 'not_joined';
      case 10010:
        key = 'room_unavailable';
      case 10007:
        key = 'no_permission';
      case 9508:
      case 9512:
        key = 'network_error';
      case 9510:
      case 9518:
      case 9519:
      case 9520:
      case 9521:
      case 9523:
      case 9524:
      case 9525:
        key = 'timeout';
      case 10016:
        key = 'send_rejected';
      default:
        key = 'send_failed';
    }
    return LiveKitResources.localizedString('tuilivekit.comment.$key');
  }

  void _apply(List<Barrage> barrages) {
    _textComments
      ..clear()
      ..addAll(barrages.map((Barrage barrage) => BarrageComment(
            id: '${barrage.sequence}-${barrage.timestampInSecond}',
            userName: _resolvedSenderName(
              senderID: barrage.sender.userID,
              senderName: barrage.sender.userName,
            ),
            content: barrage.textContent,
            level: barrage.sender.level,
            isHost:
                _hostUserID.isNotEmpty && barrage.sender.userID == _hostUserID,
            gift: null,
            timestamp: barrage.timestampInSecond.toDouble(),
          )));
    _trimToLimit(_textComments);
    _rebuildComments();
  }

  void _rebuildComments() {
    final List<BarrageComment> merged = <BarrageComment>[
      ..._textComments,
      ..._giftComments
    ]..sort((BarrageComment lhs, BarrageComment rhs) {
        final int order = lhs.timestamp.compareTo(rhs.timestamp);
        return order == 0 ? lhs.id.compareTo(rhs.id) : order;
      });
    final int skip = merged.length > _maximumCommentCount
        ? merged.length - _maximumCommentCount
        : 0;
    _comments = List<BarrageComment>.unmodifiable(merged.skip(skip));
    onStateChanged?.call();
  }
}

String _resolvedSenderName(
    {required String senderID, required String senderName}) {
  final String resolved = senderName.isEmpty ? senderID : senderName;
  return resolved.isEmpty
      ? LiveKitResources.localizedString('tuilivekit.common.viewer')
      : resolved;
}

void _trimToLimit(List<BarrageComment> comments) {
  if (comments.length <= BarrageUIStore._maximumCommentCount) return;
  comments.removeRange(
      0, comments.length - BarrageUIStore._maximumCommentCount);
}

/// 公共时间线的展示投影；时间用于两源排序，也供宿主开发模拟展示读取。
class BarrageComment extends LiveMessage {
  const BarrageComment({
    required super.id,
    required super.userName,
    required super.content,
    required super.level,
    required super.isHost,
    required super.gift,
    required this.timestamp,
  });

  final double timestamp;
}
