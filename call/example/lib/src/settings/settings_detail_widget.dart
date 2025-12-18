import 'package:flutter/material.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_calls_uikit_example/src/settings/settings_config.dart';
import 'package:tencent_calls_uikit_example/generate/app_localizations.dart';

enum SettingWidgetType {
  avatar,
  extendInfo,
}

class SettingsDetailWidget extends StatefulWidget {
  final SettingWidgetType widgetType;

  const SettingsDetailWidget({Key? key, required this.widgetType}) : super(key: key);

  @override
  State<SettingsDetailWidget> createState() => _SettingsDetailWidgetState();
}

class _SettingsDetailWidgetState extends State<SettingsDetailWidget> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          leading: IconButton(
              onPressed: _goBack,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.control_point_sharp),
              tooltip: 'Search',
              onPressed: () => _setData(),
            ),
          ],
        ),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: TextField(
              autofocus: true,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.please_enter,
                border: InputBorder.none,
              ),
              onChanged: (value) => _data = value),
        ));
  }

  _getTitle() {
    switch (widget.widgetType) {
      case SettingWidgetType.avatar:
        return AppLocalizations.of(context)!.avatar_settings;
      case SettingWidgetType.extendInfo:
        return AppLocalizations.of(context)!.extended_info_settings;
    }
  }

  _setData() {
    switch (widget.widgetType) {
      case SettingWidgetType.avatar:
        SettingsConfig.avatar = _data;
        TUICallKit.instance.setSelfInfo(SettingsConfig.nickname, SettingsConfig.avatar);
        break;
      case SettingWidgetType.extendInfo:
        SettingsConfig.extendInfo = _data;
        break;
    }
  }

  _goBack() {
    Navigator.of(context).pop();
  }
}
