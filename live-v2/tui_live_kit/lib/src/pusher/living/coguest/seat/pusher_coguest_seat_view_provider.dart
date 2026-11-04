import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

import 'pusher_coguest_unit_view.dart';

class PusherCoGuestVideoState {
  const PusherCoGuestVideoState({
    required this.isLiving,
    required this.showsEmptySeats,
    required this.connectedGuestCount,
    this.showsHostOverlay = false,
    this.usesSmallWindows = false,
    this.localCameraStatus,
  });

  final bool isLiving;
  final bool showsEmptySeats;
  final int connectedGuestCount;
  final bool showsHostOverlay;
  final bool usesSmallWindows;
  final DeviceStatus? localCameraStatus;

  bool get hasGuests => connectedGuestCount > 0;

  PusherCoGuestVideoState copyWith({
    bool? isLiving,
    bool? showsEmptySeats,
    int? connectedGuestCount,
    bool? showsHostOverlay,
    bool? usesSmallWindows,
    Object? localCameraStatus = _sentinel,
  }) {
    return PusherCoGuestVideoState(
      isLiving: isLiving ?? this.isLiving,
      showsEmptySeats: showsEmptySeats ?? this.showsEmptySeats,
      connectedGuestCount: connectedGuestCount ?? this.connectedGuestCount,
      showsHostOverlay: showsHostOverlay ?? this.showsHostOverlay,
      usesSmallWindows: usesSmallWindows ?? this.usesSmallWindows,
      localCameraStatus:
          identical(localCameraStatus, _sentinel) ? this.localCameraStatus : localCameraStatus as DeviceStatus?,
    );
  }

  static const Object _sentinel = Object();
}

/// 记录真实渲染席位的位置，供上层 Living 手势层做命中判断。
///
/// `AtomicLiveWidget` 位于 `PusherLivingView` 下方，席位自身不能直接赢得手势；
/// 因此与 iOS 一样，由容器收到点击后再查询实际席位视图。
class _PusherCoGuestSeatHitTestRegistry {
  final Map<String, GlobalKey> _seatKeys = <String, GlobalKey>{};

  GlobalKey keyFor(String userID) =>
      _seatKeys.putIfAbsent(userID, () => GlobalKey(debugLabel: 'co_guest_seat_$userID'));

  String? guestUserIDAt(Offset globalPosition) {
    _seatKeys.removeWhere((userID, key) => key.currentContext == null);
    for (final MapEntry<String, GlobalKey> entry in _seatKeys.entries.toList().reversed) {
      final RenderObject? renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
        continue;
      }
      final Offset localPosition = renderObject.globalToLocal(globalPosition);
      if ((Offset.zero & renderObject.size).contains(localPosition)) {
        return entry.key;
      }
    }
    return null;
  }

  void clear() => _seatKeys.clear();
}

class PusherCoGuestSeatViewProvider extends AtomicLiveViewChangeAdapter {
  PusherCoGuestSeatViewProvider(this.state, {String Function()? localUserID})
      : _localUserID = localUserID ?? _currentUserID;

  final String Function() _localUserID;
  static String _currentUserID() => LoginStore.shared.loginState.loginUserInfo?.userID ?? '';

  final ValueListenable<PusherCoGuestVideoState> state;
  final Map<int, ValueNotifier<UnitInfo>> _units = {};
  final Map<int, ValueNotifier<int>> _volumes = {};

  @override
  Widget onCreateUnitView(UnitInfo unitInfo) {
    final notifier = _units.putIfAbsent(unitInfo.index, () => ValueNotifier<UnitInfo>(unitInfo));
    notifier.value = unitInfo;
    final volume = _volumes.putIfAbsent(unitInfo.index, () => ValueNotifier<int>(0));
    return ValueListenableBuilder<UnitInfo>(
      valueListenable: notifier,
      builder: (BuildContext context, UnitInfo unit, _) => ValueListenableBuilder<int>(
        valueListenable: volume,
        builder: (BuildContext context, int unitVolume, _) => ValueListenableBuilder<PusherCoGuestVideoState>(
          valueListenable: state,
          builder: (BuildContext context, PusherCoGuestVideoState videoState, _) {
            final String loginUserID = _localUserID();
            final bool isHost = unit.userID.isNotEmpty && unit.userID == loginUserID;
            final bool isGuest = unit.userID.isNotEmpty && !isHost;
            final Widget seat = PusherCoGuestUnitView(
              unitInfo: unit,
              isLiving: videoState.isLiving,
              showsEmptySeats: videoState.showsEmptySeats,
              hasGuests: videoState.hasGuests,
              showsHostOverlay: videoState.showsHostOverlay,
              isHost: isHost,
              localCameraStatus: videoState.localCameraStatus,
              volume: unitVolume,
            );
            final bool tracksRegion = videoState.isLiving &&
                (unit.userID.isEmpty
                    ? videoState.showsEmptySeats
                    : ((isGuest || isHost) && (videoState.hasGuests || videoState.showsHostOverlay)));
            if (!tracksRegion) {
              return seat;
            }
            final Widget keyed = isGuest ? KeyedSubtree(key: _hitTestRegistry.keyFor(unit.userID), child: seat) : seat;
            return _observe(keyed);
          },
        ),
      ),
    );
  }

  @override
  // SDK variants pass Key? or Widget?; updates are addressed by seat index.
  void onUpdateUnitView(UnitInfo unitInfo, Object? view) {
    _units[unitInfo.index]?.value = unitInfo;
  }

  @override
  void onVolumeChanged(UnitInfo unitInfo, int volume, Widget? view) {
    final notifier = _volumes[unitInfo.index];
    if (notifier == null || notifier.value == volume) return;
    notifier.value = volume;
  }

  @override
  void onVideoViewFrameChanged(double left, double top, double right, double bottom) {}

  final _PusherCoGuestSeatHitTestRegistry _hitTestRegistry = _PusherCoGuestSeatHitTestRegistry();
  String? guestUserIDAt(Offset position) =>
      state.value.isLiving && state.value.connectedGuestCount > 0 ? _hitTestRegistry.guestUserIDAt(position) : null;
  final ValueNotifier<int> geometryChanges = ValueNotifier(0);
  final Map<Object, Rect> _regions = {};
  bool _disposed = false;
  bool _notificationPending = false;

  List<Rect> get gridRegions =>
      state.value.isLiving && !state.value.usesSmallWindows ? _regions.values.toList(growable: false) : const <Rect>[];

  List<Rect> get regions =>
      state.value.isLiving && state.value.usesSmallWindows ? _regions.values.toList(growable: false) : const <Rect>[];

  Widget _observe(Widget child) => _SeatRegionObserver(
        onRegion: (identity, rect) {
          if (_disposed || _regions[identity] == rect) return;
          if (rect == null) {
            _regions.remove(identity);
          } else {
            _regions[identity] = rect;
          }
          if (_notificationPending) return;
          _notificationPending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _notificationPending = false;
            if (!_disposed) geometryChanges.value++;
          });
          WidgetsBinding.instance.ensureVisualUpdate();
        },
        child: child,
      );

  void dispose() {
    _disposed = true;
    for (final unit in _units.values) {
      unit.dispose();
    }
    _units.clear();
    for (final volume in _volumes.values) {
      volume.dispose();
    }
    _volumes.clear();
    _hitTestRegistry.clear();
    _regions.clear();
    geometryChanges.dispose();
  }
}

// UIKit layout callbacks have no Widget equivalent. Observe painted RenderBoxes
// so SDK positions remain authoritative, including ancestor offset changes.
class _SeatRegionObserver extends SingleChildRenderObjectWidget {
  const _SeatRegionObserver({required this.onRegion, required super.child});
  final void Function(Object, Rect?) onRegion;

  @override
  RenderObject createRenderObject(BuildContext context) => _SeatRegionBox(onRegion);

  @override
  void updateRenderObject(BuildContext context, _SeatRegionBox renderObject) {
    renderObject.onRegion = onRegion;
  }
}

class _SeatRegionBox extends RenderProxyBox {
  _SeatRegionBox(this.onRegion);
  void Function(Object, Rect?) onRegion;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onRegion(this, localToGlobal(Offset.zero) & size);
  }

  @override
  void detach() {
    onRegion(this, null);
    super.detach();
  }
}
