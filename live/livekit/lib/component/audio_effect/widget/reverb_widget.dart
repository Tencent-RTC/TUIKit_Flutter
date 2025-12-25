import 'package:atomic_x_core/api/device/audio_effect_store.dart';
import 'package:flutter/material.dart';

import '../../../../../common/constants/index.dart';
import '../../../../../common/language/index.dart';
import '../../../../../common/resources/index.dart';
import '../../../../../common/widget/index.dart';
import '../../../../../common/screen/index.dart';

class ReverbWidget extends StatefulWidget {

  const ReverbWidget({super.key});

  @override
  State<ReverbWidget> createState() => _ReverbWidgetState();
}

class _ReverbWidgetState extends State<ReverbWidget> {
  late final AudioEffectStore _audioEffectStore;
  List<ReverbItem> mData = [];

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
      child: _initReverbListViewWidget(),
    );
  }

  Widget _initReverbListViewWidget() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemCount: mData.length,
      itemBuilder: (context, index) {
        return ValueListenableBuilder(
          valueListenable: _audioEffectStore.audioEffectState.audioReverbType,
          builder: (context, reverbType, child) {
            return GestureDetector(
              onTap: () {
                _setReverbType(mData[index].type);
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
                            color: reverbType == mData[index].type
                                ? LiveColors.designStandardB1
                                : LiveColors.notStandardBlue30Transparency,
                            width: 2),
                        borderRadius: BorderRadius.circular(10),
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
    mData.add(ReverbItem(
        title: LiveKitLocalizations.of(Global.appContext())!.common_reverb_none,
        icon: LiveImages.selectNone,
        type: AudioReverbType.none));
    mData.add(ReverbItem(
        title:
            LiveKitLocalizations.of(Global.appContext())!.common_reverb_karaoke,
        icon: LiveImages.reverbKTV,
        type: AudioReverbType.ktv));
    mData.add(ReverbItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_reverb_metallic_sound,
        icon: LiveImages.reverbMetallic,
        type: AudioReverbType.metallic));
    mData.add(ReverbItem(
        title: LiveKitLocalizations.of(Global.appContext())!.common_reverb_low,
        icon: LiveImages.reverbLow,
        type: AudioReverbType.deep));
    mData.add(ReverbItem(
        title: LiveKitLocalizations.of(Global.appContext())!
            .common_reverb_loud_and_loud,
        icon: LiveImages.reverbLoud,
        type: AudioReverbType.loud));
  }
}

class ReverbItem {
  String title;
  String icon;
  AudioReverbType type;

  ReverbItem({
    required this.title,
    required this.icon,
    required this.type,
  });
}

extension on _ReverbWidgetState {
  void _setReverbType(AudioReverbType type) {
    _audioEffectStore.setAudioReverbType(type);
  }
}
