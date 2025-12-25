import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

class SettingsPanelWidget extends StatefulWidget {
  final void Function(SettingsItemType) onTapSettingsPanelItem;

  const SettingsPanelWidget({super.key, required this.onTapSettingsPanelItem});

  @override
  State<SettingsPanelWidget> createState() => _SettingsPanelWidgetState();
}

class _SettingsPanelWidgetState extends State<SettingsPanelWidget> {
  late final List<SettingsItem> list;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    _initSettingItems();
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      width: _screenWidth,
      height: 350.height,
      decoration: BoxDecoration(
        color: LiveColors.designStandardG2,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.width), topRight: Radius.circular(20.width)),
      ),
      child: Column(children: [
        SizedBox(height: 20.height),
        _initTitleWidget(),
        SizedBox(height: 32.height),
        _initSettingsListWidget()
      ]),
    );
  }

  Widget _initTitleWidget() {
    return Container(
      alignment: Alignment.center,
      height: 28.height,
      width: _screenWidth,
      child: Text(
        LiveKitLocalizations.of(Global.appContext())!.common_settings,
        style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
      ),
    );
  }

  Widget _initSettingsListWidget() {
    return SizedBox(
      width: _screenWidth,
      height: 92.height,
      child: Center(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _onTapIndex(index),
              child: Container(
                width: 56.width,
                height: 79.height,
                margin: EdgeInsets.symmetric(horizontal: 22.width),
                child: Column(
                  children: [
                    Container(
                      width: 56.radius,
                      height: 56.radius,
                      padding: EdgeInsets.all(2.radius),
                      decoration: BoxDecoration(
                        color: LiveColors.notStandardBlue30Transparency,
                        border: Border.all(color: LiveColors.notStandardBlue30Transparency, width: 2.width),
                        borderRadius: BorderRadius.circular(10.radius),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30.radius,
                          height: 30.radius,
                          child: Image.asset(
                            list[index].icon,
                            package: Constants.pluginName,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.height),
                    Text(
                      list[index].title,
                      style: const TextStyle(color: LiveColors.designStandardG6, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension on _SettingsPanelWidgetState {
  void _onTapIndex(int index) {
    final item = list[index];
    switch (item.type) {
      case SettingsItemType.background:
        widget.onTapSettingsPanelItem?.call(SettingsItemType.background);
        break;
      case SettingsItemType.audioEffect:
        widget.onTapSettingsPanelItem?.call(SettingsItemType.audioEffect);
        break;
      default:
        break;
    }
  }

  void _initSettingItems() {
    list = [
      SettingsItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_settings_bg_image,
          icon: LiveImages.settingBackground,
          type: SettingsItemType.background),
      SettingsItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_audio_effect,
          icon: LiveImages.settingsItemMusic,
          type: SettingsItemType.audioEffect)
    ];
  }
}

enum SettingsItemType { background, audioEffect }

class SettingsItem {
  String title;
  String icon;
  SettingsItemType type;

  SettingsItem({
    required this.title,
    required this.icon,
    required this.type,
  });
}
