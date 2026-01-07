import 'package:flutter/foundation.dart';

/// Manages the display state of translation text bubbles.
///
/// Core features:
/// - Hidden set mode: Uses an in-memory Set<String> to store message IDs that are hidden in this session
/// - Shown by default: When translatedText has value, the translation bubble is shown by default
/// - Session-only: Hidden state only affects current session, lost when exiting message list
/// - Re-entering chat: If translatedText has value, it will be shown again
class TranslationDisplayManager extends ChangeNotifier {
  /// Set of message IDs that are hidden in this session
  final Set<String> _hiddenMessageIDs = {};

  /// Set of message IDs that are currently translating
  final Set<String> _translatingMessageIDs = {};

  /// Check if the message's translation bubble is hidden (collapsed) in this session
  bool isHidden(String messageID) {
    return _hiddenMessageIDs.contains(messageID);
  }

  /// Check if the message is currently translating
  bool isTranslating(String messageID) {
    return _translatingMessageIDs.contains(messageID);
  }

  /// Hide the translation bubble for this session
  void hide(String messageID) {
    if (_hiddenMessageIDs.add(messageID)) {
      notifyListeners();
    }
  }

  /// Show the translation bubble (remove from hidden set)
  void show(String messageID) {
    if (_hiddenMessageIDs.remove(messageID)) {
      notifyListeners();
    }
  }

  /// Mark message as translating
  void setTranslating(String messageID, bool translating) {
    bool changed = false;
    if (translating) {
      changed = _translatingMessageIDs.add(messageID);
      // When starting translation, remove from hidden set so it shows
      _hiddenMessageIDs.remove(messageID);
    } else {
      changed = _translatingMessageIDs.remove(messageID);
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Clear all display states
  void clear() {
    if (_hiddenMessageIDs.isNotEmpty || _translatingMessageIDs.isNotEmpty) {
      _hiddenMessageIDs.clear();
      _translatingMessageIDs.clear();
      notifyListeners();
    }
  }
}
