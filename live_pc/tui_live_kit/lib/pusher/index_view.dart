import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'audience/audience_widget.dart';
import 'bottom_toolbar_view.dart';
import 'head_view.dart';
import 'barrage/index.dart';
import 'pusher_style.dart';
import '../l10n/live_kit_localizations.dart';
import 'prepare/liveInfo_edit_dialog.dart';
import 'summary/live_summary_dialog.dart';
import 'scene/index_view.dart';

import 'scene/scene_engine_sync.dart';
import 'scene/scene_store.dart';
import 'stream_mixer/index_view.dart';
import 'top_toolbar_view.dart';

/// 主播端入口组件：按 PC 设计稿划定页面框架。
///
/// ```text
/// ┌──────────────────────────────────────────────┐
/// │ head_view（顶部信息栏）                        │
/// ├─────────┬────────────────────────┬───────────┤
/// │         │ top_toolbar_view       │ audience  │
/// │ scene   ├────────────────────────├───────────┤
/// │ （左侧   │ stream_mixer（预览画布） │ barrage   │
/// │  场景    ├────────────────────────┤           │
/// │  管理）  │ bottom_toolbar_view    │           │
/// └─────────┴────────────────────────┴───────────┘
/// ```
///
/// [SceneStore] 由根入口持有并注入 scene（后续 stream_mixer 的
/// 预览画布也消费同一份数据）；引擎接入后再桥接 AtomicXCore。
class PusherView extends StatefulWidget {
  final String liveID;
  final String hostName;

  const PusherView({
    super.key,
    this.liveID = '',
    this.hostName = '主播小明',
  });

  @override
  State<PusherView> createState() => _PusherViewState();
}

class _PusherViewState extends State<PusherView> {
  final SceneStore _sceneStore = SceneStore();
  late final SceneEngineSync _engineSync = SceneEngineSync(_sceneStore);
  final ValueNotifier<bool> _isLiveStarted = ValueNotifier(false);
  final ValueNotifier<DateTime?> _liveStartTime = ValueNotifier(null);
  final ValueNotifier<int> _captureVolume = ValueNotifier(68);
  final ValueNotifier<int> _outputVolume = ValueNotifier(33);
  final ValueNotifier<bool> _micOn = ValueNotifier(true);
  final ValueNotifier<bool> _speakerMuted = ValueNotifier(false);
  late final ValueNotifier<String> _liveName;
  final ValueNotifier<bool> _isPublicVisible = ValueNotifier(true);

  bool _isStarting = false;
  bool _liveNameReady = false;

  String get _avatarUrl =>
      LoginStore.shared.loginState.loginUserInfo?.avatarURL ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_liveNameReady) {
      _liveName = ValueNotifier(
        LiveKitLocalizations.of(context).liveDefaultName(widget.hostName),
      );
      _liveNameReady = true;
    }
  }

  @override
  void dispose() {
    _isPublicVisible.dispose();
    _liveName.dispose();
    _speakerMuted.dispose();
    _micOn.dispose();
    _outputVolume.dispose();
    _captureVolume.dispose();
    _liveStartTime.dispose();
    _isLiveStarted.dispose();
    _engineSync.dispose();
    _sceneStore.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    final bool isLandscape = MediaMixingStore
            .shared.state.params.value.videoEncoderParams.resolutionMode ==
        VideoResolutionMode.landscape;

    final LiveInfo liveInfo = LiveInfo()
      ..liveID = widget.liveID
      ..liveName = _liveName.value
      ..isPublicVisible = _isPublicVisible.value
      ..seatTemplate = isLandscape
          ? const VideoLandscape4Seats() // 横屏 → seatLayoutTemplateID 200
          : const VideoDynamicGrid9Seats(); // 竖屏 → seatLayoutTemplateID 600

    final LiveInfoCompletionHandler result =
        await LiveListStore.shared.startLive(liveInfo);

    if (!mounted) return;
    setState(() => _isStarting = false);
    if (!result.isSuccess) {
      return;
    }else{
      MediaMixingStore.shared.attachToLive();
    }
    _liveStartTime.value = DateTime.now();
    _isLiveStarted.value = true;

    DeviceStore.shared.setOutputVolume(
        _speakerMuted.value ? 0 : _outputVolume.value);
    if (_micOn.value) {
      final mic = await DeviceStore.shared.openLocalMicrophone();
      if (mic.isSuccess) {
        DeviceStore.shared.setCaptureVolume(_captureVolume.value);
      }
    }
  }

  Future<void> _endLive() async {
    final summary = LiveSummaryStore.create(widget.liveID,).liveSummaryState.summaryData.value;
    final durationSec = _elapsedLiveSeconds();

    final result = await LiveListStore.shared.endLive();
    if (!mounted) return;
    if (result.isSuccess) {
      _liveStartTime.value = null;
      _isLiveStarted.value = false;
      MediaMixingStore.shared.detachFromLive();
      _showLiveSummaryDialog(summary, durationSec);
    }
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
      builder: (_) => LiveSummaryDialog(
        summary: summary,
        durationSec: durationSec,
      ),
    );
  }

  Future<void> _setLiveName(String name) async {
    _liveName.value = name;
    if (!_isLiveStarted.value) return;
    await LiveListStore.shared.updateLiveInfo(
      liveInfo: LiveInfo()..liveID = widget.liveID..liveName = name,
      modifyFlagList: const [ModifyFlag.liveName],
    );
  }

  Future<void> _setLivePublicVisible(bool isPublicVisible) async {
    _isPublicVisible.value = isPublicVisible;
    if (!_isLiveStarted.value) return;
    await LiveListStore.shared.updateLiveInfo(
      liveInfo: LiveInfo()
        ..liveID = widget.liveID
        ..isPublicVisible = isPublicVisible,
      modifyFlagList: const [ModifyFlag.isPublicVisible],
    );
  }

  Future<void> _editLiveInfo() async {
    final result = await showRoomEditDialog(
      context,
      initialName: _liveName.value,
      initialVisibility: _isPublicVisible.value
          ? RoomVisibility.public
          : RoomVisibility.privacy,
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
      child: DecoratedBox(
        // 窗口底色：linear-gradient(165deg, bg-base1 → bg-base2 → bg-base3)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PusherStyle.bgBase1,
              PusherStyle.bgBase2,
              PusherStyle.bgBase3,
            ],
            stops: [0, 0.5, 1],
          ),
        ),
        child: Stack(
          children: [
            // 背景辉光（radial）：左上粉、右下青
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.8, -1.2),
                    radius: 1.2,
                    colors: [PusherStyle.bgGlow1, Color(0x00FF4691)],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(1.1, 1.2),
                    radius: 1.2,
                    colors: [PusherStyle.bgGlow2, Color(0x0014EBC8)],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const PusherHeadView(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PusherSceneView(
                          store: _sceneStore,
                          engineSync: _engineSync,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              PusherTopToolbarView(
                                isLiveStarted: _isLiveStarted,
                                liveName: _liveName,
                                avatarUrl: _avatarUrl,
                                hostName: widget.hostName,
                                liveID: widget.liveID,
                                onEditLiveInfo: _editLiveInfo,
                              ),
                              const SizedBox(height: 12),
                              const Expanded(
                                child: PusherStreamMixerView(),
                              ),
                              const SizedBox(height: 12),
                              PusherBottomToolbarView(
                                isLiveStarted: _isLiveStarted,
                                liveStartTime: _liveStartTime,
                                micOn: _micOn,
                                speakerMuted: _speakerMuted,
                                captureVolume: _captureVolume,
                                outputVolume: _outputVolume,
                                onToggleMicrophone: _toggleMicrophone,
                                onToggleSpeakerMute: _toggleSpeakerMute,
                                onCaptureVolumeChanged:
                                    _onCaptureVolumeChanged,
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
                              AudienceView(liveID: widget.liveID),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Index(
                                  liveID: widget.liveID,
                                  isLiveStarted: _isLiveStarted,
                                ),
                              ),
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
    );
  }
}
