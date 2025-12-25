import 'package:atomic_x_core/api/device/audio_effect_store.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/index.dart';
import '../../../../common/language/index.dart';
import '../../../../common/resources/index.dart';
import '../../../../common/widget/index.dart';
import '../../../../common/screen/index.dart';
import 'widget/change_voice_widget.dart';
import 'widget/reverb_widget.dart';

class AudioEffectPanelWidget extends StatefulWidget {
  final String roomId;

  const AudioEffectPanelWidget({super.key, required this.roomId});

  @override
  State<AudioEffectPanelWidget> createState() => _AudioEffectPanelWidgetState();
}

class _AudioEffectPanelWidgetState extends State<AudioEffectPanelWidget> {
  late double _screenWidth;
  late final AudioEffectStore _audioEffectStore;
  late final DeviceStore _deviceStore;

  @override
  void initState() {
    super.initState();
    _audioEffectStore = AudioEffectStore.shared;
    _deviceStore = DeviceStore.shared;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      width: _screenWidth,
      height: 663.height,
      decoration: BoxDecoration(
        color: LiveColors.designStandardG2,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.width), topRight: Radius.circular(20.width)),
      ),
      child: Column(children: [
        _initTitleWidget(),
        _initEarMonitorWidget(),
        _initAudioSettingWidget(),
        _initChangeVoiceWidget(),
        _initReverbWidget(),
      ]),
    );
  }

  Widget _initTitleWidget() {
    return SizedBox(
      height: 44.height,
      width: _screenWidth,
      child: Stack(
        children: [
          Positioned(
            left: 14.width,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 44.radius,
                height: 44.radius,
                padding: EdgeInsets.all(10.radius),
                child: Image.asset(
                  LiveImages.returnArrow,
                  package: Constants.pluginName,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.common_audio_effect,
              style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initEarMonitorWidget() {
    return Container(
      height: 112.height,
      margin: EdgeInsets.only(left: 16.width, top: 20.height, right: 16.width),
      decoration: BoxDecoration(
        color: LiveColors.notStandardBlue30Transparency,
        borderRadius: BorderRadius.all(Radius.circular(10.radius)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.width),
      child: Column(
        children: [
          SizedBox(
            height: 55.height,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    LiveKitLocalizations.of(Global.appContext())!.common_ear_return,
                    style: const TextStyle(color: LiveColors.notStandardWhite, fontSize: 16),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _audioEffectStore.audioEffectState.isEarMonitorOpened,
                    builder: (context, enableVoiceEarMonitor, child) {
                      return SizedBox(
                        height: 32.height,
                        child: FittedBox(
                          child: CupertinoSwitch(
                            inactiveTrackColor: LiveColors.designStandardG3,
                            activeTrackColor: LiveColors.designStandardB1,
                            value: enableVoiceEarMonitor,
                            onChanged: (value) {
                              _enableEarMonitor(value);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ]),
          ),
          Container(
            height: 0.5.height,
            color: LiveColors.designStandardG6,
          ),
          SizedBox(
            height: 55.height,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    LiveKitLocalizations.of(Global.appContext())!.common_ear_return_volume,
                    style: const TextStyle(color: LiveColors.notStandardWhite, fontSize: 16),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _audioEffectStore.audioEffectState.earMonitorVolume,
                    builder: (context, earMonitorVolume, child) {
                      return SizedBox(
                        width: 150.width,
                        child: Row(
                          children: [
                            Text(
                              earMonitorVolume.toString(),
                              style: const TextStyle(color: LiveColors.notStandardWhite, fontSize: 16),
                            ),
                            Expanded(
                                child: Slider(
                              min: 0,
                              max: 100,
                              value: earMonitorVolume.toDouble(),
                              activeColor: LiveColors.designStandardB1,
                              thumbColor: LiveColors.designStandardFlowkitWhite,
                              onChanged: (double value) {
                                _setEarMonitorVolume(value);
                              },
                            )),
                          ],
                        ),
                      );
                    },
                  ),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _initAudioSettingWidget() {
    return Container(
      width: _screenWidth,
      margin: EdgeInsets.only(left: 16.width, top: 20.height, right: 16.width),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_audio_settings,
            style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 14),
          ),
          Container(
            height: 57.height,
            margin: EdgeInsets.only(
              top: 10.height,
            ),
            decoration: BoxDecoration(
              color: LiveColors.notStandardBlue30Transparency,
              borderRadius: BorderRadius.all(Radius.circular(10.radius)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.width),
            child: Column(
              children: [
                SizedBox(
                  height: 55,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          LiveKitLocalizations.of(Global.appContext())!.common_people_volume,
                          style: const TextStyle(color: LiveColors.notStandardWhite, fontSize: 16),
                        ),
                        ValueListenableBuilder(
                          valueListenable: _deviceStore.state.outputVolume,
                          builder: (context, voiceVolume, child) {
                            return SizedBox(
                              width: 150.width,
                              child: Row(
                                children: [
                                  Text(
                                    voiceVolume.toString(),
                                    style: const TextStyle(color: LiveColors.notStandardWhite, fontSize: 16),
                                  ),
                                  Expanded(
                                      child: Slider(
                                    min: 0,
                                    max: 100,
                                    value: voiceVolume.toDouble(),
                                    activeColor: LiveColors.designStandardB1,
                                    thumbColor: LiveColors.designStandardFlowkitWhite,
                                    onChanged: (double value) {
                                      _setVoiceVolume(value);
                                    },
                                  )),
                                ],
                              ),
                            );
                          },
                        ),
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _initChangeVoiceWidget() {
    return Container(
      width: _screenWidth,
      margin: EdgeInsets.only(left: 16.width, top: 20.height, right: 16.width),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_change_voice,
            style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 14),
          ),
          Container(
            width: _screenWidth,
            margin: EdgeInsets.only(top: 10.height),
            child: const ChangeVoiceWidget(),
          ),
        ],
      ),
    );
  }

  Widget _initReverbWidget() {
    return Container(
      width: _screenWidth,
      margin: EdgeInsets.only(left: 16.width, top: 20.height, right: 16.width),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_reverb,
            style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 14),
          ),
          Container(
            width: _screenWidth,
            margin: EdgeInsets.only(top: 10.height),
            child: const ReverbWidget(),
          ),
        ],
      ),
    );
  }
}

extension on _AudioEffectPanelWidgetState {
  void _enableEarMonitor(bool enable) {
    _audioEffectStore.setVoiceEarMonitorEnable(enable);
  }

  void _setEarMonitorVolume(double volume) {
    _audioEffectStore.setVoiceEarMonitorVolume(volume.toInt());
  }

  void _setVoiceVolume(double volume) {
    _deviceStore.setOutputVolume(volume.toInt());
  }
}
