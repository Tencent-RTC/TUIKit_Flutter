import 'package:atomic_x_core/atomicxcore.dart';

import 'package:flutter/cupertino.dart';

import '../../common/live_kit_resources.dart';
import '../../common/theme/live_slider.dart';
import '../../common/theme/live_text.dart';
import '../../common/theme/live_theme.dart';
import 'pusher_settings_action_handling.dart';
import 'pusher_settings_item_view.dart';

// Prepare and Living keep separate instances and navigation; only audio-page assembly is shared.
const audioEffectSheetHeight = 466.0;
String get audioEffectSheetTitle => LiveKitResources.localizedString('tuilivekit.pusher.audio_effects');

Widget buildAudioEffectPage(AudioEffectView content, {Key? key}) => Positioned(
      key: key,
      left: 16,
      right: 16,
      top: 60,
      height: 372,
      child: content,
    );

class AudioEffectView extends StatefulWidget {
  const AudioEffectView({
    super.key,
    required this.settings,
    this.isActive = true,
    this.audioEffectStore,
    this.onSetCaptureVolume,
  });

  // 采集音量属于设备，继续由根入口读取和写入。
  final PusherSettingsState settings;
  final bool isActive;
  final AudioEffectStore? audioEffectStore;
  final ValueChanged<int>? onSetCaptureVolume;

  static void resetForNewSession() {
    final store = AudioEffectStore.shared;
    store.setVoiceEarMonitorEnable(false);
    store.setVoiceEarMonitorVolume(100);
    store.setAudioChangerType(AudioChangerType.none);
    store.setAudioReverbType(AudioReverbType.none);
  }

  static String _text(String key) => LiveKitResources.localizedString('tuilivekit.pusher.settings.$key');

  @override
  State<AudioEffectView> createState() => _AudioEffectViewState();
}

class _AudioEffectViewState extends State<AudioEffectView> {
  late final _store = widget.audioEffectStore ?? AudioEffectStore.shared;
  bool _subscribed = false;

  List<Listenable> get _signals => [
        _store.audioEffectState.isEarMonitorOpened,
        _store.audioEffectState.earMonitorVolume,
        _store.audioEffectState.audioChangerType,
        _store.audioEffectState.audioReverbType,
      ];

  @override
  void initState() {
    super.initState();
    _updateSubscription();
  }

  @override
  void didUpdateWidget(AudioEffectView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSubscription();
  }

  void _updateSubscription() {
    if (_subscribed == widget.isActive) return;
    _subscribed = widget.isActive;
    for (final signal in _signals) {
      if (_subscribed) {
        signal.addListener(_refresh);
      } else {
        signal.removeListener(_refresh);
      }
    }
  }

  void _refresh() {
    if (mounted && _subscribed) setState(() {});
  }

  @override
  void dispose() {
    for (final signal in _signals) {
      signal.removeListener(_refresh);
    }
    _subscribed = false;
    super.dispose();
  }

  void _setChanger(AudioChangerType value) {
    if (!_subscribed) return;
    _store.setAudioChangerType(value);
  }

  void _setReverb(AudioReverbType value) {
    if (!_subscribed) return;
    _store.setAudioReverbType(value);
  }

  static String _text(String key) => AudioEffectView._text(key);

  @override
  Widget build(BuildContext context) {
    final state = _store.audioEffectState;
    return Stack(children: <Widget>[
      Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 96,
          child: _card(
              child: Stack(children: <Widget>[
            Positioned(
                left: 16,
                top: 0,
                height: 48,
                child: Center(child: LiveText(LiveTextRole.body, text: _text('ear_monitor'), isEmphasized: true))),
            Positioned(
                right: 10,
                top: 8.5,
                width: 51,
                height: 31,
                child: Transform.scale(
                    scale: .81,
                    child: CupertinoSwitch(
                      value: state.isEarMonitorOpened.value,
                      activeColor: const Color(0xFF2E85F2),
                      onChanged: (value) {
                        if (_subscribed) _store.setVoiceEarMonitorEnable(value);
                      },
                    ))),
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 48,
                child: _SettingsVolumeView(
                    title: _text('ear_monitor_volume'),
                    value: state.earMonitorVolume.value,
                    onValueChanged: (value) {
                      if (_subscribed) {
                        _store.setVoiceEarMonitorVolume(value.clamp(0, 100));
                      }
                    })),
          ]))),
      Positioned(
          left: 0,
          top: 108,
          height: 15,
          child: LiveText(LiveTextRole.sectionTitle, text: _text('audio'), tone: LiveTextTone.tertiary)),
      Positioned(
          left: 0,
          right: 0,
          top: 130,
          height: 46,
          child: _card(
              child: _SettingsVolumeView(
                  title: _text('capture_volume'),
                  value: widget.settings.captureVolume,
                  onValueChanged: widget.onSetCaptureVolume))),
      Positioned(
          left: 0,
          right: 0,
          top: 188,
          height: 86,
          child: _SoundOptionSection<AudioChangerType>(
              title: _text('voice_changer'),
              selected: state.audioChangerType.value,
              onSelect: _setChanger,
              options: const [
                (AudioChangerType.none, 'voice.original', 'livekit_voice_original'),
                (AudioChangerType.child, 'voice.child', 'livekit_voice_child'),
                (AudioChangerType.littleGirl, 'voice.loli', 'livekit_voice_loli'),
                (AudioChangerType.man, 'voice.uncle', 'livekit_voice_uncle'),
                (AudioChangerType.ethereal, 'voice.spirit', 'livekit_voice_spirit'),
              ])),
      Positioned(
          left: 0,
          right: 0,
          top: 286,
          height: 86,
          child: _SoundOptionSection<AudioReverbType>(
              title: _text('reverb'),
              selected: state.audioReverbType.value,
              onSelect: _setReverb,
              options: const [
                (AudioReverbType.none, 'reverb.none', 'livekit_reverb_none'),
                (AudioReverbType.ktv, 'reverb.ktv', 'livekit_reverb_ktv'),
                (AudioReverbType.metallic, 'reverb.metal', 'livekit_reverb_metal'),
                (AudioReverbType.deep, 'reverb.deep', 'livekit_reverb_deep'),
                (AudioReverbType.loud, 'reverb.bright', 'livekit_reverb_bright'),
              ])),
    ]);
  }

  Widget _card({required Widget child}) => Container(
        decoration:
            BoxDecoration(color: PusherSettingsSelectionStyle.idleBackground, borderRadius: BorderRadius.circular(14)),
        foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PusherSettingsSelectionStyle.idleBorder)),
        child: child,
      );
}

class _SoundOptionSection<T> extends StatelessWidget {
  const _SoundOptionSection(
      {required this.title, required this.options, required this.selected, required this.onSelect});
  final String title;
  final List<(T, String, String)> options;
  final T selected;
  final ValueChanged<T>? onSelect;

  @override
  Widget build(BuildContext context) {
    final selection = options.any((option) => option.$1 == selected) ? selected : options.first.$1;
    return Stack(children: <Widget>[
      Positioned(
          left: 0,
          top: 0,
          height: 15,
          child: LiveText(LiveTextRole.sectionTitle, text: title, tone: LiveTextTone.tertiary)),
      Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 64,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final option in options)
              Expanded(
                  child: PusherSettingsItemView(
                style: PusherSettingsItemStyle.soundOption,
                title: AudioEffectView._text(option.$2),
                assetName: option.$3,
                isSelected: selection == option.$1,
                onPressed: () => onSelect?.call(option.$1),
              )),
          ])),
    ]);
  }
}

class _SettingsVolumeView extends StatelessWidget {
  const _SettingsVolumeView({required this.title, required this.value, required this.onValueChanged});
  final String title;
  final int value;
  final ValueChanged<int>? onValueChanged;

  @override
  Widget build(BuildContext context) => Stack(children: <Widget>[
        Positioned(
            left: 16,
            width: 112,
            top: 0,
            bottom: 0,
            child: Align(
                alignment: Alignment.centerLeft,
                child: LiveText(LiveTextRole.itemTitle, text: title, tone: LiveTextTone.secondary, maxLines: 2))),
        Positioned(
            left: 136,
            width: 30,
            top: 0,
            bottom: 0,
            child: Align(
                alignment: Alignment.centerRight,
                child: LiveText(LiveTextRole.action,
                    text: '$value', tone: LiveTextTone.secondary, alignment: TextAlign.right))),
        Positioned(
            left: 176,
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
                child: LiveSlider(
                    value: value.toDouble(),
                    max: 100,
                    semanticLabel: title,
                    onChanged: (value) => onValueChanged?.call(value.round())))),
      ]);
}
