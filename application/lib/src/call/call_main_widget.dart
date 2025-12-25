
import 'package:flutter/material.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import '../utils/index.dart';

class CallMainWidget extends StatefulWidget {
  const CallMainWidget({Key? key}) : super(key: key);

  @override
  State<CallMainWidget> createState() => _CallMainWidgetState();
}

class _CallMainWidgetState extends State<CallMainWidget> {
  String _groupId = '';
  String _userIDsStr = '';
  List<String> _userIDs = [];
  bool _isAudioCall = true;
  bool _enableFloatingWindow = false;
  bool _enableIncomingBanner = false;
  bool _enableMuteMode = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableFloatingWindow = _prefs?.getBool('enable_floating_window') ?? false;
      _enableIncomingBanner = _prefs?.getBool('enable_incoming_banner') ?? false;
      _enableMuteMode = _prefs?.getBool('enable_mute_mode') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.app_call),
        leading: IconButton(
            onPressed: () => _goBack(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            )),
      ),
      body: Stack(
        children: [
          _getCallParamsWidget(),
          _getBtnWidget()],
      ),
    );
  }

  _getCallParamsWidget() {
    return Positioned(
        top: 20,
        left: 10,
        width: MediaQuery.of(context).size.width - 20,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.app_call_user_ids,
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.normal,
                      color: Colors.black),
                ),
                SizedBox(
                    width: 200,
                    child: TextField(
                        autofocus: true,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.app_call_user_ids_separated,
                          border: InputBorder.none,
                        ),
                        onChanged: ((value) => _userIDsStr = value)))
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.app_call_media_type,
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.normal,
                      color: Colors.black),
                ),
                Row(children: [
                  Row(
                    children: [
                      Checkbox(
                        value: !_isAudioCall,
                        onChanged: (value) {
                          setState(() {
                            _isAudioCall = !value!;
                          });
                        },
                        shape: const CircleBorder(),
                      ),
                      Text(
                        AppLocalizations.of(context)!.app_call_media_type_video,
                        style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAudioCall,
                        onChanged: (value) {
                          setState(() {
                            _isAudioCall = value!;
                          });
                        },
                        shape: const CircleBorder(),
                      ),
                      Text(
                        AppLocalizations.of(context)!.app_call_media_type_audio,
                        style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ])
              ],
            ),
            ExpansionTile(
              title: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text(
                  AppLocalizations.of(context)!.app_call_optional_params,
                ),
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.app_call_group_id,
                      style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.normal,
                          color: Colors.black),
                    ),
                    SizedBox(
                        width: 200,
                        child: TextField(
                            autofocus: true,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: _groupId.isNotEmpty
                                  ? _groupId
                                  : AppLocalizations.of(context)!.app_call_group_id,
                              border: InputBorder.none,
                            ),
                            onChanged: ((value) => _groupId = value)))
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSwitchItem(
              AppLocalizations.of(context)!.app_call_enable_floating_window,
              _enableFloatingWindow,
              (value) {
                setState(() {
                  _enableFloatingWindow = value;
                });
                _saveSetting('enable_floating_window', value);
                TUICallKit.instance.enableFloatWindow(value);
              },
            ),
            _buildSwitchItem(
              AppLocalizations.of(context)!.app_call_enable_incoming_banner,
              _enableIncomingBanner,
              (value) {
                setState(() {
                  _enableIncomingBanner = value;
                });
                _saveSetting('enable_incoming_banner', value);
                TUICallKit.instance.enableIncomingBanner(value);
              },
            ),
            _buildSwitchItem(
              AppLocalizations.of(context)!.app_call_enable_mute_mode,
              _enableMuteMode,
              (value) {
                setState(() {
                  _enableMuteMode = value;
                });
                _saveSetting('enable_mute_mode', value);
                TUICallKit.instance.enableMuteMode(value);
              },
            ),
            const SizedBox(height: 50),
          ],
        ));
  }

  Widget _buildSwitchItem(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                color: Colors.black),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xff056DF6),
          ),
        ],
      ),
    );
  }

  _getBtnWidget() {
    return Positioned(
        left: 0,
        bottom: 50,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 52,
              width: MediaQuery.of(context).size.width * 5 / 6,
              child: ElevatedButton(
                  onPressed: () => _call(),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xff056DF6)),
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.call),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.app_call_initiate,
                        style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ],
                  )),
            ),
          ],
        ));
  }

  _goBack() {
    Navigator.of(context).pop();
  }

  _call() {
    _userIDs = _userIDsStr.split(',');
    TUICallKit.instance.calls(_userIDs,
        _isAudioCall ? CallMediaType.audio : CallMediaType.video);
  }


}
