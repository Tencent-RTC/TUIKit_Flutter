import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/api/ai/ai_transcriber_store.dart';
import 'package:atomic_x_core/api/device/music_store.dart';
import 'package:atomic_x_core/impl/barrage/barrage_store_impl.dart';
import 'package:atomic_x_core/impl/device/audio_effect_store_impl.dart';
import 'package:atomic_x_core/impl/device/base_beauty_store_impl.dart';
import 'package:atomic_x_core/impl/device/music_store_impl.dart';
import 'package:atomic_x_core/impl/device/screen_share_store_impl.dart';
import 'package:atomic_x_core/impl/gift/gift_store_impl.dart';
import 'package:atomic_x_core/impl/live/battle_store_impl.dart';
import 'package:atomic_x_core/impl/live/co_guest_store_impl.dart';
import 'package:atomic_x_core/impl/live/co_host_store_impl.dart';
import 'package:atomic_x_core/impl/live/like_store_impl.dart';
import 'package:atomic_x_core/impl/live/live_audience_store_impl.dart';
import 'package:atomic_x_core/impl/live/live_list_store_impl.dart';
import 'package:atomic_x_core/impl/live/live_seat_store_impl.dart';
import 'package:atomic_x_core/impl/live/live_summary_store_impl.dart';
import 'package:atomic_x_core/impl/room/room_participant_store_impl.dart';
import 'package:atomic_x_core/impl/room/room_store_impl.dart';

enum SceneType {
  live,
  room,
  call,
}

abstract class IStore {
  void beforeEnterRoom(String roomID);

  void afterEnterRoom(dynamic info);

  void didLeaveRoom(String roomID);
}

class StoreFactory {
  static final StoreFactory shared = StoreFactory._();

  StoreFactory._() {}

  final Map<String, Map<String, dynamic>> _storeMap = {};

  T getStore<T>({String roomID = ''}) {
    if (T == AudioEffectStore) return AudioEffectStoreImpl.shared as T;
    if (T == BaseBeautyStore) return BaseBeautyStoreImpl.shared as T;
    if (T == DeviceStore) return DeviceStore.shared as T;
    if (T == ScreenShareStore) return ScreenShareStoreImpl.shared as T;
    if (T == RoomStore) return RoomStoreImpl.shared as T;
    if (T == LiveListStore) return LiveListStoreImpl.shared as T;
    final storeProviderMap = _storeMap.putIfAbsent(roomID, () => {});

    return storeProviderMap.putIfAbsent(T.toString(), () {
      if (T == AITranscriberStore) {
        return AITranscriberStoreImpl(roomID);
      } else if (T == BarrageStore) {
        return BarrageStoreImpl(roomID);
      } else if (T == BattleStore) {
        return BattleStoreImpl(roomID);
      } else if (T == CoGuestStore) {
        return CoGuestStoreImpl(roomID);
      } else if (T == CoHostStore) {
        return CoHostStoreImpl(roomID);
      } else if (T == GiftStore) {
        return GiftStoreImpl(roomID);
      } else if (T == LikeStore) {
        return LikeStoreImpl(roomID);
      } else if (T == LiveAudienceStore) {
        return LiveAudienceStoreImpl(roomID);
      } else if (T == LiveSeatStore) {
        return LiveSeatStoreImpl(roomID);
      } else if (T == LiveSummaryStore) {
        return LiveSummaryStoreImpl(roomID);
      } else if (T == MusicStore) {
        return MusicStoreImpl(roomID);
      } else if (T == RoomParticipantStore) {
        return RoomParticipantStoreImpl(roomID);
      } else {
        throw Exception('Type ${T.toString()} is not supported');
      }
    }) as T;
  }

  // MARK: - Enter room lifecycle
  void beforeEnterRoom(String roomID, SceneType sceneType) {
    switch (sceneType) {
      case SceneType.live:
        (getStore<CoGuestStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<CoHostStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<BattleStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<LiveSeatStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<BarrageStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<GiftStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<LikeStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<LiveAudienceStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<LiveSummaryStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<AITranscriberStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<MusicStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        break;
      case SceneType.room:
        (getStore<RoomParticipantStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<BarrageStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        (getStore<AITranscriberStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
        break;
      case SceneType.call:
        (getStore<AITranscriberStore>(roomID: roomID) as IStore?)?.beforeEnterRoom(roomID);
    }
  }

  void afterEnterRoom(String roomID, dynamic info) {
    final roomStoreMap = _storeMap[roomID];
    roomStoreMap?.forEach((key, store) {
      if (store is IStore) {
        store.afterEnterRoom(info);
      }
    });
  }

  // MARK: - Leave room (shared by both scenes)

  void didLeaveRoom(String roomID) {
    final roomStoreMap = _storeMap.remove(roomID);
    roomStoreMap?.forEach((key, store) {
      if (store is IStore) {
        store.didLeaveRoom(roomID);
      }
    });
    getStore<BaseBeautyStore>().reset();
    getStore<AudioEffectStore>().reset();
    getStore<DeviceStore>().reset();
  }

  void removeAllStores() {
    _storeMap.keys.toList().forEach((roomID) {
      didLeaveRoom(roomID);
    });
    _storeMap.clear();
  }
}
