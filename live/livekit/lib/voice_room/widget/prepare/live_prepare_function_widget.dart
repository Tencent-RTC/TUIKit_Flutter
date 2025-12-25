import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/component/audio_effect/audio_effect_panel_widget.dart';
import 'package:tencent_live_uikit/voice_room/index.dart';
import 'package:tencent_live_uikit/voice_room/manager/voice_room_prepare_store.dart';

class LivePrepareFunctionWidget extends StatefulWidget {
  final VoiceRoomPrepareStore prepareStore;

  const LivePrepareFunctionWidget({super.key, required this.prepareStore});

  @override
  State<LivePrepareFunctionWidget> createState() => _LivePrepareFunctionWidgetState();
}

class _LivePrepareFunctionWidgetState extends State<LivePrepareFunctionWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _initBackgroundSelectorWidget(),
      _initAudioEffectWidget(),
      _initSettingsWidget(),
    ]);
  }

  Widget _initBackgroundSelectorWidget() {
    return GestureDetector(
      onTap: () {
        _showBackgroundSelectorPanel();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.radius,
            height: 36.radius,
            child: Image.asset(
              LiveImages.voiceBackground,
              package: Constants.pluginName,
            ),
          ),
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_settings_bg_image,
            style: const TextStyle(
              fontSize: 12,
              color: LiveColors.designStandardG7,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _initAudioEffectWidget() {
    return GestureDetector(
      onTap: () {
        _showAudioEffectPanel();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.radius,
            height: 36.radius,
            child: Image.asset(
              LiveImages.prepareAudio,
              package: Constants.pluginName,
            ),
          ),
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_audio_effect,
            style: const TextStyle(
              fontSize: 12,
              color: LiveColors.designStandardG7,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _initSettingsWidget() {
    return GestureDetector(
      onTap: () {
        _showSettingsPanel();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.radius,
            height: 36.radius,
            child: Image.asset(
              LiveImages.prepareSetting,
              package: Constants.pluginName,
            ),
          ),
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_settings,
            style: const TextStyle(
              fontSize: 12,
              color: LiveColors.designStandardG7,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

extension on _LivePrepareFunctionWidgetState {
  void _showBackgroundSelectorPanel() {
    popupWidget(LiveBackgroundSelectPanelWidget(
        prepareStore: widget.prepareStore,
        backgroundUrls: Constants.backgroundUrlList,
        initialBackgroundUrl: widget.prepareStore.state.liveInfo.value.backgroundURL));
  }

  void _showAudioEffectPanel() {
    popupWidget(AudioEffectPanelWidget(roomId: widget.prepareStore.state.liveInfo.value.liveID));
  }

  void _showSettingsPanel() {
    popupWidget(SeatModeSettingPanelWidget(prepareStore: widget.prepareStore));
  }
}
