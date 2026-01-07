import 'package:flutter/foundation.dart';

/// Manages the display state of ASR (Automatic Speech Recognition) text bubbles.
///
/// Core features:
/// - Hidden set mode: Uses an in-memory Set<String> to store message IDs that are hidden in this session
/// - Shown by default: When asrText has value, the ASR text bubble is shown by default
/// - Session-only: Hidden state only affects current session, lost when exiting message list
/// - Re-entering chat: If asrText has value, it will be shown again
class AsrDisplayManager extends ChangeNotifier {
  /// Set of message IDs that are hidden in this session
  final Set<String> _hiddenMessageIDs = {};

  /// Set of message IDs that are currently converting
  final Set<String> _convertingMessageIDs = {};

  /// Check if the message's ASR text bubble is hidden (collapsed) in this session
  bool isHidden(String messageID) {
    return _hiddenMessageIDs.contains(messageID);
  }

  /// Check if the message is currently converting
  bool isConverting(String messageID) {
    return _convertingMessageIDs.contains(messageID);
  }

  /// Hide the ASR text bubble for this session
  void hide(String messageID) {
    if (_hiddenMessageIDs.add(messageID)) {
      notifyListeners();
    }
  }

  /// Show the ASR text bubble (remove from hidden set)
  void show(String messageID) {
    if (_hiddenMessageIDs.remove(messageID)) {
      notifyListeners();
    }
  }

  /// Mark message as converting
  void setConverting(String messageID, bool converting) {
    bool changed = false;
    if (converting) {
      changed = _convertingMessageIDs.add(messageID);
      // When starting conversion, remove from hidden set so it shows
      _hiddenMessageIDs.remove(messageID);
    } else {
      changed = _convertingMessageIDs.remove(messageID);
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Clear all display states
  void clear() {
    if (_hiddenMessageIDs.isNotEmpty || _convertingMessageIDs.isNotEmpty) {
      _hiddenMessageIDs.clear();
      _convertingMessageIDs.clear();
      notifyListeners();
    }
  }
}
