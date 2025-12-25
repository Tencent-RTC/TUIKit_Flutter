import 'package:atomic_x_core/api/barrage/barrage_store.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import '../state/store.dart';

class BarrageManager {
  late V2TimAdvancedMsgListener listener;
  bool isInit = false;
  late BarrageStore barrageStore;

  void init(String roomId, String ownerId, String userId, String? name) {
    barrageStore = BarrageStore.create(roomId);
    Store().init(roomId, ownerId, userId, name);
  }

  Future<bool> sendBarrage(Barrage barrage) async {
    final result = await barrageStore.sendTextMessage(text: barrage.textContent, extensionInfo: barrage.extensionInfo);
    if (!result.isSuccess) {
      Store().onError?.call(result.errorCode, result.errorMessage ?? '');
    }
    return result.isSuccess;
  }

  void insertBarrage(Barrage barrage) {
    barrageStore.appendLocalTip(barrage);
  }
}
