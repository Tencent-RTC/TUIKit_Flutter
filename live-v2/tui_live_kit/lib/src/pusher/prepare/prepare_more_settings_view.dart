/// Prepare 阶段的更多抽屉：镜像与音效；美颜由根入口的公共面板承载。
library;

import 'package:flutter/widgets.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import '../../common/live_kit_resources.dart';
import '../../common/theme/bottom_sheet_view.dart';
import '../settings/audio_effect_view.dart';
import '../settings/pusher_settings_action_handling.dart';
import '../settings/pusher_settings_item_view.dart';

enum PrepareMoreSettingsPage { main, audioEffect, beauty }

class PrepareMoreSettingsView extends StatefulWidget {
  const PrepareMoreSettingsView({
    super.key,
    required this.settings,
    required this.actionHandler,
    required this.onDismiss,
    this.isPresented = true,
    this.audioEffectStore,
    this.initialPage = PrepareMoreSettingsPage.main,
  });

  final PusherSettingsState settings;
  final PusherSettingsActionHandling actionHandler;
  final VoidCallback onDismiss;
  final PrepareMoreSettingsPage initialPage;
  final bool isPresented;
  final AudioEffectStore? audioEffectStore;

  @override
  State<PrepareMoreSettingsView> createState() => _PrepareMoreSettingsViewState();
}

class _PrepareMoreSettingsViewState extends State<PrepareMoreSettingsView> {
  late bool _showsAudio;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _showsAudio = widget.initialPage == PrepareMoreSettingsPage.audioEffect;
  }

  @override
  void didUpdateWidget(PrepareMoreSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPresented && widget.isPresented) {
      _showsAudio = widget.initialPage == PrepareMoreSettingsPage.audioEffect;
      _isDismissing = false;
    }
  }

  @override
  Widget build(BuildContext context) => BottomSheetView(
        sheetTitle:
            _showsAudio ? audioEffectSheetTitle : LiveKitResources.localizedString('tuilivekit.pusher.settings.more'),
        isPresented: widget.isPresented,
        sheetHeight: _showsAudio ? audioEffectSheetHeight : 191,
        onWillDismiss: () => setState(() => _isDismissing = true),
        onDismiss: widget.onDismiss,
        child: Stack(children: [
          if (!_showsAudio)
            Positioned(
              left: 16,
              right: 16,
              top: 75,
              height: 84,
              child: Row(children: [
                Expanded(
                  child: PusherSettingsItemView(
                    assetName:
                        widget.settings.isMirrorEnabled ? 'livekit_settings_mirror_on' : 'livekit_settings_mirror_off',
                    title: LiveKitResources.localizedString('tuilivekit.pusher.mirror'),
                    onPressed: widget.actionHandler.toggleMirror,
                  ),
                ),
                Expanded(
                  child: PusherSettingsItemView(
                    assetName: 'livekit_settings_audio_effect',
                    title: LiveKitResources.localizedString('tuilivekit.pusher.audio_effects'),
                    onPressed: () => setState(() => _showsAudio = true),
                  ),
                ),
              ]),
            ),
          if (_showsAudio)
            buildAudioEffectPage(
              AudioEffectView(
                settings: widget.settings,
                audioEffectStore: widget.audioEffectStore,
                isActive: widget.isPresented && !_isDismissing,
                onSetCaptureVolume: widget.actionHandler.setCaptureVolume,
              ),
            ),
        ]),
      );
}
