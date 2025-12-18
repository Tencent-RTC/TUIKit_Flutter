import 'package:flutter/material.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_calls_uikit_example/src/settings/settings_config.dart';
import 'package:tencent_calls_uikit_example/src/settings/settings_detail_widget.dart';
import 'package:tencent_calls_uikit_example/generate/app_localizations.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        leading: IconButton(
            onPressed: () => _goBack(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            )),
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
        child: ListView(
          children: [
            _getBasicSettingsWidget(),
            _getCallParamsSettingsWidget(),
            _getVideoSettingsWidget()
          ],
        ),
      ),
    );
  }

  _getBasicSettingsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Text(
            AppLocalizations.of(context)!.settings,
            style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                color: Colors.black54),
          ),
        ),
        SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.avatar,
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.normal,
                      color: Colors.black),
                ),
                InkWell(
                    onTap: () => _goDetailSettings(SettingWidgetType.avatar),
                    child: Row(children: [
                      SizedBox(
                          width: 200,
                          child: Text(
                            (SettingsConfig.avatar.isEmpty)
                                ? AppLocalizations.of(context)!.not_set
                                : SettingsConfig.avatar,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.normal,
                                color: Colors.black),
                            textAlign: TextAlign.right,
                          )),
                      const SizedBox(width: 10),
                      const Text('>')
                    ]))
              ],
            )),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.nick_name,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: TextField(
                      autofocus: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: (SettingsConfig.nickname.isEmpty)
                            ? AppLocalizations.of(context)!.not_set
                            : SettingsConfig.nickname,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        SettingsConfig.nickname = value;
                        TUICallKit.instance
                            .setSelfInfo(SettingsConfig.nickname, SettingsConfig.avatar);
                      }))
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.silent_mode,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              Switch(
                  value: SettingsConfig.muteMode,
                  onChanged: (value) {
                    setState(() {
                      SettingsConfig.muteMode = value;
                      TUICallKit.instance.enableMuteMode(SettingsConfig.muteMode);
                    });
                  })
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.enable_floating,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              Switch(
                  value: SettingsConfig.enableFloatWindow,
                  onChanged: (value) {
                    setState(() {
                      SettingsConfig.enableFloatWindow = value;
                      TUICallKit.instance.enableFloatWindow(SettingsConfig.enableFloatWindow);
                    });
                  })
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.show_blur_background_button,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              Switch(
                  value: SettingsConfig.showBlurBackground,
                  onChanged: (value) {
                    setState(() {
                      SettingsConfig.showBlurBackground = value;
                      TUICallKit.instance
                          .enableVirtualBackground(SettingsConfig.showBlurBackground);
                    });
                  })
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.show_incoming_banner,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              Switch(
                  value: SettingsConfig.showIncomingBanner,
                  onChanged: (value) {
                    setState(() {
                      SettingsConfig.showIncomingBanner = value;
                      TUICallKit.instance.enableIncomingBanner(SettingsConfig.showIncomingBanner);
                    });
                  })
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  _getCallParamsSettingsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Text(
            AppLocalizations.of(context)!.call_custom_setiings,
            style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                color: Colors.black54),
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.digital_room,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: TextField(
                      autofocus: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: '${SettingsConfig.intRoomId}',
                        border: InputBorder.none,
                      ),
                      onChanged: ((value) => SettingsConfig.intRoomId = int.parse(value))))
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.string_room,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: TextField(
                      autofocus: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: SettingsConfig.strRoomId,
                        border: InputBorder.none,
                      ),
                      onChanged: ((value) => SettingsConfig.strRoomId = value)))
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.timeout,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: TextField(
                      autofocus: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: '${SettingsConfig.timeout}',
                        border: InputBorder.none,
                      ),
                      onChanged: ((value) => SettingsConfig.timeout = int.parse(value))))
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.extended_info,
                style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              InkWell(
                  onTap: () => _goDetailSettings(SettingWidgetType.extendInfo),
                  child: Row(children: [
                    Text(
                      SettingsConfig.extendInfo.isEmpty
                          ? AppLocalizations.of(context)!.not_set
                          : SettingsConfig.extendInfo,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.normal,
                          color: Colors.black),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(width: 10),
                    const Text('>')
                  ]))
            ],
          ),
        ),
      ],
    );
  }

  _getVideoSettingsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Text(
            AppLocalizations.of(context)!.video_settings,
            style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                color: Colors.black54),
          ),
        ),
      ],
    );
  }

  _goBack() {
    Navigator.of(context).pop();
  }

  _goDetailSettings(SettingWidgetType widgetType) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return SettingsDetailWidget(widgetType: widgetType);
      },
    ));
  }
}
