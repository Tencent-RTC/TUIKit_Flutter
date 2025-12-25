import 'package:atomic_x_core/api/live/like_store.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

class LikeManagerFactory {
  static final Map<String, LikeManager> _likeManagerMap = {};

  static LikeManager getLikeManager(String roomId) {
    if (_likeManagerMap.containsKey(roomId)) {
      return _likeManagerMap[roomId]!;
    }

    final giftManager = LikeManager(roomId: roomId);
    _likeManagerMap[roomId] = giftManager;
    return giftManager;
  }

  static void destroyLikeManager(String roomId) {
    _likeManagerMap.remove(roomId);
  }
}

class LikeManager {
  final String roomId;
  late final LikeStore _likeStore;

  LikeManager({required this.roomId}) {
    _likeStore = LikeStore.create(roomId);
  }

  Future<TUIActionCallback> sendLike(int count) async {
    final result = await _likeStore.sendLike(count);
    return TUIActionCallback(code: TUIError.fromRawValue(result.errorCode), message: result.errorMessage);
  }

  Future<TUIValueCallBack<int>> getLikesCount() async {
    return TUIValueCallBack(code: TUIError.success, message: '', data: _likeStore.likeState.totalLikeCount.value);
  }
}
