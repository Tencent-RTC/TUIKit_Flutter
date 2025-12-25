import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/foundation.dart';

import 'index.dart';

class SeatGridController {
  final String liveID;
  late final SeatGridWidgetManager _manager = SeatGridWidgetManager(liveID: liveID);

  WidgetState get widgetState => _manager.widgetState;

  List<SeatWidgetState> _seatWidgetStates = [];

  List<SeatWidgetState> get seatWidgetStates => _seatWidgetStates;

  LiveListStore get _liveListStore => LiveListStore.shared;

  LiveSeatStore get _seatStore => LiveSeatStore.create(liveID);

  int get _seatListCount => _seatStore.liveSeatState.seatList.value.length;

  late final VoidCallback _seatListChangedListener = _onSeatListChanged;
  late final VoidCallback _speakingUserChangedListener = _onSpeakingUsersChanged;

  EventNotifier onSeatWidgetStateSynced = EventNotifier();

  SeatGridController({required this.liveID}) {
    _subscribeState();
    _onSeatListChanged();
  }

  void dispose() {
    _unsubscribeState();
  }

  void setLayoutMode(LayoutMode layoutMode, SeatWidgetLayoutConfig? layoutConfig) {
    _manager.setLayoutMode(layoutMode, layoutConfig);
  }
}

extension SeatGridControllerWithSubsribeState on SeatGridController {
  void _subscribeState() {
    _seatStore.liveSeatState.seatList.addListener(_seatListChangedListener);
    _seatStore.liveSeatState.speakingUsers.addListener(_speakingUserChangedListener);
  }

  void _unsubscribeState() {
    _seatStore.liveSeatState.speakingUsers.removeListener(_speakingUserChangedListener);
    _seatStore.liveSeatState.seatList.removeListener(_seatListChangedListener);
  }

  void _onSeatListChanged() {
    final currentSeatList = _seatStore.liveSeatState.seatList.value;
    final seatCountChanged = _seatWidgetStates.length != currentSeatList.length;

    if (currentSeatList.isEmpty) {
      return _onSeatListEmpty();
    }

    if (seatCountChanged && _seatStore.liveSeatState.seatList.value.isNotEmpty) {
      return _onSeatCountChanged();
    }

    final seatMovementDetected = _isSeatMovementDetected();

    _syncSeatsAndOwner();

    if (seatMovementDetected) {
      _onSeatMovementHappened();
    }
  }

  void _onSeatListEmpty() {
    for (final seatWidgetState in _seatWidgetStates) {
      seatWidgetState.seatInfoNotifier.value = SeatInfo();
    }
  }

  void _onSeatCountChanged() {
    _seatWidgetStates = List.generate(_seatListCount, (_) => SeatWidgetState());
    _supplySeatWidgetStates();
  }

  void _onSpeakingUsersChanged() {
    _syncSpeakingVolumes();
  }

  void _supplySeatWidgetStates() {
    _syncSeatsAndOwner();
    _syncSpeakingVolumes();
    _syncAudioAvailability();
  }

  void _syncSeatsAndOwner() {
    if (_seatWidgetStates.length != _seatListCount) return;

    for (int i = 0; i < _seatWidgetStates.length; i++) {
      final seatInfo = _seatStore.liveSeatState.seatList.value[i];
      _seatWidgetStates[i].seatInfoNotifier.value = seatInfo;
      _seatWidgetStates[i].isOwner =
          seatInfo.userInfo.userID == _liveListStore.liveState.currentLive.value.liveOwner.userID;
    }
    onSeatWidgetStateSynced.notifyRebuild();
  }

  void _syncSpeakingVolumes() {
    final speakingUserVolumeMap = _seatStore.liveSeatState.speakingUsers.value;
    if (_seatWidgetStates.isEmpty) return;
    final userSeatModelMap = <String, SeatWidgetState>{};
    for (final seatWidgetState in _seatWidgetStates) {
      final userId = seatWidgetState.seatInfoNotifier.value.userInfo.userID;
      userSeatModelMap[userId] = seatWidgetState;
    }

    for (final entry in userSeatModelMap.entries) {
      final userId = entry.key;
      final seatWidgetState = entry.value;
      final userVolume = speakingUserVolumeMap[userId];

      if (userVolume != null) {
        if (userVolume == seatWidgetState.volumeNotifier.value) continue;
        seatWidgetState.volumeNotifier.value = userVolume;
      } else {
        seatWidgetState.volumeNotifier.value = 0;
      }
    }
    onSeatWidgetStateSynced.notifyRebuild();
  }

  void _syncAudioAvailability() {
    final hasAudioStreamUserIds = _seatStore.liveSeatState.seatList.value
        .where((seat) => seat.userInfo.microphoneStatus == DeviceStatus.on)
        .map((seat) => seat.userInfo.userID)
        .toSet();
    if (_seatWidgetStates.isEmpty) return;
    final userSeatModelMap = <String, SeatWidgetState>{};
    for (final seatWidgetState in _seatWidgetStates) {
      final userId = seatWidgetState.seatInfoNotifier.value.userInfo.userID;
      userSeatModelMap[userId] = seatWidgetState;
    }

    for (final entry in userSeatModelMap.entries) {
      final userId = entry.key;
      final seatModel = entry.value;
      final hasAudioStreamUserId =
      _safeFind<String>(hasAudioStreamUserIds, (hasAudioStreamUserId) => hasAudioStreamUserId == userId);

      if (hasAudioStreamUserId != null && hasAudioStreamUserId.isNotEmpty) {
        seatModel.hasAudioNotifier.value = true;
      } else {
        seatModel.hasAudioNotifier.value = false;
      }
    }
    onSeatWidgetStateSynced.notifyRebuild();
  }

  bool _isSeatMovementDetected() {
    final oldSeatedCount =
        seatWidgetStates
            .where((seatWidget) => seatWidget.seatInfoNotifier.value.userInfo.userID.isNotEmpty)
            .length;
    final newSeatedCount =
        _seatStore.liveSeatState.seatList.value
            .where((seatInfo) => seatInfo.userInfo.userID.isNotEmpty)
            .length;
    return oldSeatedCount == newSeatedCount;
  }

  void _onSeatMovementHappened() {
    _syncSpeakingVolumes();
    _syncAudioAvailability();
  }

  T? _safeFind<T>(Set<T> collection, bool Function(T) predicate) {
    try {
      return collection.firstWhere(predicate);
    } on StateError {
      return null;
    }
  }
}

extension SeatGridControllerWithGetState on SeatGridController {
  int getSeatIndex(SeatWidgetLayoutConfig layoutConfig, int row, int column) {
    final rows = layoutConfig.rowConfigs.length;
    if (row < 0 || row >= rows) {
      throw ArgumentError("Invalid row index: $row");
    }
    if (column < 0 || column >= layoutConfig.rowConfigs[row].count) {
      throw ArgumentError("Invalid column index: $column");
    }
    final seatsBefore = layoutConfig.rowConfigs.sublist(0, row).fold(0, (sum, config) => sum + config.count);
    return seatsBefore + column;
  }

  SeatWidgetState getSeatWidgetState(SeatWidgetLayoutConfig layoutConfig, int row, int column) {
    final index = getSeatIndex(layoutConfig, row, column);
    if (index >= _seatWidgetStates.length) {
      return SeatWidgetState();
    }

    return _seatWidgetStates[index];
  }
}

class SeatWidgetState {
  ValueNotifier<SeatInfo> seatInfoNotifier = ValueNotifier(SeatInfo());
  ValueNotifier<int> volumeNotifier = ValueNotifier(0);
  ValueNotifier<bool> hasAudioNotifier = ValueNotifier(false);
  bool isOwner = false;
}

class EventNotifier extends ValueNotifier<int> {
  EventNotifier() : super(0);

  void notifyRebuild() {
    notifyListeners();
  }
}
