import '../../common/theme/live_theme.dart';
import '../settings/pusher_settings_action_handling.dart';
import 'dart:async';
import 'countdown_view.dart';

import 'package:flutter/widgets.dart';
import '../../common/live_kit_resources.dart';

import 'pusher_prepare_gradient_overlay_view.dart';
import 'pusher_live_info_editor_view.dart';
import 'prepare_more_settings_view.dart';
import '../settings/pusher_settings_item_view.dart';
import 'pusher_cover_picker_view.dart';

class PusherPrepareView extends StatefulWidget {
  const PusherPrepareView({
    super.key,
    required this.liveTitle,
    required this.coverURL,
    required this.settings,
    required this.actionHandler,
    this.onCountdownFinished,
    this.onExit,
    this.onSelectCover,
    this.onFlipCamera,
    this.onRefreshSettings,
    this.onTitleChanged,
    this.onShowBeauty,
    this.onBackStateChanged,
  });

  final String liveTitle;

  final String coverURL;

  final PusherSettingsState settings;
  final PusherSettingsActionHandling actionHandler;

  final void Function(String title)? onCountdownFinished;

  final VoidCallback? onExit;

  final void Function(String coverURL)? onSelectCover;

  final VoidCallback? onFlipCamera;

  final VoidCallback? onRefreshSettings;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onShowBeauty;
  final VoidCallback? onBackStateChanged;

  @override
  State<PusherPrepareView> createState() => PusherPrepareViewState();
}

class PusherPrepareViewState extends State<PusherPrepareView> {
  final PusherLiveInfoEditorController _liveInfoEditorController = PusherLiveInfoEditorController();
  Timer? _countdownTimer;
  int _countdownValue = 0;
  String? _countdownTitle;

  bool get hasTransientUI => _countdownValue > 0 || _isSettingsVisible || _isCoverPickerVisible;

  bool handleBackPressed() {
    if (_countdownValue > 0) {
      cancelCountdown();
    } else if (_isSettingsVisible) {
      _setSettingsVisible(false);
    } else if (_isCoverPickerVisible) {
      _setCoverPickerVisible(false);
    } else {
      return false;
    }
    return true;
  }

  void _setSettingsVisible(bool visible) {
    setState(() => _isSettingsVisible = visible);
    widget.onBackStateChanged?.call();
  }

  void _setCoverPickerVisible(bool visible) {
    setState(() => _isCoverPickerVisible = visible);
    widget.onBackStateChanged?.call();
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownTitle = null;
    if (mounted) setState(() => _countdownValue = 0);
    widget.onBackStateChanged?.call();
  }

  bool _isSettingsVisible = false;
  bool _isCoverPickerVisible = false;
  PrepareMoreSettingsPage _settingsInitialPage = PrepareMoreSettingsPage.main;

  @override
  void initState() {
    super.initState();
    _liveInfoEditorController.bind(title: widget.liveTitle);
  }

  @override
  void didUpdateWidget(PusherPrepareView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_countdownTimer == null && oldWidget.liveTitle != widget.liveTitle) {
      _liveInfoEditorController.bind(title: widget.liveTitle);
    }
  }

  @override
  void deactivate() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownValue = 0;
    _countdownTitle = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _liveInfoEditorController.dispose();
    super.dispose();
  }

  void _start() {
    if (_countdownTimer != null) return;
    _liveInfoEditorController.endEditing();
    _countdownTitle = _liveInfoEditorController.title;
    setState(() => _countdownValue = 3);
    widget.onBackStateChanged?.call();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
      } else {
        final String title = _countdownTitle ?? _liveInfoEditorController.title;
        cancelCountdown();
        widget.onCountdownFinished?.call(title);
      }
    });
  }

  /// `PusherSettingsItemView` 的固有高度，用于把信息区底部锚到快捷操作区上方。
  static const double _actionsHeight = 71;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double actionsBottomInset = padding.bottom + 7 + 52 + 46;

    return Stack(
      children: <Widget>[
        Positioned.fill(
            child: Offstage(
                offstage: _countdownValue > 0,
                child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _liveInfoEditorController.endEditing,
                    child: Stack(children: <Widget>[
                      const Positioned.fill(child: PusherPrepareGradientOverlayView()),
                      Positioned(
                        // top = safeArea.top + 85 高优先级，同时
                        // top ≥ exitButton.bottom + 32、bottom ≤ actions.top - 40，高度由内容决定。
                        // 退出按钮 = safeArea.top + 4 起、44 高；动作区顶部见下方 bottom 计算。
                        left: 0,
                        right: 0,
                        top: padding.top + 85,
                        bottom: actionsBottomInset + _actionsHeight + 40,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: PusherLiveInfoEditorView(
                            controller: _liveInfoEditorController,
                            coverURL: widget.coverURL,
                            onChangeCover: _showCoverPicker,
                            onTitleChanged: widget.onTitleChanged,
                          ),
                        ),
                      ),
                      Positioned(
                        left: padding.left + 8,
                        top: padding.top + 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onExit?.call(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Text(
                                '×',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: padding.bottom + 7,
                        height: 52,
                        child: _GradientButton(
                            title: LiveKitResources.localizedString('tuilivekit.pusher.prepare.start_live'),
                            onPressed: _start),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: actionsBottomInset,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                PusherSettingsItemView(
                                  style: PusherSettingsItemStyle.prepare,
                                  assetName: 'livekit_prepare_beauty',
                                  title: LiveKitResources.localizedString('tuilivekit.pusher.beautify'),
                                  onPressed: _showBeauty,
                                ),
                                const SizedBox(width: 32),
                                PusherSettingsItemView(
                                  style: PusherSettingsItemStyle.prepare,
                                  assetName: 'livekit_prepare_flip',
                                  title: LiveKitResources.localizedString('tuilivekit.pusher.flip_camera'),
                                  onPressed: () => widget.onFlipCamera?.call(),
                                ),
                                const SizedBox(width: 32),
                                PusherSettingsItemView(
                                  style: PusherSettingsItemStyle.prepare,
                                  assetName: 'livekit_prepare_more',
                                  title: LiveKitResources.localizedString('tuilivekit.common.more'),
                                  onPressed: _showSettings,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ])))),
        if (_isCoverPickerVisible)
          Positioned.fill(
            child: PusherCoverPickerView(
              selectedCoverURL: widget.coverURL,
              onSelect: widget.onSelectCover,
              onDismiss: () => _setCoverPickerVisible(false),
            ),
          ),
        Positioned.fill(
          child: PrepareMoreSettingsView(
            settings: widget.settings,
            actionHandler: widget.actionHandler,
            isPresented: _isSettingsVisible,
            initialPage: _settingsInitialPage,
            onDismiss: () => _setSettingsVisible(false),
          ),
        ),
        if (_countdownValue > 0)
          Positioned.fill(child: CountdownView(number: _countdownValue, onCancel: cancelCountdown)),
      ],
    );
  }

  void _showCoverPicker() {
    _liveInfoEditorController.endEditing();
    _setCoverPickerVisible(true);
  }

  void _showSettings() {
    widget.onRefreshSettings?.call();
    _settingsInitialPage = PrepareMoreSettingsPage.main;
    _setSettingsVisible(true);
  }

  void _showBeauty() {
    _liveInfoEditorController.endEditing();
    widget.onShowBeauty?.call();
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  /// UIColor(red: 0, green: 0.32, blue: 0.85, alpha: 1)
  static const Color _deepBlue = LiveTheme.brandDeepBlue;

  /// UIColor(red: 0.29, green: 0.62, blue: 1, alpha: 1)
  static const Color _blue = LiveTheme.brandBlue;

  /// UIColor(red: 0.49, green: 0.91, blue: 1, alpha: 1)
  static const Color _lightBlue = LiveTheme.brandCyan;

  /// _deepBlue，shadowOpacity 0.4
  static const Color _shadowColor = Color(0x660052D9);

  /// 内层渐变：_deepBlue alpha 0.92 → _blue alpha 0.8
  static const Color _innerDeepBlue = Color(0xEB0052D9);
  static const Color _innerBlue = Color(0xCC4A9EFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: <Color>[_deepBlue, _blue, _lightBlue],
            stops: <double>[0, 0.5, 1],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: _shadowColor,
              offset: Offset(0, 8),
              blurRadius: 14,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: <Color>[_innerDeepBlue, _innerBlue],
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
