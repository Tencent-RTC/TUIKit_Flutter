import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user already tapped a call entry in the message input's
/// more panel, keyed per SDKAppID so switching accounts brings the dot back.
///
/// [load] mirrors the flags into memory at startup, because [shouldShow] is
/// asked while the input builds and so cannot await storage. [markClicked]
/// updates that memory copy before persisting, so leaving and re-entering a
/// conversation within one session already sees the dot as consumed.
class MessageInputCallRedDotStore {
  MessageInputCallRedDotStore._();

  static const String _clickedKeyPrefix = 'message_input_call_red_dot_clicked_';

  static final Set<String> _clickedKeys = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final clicked = prefs
        .getKeys()
        .where((key) => key.startsWith(_clickedKeyPrefix) && (prefs.getBool(key) ?? false));
    _clickedKeys
      ..clear()
      ..addAll(clicked);
  }

  /// Whether [actionID] still deserves a dot. Answered from memory, so it can
  /// be called synchronously while the input builds.
  static bool shouldShow(int sdkAppID, String actionID) {
    if (sdkAppID <= 0) {
      return false;
    }
    return !_clickedKeys.contains(_storageKey(sdkAppID, actionID));
  }

  static Future<void> markClicked(int sdkAppID, String actionID) async {
    if (sdkAppID <= 0) {
      return;
    }
    final key = _storageKey(sdkAppID, actionID);
    if (!_clickedKeys.add(key)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  static String _storageKey(int sdkAppID, String actionID) {
    return '$_clickedKeyPrefix$sdkAppID$actionID';
  }
}
