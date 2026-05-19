import 'package:flutter/material.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/index.dart';

class CallSettingsWidget extends StatefulWidget {
  const CallSettingsWidget({Key? key}) : super(key: key);

  @override
  State<CallSettingsWidget> createState() => _CallSettingsWidgetState();
}

class _CallSettingsWidgetState extends State<CallSettingsWidget> {
  bool _enableFloatingWindow = true;
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
      _enableFloatingWindow = _prefs?.getBool('enable_floating_window') ?? true;
      _enableIncomingBanner = _prefs?.getBool('enable_incoming_banner') ?? false;
      _enableMuteMode = _prefs?.getBool('enable_mute_mode') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(l10n.app_call_settings),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSwitchItem(
                  l10n.app_call_enable_floating_window,
                  _enableFloatingWindow,
                  (value) {
                    setState(() {
                      _enableFloatingWindow = value;
                    });
                    _saveSetting('enable_floating_window', value);
                    TUICallKit.instance.enableFloatWindow(value);
                  },
                ),
                _buildDivider(),
                _buildSwitchItem(
                  l10n.app_call_enable_incoming_banner,
                  _enableIncomingBanner,
                  (value) {
                    setState(() {
                      _enableIncomingBanner = value;
                    });
                    _saveSetting('enable_incoming_banner', value);
                    TUICallKit.instance.enableIncomingBanner(value);
                  },
                ),
                _buildDivider(),
                _buildSwitchItem(
                  l10n.app_call_enable_mute_mode,
                  _enableMuteMode,
                  (value) {
                    setState(() {
                      _enableMuteMode = value;
                    });
                    _saveSetting('enable_mute_mode', value);
                    TUICallKit.instance.enableMuteMode(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }

  Widget _buildSwitchItem(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
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
}
