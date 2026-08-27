import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import 'voice_clone_page.dart';
import 'voice_select_page.dart';

/// "Voice Message Settings" page. Per spec it only exposes two entries:
/// voice clone and voice selection.
class VoiceMessageSettingsPage extends StatefulWidget {
  const VoiceMessageSettingsPage({super.key});

  @override
  State<VoiceMessageSettingsPage> createState() =>
      _VoiceMessageSettingsPageState();
}

class _VoiceMessageSettingsPageState extends State<VoiceMessageSettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadSelectedVoice();
  }

  Future<void> _loadSelectedVoice() async {
    await VoiceMessageConfig.instance.load();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final chatLocale = ChatLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bgColorInput,
      appBar: SettingWidgets.buildAppBar(
        context: context,
        title: chatLocale.voiceMessageSettings,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SettingWidgets.buildSettingGroup(
              context: context,
              children: [
                SettingWidgets.buildNavigationRow(
                  context: context,
                  title: chatLocale.voiceClone,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceClonePage()),
                    );
                    // Cloning auto-selects the new voice; refresh the value.
                    if (mounted) setState(() {});
                  },
                ),
                SettingWidgets.buildNavigationRow(
                  context: context,
                  title: chatLocale.voiceSelect,
                  value: _selectedVoiceDisplayName(chatLocale),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceSelectPage()),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _selectedVoiceDisplayName(ChatLocalizations chatLocale) {
    final name = VoiceMessageConfig.instance.selectedVoiceName;
    return name.isEmpty ? chatLocale.voiceDefault : name;
  }
}
