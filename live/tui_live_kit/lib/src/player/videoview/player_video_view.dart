import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../player_view.dart';
import '../../common/live_kit_resources.dart';
import 'player_unit_view.dart';

enum PlayerPlaybackState {
  idle,
  loading,
  playing,
  failed,
}

class PlayerVideoViewController {
  final AtomicLiveController coreController = AtomicLiveController.create(AtomicLiveViewType.playView);
  final AtomicPlayer player = AtomicPlayer();
  late final AtomicLiveWidget widget = AtomicLiveWidget(controller: coreController);
  late final AtomicLiveViewChangeAdapter _adapter = _PlayerUnitAdapter(this);
  final ValueNotifier<PlayerPlaybackState> state = ValueNotifier<PlayerPlaybackState>(PlayerPlaybackState.idle);

  /// 当前 `PlayerStatus`，由 `_PlayerViewControllerImpl` 同步，仅用于席位挂件门控。
  /// `inRoom` / `coGuest` 之外的阶段，`PlayerUnitView` 内置规则会隐藏 overlay。
  final ValueNotifier<PlayerStatus> playerStatus = ValueNotifier<PlayerStatus>(PlayerStatus.idle);

  String? _playingLiveID;
  final ValueNotifier<int> geometryChanges = ValueNotifier(0);
  final Map<Object, (String, Rect)> _regions = {};
  final Set<Object> _remoteHostRegions = {};
  final ValueNotifier<bool> coHostConnected = ValueNotifier(false);
  bool _geometryScheduled = false;
  bool _disposed = false;
  List<Rect> seatRegions() =>
      _regions.values.where((entry) => entry.$1 == _liveInfo?.liveID).map((entry) => entry.$2).toList(growable: false);
  void _regionChanged(Object id, String liveID, Rect? rect, bool isRemoteHost) {
    if (_disposed || liveID != _liveInfo?.liveID) return;
    final wasRemote = _remoteHostRegions.contains(id);
    if (rect != null && isRemoteHost) {
      _remoteHostRegions.add(id);
    } else {
      _remoteHostRegions.remove(id);
    }
    if (rect != null && _regions[id] == (liveID, rect) && wasRemote == isRemoteHost) return;
    if (rect == null) {
      if (_regions.remove(id) == null) return;
    } else {
      _regions[id] = (liveID, rect);
    }
    if (_geometryScheduled) return;
    _geometryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryScheduled = false;
      if (!_disposed) {
        coHostConnected.value = _remoteHostRegions.isNotEmpty;
        geometryChanges.value++;
      }
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
    playerStatus.addListener(_onPlayerStatus);
  }

  void _onPlayerStatus() {
    if (playerStatus.value != PlayerStatus.inRoom && playerStatus.value != PlayerStatus.coGuest) {
      (_adapter as _PlayerUnitAdapter).clearVolumes();
    }
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
      _remoteHostRegions.clear();
      coHostConnected.value = false;
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
    (_adapter as _PlayerUnitAdapter).clearVolumes();
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
    coHostConnected.dispose();
    player.state.playbackStatus.removeListener(_onPlaybackStatus);
    playerStatus.removeListener(_onPlayerStatus);
    (_adapter as _PlayerUnitAdapter).clearUnits();
    state.dispose();
    playerStatus.dispose();
  }
}

class PlayerVideoView extends StatelessWidget {
  const PlayerVideoView({super.key, required this.controller});

  final PlayerVideoViewController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: controller.coHostConnected,
        child: controller.widget,
        builder: (context, connected, child) => Stack(fit: StackFit.expand, children: [
          if (connected) Image(image: LiveKitResources.image('livekit_pusher_coguest_background'), fit: BoxFit.fill),
          child!,
        ]),
      );
}

class _PlayerUnitAdapter extends AtomicLiveViewChangeAdapter {
  _PlayerUnitAdapter(this.controller);

  final PlayerVideoViewController controller;
  final Map<String, ValueNotifier<(UnitInfo, int)>> _units = {};

  @override
  Widget onCreateUnitView(UnitInfo unitInfo) {
    if (controller._disposed) return const SizedBox.shrink();
    final sessionLiveID = controller.liveInfo?.liveID ?? '';
    final notifier =
        _units.putIfAbsent('${unitInfo.liveID}:${unitInfo.index}', () => ValueNotifier((_copyUnit(unitInfo), 0)));
    _updateUnit(unitInfo);
    return ValueListenableBuilder<(UnitInfo, int)>(
      valueListenable: notifier,
      builder: (_, entry, __) => ValueListenableBuilder<PlayerStatus>(
        valueListenable: controller.playerStatus,
        builder: (_, status, __) => ValueListenableBuilder<bool>(
          valueListenable: controller.coHostConnected,
          builder: (_, connected, __) => _PlayerSeatObserver(
              onRegion: (id, rect) => controller._regionChanged(id, sessionLiveID, rect,
                  entry.$1.userID.isNotEmpty && entry.$1.liveID.isNotEmpty && entry.$1.liveID != sessionLiveID),
              child: PlayerUnitView(
                  unitInfo: entry.$1,
                  liveInfo: controller.liveInfo,
                  playerStatus: status,
                  volume: entry.$2,
                  isCoHostConnected: connected)),
        ),
      ),
    );
  }

  @override
  // SDK variants pass Key? or Widget?; updates are addressed by seat index.
  void onUpdateUnitView(UnitInfo unitInfo, Object? view) {
    if (_isCurrentLive(unitInfo)) _updateUnit(unitInfo);
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

  bool _isCurrentLive(UnitInfo info) => !controller._disposed;

  bool get _roomActive =>
      controller.playerStatus.value == PlayerStatus.inRoom || controller.playerStatus.value == PlayerStatus.coGuest;

  void _updateUnit(UnitInfo info) {
    final notifier = _units['${info.liveID}:${info.index}'];
    if (notifier == null) return;
    final previous = notifier.value;
    final keepVolume = previous.$1.userID == info.userID &&
        info.userID.isNotEmpty &&
        info.microphoneStatus == DeviceStatus.on &&
        _roomActive;
    notifier.value = (_copyUnit(info), keepVolume ? previous.$2 : 0);
  }

  @override
  void onVolumeChanged(UnitInfo unitInfo, int volume, Object? view) {
    if (!_isCurrentLive(unitInfo) || !_roomActive) return;
    final notifier = _units['${unitInfo.liveID}:${unitInfo.index}'];
    if (notifier == null) return;
    final unit = notifier.value.$1;
    if (unit.userID.isEmpty || unit.userID != unitInfo.userID) return;
    notifier.value = (unit, unit.microphoneStatus == DeviceStatus.on ? volume.clamp(0, 100) : 0);
  }

  void clearVolumes() {
    for (final notifier in _units.values) {
      notifier.value = (notifier.value.$1, 0);
    }
  }

  @override
  void onVideoViewFrameChanged(double left, double top, double right, double bottom) {}

  void clearUnits() {
    for (final unit in _units.values) {
      unit.dispose();
    }
    _units.clear();
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
