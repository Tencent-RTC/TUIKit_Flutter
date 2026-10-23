import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'beauty_view.dart';
import '../live_kit_resources.dart';
import '../platform/advanced_beauty_channel.dart';
import '../theme/bottom_sheet_view.dart';
import '../theme/bottom_sheet_background_view.dart';
import '../theme/live_toast_view.dart';

/// User preferences are independent of SDK readback and keyed by app/account.
/// Flutter uses its existing application-support storage instead of UserDefaults.
class BeautyPreferences {
  const BeautyPreferences({
    this.isEnabled = true,
    this.smoothLevel = 0,
    this.whitenessLevel = 0,
    this.ruddyLevel = 0,
  });

  final bool isEnabled;
  final double smoothLevel;
  final double whitenessLevel;
  final double ruddyLevel;

  // Serialize disk operations, but never keep another account's UI state here.
  static Future<void> _pendingWrite = Future.value();

  static String? get currentKey {
    final login = LoginStore.shared;
    final userID = login.loginState.loginUserInfo?.userID;
    if (userID == null || userID.isEmpty) return null;
    return 'TUILiveKit.beauty.v1.${login.sdkAppID}.$userID';
  }

  static Future<File> _file(String key) async {
    final support = await getApplicationSupportDirectory();
    final name = sha256.convert(utf8.encode(key));
    return File('${support.path}/TUILiveKit/beauty.v1/$name.json');
  }

  static double _validated(Object? value) {
    if (value is! num || !value.isFinite) return 0;
    return value.toDouble().clamp(0, 9);
  }

  static Future<BeautyPreferences> load(String? key) async {
    if (key == null) return const BeautyPreferences();
    await _pendingWrite;
    try {
      final file = await _file(key);
      if (!await file.exists()) return const BeautyPreferences();
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return const BeautyPreferences();
      return BeautyPreferences(
        isEnabled: data['isEnabled'] is bool ? data['isEnabled'] as bool : true,
        smoothLevel: _validated(data['smoothLevel']),
        whitenessLevel: _validated(data['whitenessLevel']),
        ruddyLevel: _validated(data['ruddyLevel']),
      );
    } catch (error) {
      debugPrint('TUILiveKit beauty preferences could not be read: $error');
      return const BeautyPreferences();
    }
  }

  Future<void> save(String? key) {
    if (key == null) return Future.value();
    final encoded = jsonEncode({
      'isEnabled': isEnabled,
      'smoothLevel': smoothLevel,
      'whitenessLevel': whitenessLevel,
      'ruddyLevel': ruddyLevel,
    });
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        final file = await _file(key);
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(encoded, flush: true);
        await temporary.rename(file.path);
      } catch (error) {
        debugPrint('TUILiveKit beauty preferences could not be saved: $error');
      }
    });
  }

  static Future<void> restore({bool Function()? canApply}) async {
    final key = currentKey;
    final settings = await load(key);
    if (key == currentKey && (canApply?.call() ?? true)) settings.apply();
  }

  void apply() {
    final store = BaseBeautyStore.shared;
    final enabled = isEnabled && !AdvancedBeautySession.shared.isProcessing;
    store.setSmoothLevel(enabled ? smoothLevel : 0);
    store.setWhitenessLevel(enabled ? whitenessLevel : 0);
    store.setRuddyLevel(enabled ? ruddyLevel : 0);
  }

  BeautyViewState get viewState => BeautyViewState(
        isBeautyEnabled: isEnabled,
        smoothLevel: smoothLevel,
        whitenessLevel: whitenessLevel,
        ruddyLevel: ruddyLevel,
      );

  BeautyPreferences copyWith({
    bool? isEnabled,
    double? smoothLevel,
    double? whitenessLevel,
    double? ruddyLevel,
  }) =>
      BeautyPreferences(
        isEnabled: isEnabled ?? this.isEnabled,
        smoothLevel: smoothLevel ?? this.smoothLevel,
        whitenessLevel: whitenessLevel ?? this.whitenessLevel,
        ruddyLevel: ruddyLevel ?? this.ruddyLevel,
      );
}

class BeautyPanelController with WidgetsBindingObserver {
  final _store = _BeautyStore();
  final ValueNotifier<bool> _presentation = ValueNotifier(false);
  ValueListenable<bool> get presentation => _presentation;
  bool get isShowing => _presentation.value;
  OverlayEntry? _entry;
  int _generation = 0;
  bool _isOpening = false;
  bool _disposed = false;
  // Native plugins survive hot restart; new Dart isolates must not reuse closed IDs.
  static int _nextPresentation = DateTime.now().microsecondsSinceEpoch;
  int? _nativePresentation;
  StreamSubscription? _nativeEvents;

  Future<void> show(BuildContext context, {bool usePusherTheme = false}) async {
    if (isShowing || _isOpening || _disposed) return;
    _isOpening = true;
    _presentation.value = true;
    final generation = ++_generation;
    WidgetsBinding.instance.addObserver(this);
    final id = ++_nextPresentation;
    _nativePresentation = id;
    _nativeEvents = AdvancedBeautyChannel.events.listen((call) {
      final args = call.arguments;
      if (call.method == 'dismissed' && args is Map && args['presentation'] == _nativePresentation) dismiss();
      if (call.method == 'processing' && args is Map && args['ready'] == true && _entry != null) dismiss();
    });
    AdvancedBeautySession.shared.refreshForPresentation();
    final shown = await AdvancedBeautyChannel.showWhenReady(id,
        isCurrent: () => !_disposed && generation == _generation && context.mounted);
    if (_disposed || generation != _generation || !context.mounted) {
      unawaited(AdvancedBeautyChannel.dismiss(id));
      if (!_disposed && generation == _generation) dismiss();
      return;
    }
    if (shown) {
      _isOpening = false;
      return;
    }
    _nativePresentation = null;
    final active = await _store.activate();
    if (!active || _disposed || generation != _generation || !context.mounted) {
      if (generation == _generation) dismiss();
      return;
    }
    // Authorization may finish while basic preferences are loading.
    if (AdvancedBeautySession.shared.isProcessing) {
      _nativePresentation = id;
      final upgraded = await AdvancedBeautyChannel.show(id);
      if (_disposed || generation != _generation || !context.mounted) {
        unawaited(AdvancedBeautyChannel.dismiss(id));
        if (!_disposed && generation == _generation) dismiss();
        return;
      }
      if (upgraded) {
        _store.deactivate();
        _isOpening = false;
        return;
      }
      _nativePresentation = null;
    }
    _isOpening = false;
    _entry = OverlayEntry(
      builder: (_) {
        final sheet = BottomSheetView(
          sheetHeight: 220,
          dimsBackground: false,
          sheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.beauty'),
          onWillDismiss: _store.deactivate,
          onDismiss: dismiss,
          child: Stack(children: [
            Positioned(
              left: 20,
              right: 20,
              top: 68,
              height: 112,
              child: ValueListenableBuilder<BeautyViewState>(
                valueListenable: _store,
                builder: (context, state, child) => BeautyView(
                  settings: state,
                  onSetEnabled: _store.setEnabled,
                  onSetSmoothLevel: _store.setSmooth,
                  onSetWhitenessLevel: _store.setWhiteness,
                  onSetRuddyLevel: _store.setRuddy,
                ),
              ),
            ),
          ]),
        );
        return usePusherTheme ? BottomSheetTheme(child: sheet) : sheet;
      },
    );
    LiveToastView.insertBelowToast(Overlay.of(context), _entry!);
  }

  void dismiss() {
    final id = _nativePresentation;
    _nativePresentation = null;
    if (id != null) unawaited(AdvancedBeautyChannel.dismiss(id));
    unawaited(_nativeEvents?.cancel());
    _nativeEvents = null;
    ++_generation;
    _isOpening = false;
    _store.deactivate();
    WidgetsBinding.instance.removeObserver(this);
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _presentation.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) dismiss();
  }

  void dispose() {
    _disposed = true;
    dismiss();
    _store.dispose();
    _presentation.dispose();
  }
}

class _BeautyStore extends ValueNotifier<BeautyViewState> {
  _BeautyStore() : super(const BeautyViewState());
  bool _active = false;
  int _generation = 0;
  String? _preferencesKey;
  BeautyPreferences _settings = const BeautyPreferences();

  Future<bool> activate() async {
    final generation = ++_generation;
    final key = BeautyPreferences.currentKey;
    final settings = await BeautyPreferences.load(key);
    if (generation != _generation || key != BeautyPreferences.currentKey) {
      return false;
    }
    _preferencesKey = key;
    _settings = settings;
    _active = true;
    settings.apply();
    value = settings.viewState;
    return true;
  }

  void deactivate() {
    _active = false;
    ++_generation;
  }

  bool get _canEdit => _active && _preferencesKey == BeautyPreferences.currentKey;

  void _update(BeautyPreferences settings) {
    if (!_canEdit) return;
    _settings = settings;
    unawaited(settings.save(_preferencesKey));
    settings.apply();
    value = settings.viewState;
  }

  void setEnabled(bool enabled) {
    if (_settings.isEnabled != enabled) {
      _update(_settings.copyWith(isEnabled: enabled));
    }
  }

  void setSmooth(double level) {
    if (_settings.isEnabled && level.isFinite) {
      _update(_settings.copyWith(smoothLevel: level.clamp(0, 9)));
    }
  }

  void setWhiteness(double level) {
    if (_settings.isEnabled && level.isFinite) {
      _update(_settings.copyWith(whitenessLevel: level.clamp(0, 9)));
    }
  }

  void setRuddy(double level) {
    if (_settings.isEnabled && level.isFinite) {
      _update(_settings.copyWith(ruddyLevel: level.clamp(0, 9)));
    }
  }
}

/// Owns preprocessing of the shared SDK camera while a Live entry is mounted.
/// The SDK still owns capture and login; this lease only coordinates the plugin.
class AdvancedBeautySession with WidgetsBindingObserver {
  static final shared = AdvancedBeautySession._();
  AdvancedBeautySession._();
  final Set<Object> _owners = {};
  StreamSubscription? _events;
  int _generation = 0;
  bool _foreground = true;
  bool _enabled = false;
  String? _key;
  bool isProcessing = false;

  void acquire(Object owner) {
    if (!AdvancedBeautyChannel.supported || !_owners.add(owner) || _owners.length != 1) return;
    _foreground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden;
    WidgetsBinding.instance.addObserver(this);
    DeviceStore.shared.state.cameraStatus.addListener(_refresh);
    LoginStore.shared.addListener(_refresh);
    _events = AdvancedBeautyChannel.events.listen((call) {
      final args = call.arguments;
      if (call.method == 'license') _refresh(force: true);
      if (call.method != 'processing' || args is! Map || args['generation'] != _generation) return;
      final ready = args['ready'] == true && _enabled && _key == BeautyPreferences.currentKey;
      if (isProcessing == ready) return;
      isProcessing = ready;
      if (ready) {
        const BeautyPreferences(isEnabled: false).apply();
      } else {
        unawaited(BeautyPreferences.restore(canApply: () => !isProcessing && _owners.isNotEmpty));
      }
    });
    _refresh(force: true);
  }

  void refreshForPresentation() {
    if (_owners.isNotEmpty) _refresh(force: true);
  }

  void release(Object owner) {
    if (!_owners.remove(owner) || _owners.isNotEmpty) return;
    DeviceStore.shared.state.cameraStatus.removeListener(_refresh);
    LoginStore.shared.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_events?.cancel());
    _events = null;
    _refresh(force: true);
  }

  void _refresh({bool force = false}) {
    final key = BeautyPreferences.currentKey;
    final enabled = _owners.isNotEmpty &&
        _foreground &&
        key != null &&
        DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on;
    if (!force && key == _key && enabled == _enabled) return;
    _key = key;
    _enabled = enabled;
    if (!enabled) isProcessing = false;
    unawaited(AdvancedBeautyChannel.configure(
        key: key == null ? null : '$key.advanced', generation: ++_generation, enabled: enabled));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _refresh();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _foreground = false;
      _refresh();
    }
  }
}
