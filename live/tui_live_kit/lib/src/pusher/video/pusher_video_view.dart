import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../living/coguest/pusher_coguest_store.dart';
import 'pusher_unit_view.dart';

class PusherCoGuestVideoState {
  const PusherCoGuestVideoState({
    required this.isLiving,
    required this.showsEmptySeats,
    required this.connectedGuestCount,
    this.showsHostOverlay = false,
    this.isCoHostConnected = false,
    this.usesSmallWindows = false,
    this.localCameraStatus,
  });

  final bool isLiving;
  final bool showsEmptySeats;
  final int connectedGuestCount;
  final bool showsHostOverlay;
  final bool isCoHostConnected;
  final bool usesSmallWindows;
  final DeviceStatus? localCameraStatus;

  bool get hasGuests => isCoHostConnected || connectedGuestCount > 0;

  PusherCoGuestVideoState copyWith({
    bool? isLiving,
    bool? showsEmptySeats,
    int? connectedGuestCount,
    bool? showsHostOverlay,
    bool? isCoHostConnected,
    bool? usesSmallWindows,
    Object? localCameraStatus = _sentinel,
  }) {
    return PusherCoGuestVideoState(
      isLiving: isLiving ?? this.isLiving,
      showsEmptySeats: showsEmptySeats ?? this.showsEmptySeats,
      connectedGuestCount: connectedGuestCount ?? this.connectedGuestCount,
      showsHostOverlay: showsHostOverlay ?? this.showsHostOverlay,
      isCoHostConnected: isCoHostConnected ?? this.isCoHostConnected,
      usesSmallWindows: usesSmallWindows ?? this.usesSmallWindows,
      localCameraStatus:
          identical(localCameraStatus, _sentinel) ? this.localCameraStatus : localCameraStatus as DeviceStatus?,
    );
  }

  static const Object _sentinel = Object();
}

/// 渲染层的命令入口。
class PusherVideoController {
  PusherVideoController({required String liveID}) {
    _adapter = PusherUnitAdapter(coGuestVideoStateNotifier);
    coreController.setViewChangeAdapter(_adapter);
    AtomicPusher.shared.setView(widget);
  }

  final AtomicLiveController coreController = AtomicLiveController.create(AtomicLiveViewType.pushView);
  late final AtomicLiveWidget widget = AtomicLiveWidget(controller: coreController);
  late final PusherUnitAdapter _adapter;
  Listenable get coGuestGeometryChanges => _adapter.geometryChanges;
  List<Rect> coGuestGridRegions() => _adapter.gridRegions;
  List<Rect> coGuestSmallWindowRegions() => _adapter.regions;

  final ValueNotifier<PusherCoGuestVideoState> coGuestVideoStateNotifier = ValueNotifier<PusherCoGuestVideoState>(
    const PusherCoGuestVideoState(
      isLiving: false,
      showsEmptySeats: false,
      connectedGuestCount: 0,
      showsHostOverlay: false,
      localCameraStatus: null,
    ),
  );

  PusherCoGuestVideoState get _coGuestVideoState => coGuestVideoStateNotifier.value;
  CoGuestLayoutTemplate _layout = CoGuestLayoutTemplate.dynamicLayout;

  final ValueNotifier<String?> selectedGuestUserID = ValueNotifier<String?>(null);

  /// 由上层 Living 手势层传入全局坐标，再命中实际渲染的观众席位。
  bool selectGuestAt(Offset globalPosition) {
    if (_coGuestVideoState.isCoHostConnected) return false;
    final String? userID = _adapter.guestUserIDAt(globalPosition);
    if (userID == null || userID.isEmpty) {
      return false;
    }
    selectedGuestUserID.value = userID;
    return true;
  }

  void clearSelectedGuest() {
    selectedGuestUserID.value = null;
  }

  void updateCoGuestVideoState({
    required bool isLiving,
    required CoGuestLayoutTemplate layout,
    required int connectedGuestCount,
    bool isCoHostConnected = false,
  }) {
    _layout = layout;
    final bool showsHostOverlay = isCoHostConnected ||
        layout == CoGuestLayoutTemplate.gridLayout ||
        (layout == CoGuestLayoutTemplate.dynamicLayout && connectedGuestCount > 0);
    coGuestVideoStateNotifier.value = _coGuestVideoState.copyWith(
      isLiving: isLiving,
      showsEmptySeats: !isCoHostConnected && layout.showsEmptySeats,
      isCoHostConnected: isCoHostConnected,
      connectedGuestCount: connectedGuestCount,
      showsHostOverlay: showsHostOverlay,
      usesSmallWindows: !isCoHostConnected &&
          (layout == CoGuestLayoutTemplate.floatLayout || layout == CoGuestLayoutTemplate.columnLayout),
    );
  }

  void updateLocalCameraStatus(DeviceStatus? status) {
    if (_coGuestVideoState.localCameraStatus == status) return;
    coGuestVideoStateNotifier.value = _coGuestVideoState.copyWith(localCameraStatus: status);
  }

  bool get isCoGuestStageVisible {
    final PusherCoGuestVideoState state = _coGuestVideoState;
    return state.isCoHostConnected ||
        showsCoGuestStage(
          isLiving: state.isLiving,
          layout: _layout,
          connectedGuestCount: state.connectedGuestCount,
        );
  }

  static bool showsCoGuestStage({
    required bool isLiving,
    required CoGuestLayoutTemplate layout,
    required int connectedGuestCount,
  }) =>
      isLiving && (connectedGuestCount > 0 || layout != CoGuestLayoutTemplate.floatLayout);

  void dispose() {
    _adapter.dispose();
    coGuestVideoStateNotifier.dispose();
    selectedGuestUserID.dispose();
  }
}

class PusherVideoView extends StatelessWidget {
  const PusherVideoView({super.key, required this.controller});

  final PusherVideoController controller;

  /// 68 工具栏内容 + 10 舞台间距 + 实际安全区；键盘不改变画布。
  static double bottomInsetOf(BuildContext context) => 78 + MediaQuery.viewPaddingOf(context).bottom;

  /// UIColor(white: 0.12, alpha: 1)
  static const Color _idleBackgroundColor = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PusherCoGuestVideoState>(
      valueListenable: controller.coGuestVideoStateNotifier,
      builder: (BuildContext context, PusherCoGuestVideoState videoState, Widget? child) {
        return ColoredBox(
          color: controller.isCoGuestStageVisible ? const Color(0x00000000) : _idleBackgroundColor,
          child: controller.widget,
        );
      },
    );
  }
}

/// 记录真实渲染席位的位置，供上层 Living 手势层做命中判断。
///
/// `AtomicLiveWidget` 位于 `PusherLivingView` 下方，席位自身不能直接赢得手势；
/// 因此与 iOS 一样，由容器收到点击后再查询实际席位视图。
class _PusherCoGuestSeatHitTestRegistry {
  final Map<String, GlobalKey> _seatKeys = <String, GlobalKey>{};

  GlobalKey keyFor(String userID) => _seatKeys.putIfAbsent(
        userID,
        () => GlobalKey(debugLabel: 'co_guest_seat_$userID'),
      );

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

class PusherUnitAdapter extends AtomicLiveViewChangeAdapter {
  PusherUnitAdapter(this.state, {String Function()? localUserID}) : _localUserID = localUserID ?? _currentUserID {
    state.addListener(_onVideoStateChanged);
  }

  final String Function() _localUserID;
  static String _currentUserID() => LoginStore.shared.loginState.loginUserInfo?.userID ?? '';

  final ValueListenable<PusherCoGuestVideoState> state;
  final Map<String, ValueNotifier<(UnitInfo, int)>> _units = {};

  @override
  Widget onCreateUnitView(UnitInfo unitInfo) {
    if (_disposed) return const SizedBox.shrink();
    final notifier =
        _units.putIfAbsent('${unitInfo.liveID}:${unitInfo.index}', () => ValueNotifier((_copyUnit(unitInfo), 0)));
    _updateUnit(unitInfo);
    return ValueListenableBuilder<(UnitInfo, int)>(
      valueListenable: notifier,
      builder: (BuildContext context, (UnitInfo, int) entry, _) {
        final unit = entry.$1;
        return ValueListenableBuilder<PusherCoGuestVideoState>(
          valueListenable: state,
          builder: (BuildContext context, PusherCoGuestVideoState videoState, _) {
            final String loginUserID = _localUserID();
            final bool isHost = unit.userID.isNotEmpty && unit.userID == loginUserID;
            final bool isGuest = unit.userID.isNotEmpty && !isHost;
            final Widget seat = PusherUnitView(
              unitInfo: unit,
              isLiving: videoState.isLiving,
              showsEmptySeats: videoState.showsEmptySeats,
              hasGuests: videoState.hasGuests,
              showsHostOverlay: videoState.showsHostOverlay,
              isHost: isHost,
              localCameraStatus: videoState.localCameraStatus,
              volume: entry.$2,
            );
            final bool tracksRegion = videoState.isLiving &&
                (unit.userID.isEmpty
                    ? videoState.showsEmptySeats
                    : ((isGuest || isHost) && (videoState.hasGuests || videoState.showsHostOverlay)));
            if (!tracksRegion) {
              return seat;
            }
            final Widget keyed = isGuest
                ? KeyedSubtree(
                    key: _hitTestRegistry.keyFor(unit.userID),
                    child: seat,
                  )
                : seat;
            return _observe(keyed);
          },
        );
      },
    );
  }

  @override
  // SDK variants pass Key? or Widget?; updates are addressed by seat index.
  void onUpdateUnitView(UnitInfo unitInfo, Object? view) {
    if (!_disposed) _updateUnit(unitInfo);
  }

  UnitInfo _copyUnit(UnitInfo info) => UnitInfo(
        index: info.index,
        liveID: info.liveID,
        userID: info.userID,
        userName: info.userName,
        avatarURL: info.avatarURL,
        microphoneStatus: info.microphoneStatus,
        cameraStatus: info.cameraStatus,
        userSuspendStatus: info.userSuspendStatus,
      );

  void _updateUnit(UnitInfo info) {
    final notifier = _units['${info.liveID}:${info.index}'];
    if (notifier == null) return;
    final previous = notifier.value;
    final keepVolume = previous.$1.userID == info.userID &&
        previous.$1.liveID == info.liveID &&
        info.userID.isNotEmpty &&
        info.microphoneStatus == DeviceStatus.on &&
        state.value.isLiving;
    notifier.value = (_copyUnit(info), keepVolume ? previous.$2 : 0);
  }

  void _onVideoStateChanged() {
    if (_disposed || state.value.isLiving) return;
    for (final notifier in _units.values) {
      notifier.value = (notifier.value.$1, 0);
    }
  }

  @override
  void onVolumeChanged(UnitInfo unitInfo, int volume, Object? view) {
    if (_disposed || !state.value.isLiving) return;
    final notifier = _units['${unitInfo.liveID}:${unitInfo.index}'];
    if (notifier == null) return;
    final unit = notifier.value.$1;
    if (unit.userID.isEmpty || unit.userID != unitInfo.userID || unit.liveID != unitInfo.liveID) return;
    notifier.value = (unit, unit.microphoneStatus == DeviceStatus.on ? volume.clamp(0, 100) : 0);
  }

  @override
  void onVideoViewFrameChanged(double left, double top, double right, double bottom) {}

  final _PusherCoGuestSeatHitTestRegistry _hitTestRegistry = _PusherCoGuestSeatHitTestRegistry();
  String? guestUserIDAt(Offset position) =>
      state.value.isLiving && !state.value.isCoHostConnected && state.value.connectedGuestCount > 0
          ? _hitTestRegistry.guestUserIDAt(position)
          : null;
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
    if (_disposed) return;
    _disposed = true;
    state.removeListener(_onVideoStateChanged);
    for (final unit in _units.values) {
      unit.dispose();
    }
    _units.clear();
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
