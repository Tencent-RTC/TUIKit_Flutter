import 'package:atomic_x_core/api/barrage/barrage_store.dart';

import '../manager/index.dart';

typedef OnBarrageError = void Function(int code, String message);

class Store {
  static Store? _instance;
  OnBarrageError? onError;

  Store._internal();

  factory Store() {
    _instance ??= Store._internal();
    return _instance!;
  }

  BarrageManager manager = BarrageManager();

  String roomId = '';

  String selfUserId = '';

  String selfName = '';

  String ownerId = '';

  void init(String roomId, String ownerId, String userId, String? name) {
    if (this.roomId != roomId ||
        this.ownerId != ownerId ||
        selfUserId != userId) {
      this.roomId = roomId;
      this.ownerId = ownerId;
      selfUserId = userId;
      selfName = name ?? selfUserId;
    } else {
      selfName = name ?? selfUserId;
    }
  }
}
