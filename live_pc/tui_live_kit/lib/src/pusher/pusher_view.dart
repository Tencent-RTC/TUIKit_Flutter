import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_media_mixing/api/media_mixing_store.dart';
import 'package:flutter/material.dart';

import 'living/audience/audience_widget.dart';
import 'basic_control/live_control_bar.dart';
import '../common/style/live_kit_style.dart';
import 'living/barrage/interaction_panel.dart';
import '../l10n/live_kit_localizations.dart';
import '../common/widget/toast.dart';
import 'live_info/live_info_edit_dialog.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_persistence.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_store.dart';

import '../common/platform/bookmark_channel.dart';
import 'capabilities/scene/scene_localization.dart';
import 'summary/live_summary_dialog.dart';
import 'capabilities/capabilities_panel.dart';

import 'stream_mixer_view.dart';
import 'live_info/live_info_bar.dart';

const int _kLandscapeLayoutTemplateId = 200;

class PusherView extends StatefulWidget {
  final String liveID;
  final String hostName;

  /// Vertical space reserved under a host-drawn top bar that overlays this
  /// view: content starts below it while the background gradient still
  /// extends underneath.
  final double topInset;

  const PusherView({super.key, this.liveID = '', this.hostName = '', this.topInset = 0});

  @override
  State<PusherView> createState() => _PusherViewState();
}

class _PusherViewState extends State<PusherView> {
  final SceneStore _sceneStore = SceneStore(strings: const LiveKitSceneStrings());
  late final SceneController _controller = SceneController(
    _sceneStore,
    onRuntimeError: (message) => showToast(context, message, level: ToastLevel.error),
    bookmarkChannel: const LiveKitBookmarkChannel(),
  );
  final ValueNotifier<bool> _isLiveStarted = ValueNotifier(false);
  final ValueNotifier<DateTime?> _liveStartTime = ValueNotifier(null);
  final ValueNotifier<int> _captureVolume = ValueNotifier(100);
  final ValueNotifier<int> _outputVolume = ValueNotifier(100);
  final ValueNotifier<bool> _isStarting = ValueNotifier(false);
  final ValueNotifier<bool> _micOn = ValueNotifier(true);
  final ValueNotifier<bool> _speakerMuted = ValueNotifier(false);
  late final ValueNotifier<String> _liveName;
  final ValueNotifier<bool> _isPublicVisible = ValueNotifier(true);

  PusherListener? _pusherListener;
  Completer<PusherSummary?>? _stopPushCompleter;

  bool _liveNameReady = false;

  SceneAutoSave? _persistence;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSnapshot());
    _persistence = SceneAutoSave(userId: _snapshotUserId, store: _sceneStore);
    _pusherListener = PusherListener(
      pusherError: _onPusherError,
      liveEnded: _onPusherLiveEnded,
      kickedOut: _onPusherKickedOut,
    );
    AtomicPusher.shared.addListener(_pusherListener);
    AtomicPusher.shared.state.networkState.addListener(_onPushNetworkChanged);
  }

  String get _avatarUrl => LoginStore.shared.loginState.loginUserInfo?.avatarURL ?? '';

  String get _snapshotUserId {
    final userId = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return widget.hostName;
  }

  Future<void> _restoreSnapshot() async {
    final userId = _snapshotUserId;
    if (userId.isEmpty) {
      return;
    }
    final snapshot = await SceneSnapshotStore.load(userId);
    if (snapshot == null || !mounted) {
      return;
    }
    final encoderParams = SceneSnapshotStore.encoderParamsFromSnapshot(snapshot);
    if (encoderParams != null) {
      SceneSnapshotStore.applyEncoderParams(encoderParams);
    }
    if (!mounted) {
      return;
    }
    _controller.restoreSnapshot(snapshot);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_liveNameReady) {
      _liveName = ValueNotifier(LiveKitLocalizations.of(context).liveDefaultName(widget.hostName));
      _liveNameReady = true;
    }
  }

  @override
  void dispose() {
    final stopCompleter = _stopPushCompleter;
    if (stopCompleter != null && !stopCompleter.isCompleted) {
      stopCompleter.complete(null);
    }
    _stopPushCompleter = null;
    if (_isLiveStarted.value || _isStarting.value) {
      AtomicPusher.shared.stopPush();
      MediaMixingStore.shared.detachFromLive();
    }
    AtomicPusher.shared.state.networkState.removeListener(_onPushNetworkChanged);
    AtomicPusher.shared.removeListener(_pusherListener);
    _pusherListener = null;
    _persistence?.dispose();
    _isPublicVisible.dispose();
    _liveName.dispose();
    _isStarting.dispose();
    _speakerMuted.dispose();
    _micOn.dispose();
    _outputVolume.dispose();
    _captureVolume.dispose();
    _liveStartTime.dispose();
    _isLiveStarted.dispose();
    _controller.dispose();
    _sceneStore.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    if (_isStarting.value) return;
    _isStarting.value = true;
    AtomicPusher.shared.startPush(
      PusherInfo(liveID: widget.liveID, liveName: _liveName.value, isPublicVisible: _isPublicVisible.value),
    );
  }

  void _onPushConnected() {
    _isStarting.value = false;
    MediaMixingStore.shared.attachToLive();
    _syncLayoutTemplate();
    final int createTimeSec = AtomicPusher.shared.state.pusherInfo.value.createTime;
    _liveStartTime.value =
        createTimeSec > 0 ? DateTime.fromMillisecondsSinceEpoch(createTimeSec * 1000) : DateTime.now();
    _isLiveStarted.value = true;

    DeviceStore.shared.setOutputVolume(_speakerMuted.value ? 0 : _outputVolume.value);
    if (_micOn.value) {
      DeviceStore.shared.openLocalMicrophone().then((mic) {
        if (!mounted) return;
        if (mic.isSuccess) {
          DeviceStore.shared.setCaptureVolume(_captureVolume.value);
        }
      });
    }
  }

  Future<void> _syncLayoutTemplate() async {
    final bool isLandscape =
        MediaMixingStore.shared.state.params.value.videoEncoderParams.resolutionMode == VideoResolutionMode.landscape;
    if (!isLandscape) return;
    final result = await CoGuestStore.create(
      widget.liveID,
    ).setLayoutTemplate(template: const CoGuestLayoutTemplate(_kLandscapeLayoutTemplateId));
    if (!mounted) return;
    if (!result.isSuccess) {
      showToast(context, LiveKitLocalizations.of(context).errorOperationFailed, level: ToastLevel.error);
    }
  }

  void _onPushNetworkChanged() {
    if (!mounted) return;
    switch (AtomicPusher.shared.state.networkState.value) {
      case PusherConnectState.connected:
        if (!_isLiveStarted.value && _isStarting.value) {
          _onPushConnected();
        }
      case PusherConnectState.disconnected:
        if (_isStarting.value) {
          _isStarting.value = false;
        }
      case PusherConnectState.connecting:
        break;
    }
  }

  void _onPusherError(PusherCode code, String message) {
    if (!mounted) return;
    if (_isStarting.value) {
      _isStarting.value = false;
    }
    final l10n = LiveKitLocalizations.of(context);
    final serverCode = RegExp(r'error_code:(\d+)').firstMatch(message)?.group(1);
    final String text;
    if (serverCode == '100026') {
      text = l10n.liveStartFailedSensitiveInfo;
    } else {
      text = l10n.liveStartFailed('${code.value}', message.isNotEmpty ? message : l10n.errorUnknown);
    }
    showToast(context, text, level: ToastLevel.error);
  }

  void _onPusherLiveEnded(EndedReason reason, PusherSummary? summary) {
    final completer = _stopPushCompleter;
    _stopPushCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(summary);
      return;
    }
    if (!mounted) return;
    _resetLiveState();
  }

  void _onPusherKickedOut(KickedOutReason reason, String message) {
    _stopPushCompleter = null;
    if (!mounted) return;
    _resetLiveState();
    if (message.isNotEmpty) {
      showToast(context, message, level: ToastLevel.error);
    }
  }

  void _resetLiveState() {
    _isStarting.value = false;
    _liveStartTime.value = null;
    _isLiveStarted.value = false;
    MediaMixingStore.shared.detachFromLive();
  }

  Future<void> _endLive() async {
    final durationSec = _elapsedLiveSeconds();

    final summary = await _stopPushAndWaitSummary();
    if (!mounted) return;
    _resetLiveState();
    if (summary != null) {
      final data = LiveSummaryData(
        totalViewers: summary.totalViewers,
        totalGiftsSent: summary.totalGiftsSent,
        totalGiftUniqueSenders: summary.totalUniqueGiftSenders,
        totalGiftCoins: summary.totalGiftCoins,
        totalLikesReceived: summary.totalLikesReceived,
        totalMessageSent: summary.totalMessageCount,
      );
      final int finalDurationSec = summary.liveDuration > 0 ? summary.liveDuration : durationSec;
      _showLiveSummaryDialog(data, finalDurationSec);
    }
  }

  Future<PusherSummary?> _stopPushAndWaitSummary() {
    final completer = Completer<PusherSummary?>();
    _stopPushCompleter = completer;
    AtomicPusher.shared.stopPush();
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () => null);
  }

  int _elapsedLiveSeconds() {
    final start = _liveStartTime.value;
    if (start == null) return 0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  void _showLiveSummaryDialog(LiveSummaryData? summary, int durationSec) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: false,
      builder: (_) => PopScope(canPop: false, child: LiveSummaryDialog(summary: summary, durationSec: durationSec)),
    );
  }

  Future<void> _setLiveName(String name) async {
    _liveName.value = name;
    if (!_isLiveStarted.value) return;
    AtomicPusher.shared.updateConfig(PusherInfo(liveID: widget.liveID, liveName: name), const [
      PusherInfoModifyFlag.liveName,
    ]);
  }

  Future<void> _setLivePublicVisible(bool isPublicVisible) async {
    _isPublicVisible.value = isPublicVisible;
    if (!_isLiveStarted.value) return;
    AtomicPusher.shared.updateConfig(PusherInfo(liveID: widget.liveID, isPublicVisible: isPublicVisible), const [
      PusherInfoModifyFlag.isPublicVisible,
    ]);
  }

  Future<void> _editLiveInfo() async {
    final result = await showRoomEditDialog(
      context,
      initialName: _liveName.value,
      initialVisibility: _isPublicVisible.value ? RoomVisibility.public : RoomVisibility.privacy,
    );
    if (result == null || !mounted) return;
    await _setLiveName(result.name);
    await _setLivePublicVisible(result.visibility == RoomVisibility.public);
  }

  void _onCaptureVolumeChanged(int volume) {
    _captureVolume.value = volume;
    if (!_isLiveStarted.value) return;
    DeviceStore.shared.setCaptureVolume(volume);
  }

  void _onOutputVolumeChanged(int volume) {
    _outputVolume.value = volume;
    if (_speakerMuted.value && volume > 0) {
      _speakerMuted.value = false;
    }
    if (!_isLiveStarted.value) return;
    DeviceStore.shared.setOutputVolume(volume);
  }

  void _toggleMicrophone() {
    final on = !_micOn.value;
    _micOn.value = on;
    if (!_isLiveStarted.value) return;
    if (on) {
      DeviceStore.shared.openLocalMicrophone();
    } else {
      DeviceStore.shared.closeLocalMicrophone();
    }
  }

  void _toggleSpeakerMute() {
    final muted = !_speakerMuted.value;
    _speakerMuted.value = muted;
    if (!_isLiveStarted.value) return;
    DeviceStore.shared.setOutputVolume(muted ? 0 : _outputVolume.value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamilyFallback: LiveKitStyle.cjkFontFamilyFallback),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.26, -0.97),
              end: Alignment(0.26, 0.97),
              colors: [LiveKitStyle.bgBase1, LiveKitStyle.bgBase2, LiveKitStyle.bgBase3],
              stops: [0, 0.5, 1],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.8, -1.2),
                      radius: 1.2,
                      stops: [0, 0.68],
                      colors: [LiveKitStyle.bgGlow1, Color(0x00FF4691)],
                      transform: EllipticalGradientTransform(
                        center: Alignment(-0.8, -1.2),
                        yScale: 585 / 1080, // ry / rx
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(1.0, 1.2),
                      radius: 1.12,
                      stops: [0, 0.68],
                      colors: [LiveKitStyle.bgGlow2, Color(0x0014EBC8)],
                      transform: EllipticalGradientTransform(
                        center: Alignment(1.0, 1.2),
                        yScale: 540 / 1008, // ry / rx
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12, 12 + widget.topInset, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CapabilitiesPanel(store: _sceneStore, controller: _controller),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                PusherLiveInfoBar(
                                  isLiveStarted: _isLiveStarted,
                                  liveName: _liveName,
                                  avatarUrl: _avatarUrl,
                                  hostName: widget.hostName,
                                  liveID: widget.liveID,
                                  liveStartTime: _liveStartTime,
                                  onEditLiveInfo: _editLiveInfo,
                                ),
                                const SizedBox(height: 12),
                                Expanded(child: PusherStreamMixerView(store: _sceneStore, controller: _controller)),
                                const SizedBox(height: 12),
                                PusherControlBar(
                                  isLiveStarted: _isLiveStarted,
                                  isStarting: _isStarting,
                                  micOn: _micOn,
                                  speakerMuted: _speakerMuted,
                                  captureVolume: _captureVolume,
                                  outputVolume: _outputVolume,
                                  onToggleMicrophone: _toggleMicrophone,
                                  onToggleSpeakerMute: _toggleSpeakerMute,
                                  onCaptureVolumeChanged: _onCaptureVolumeChanged,
                                  onOutputVolumeChanged: _onOutputVolumeChanged,
                                  onStartLive: _startLive,
                                  onEndLive: _endLive,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 256,
                            child: Column(
                              children: [
                                AudienceView(liveID: widget.liveID, isLiveStarted: _isLiveStarted),
                                const SizedBox(height: 8),
                                Expanded(child: InteractionPanel(liveID: widget.liveID, isLiveStarted: _isLiveStarted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
