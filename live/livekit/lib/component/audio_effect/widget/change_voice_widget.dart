import 'package:atomic_x_core/api/device/audio_effect_store.dart';
import 'package:flutter/material.dart';

import '../../../../../common/constants/index.dart';
import '../../../../../common/language/index.dart';
import '../../../../../common/resources/index.dart';
import '../../../../../common/widget/index.dart';
import '../../../../../common/screen//index.dart';

class ChangeVoiceWidget extends StatefulWidget {

  const ChangeVoiceWidget({super.key});

  @override
  State<ChangeVoiceWidget> createState() => _ChangeVoiceWidgetState();
}

class _ChangeVoiceWidgetState extends State<ChangeVoiceWidget> {
  List<ChangeVoiceItem> mData = [];
  late final AudioEffectStore _audioEffectStore;

  @override
  void initState() {
    super.initState();
    _audioEffectStore = AudioEffectStore.shared;
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 89.height,
      child: _initChangeVoiceListViewWidget(),
    );
  }

  Widget _initChangeVoiceListViewWidget() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemCount: mData.length,
      itemBuilder: (context, index) {
        return ValueListenableBuilder(
          valueListenable: _audioEffectStore.audioEffectState.audioChangerType,
          builder: (context, changerType, child) {
            return GestureDetector(
              onTap: () {
                _changeVoice(mData[index].type);
              },
              child: Container(
                width: 56.width,
                height: 80.height,
                margin: EdgeInsets.only(left: 6.width, right: 6.width),
                child: Column(
                  children: [
                    Container(
                      width: 56.radius,
                      height: 56.radius,
                      padding: EdgeInsets.all(13.radius),
                      decoration: BoxDecoration(
                        color: LiveColors.notStandardBlue30Transparency,
                        border: Border.all(
                            color: changerType == mData[index].type
                                ? LiveColors.designStandardB1
                                : LiveColors.notStandardBlue30Transparency,
                            width: 2.width),
                        borderRadius: BorderRadius.circular(10.radius),
                      ),
                      child: Image.asset(
                        mData[index].icon,
                        package: Constants.pluginName,
                      ),
                    ),
                    SizedBox(height: 2.height),
                    SizedBox(
                      height: 18.height,
                      child: Text(
                        mData[index].title,
                        style: const TextStyle(
                            color: LiveColors.designStandardG6, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _initData() {
    mData.clear();
    mData.add(ChangeVoiceItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_change_voice_none,
        icon: LiveImages.selectNone,
        type: AudioChangerType.none));
    mData.add(ChangeVoiceItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_change_voice_child,
        icon: LiveImages.changeVoiceChild,
        type: AudioChangerType.child));
    mData.add(ChangeVoiceItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_change_voice_girl,
        icon: LiveImages.changeVoiceGirl,
        type: AudioChangerType.littleGirl));
    mData.add(ChangeVoiceItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_change_voice_uncle,
        icon: LiveImages.changeVoiceUncle,
        type: AudioChangerType.man));
    mData.add(ChangeVoiceItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_change_voice_ethereal,
        icon: LiveImages.changeVoiceEthereal,
        type: AudioChangerType.ethereal));
  }
}

class ChangeVoiceItem {
  String title;
  String icon;
  AudioChangerType type;

  ChangeVoiceItem({
    required this.title,
    required this.icon,
    required this.type,
  });
}

extension on _ChangeVoiceWidgetState {
  void _changeVoice(AudioChangerType type) {
    _audioEffectStore.setAudioChangerType(type);
  }
}
