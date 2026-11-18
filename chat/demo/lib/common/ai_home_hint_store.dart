import 'package:shared_preferences/shared_preferences.dart';

/// Whether the experience demo's AI home hints are still pending.
///
/// Stored in app-private preferences, so uninstalling brings both dots and the
/// prefilled prompt back.
class AIHomeHintStore {
  AIHomeHintStore._();

  static const String _sendClickedKey = 'ai_home_send_red_dot_clicked';
  static const String _callClickedKey = 'ai_home_call_red_dot_clicked';

  static bool _sendClicked = false;
  static bool _callClicked = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sendClicked = prefs.getBool(_sendClickedKey) ?? false;
    _callClicked = prefs.getBool(_callClickedKey) ?? false;
  }

  static bool get shouldShowSend => !_sendClicked;

  static bool get shouldShowCall => !_callClicked;

  static void markSendClicked() {
    if (_sendClicked) return;
    _sendClicked = true;
    _persist(_sendClickedKey);
  }

  static void markCallClicked() {
    if (_callClicked) return;
    _callClicked = true;
    _persist(_callClickedKey);
  }

  static void _persist(String key) {
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(key, true));
  }
}
