/// Living 更多设置抽屉：主页面（暂停、静音、基础设置、互动功能）与
/// 音效二级页面；美颜关闭当前抽屉后交给根入口的公共面板。
library;

import '../settings/pusher_settings_action_handling.dart';
import 'package:flutter/widgets.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import '../../common/live_kit_resources.dart';
import '../../common/theme/live_text.dart';
import '../../common/theme/live_theme.dart';

import '../../common/theme/bottom_sheet_view.dart';
import '../settings/audio_effect_view.dart';
import '../settings/pusher_settings_item_view.dart';

enum LivingSettingsPage { main, beauty, audioEffect }

extension _LivingSettingsPageStyle on LivingSettingsPage {
  String? get title {
    switch (this) {
      case LivingSettingsPage.main:
        return null;
      case LivingSettingsPage.beauty:
        return LiveKitResources.localizedString('tuilivekit.pusher.beauty');
      case LivingSettingsPage.audioEffect:
        return audioEffectSheetTitle;
    }
  }

  double get sheetHeight {
    switch (this) {
      case LivingSettingsPage.main:
        return 385;
      case LivingSettingsPage.beauty:
        return 220;
      case LivingSettingsPage.audioEffect:
        return audioEffectSheetHeight;
    }
  }
}

class PusherLivingSettingsView extends StatefulWidget {
  const PusherLivingSettingsView({
    super.key,
    required this.settings,
    required this.settingsActionHandler,
    required this.isPresented,
    required this.onDismiss,
    this.onToggleMute,
    this.onPause,
    this.onShowComment,
    this.onShowBeauty,
    this.audioEffectStore,
  });

  final PusherSettingsState settings;
  final PusherSettingsActionHandling settingsActionHandler;
  final bool isPresented;
  final AudioEffectStore? audioEffectStore;

  /// 抽屉关闭。
  final VoidCallback onDismiss;

  final VoidCallback? onToggleMute;
  final VoidCallback? onPause;
  final VoidCallback? onShowComment;
  final VoidCallback? onShowBeauty;

  @override
  State<PusherLivingSettingsView> createState() => _PusherLivingSettingsViewState();
}

class _PusherLivingSettingsViewState extends State<PusherLivingSettingsView> {
  LivingSettingsPage _page = LivingSettingsPage.main;
  final BottomSheetController _sheetController = BottomSheetController();
  bool _isDismissing = false;
  int _dismissActionID = 0;
  late final _muted = ValueNotifier(widget.settings.isMuted);
  late final _mirror = ValueNotifier(widget.settings.isMirrorEnabled);
  late final Widget _mainPage = _buildMainPage();

  Future<void> _dismiss({VoidCallback? completion}) async {
    if (!mounted || !widget.isPresented || _isDismissing) return;
    _isDismissing = true;
    final actionID = ++_dismissActionID;
    await _sheetController.dismiss();
    // A system back can hide the sheet while its action animation is running.
    // Do not open another panel or pause after that cancellation.
    if (mounted && widget.isPresented && actionID == _dismissActionID) {
      completion?.call();
    }
  }

  void _showPage(LivingSettingsPage page) {
    setState(() {
      _page = page;
    });
  }

  @override
  void didUpdateWidget(PusherLivingSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _muted.value = widget.settings.isMuted;
    _mirror.value = widget.settings.isMirrorEnabled;
    if (oldWidget.isPresented != widget.isPresented) {
      _dismissActionID++;
    }
    if (!oldWidget.isPresented && widget.isPresented) {
      _page = LivingSettingsPage.main;
      _isDismissing = false;
    }
  }

  @override
  void dispose() {
    _dismissActionID++;
    _muted.dispose();
    _mirror.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetView(
      controller: _sheetController,
      isPresented: widget.isPresented,
      sheetHeight: _page.sheetHeight,
      sheetTitle: _page.title,
      onWillDismiss: () => setState(() => _isDismissing = true),
      onDismiss: widget.onDismiss,
      child: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: LivingSettingsPage.main.sheetHeight,
          child: Offstage(
            offstage: _page != LivingSettingsPage.main,
            child: _mainPage,
          ),
        ),
        if (_page == LivingSettingsPage.audioEffect)
          buildAudioEffectPage(
            AudioEffectView(
              settings: widget.settings,
              audioEffectStore: widget.audioEffectStore,
              isActive: widget.isPresented && !_isDismissing,
              onSetCaptureVolume: widget.settingsActionHandler.setCaptureVolume,
            ),
            key: const ValueKey('audio'),
          ),
      ]),
    );
  }

  Widget _buildMainPage() {
    return Stack(
      children: <Widget>[
        Positioned(
          left: 16,
          right: 16,
          top: 30,
          height: 84,
          child: _buildRow(<Widget>[
            PusherSettingsItemView(
              title: LiveKitResources.localizedString('tuilivekit.pusher.living.pause'),
              assetName: 'livekit_living_setting_pause',
              iconSize: const Size(17, 17),
              onPressed: () => _dismiss(completion: () => widget.onPause?.call()),
            ),
            ValueListenableBuilder(
                valueListenable: _muted,
                builder: (context, muted, _) => PusherSettingsItemView(
                      title: muted
                          ? LiveKitResources.localizedString('tuilivekit.pusher.living.unmute')
                          : LiveKitResources.localizedString('tuilivekit.pusher.living.mute'),
                      assetName: muted ? 'livekit_living_setting_mic_off' : 'livekit_living_setting_mic_on',
                      iconSize: const Size(44, 44),
                      // Both Ardot exports include the full 44px circle.
                      showsIconBackground: false,
                      onPressed: () => widget.onToggleMute?.call(),
                    )),
          ]),
        ),
        Positioned(
          left: 20,
          top: 121,
          height: 15,
          child: _LivingSectionTitle(LiveKitResources.localizedString('tuilivekit.pusher.living.basic_settings')),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 148,
          height: 84,
          child: _buildRow(<Widget>[
            PusherSettingsItemView(
              title: LiveKitResources.localizedString('tuilivekit.pusher.beautify'),
              assetName: 'livekit_living_setting_beauty',
              iconSize: const Size(18.05, 16.3),
              onPressed: () => _dismiss(completion: () => widget.onShowBeauty?.call()),
            ),
            ValueListenableBuilder(
                valueListenable: _mirror,
                builder: (context, mirror, _) => PusherSettingsItemView(
                      title: LiveKitResources.localizedString('tuilivekit.pusher.mirror'),
                      assetName: mirror ? 'livekit_settings_mirror_on' : 'livekit_settings_mirror_off',
                      iconSize: const Size(21, 22),
                      onPressed: () => widget.settingsActionHandler.toggleMirror(),
                    )),
            PusherSettingsItemView(
              title: LiveKitResources.localizedString('tuilivekit.pusher.audio_effects'),
              assetName: 'livekit_living_setting_audio',
              iconSize: const Size(18.1, 18.6),
              onPressed: () => _showPage(LivingSettingsPage.audioEffect),
            ),
          ]),
        ),
        Positioned(
          left: 20,
          top: 239,
          height: 15,
          child: _LivingSectionTitle(LiveKitResources.localizedString('tuilivekit.pusher.living.interaction')),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 266,
          height: 84,
          child: _buildRow(<Widget>[
            PusherSettingsItemView(
              title: LiveKitResources.localizedString('tuilivekit.pusher.living.comment'),
              assetName: 'livekit_living_setting_comment',
              iconSize: const Size(19, 16),
              onPressed: () => _dismiss(completion: () => widget.onShowComment?.call()),
            ),
          ]),
        ),
      ],
    );
  }

  /// 三行条目共用 5 列栅格；不足 5 个时右侧留空，保证各行图标纵向对齐。
  static const int _columnCount = 5;

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < _columnCount; i++) Expanded(child: i < children.length ? children[i] : const SizedBox()),
      ],
    );
  }
}

class _LivingSectionTitle extends StatelessWidget {
  const _LivingSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return LiveText(LiveTextRole.caption, text: title, tone: LiveTextTone.tertiary);
  }
}
