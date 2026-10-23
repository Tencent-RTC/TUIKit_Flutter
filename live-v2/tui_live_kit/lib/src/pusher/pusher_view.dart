import '../common/platform/screen_awake_channel.dart';
import '../common/beauty/beauty_view.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../common/beauty/beauty_panel.dart';
import '../common/theme/live_toast_view.dart';
import '../common/live_kit_error_text.dart';
import 'settings/audio_effect_view.dart';

import 'package:atomic_x_core/atomicxcore.dart';

import '../common/theme/bottom_sheet_background_view.dart';
import 'living/coguest/pusher_coguest_store.dart';
import 'living/pusher_living_view.dart';
import 'prepare/pusher_prepare_view.dart';
import 'living/status/pusher_live_status_view.dart';
import 'settings/pusher_settings_action_handling.dart';
import '../common/key_metrics.dart';
import '../common/live_kit_resources.dart';
import '../common/platform/live_network_type_channel.dart';
import '../common/platform/live_thermal_state_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'video/pusher_video_view.dart';
import 'summary/pusher_summary_view.dart';

enum _PusherPhase { prepare, living, summary }

class _PusherPresentationState {
  String hostName = LiveKitResources.localizedString('tuilivekit.common.host');
  String hostAvatarURL = '';
  PusherSettingsState settings = PusherSettingsState();
  PusherDeviceStatusState deviceStatus = PusherDeviceStatusState();
}

class PusherView extends StatefulWidget {
  const PusherView({
    super.key,
    required this.liveID,
    this.onExit,
  });

  final String liveID;

  final VoidCallback? onExit;

  @override
  State<PusherView> createState() => _PusherViewState();
}

class _PusherViewState extends State<PusherView> with WidgetsBindingObserver implements PusherSettingsActionHandling {
  late final LiveSeatStore _seatStore;
  late final PusherCoGuestStore _coGuestStore;
  BeautyViewState? _suspendedBeauty;
  final _PusherPresentationState _presentationState = _PusherPresentationState();
  String _liveTitle = LiveKitResources.localizedString('tuilivekit.pusher.default_title');
  String _coverURL = LiveKitResources.defaultCoverURL;
  final List<(Listenable, VoidCallback)> _deviceListeners = [];
  StreamSubscription<LiveThermalState>? _thermalStateSubscription;
  StreamSubscription<LiveNetworkType>? _networkTypeSubscription;
  LiveThermalState _temperatureStatus = LiveThermalState.normal;
  LiveNetworkType _networkKind = LiveNetworkType.unknown;
  int _previewOperationID = 0;
  bool _didStartPreview = false;
  bool _isPreviewStarting = false;

  late final PusherVideoController _videoController;

  _PusherPhase _phase = _PusherPhase.prepare;
  bool get _isLiving => _phase == _PusherPhase.living;
  final GlobalKey<PusherPrepareViewState> _prepareKey = GlobalKey();
  final GlobalKey<PusherLivingViewState> _livingKey = GlobalKey();
  Widget? _prepareView;
  DateTime? _liveStartTime;
  DateTime? _liveEndTime;
  final _elapsedChanges = ValueNotifier<int>(0);
  final _pauseChanges = ValueNotifier<(bool, int)>((false, 0));
  final _settingsChanges = ValueNotifier(PusherSettingsState());
  final _deviceChanges = ValueNotifier(PusherDeviceStatusState());
  final _coGuestLayout = ValueNotifier((CoGuestLayoutTemplate.dynamicLayout, 0));
  bool _isPaused = false;
  Duration _accumulatedPause = Duration.zero;
  DateTime? _pauseStartTime;
  bool _ending = false;
  bool _exitRequested = false;
  bool _sessionReleased = false;
  final String _screenAwakeOwner = UniqueKey().toString();
  bool _screenAwakeEnabled = false;
  bool _screenAwakeAttached = true;
  bool _hasConnected = false;
  int _sessionID = 0;
  int _unmuteOperationID = 0;
  bool _unmutePending = false;
  bool _didInitializePreview = false;
  bool _didInitializeAudio = false;
  bool _needsDeviceCleanup = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  ({bool camera, bool microphone, bool isFront})? _backgroundDevices;
  PusherSummary? _finalSummary;
  String? _interruptionMessage;
  StreamSubscription<LoginEvent>? _accountEvents;
  final _toast = LiveToastController();
  final _beautyPanel = BeautyPanelController();
  bool get _canCapture =>
      mounted &&
      !_sessionReleased &&
      !_ending &&
      _phase != _PusherPhase.summary &&
      !_isPaused &&
      _lifecycle == AppLifecycleState.resumed;
  Duration get _currentPause => _pauseStartTime == null ? Duration.zero : DateTime.now().difference(_pauseStartTime!);
  Timer? _elapsedTimer;
  Timer? _pauseTimer;
  final AtomicPusher _pusher = AtomicPusher.shared;
  PusherListener? _pusherListener;

  void _attachPushEvents() {
    _detachPushEvents();
    final id = ++_sessionID;
    bool isCurrent() => mounted && !_sessionReleased && id == _sessionID;
    _pusherListener = PusherListener(
      pusherError: (code, message) {
        if (!isCurrent() || !_isLiving || code == PusherCode.ok) return;
        final rejected =
            (code == PusherCode.errorStartPushRequestFailed || code == PusherCode.errorUpdateConfigRequestFailed) &&
                RegExp(r'^\s*error_code:\s*100026(?:\s*[,|]|\s*$)').hasMatch(message);
        final key = rejected
            ? 'content_rejected'
            : code == PusherCode.errorStartPushRequestFailed
                ? 'start_failed'
                : code == PusherCode.errorUpdateConfigRequestFailed
                    ? 'update_failed'
                    : 'operation_failed';
        if (code == PusherCode.errorStartPushRequestFailed && !_hasConnected && !_ending) {
          _returnToPrepare();
        }
        _toast.show(LiveKitResources.localizedString('tuilivekit.pusher.error.$key'));
      },
      liveEnded: (reason, summary) {
        if (!isCurrent() || !_isLiving) return;
        _finalSummary = summary;
        if (!_ending) {
          _interruptionMessage = LiveKitResources.localizedString(
              'tuilivekit.pusher.interruption.${reason == EndedReason.endedByServer ? 'server' : 'ended'}');
        }
        _settleLive();
      },
      kickedOut: (reason, _) {
        if (!isCurrent() || !_isLiving) return;
        final key = switch (reason) {
          KickedOutReason.byAdmin => 'admin',
          KickedOutReason.byLoggedOnOtherDevice => 'other_device',
          KickedOutReason.byServer => 'server',
          KickedOutReason.forNetworkDisconnected => 'network',
          KickedOutReason.forLiveChannelExpired => 'expired',
        };
        _interruptionMessage = LiveKitResources.localizedString('tuilivekit.pusher.interruption.$key');
        _settleLive();
      },
    );
    _pusher.addListener(_pusherListener!);
  }

  void _detachPushEvents() {
    _sessionID++;
    final listener = _pusherListener;
    if (listener != null) _pusher.removeListener(listener);
    _pusherListener = null;
  }

  void _startLive(String title) {
    if (_phase != _PusherPhase.prepare || _sessionReleased || _pusherListener != null) return;
    _liveTitle = title;
    if (widget.liveID.isEmpty || utf8.encode(widget.liveID).length > 48) {
      _toast.show(LiveKitResources.localizedString('tuilivekit.pusher.error.start_failed'));
      return;
    }
    _beautyPanel.dismiss();
    _coGuestStore.activate();
    _resetLiveClock(DateTime.now());
    _hasConnected = false;
    _ending = false;
    _finalSummary = null;
    _interruptionMessage = null;
    _phase = _PusherPhase.living;
    _updateScreenAwake();
    _updateCoGuestPresentation();
    setState(() {});
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isLiving && !_ending) _updateElapsedTime();
    });
    _attachPushEvents();
    reportAtomicMetrics(liveIntegrationSuccessful);
    setComponent(componentLiveStream);
    final trimmed = title.trim();
    _pusher.startPush(PusherInfo(
      liveID: widget.liveID,
      liveName: trimmed.isEmpty ? LiveKitResources.localizedString('tuilivekit.pusher.default_title') : trimmed,
      coverURL: _coverURL,
      backgroundURL: LiveKitResources.defaultBackgroundURL,
    ));
  }

  void _returnToPrepare() {
    _beautyPanel.dismiss();
    _detachPushEvents();
    _unmuteOperationID++;
    _unmutePending = false;
    _deactivateLiving(discardPendingLikes: true);
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _resetLiveClock(null);
    _phase = _PusherPhase.prepare;
    _updateScreenAwake();
    _prepareKey.currentState?.cancelCountdown();
    _updateCoGuestPresentation();
    setState(() {});
    _preparePreview().ignore();
  }

  /// 清空计时与暂停累计；开播传入起点，回到 Prepare 传 null。
  void _resetLiveClock(DateTime? startTime) {
    _finishPause();
    _accumulatedPause = Duration.zero;
    _liveStartTime = startTime;
    _liveEndTime = null;
    _elapsedChanges.value = 0;
  }

  void _pauseLive() {
    if (!_isLiving || _isPaused || _ending || _sessionReleased) return;
    _pauseStartTime = DateTime.now();
    _isPaused = true;
    _backgroundDevices = null;
    _updateElapsedTime();
    _stopPreview();
    _pauseChanges.value = (true, 0);
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPaused) return;
      _pauseChanges.value = (true, _currentPause.inSeconds);
    });
  }

  void _finishPause() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
    _accumulatedPause += _currentPause;
    _pauseStartTime = null;
    _isPaused = false;
    _pauseChanges.value = (false, 0);
  }

  void _resumeLive() {
    if (!_isLiving || !_isPaused || _ending || _sessionReleased) return;
    _finishPause();
    _preparePreview().ignore();
  }

  void _updateElapsedTime() {
    final start = _liveStartTime;
    if (start == null) return;
    final elapsed = (_liveEndTime ?? DateTime.now()).difference(start) - _accumulatedPause - _currentPause;
    _elapsedChanges.value = elapsed.isNegative ? 0 : elapsed.inSeconds;
  }

  void _endLive() {
    if (!_isLiving || _ending || _sessionReleased) return;
    _ending = true;
    _beautyPanel.dismiss();
    setState(() {});
    _pusher.stopPush();
  }

  void _deactivateLiving({bool discardPendingLikes = false}) {
    _livingKey.currentState?.deactivateAudience();
    _livingKey.currentState?.deactivateLikes(discardPending: discardPendingLikes);
    _livingKey.currentState?.deactivateComments();
    _livingKey.currentState?.deactivateMusic();
    _coGuestStore.deactivate();
  }

  void _settleLive() {
    if (!_isLiving || _sessionReleased) return;
    _detachPushEvents();
    _deactivateLiving();
    _finishPause();
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _liveEndTime = DateTime.now();
    _updateElapsedTime();
    _phase = _PusherPhase.summary;
    _ending = false;
    _updateCoGuestPresentation();
    _releaseSession();
    setState(() {});
  }

  void _releaseSession() {
    if (_sessionReleased) return;
    final shouldStop = _pusherListener != null && _isLiving && !_ending;
    _sessionReleased = true;
    _updateScreenAwake();
    _ending = false;
    _unmuteOperationID++;
    _detachPushEvents();
    _backgroundDevices = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;
    _pusher.state.networkState.removeListener(_onPushStateChanged);
    _pusher.state.pusherInfo.removeListener(_onPushStateChanged);
    LoginStore.shared.removeListener(_updateHostProfile);
    _accountEvents?.cancel();
    _accountEvents = null;
    _coGuestStore.removeListener(_onCoGuestStateChanged);
    _prepareKey.currentState?.cancelCountdown();
    _deactivateLiving();
    _beautyPanel.dismiss();
    _stopPreview(closeMicrophone: true);
    if (shouldStop) _pusher.stopPush();
    _pusher.release();
    for (final entry in _deviceListeners) {
      entry.$1.removeListener(entry.$2);
    }
    _deviceListeners.clear();
    _thermalStateSubscription?.cancel();
    _thermalStateSubscription = null;
    _networkTypeSubscription?.cancel();
    _networkTypeSubscription = null;
  }

  void _exit() {
    if (_exitRequested) return;
    _exitRequested = true;
    _releaseSession();
    if (mounted) setState(() {});
    widget.onExit?.call();
  }

  void _showBeauty(_PusherPhase phase) {
    if (!_sessionReleased && !_ending && _phase == phase && _lifecycle == AppLifecycleState.resumed) {
      _beautyPanel.show(context, usePusherTheme: true);
    }
  }

  void _onBackStateChanged() {
    if (mounted && !_sessionReleased) setState(() {});
  }

  void _dismissTransientUI() {
    if (_ending || _sessionReleased) return;
    if (_beautyPanel.isShowing) {
      _beautyPanel.dismiss();
    } else if (_phase == _PusherPhase.prepare) {
      _prepareKey.currentState?.handleBackPressed();
    } else if (_isLiving) {
      _livingKey.currentState?.handleBackPressed();
    }
  }

  /// 登录用户的昵称（空则回退 userID / 默认文案）与头像。
  static (String, String) _loginProfile() {
    final user = LoginStore.shared.loginState.loginUserInfo;
    final name = (user?.nickname ?? '').trim();
    final displayName =
        name.isEmpty ? (user?.userID ?? LiveKitResources.localizedString('tuilivekit.common.host')) : name;
    return (displayName, user?.avatarURL ?? '');
  }

  void _updateHostProfile() {
    if (!mounted || _sessionReleased) return;
    final (name, avatar) = _loginProfile();
    if (_presentationState.hostName == name && _presentationState.hostAvatarURL == avatar) return;
    setState(() {
      _presentationState.hostName = name;
      _presentationState.hostAvatarURL = avatar;
    });
  }

  @override
  void initState() {
    super.initState();
    AdvancedBeautySession.shared.acquire(this);
    _beautyPanel.presentation.addListener(_onBackStateChanged);
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _seatStore = LiveSeatStore.create(widget.liveID);
    _coGuestStore = PusherCoGuestStore(liveID: widget.liveID, seatStore: _seatStore);
    _coGuestStore.onToast = (message) {
      if (_isLiving) _livingKey.currentState?.showCoGuestToast(message);
    };
    final (hostName, hostAvatarURL) = _loginProfile();
    _presentationState
      ..hostName = hostName
      ..hostAvatarURL = hostAvatarURL;
    _presentationState.settings = _makeSettingsState();
    _presentationState.deviceStatus = _makeDeviceStatusState();
    _publishSettings();
    _publishDeviceStatus();
    _videoController = PusherVideoController(liveID: widget.liveID);
    _videoController.updateLocalCameraStatus(DeviceStore.shared.state.cameraStatus.value);
    _subscribeDeviceStatus();
    _subscribePlatformStatus();
    _subscribeAVStatistics();
    LoginStore.shared.addListener(_updateHostProfile);
    _accountEvents = LoginStore.shared.loginEventStream.listen((event) {
      if (!mounted || _sessionReleased || event != LoginEvent.kickedOffline) {
        return;
      }
      if (_isLiving) {
        _interruptionMessage = LiveKitResources.localizedString('tuilivekit.pusher.interruption.account');
        _endLive();
      } else if (_phase == _PusherPhase.prepare) {
        scheduleMicrotask(() {
          if (mounted) _exit();
        });
      }
    });
    _pusher.state.networkState.addListener(_onPushStateChanged);
    _pusher.state.pusherInfo.addListener(_onPushStateChanged);
    _coGuestStore.addListener(_onCoGuestStateChanged);
    _preparePreview().ignore();
  }

  void _updateScreenAwake() {
    final enabled = mounted &&
        _screenAwakeAttached &&
        _isLiving &&
        !_sessionReleased &&
        (_lifecycle == AppLifecycleState.resumed || _lifecycle == AppLifecycleState.inactive);
    if (_screenAwakeEnabled == enabled) return;
    _screenAwakeEnabled = enabled;
    ScreenAwakeChannel.setEnabled(_screenAwakeOwner, enabled).ignore();
  }

  @override
  void activate() {
    super.activate();
    _screenAwakeAttached = true;
    _updateScreenAwake();
  }

  @override
  void deactivate() {
    _screenAwakeAttached = false;
    _updateScreenAwake();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 会话内的 SDK 监听、计时、订阅与阶段功能统一由 _releaseSession 释放。
    _releaseSession();
    _beautyPanel.presentation.removeListener(_onBackStateChanged);
    _beautyPanel.dispose();
    AdvancedBeautySession.shared.release(this);
    _toast.dispose();
    _coGuestStore.dispose();
    _videoController.dispose();
    _elapsedChanges.dispose();
    _pauseChanges.dispose();
    _settingsChanges.dispose();
    _deviceChanges.dispose();
    _coGuestLayout.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _updateScreenAwake();
    if (_sessionReleased) return;
    if (state == AppLifecycleState.resumed) {
      _preparePreview().ignore();
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _prepareKey.currentState?.cancelCountdown();
      _beautyPanel.dismiss();
      if (_backgroundDevices == null && !_isPaused && (_didStartPreview || _isPreviewStarting || _needsDeviceCleanup)) {
        final device = DeviceStore.shared.state;
        _backgroundDevices = (
          camera: device.cameraStatus.value == DeviceStatus.on || _isPreviewStarting,
          microphone: device.microphoneStatus.value == DeviceStatus.on || _isPreviewStarting,
          isFront: _didInitializePreview ? device.isFrontCamera.value : true
        );
      }
      _stopPreview();
    }
  }

  void _onPushStateChanged() {
    if (!_isLiving ||
        _ending ||
        _sessionReleased ||
        _pusherListener == null ||
        _pusher.state.pusherInfo.value.liveID != widget.liveID ||
        _pusher.state.networkState.value != PusherConnectState.connected ||
        _hasConnected) {
      return;
    }
    _hasConnected = true;
    _livingKey.currentState?.showSystemAnnouncement();
    _livingKey.currentState?.refreshAudience();
    final session = _sessionID;
    _seatStore.setSeatMode(SeatMode.apply).then((result) {
      if (mounted && !_sessionReleased && _isLiving && !_ending && _sessionID == session && !result.isSuccess) {
        _toast.show(LiveKitErrorText.message(result));
      }
    });
    _coGuestStore.didConnect();
  }

  void _onCoGuestStateChanged() {
    final state = _coGuestStore.state;
    // The Store mutates one State instance; retain scalar layout inputs.
    final next = (state.layout, state.connected.length);
    if (_coGuestLayout.value == next) return;
    _coGuestLayout.value = next;
    _updateCoGuestPresentation();
  }

  void _updateCoGuestPresentation() {
    final PusherCoGuestState coGuestState = _coGuestStore.state;
    _videoController.updateCoGuestVideoState(
      isLiving: _isLiving,
      layout: coGuestState.layout,
      connectedGuestCount: coGuestState.connected.length,
    );
  }

  bool get _isCoGuestStageActive {
    final PusherCoGuestState coGuestState = _coGuestStore.state;
    return _isLiving && (coGuestState.connected.isNotEmpty || coGuestState.layout != CoGuestLayoutTemplate.floatLayout);
  }

  void _publishSettings() {
    final next = _presentationState.settings;
    if (!_settingsChanges.value.isSameAs(next)) {
      _settingsChanges.value = next.copy();
    }
  }

  void _publishDeviceStatus() {
    final next = _presentationState.deviceStatus;
    if (!_deviceChanges.value.isSameAs(next)) {
      _deviceChanges.value = next.copy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _PusherPhase phase = _phase;

    return PusherBackNavigation(
        isLiving: _isLiving,
        isEnding: _ending,
        hasTransientUI: _beautyPanel.isShowing ||
            (phase == _PusherPhase.prepare && (_prepareKey.currentState?.hasTransientUI ?? false)),
        onDismissTransientUI: _dismissTransientUI,
        onDidPop: () {
          _exitRequested = true;
          _releaseSession();
        },
        child: BottomSheetTheme(
            // 组件不依赖宿主的 Material；统一去掉无 Material 祖先时的文字下划线。
            child: DefaultTextStyle.merge(
                style: const TextStyle(decoration: TextDecoration.none),
                child: ColoredBox(
                  color: const Color(0xFF000000),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      // 铺满整个 PusherView，位于渲染层之下。
                      Positioned.fill(
                        child: ValueListenableBuilder(
                          valueListenable: _coGuestLayout,
                          builder: (context, _, child) => _isCoGuestStageActive ? child! : const SizedBox.shrink(),
                          child: IgnorePointer(
                            child: Image(
                              image: LiveKitResources.image('livekit_pusher_coguest_background'),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      if (!_sessionReleased)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: PusherVideoView.bottomInsetOf(context),
                          child: Offstage(
                            offstage: phase == _PusherPhase.summary,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              child: PusherVideoView(controller: _videoController),
                            ),
                          ),
                        ),
                      if (!_sessionReleased)
                        Offstage(
                          offstage: phase != _PusherPhase.prepare || _beautyPanel.isShowing,
                          child: ValueListenableBuilder<PusherSettingsState>(
                            valueListenable: _settingsChanges,
                            builder: (context, settings, _) {
                              if (phase != _PusherPhase.prepare && _prepareView != null) {
                                return _prepareView!;
                              }
                              return _prepareView = PusherPrepareView(
                                key: _prepareKey,
                                liveTitle: _liveTitle,
                                coverURL: _coverURL,
                                settings: settings,
                                actionHandler: this,
                                onSelectCover: _updateCoverURL,
                                onTitleChanged: (value) => _liveTitle = value,
                                onShowBeauty: () => _showBeauty(_PusherPhase.prepare),
                                onBackStateChanged: _onBackStateChanged,
                                onCountdownFinished: _startLive,
                                onExit: _exit,
                                onFlipCamera: _switchCamera,
                                onRefreshSettings: _refreshSettings,
                              );
                            },
                          ),
                        ),
                      if (!_sessionReleased && phase == _PusherPhase.living)
                        PusherLivingView(
                          key: _livingKey,
                          coGuestActionHandler: _coGuestStore,
                          liveID: widget.liveID,
                          hostName: _presentationState.hostName,
                          hostAvatarURL: _presentationState.hostAvatarURL,
                          elapsedSeconds: _elapsedChanges,
                          pauseState: _pauseChanges,
                          settings: _settingsChanges,
                          settingsActionHandler: this,
                          deviceStatus: _deviceChanges,
                          coGuestState: _coGuestStore.state,
                          coGuestChanges: _coGuestStore,
                          coGuestLayout: _coGuestLayout,
                          onCoGuestStageTap: _videoController.selectGuestAt,
                          coGuestGeometryChanges: _videoController.coGuestGeometryChanges,
                          coGuestSmallWindowRegions: _videoController.coGuestSmallWindowRegions,
                          coGuestGridRegions: _videoController.coGuestGridRegions,
                          hasConnected: _hasConnected,
                          selectedCoGuestUserID: _videoController.selectedGuestUserID,
                          onDismissCoGuestActions: _videoController.clearSelectedGuest,
                          onShowSettings: _refreshSettings,
                          onShowBeauty: () => _showBeauty(_PusherPhase.living),
                          onToggleMute: _toggleMute,
                          onPause: _pauseLive,
                          onResume: _resumeLive,
                          onEnd: _endLive,
                          onFlipCamera: _switchCamera,
                        ),
                      if (phase == _PusherPhase.summary)
                        PusherSummaryView(
                          liveID: widget.liveID,
                          finalSummary: _finalSummary,
                          summaryContext: PusherSummaryContext(
                              startTime: _liveStartTime,
                              endTime: _liveEndTime!,
                              pausedSeconds: _accumulatedPause.inSeconds,
                              interruptionMessage: _interruptionMessage),
                          onExit: _exit,
                        ),
                      if (_ending)
                        Positioned.fill(
                            child: ColoredBox(
                          color: const Color(0x8C000000),
                          child: Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const CupertinoActivityIndicator(radius: 18.5, color: Color(0xFFFFFFFF)),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(LiveKitResources.localizedString('tuilivekit.pusher.ending'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFFFFFFFF))),
                            ),
                          ])),
                        )),
                      Positioned.fill(child: LiveToastView(controller: _toast)),
                    ],
                  ),
                ))));
  }

  void _stopPreview({bool closeMicrophone = false}) {
    _previewOperationID++;
    if (_needsDeviceCleanup) {
      DeviceStore.shared.closeLocalCamera();
      if (closeMicrophone) {
        _needsDeviceCleanup = false;
        DeviceStore.shared.closeLocalMicrophone();
      } else {
        _seatStore.muteMicrophone();
      }
    }
    _didStartPreview = false;
    _isPreviewStarting = false;
  }

  bool _validPreview(int id) => _previewOperationID == id && _canCapture;

  Future<void> _preparePreview() async {
    if (!_canCapture || _didStartPreview || _isPreviewStarting) return;
    if (!_didInitializeAudio) {
      _didInitializeAudio = true;
      AudioEffectView.resetForNewSession();
      setCaptureVolume(100);
      DeviceStore.shared.updateVideoQuality(VideoQuality.quality720P);
    }
    final id = ++_previewOperationID;
    _isPreviewStarting = true;
    try {
      if (_backgroundDevices?.camera != false) {
        final granted = await _requestAccess(DeviceType.camera);
        if (!_validPreview(id)) return;
        if (!granted) return;
        final front = _backgroundDevices?.isFront ??
            (_didInitializePreview ? DeviceStore.shared.state.isFrontCamera.value : true);
        if (!_didInitializePreview) {
          _didInitializePreview = true;
          DeviceStore.shared.switchMirror(MirrorType.enable);
          _presentationState.settings.isMirrorEnabled = true;
          _publishSettings();
        }
        await BeautyPreferences.restore(canApply: () => _validPreview(id));
        if (!_validPreview(id)) return;
        _needsDeviceCleanup = true;
        final result = await DeviceStore.shared.openLocalCamera(front);
        if (!result.isSuccess) return;
      }
      await _requestMicrophoneAccess(id);
    } finally {
      if (_previewOperationID == id) _isPreviewStarting = false;
    }
  }

  void _updateCoverURL(String coverURL) {
    if (!LiveKitResources.presetCoverURLs.contains(coverURL) || _coverURL == coverURL) {
      return;
    }
    _coverURL = coverURL;
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    final bool isFrontCamera = DeviceStore.shared.state.isFrontCamera.value;
    DeviceStore.shared.switchCamera(!isFrontCamera);
  }

  void _refreshSettings() {
    _presentationState.settings = _makeSettingsState();
    _publishSettings();
    _publishDeviceStatus();
  }

  @override
  void toggleMirror() {
    final bool enabled = DeviceStore.shared.state.localMirrorType.value != MirrorType.disable;
    DeviceStore.shared.switchMirror(enabled ? MirrorType.disable : MirrorType.enable);
    _presentationState.settings.isMirrorEnabled = !enabled;
    _publishSettings();
  }

  Future<void> _toggleMute() async {
    if (!_isLiving || _ending || _isPaused || _sessionReleased || _unmutePending) return;
    final wasMuted = _presentationState.settings.isMuted;
    _presentationState.settings.isMuted = !wasMuted;
    _publishSettings();
    _publishDeviceStatus();
    if (!wasMuted) {
      _seatStore.muteMicrophone();
      return;
    }
    final id = ++_unmuteOperationID;
    _unmutePending = true;
    bool succeeded = false;
    try {
      succeeded = (await _seatStore.unmuteMicrophone()).isSuccess;
    } catch (_) {}
    if (!_sessionReleased && (_isPaused || _lifecycle != AppLifecycleState.resumed)) {
      _seatStore.muteMicrophone();
    }
    if (!mounted || id != _unmuteOperationID) return;
    _unmutePending = false;
    if (!_isLiving || _ending || _sessionReleased) return;
    if (!succeeded) {
      _presentationState.settings.isMuted = wasMuted;
      _publishSettings();
      _publishDeviceStatus();
      _toast.show(LiveKitResources.localizedString('tuilivekit.pusher.error.mute_switch_failed'));
    }
  }

  @override
  void setBeautyEnabled(bool enabled) {
    if (_presentationState.settings.isBeautyEnabled == enabled) return;
    if (enabled) {
      final saved = _suspendedBeauty;
      if (saved != null) {
        BaseBeautyStore.shared.setSmoothLevel(saved.smoothLevel);
        BaseBeautyStore.shared.setWhitenessLevel(saved.whitenessLevel);
        BaseBeautyStore.shared.setRuddyLevel(saved.ruddyLevel);
      }
      _suspendedBeauty = null;
    } else {
      final sdk = BaseBeautyStore.shared.baseBeautyState;
      _suspendedBeauty = BeautyViewState(
          smoothLevel: sdk.smoothLevel.value,
          whitenessLevel: sdk.whitenessLevel.value,
          ruddyLevel: sdk.ruddyLevel.value);
      BaseBeautyStore.shared.reset();
    }
    _presentationState.settings.isBeautyEnabled = enabled;
    _presentationState.settings = _makeSettingsState();
    _publishSettings();
  }

  @override
  void setSmoothLevel(double level) =>
      _setBeautyLevel(level, BaseBeautyStore.shared.setSmoothLevel, (settings, value) => settings.smoothLevel = value);

  @override
  void setWhitenessLevel(double level) => _setBeautyLevel(
      level, BaseBeautyStore.shared.setWhitenessLevel, (settings, value) => settings.whitenessLevel = value);

  @override
  void setRuddyLevel(double level) =>
      _setBeautyLevel(level, BaseBeautyStore.shared.setRuddyLevel, (settings, value) => settings.ruddyLevel = value);

  /// 美颜关闭时忽略调节；数值限制在 0～9，先写 SDK 再同步本地投影。
  void _setBeautyLevel(
      double level, void Function(double) apply, void Function(PusherSettingsState settings, double value) save) {
    if (!_presentationState.settings.isBeautyEnabled) return;
    final double value = level.clamp(0, 9);
    apply(value);
    save(_presentationState.settings, value);
    _publishSettings();
  }

  @override
  void setCaptureVolume(int volume) {
    final int value = volume.clamp(0, 100);
    DeviceStore.shared.setCaptureVolume(value);
    _presentationState.settings.captureVolume = value;
    _publishSettings();
    _publishDeviceStatus();
  }

  Future<void> _requestMicrophoneAccess(int id) async {
    if (!_validPreview(id)) return;
    if (_backgroundDevices?.microphone == false) {
      _didStartPreview = true;
      _backgroundDevices = null;
      return;
    }
    if (!await _requestAccess(DeviceType.microphone) || !_validPreview(id)) {
      return;
    }
    _needsDeviceCleanup = true;
    final muted = _presentationState.settings.isMuted;
    if (muted) _seatStore.muteMicrophone();
    bool succeeded = true;
    if (DeviceStore.shared.state.microphoneStatus.value == DeviceStatus.on) {
      if (!muted) succeeded = (await _seatStore.unmuteMicrophone()).isSuccess;
    } else {
      succeeded = (await DeviceStore.shared.openLocalMicrophone()).isSuccess;
    }
    if (!_sessionReleased &&
        (_isPaused || _lifecycle != AppLifecycleState.resumed || _presentationState.settings.isMuted)) {
      _seatStore.muteMicrophone();
    }
    if (!_validPreview(id)) return;
    if (succeeded) {
      _didStartPreview = true;
      _backgroundDevices = null;
      _refreshSettings();
    }
  }

  Future<bool> _requestAccess(DeviceType deviceType) async {
    final Permission permission = deviceType == DeviceType.camera ? Permission.camera : Permission.microphone;
    final PermissionStatus status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }
    final PermissionStatus requested = await permission.request();
    return requested.isGranted || requested.isLimited;
  }

  PusherSettingsState _makeSettingsState() {
    final DeviceState deviceState = DeviceStore.shared.state;
    final BaseBeautyState beautyState = BaseBeautyStore.shared.baseBeautyState;

    return PusherSettingsState(
      isMirrorEnabled: deviceState.localMirrorType.value != MirrorType.disable,
      isMuted: _presentationState.settings.isMuted,
      captureVolume: deviceState.captureVolume.value,
      isBeautyEnabled: _presentationState.settings.isBeautyEnabled,
      smoothLevel: beautyState.smoothLevel.value,
      whitenessLevel: beautyState.whitenessLevel.value,
      ruddyLevel: beautyState.ruddyLevel.value,
    );
  }

  PusherDeviceStatusState _makeDeviceStatusState() {
    final DeviceState deviceState = DeviceStore.shared.state;
    final PusherDeviceStatusState status = _presentationState.deviceStatus.copy();
    status.networkKind = _networkKind;
    final NetworkInfo networkInfo = deviceState.networkInfo.value;
    status.networkQuality = networkInfo.quality.value;
    status.delay = networkInfo.delay;
    status.downLoss = networkInfo.downLoss;
    status.upLoss = networkInfo.upLoss;
    status.temperatureStatus = _temperatureStatus;
    _updateMediaStatuses(deviceState, status);
    return status;
  }

  void _updateMediaStatuses(DeviceState deviceState, PusherDeviceStatusState status) {
    status.cameraStatus = deviceState.cameraStatus.value;
    status.microphoneStatus = deviceState.microphoneStatus.value;
    status.cameraError = deviceState.cameraLastError.value;
    status.microphoneError = deviceState.microphoneLastError.value;
  }

  void _subscribeDeviceStatus() {
    final DeviceState deviceState = DeviceStore.shared.state;
    void onDeviceStateChanged() {
      if (_sessionReleased) return;
      final PusherDeviceStatusState nextState = _makeDeviceStatusState();
      _videoController.updateLocalCameraStatus(DeviceStore.shared.state.cameraStatus.value);
      if (_presentationState.deviceStatus.isSameAs(nextState)) {
        return;
      }
      _presentationState.deviceStatus = nextState;
      _publishDeviceStatus();
    }

    _bindDevice(deviceState.cameraStatus, onDeviceStateChanged);
    _bindDevice(deviceState.cameraLastError, onDeviceStateChanged);
    _bindDevice(deviceState.microphoneStatus, onDeviceStateChanged);
    _bindDevice(deviceState.microphoneLastError, onDeviceStateChanged);
    _bindDevice(deviceState.networkInfo, onDeviceStateChanged);
  }

  /// 系统热状态与网络类型来自 Common 平台桥，变化后重算设备状态投影。
  void _subscribePlatformStatus() {
    _thermalStateSubscription = LiveThermalStateChannel.states.listen((LiveThermalState thermalState) {
      if (_temperatureStatus == thermalState) return;
      _temperatureStatus = thermalState;
      _presentationState.deviceStatus = _makeDeviceStatusState();
      _publishDeviceStatus();
    });
    _networkTypeSubscription = LiveNetworkTypeChannel.types.listen((LiveNetworkType networkType) {
      if (_networkKind == networkType) return;
      _networkKind = networkType;
      _presentationState.deviceStatus = _makeDeviceStatusState();
      _publishDeviceStatus();
    });
  }

  void _subscribeAVStatistics() {
    void update() {
      if (_sessionReleased || !_isLiving || _ending) return;
      final statistics = _pusher.state.statistics.value;
      final next = _presentationState.deviceStatus.copy();
      next.videoBitrate = statistics.videoBitrate;
      next.videoWidth = statistics.videoWidth;
      next.videoHeight = statistics.videoHeight;
      next.frameRate = statistics.videoFps;
      next.audioBitrate = statistics.audioBitrate;
      next.hasAVStatistics = _pusher.state.networkState.value == PusherConnectState.connected;
      _updateMediaStatuses(DeviceStore.shared.state, next);
      if (_presentationState.deviceStatus.isSameAs(next)) return;
      _presentationState.deviceStatus = next;
      _publishDeviceStatus();
    }

    _bindDevice(_pusher.state.statistics, update);
    _bindDevice(_pusher.state.networkState, update);
    _bindDevice(_seatStore.liveSeatState.avStatistics, () {
      if (_sessionReleased) return;
      final userID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
      final values = _seatStore.liveSeatState.avStatistics.value;
      final own = values.where((item) => item.userID == userID);
      final fallback = values.where((item) => item.userID.isEmpty);
      final rate = own.isNotEmpty
          ? own.first.audioSampleRate
          : fallback.isNotEmpty
              ? fallback.first.audioSampleRate
              : 0;
      if (_presentationState.deviceStatus.audioSampleRate == rate) return;
      _presentationState.deviceStatus.audioSampleRate = rate;
      _publishDeviceStatus();
    });
  }

  void _bindDevice(Listenable listenable, VoidCallback callback) {
    listenable.addListener(callback);
    _deviceListeners.add((listenable, callback));
  }
}

/// Android's Pusher handleBackPressed expressed as route-level Flutter input.
/// The owning stage keeps its overlays and session lifecycle; this adapter only
/// prevents an active broadcast or visible overlay from popping the route.
class PusherBackNavigation extends StatelessWidget {
  const PusherBackNavigation({
    super.key,
    required this.isLiving,
    required this.isEnding,
    required this.hasTransientUI,
    required this.onDismissTransientUI,
    required this.onDidPop,
    required this.child,
  });

  final bool isLiving;
  final bool isEnding;
  final bool hasTransientUI;
  final VoidCallback onDismissTransientUI;
  final VoidCallback onDidPop;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !isLiving && !isEnding && !hasTransientUI,
        onPopInvoked: (didPop) {
          if (didPop) {
            onDidPop();
          } else if (!isEnding) {
            onDismissTransientUI();
          }
        },
        child: child,
      );
}
