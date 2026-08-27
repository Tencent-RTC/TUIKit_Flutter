import 'package:flutter/foundation.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

/// Per-conversation chat background persistence, shared by the chat setting
/// pages (which write) and the message list (which paints).
///
/// The value is cached in memory so the message list can paint the right
/// background on its first frame, and [revision] lets an already-open message
/// list repaint as soon as a setting page changes the selection.
class ChatBackgroundStore {
  ChatBackgroundStore._();

  static final ChatBackgroundStore shared = ChatBackgroundStore._();

  /// Same storage key shape as the native implementations.
  static const String _keyPrefix = 'chat_background::';

  final Map<String, String?> _cache = {};

  /// Bumped on every write; listeners re-read through [peek].
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Reads the persisted value, populating the cache on first access.
  Future<String?> load(String conversationID) async {
    if (_cache.containsKey(conversationID)) {
      return _cache[conversationID];
    }
    final stored = await StorageUtil.get('$_keyPrefix$conversationID');
    final imageUri = (stored is String && stored.isNotEmpty) ? stored : null;
    _cache[conversationID] = imageUri;
    return imageUri;
  }

  /// Cached value only; `null` both when unset and when not loaded yet.
  String? peek(String conversationID) => _cache[conversationID];

  /// Passing a `null` or empty [imageUri] restores the default background.
  Future<void> setImageUri(String conversationID, String? imageUri) async {
    final key = '$_keyPrefix$conversationID';
    if (imageUri == null || imageUri.isEmpty) {
      _cache[conversationID] = null;
      await StorageUtil.remove(key);
    } else {
      _cache[conversationID] = imageUri;
      await StorageUtil.set<String>(key, imageUri);
    }
    revision.value++;
  }
}
