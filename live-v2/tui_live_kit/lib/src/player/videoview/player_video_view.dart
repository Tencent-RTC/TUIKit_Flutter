import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../player_view.dart';
import 'unit_view.dart';

enum PlayerPlaybackState { idle, loading, playing, failed }

class PlayerVideoViewController {
  final AtomicLiveController coreController = AtomicLiveController.create(AtomicLiveViewType.playView);
  final AtomicPlayer player = AtomicPlayer();
  late final AtomicLiveWidget widget = AtomicLiveWidget(controller: coreController);
  late final AtomicLiveViewChangeAdapter _adapter = _PlayerUnitAdapter(this);
  final ValueNotifier<PlayerPlaybackState> state = ValueNotifier<PlayerPlaybackState>(PlayerPlaybackState.idle);

  /// 当前 `PlayerStatus`，由 `_PlayerViewControllerImpl` 同步，仅用于席位挂件门控。
  /// `inRoom` / `coGuest` 之外的阶段，`UnitView` 内置规则会隐藏 overlay。
  final ValueNotifier<PlayerStatus> playerStatus = ValueNotifier<PlayerStatus>(PlayerStatus.idle);

  String? _playingLiveID;
  final ValueNotifier<int> geometryChanges = ValueNotifier(0);
  final Map<Object, (String, Rect)> _regions = {};
  bool _geometryScheduled = false;
  bool _disposed = false;
  List<Rect> seatRegions() =>
      _regions.values.where((entry) => entry.$1 == _liveInfo?.liveID).map((entry) => entry.$2).toList(growable: false);
  void _regionChanged(Object id, String liveID, Rect? rect) {
    if (_disposed || (rect != null && _regions[id] == (liveID, rect))) return;
    if (rect == null) {
      if (_regions.remove(id) == null) return;
    } else {
      _regions[id] = (liveID, rect);
    }
    if (_geometryScheduled) return;
    _geometryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryScheduled = false;
      if (!_disposed) geometryChanges.value++;
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// 当前播放音量，与 iOS `PlayerViewImpl.setVolume` 一样由入口显式设置；
  /// `startPreview` 只用它恢复音量，不再由静音参数推导。
  int volume = 0;
  LiveInfo? _liveInfo;
  LiveInfo? get liveInfo => _liveInfo;

  PlayerVideoViewController() {
    coreController.setViewChangeAdapter(_adapter);
    player.setView(widget);
    player.state.playbackStatus.addListener(_onPlaybackStatus);
  }

  void _onPlaybackStatus() {
    if (_playingLiveID == null) return;
    state.value = switch (player.state.playbackStatus.value) {
      PlayerPlaybackStatus.idle => PlayerPlaybackState.idle,
      PlayerPlaybackStatus.loading => PlayerPlaybackState.loading,
      PlayerPlaybackStatus.playing => PlayerPlaybackState.playing,
    };
  }

  void setLiveInfo(LiveInfo liveInfo) {
    if (_liveInfo?.liveID != liveInfo.liveID) {
      _regions.clear();
      (_adapter as _PlayerUnitAdapter).clearUnits();
    }
    _liveInfo = liveInfo;
  }

  void startPreview({required String liveID}) {
    if (liveID.isEmpty) return;
    if (_playingLiveID == liveID) return;
    _playingLiveID = liveID;
    state.value = PlayerPlaybackState.loading;
    player.setVolume(volume);
    player.startPlay('livekit://liveid=$liveID');
  }

  void setVolume(int value) {
    volume = value;
    if (_playingLiveID == null) return;
    player.setVolume(value);
  }

  void stopPreview() {
    if (_playingLiveID == null) return;
    _playingLiveID = null;
    player.stopPlay();
    state.value = PlayerPlaybackState.idle;
  }

  void dispose() {
    stopPreview();
    _disposed = true;
    _regions.clear();
    geometryChanges.dispose();
    player.state.playbackStatus.removeListener(_onPlaybackStatus);
    (_adapter as _PlayerUnitAdapter).clearUnits();
    state.dispose();
    playerStatus.dispose();
  }
}

class PlayerVideoView extends StatelessWidget {
  const PlayerVideoView({super.key, required this.controller});

  final PlayerVideoViewController controller;

  @override
  Widget build(BuildContext context) => controller.widget;
}

class _PlayerUnitAdapter extends AtomicLiveViewChangeAdapter {
  _PlayerUnitAdapter(this.controller);

  final PlayerVideoViewController controller;
  final Map<String, ValueNotifier<UnitInfo>> _units = {};
  final Map<String, ValueNotifier<int>> _volumes = {};

  String _unitKey(UnitInfo unitInfo) => '${unitInfo.liveID}:${unitInfo.index}';

  @override
  Widget onCreateUnitView(UnitInfo unitInfo) {
    final key = _unitKey(unitInfo);
    final notifier = _units.putIfAbsent(key, () => ValueNotifier<UnitInfo>(unitInfo));
    notifier.value = unitInfo;
    final volume = _volumes.putIfAbsent(key, () => ValueNotifier<int>(0));
    return ValueListenableBuilder<UnitInfo>(
      valueListenable: notifier,
      builder: (_, unit, __) => ValueListenableBuilder<int>(
        valueListenable: volume,
        builder: (_, unitVolume, __) => ValueListenableBuilder<PlayerStatus>(
          valueListenable: controller.playerStatus,
          builder: (_, status, __) => _PlayerSeatObserver(
            onRegion: (id, rect) => controller._regionChanged(id, unit.liveID, rect),
            child: UnitView(
              unitInfo: unit,
              liveInfo: controller.liveInfo,
              playerStatus: status,
              volume: unitVolume,
            ),
          ),
        ),
      ),
    );
  }

  @override
  // SDK variants pass Key? or Widget?; updates are addressed by seat index.
  void onUpdateUnitView(UnitInfo unitInfo, Object? view) {
    _units[_unitKey(unitInfo)]?.value = unitInfo;
  }

  @override
  void onVolumeChanged(UnitInfo unitInfo, int volume, Widget? view) {
    final notifier = _volumes[_unitKey(unitInfo)];
    if (notifier == null || notifier.value == volume) return;
    notifier.value = volume;
  }

  @override
  void onVideoViewFrameChanged(double left, double top, double right, double bottom) {}

  void clearUnits() {
    for (final unit in _units.values) {
      unit.dispose();
    }
    _units.clear();
    for (final volume in _volumes.values) {
      volume.dispose();
    }
    _volumes.clear();
  }
}

class _PlayerSeatObserver extends SingleChildRenderObjectWidget {
  const _PlayerSeatObserver({required this.onRegion, required super.child});
  final void Function(Object, Rect?) onRegion;
  @override
  RenderObject createRenderObject(BuildContext context) => _PlayerSeatBox(onRegion);
  @override
  void updateRenderObject(BuildContext context, _PlayerSeatBox box) {
    box.onRegion = onRegion;
  }
}

class _PlayerSeatBox extends RenderProxyBox {
  _PlayerSeatBox(this.onRegion);
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
