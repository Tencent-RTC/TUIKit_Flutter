import 'package:flutter/widgets.dart';
import 'package:tuikit_atomic_x/base_component/utils/storage_util.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_picker_config.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_picker_data.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_picker_model.dart';

/// Manager for recent reaction emojis
class RecentEmojiManager {
  static const String _recentEmojiKey = 'recent_reaction_emojis';
  static const int _maxRecentCount = 20;
  static const int _quickEmojiCount = 6;

  /// Get recent emoji IDs (reactionIDs)
  static List<String> getRecentEmojiIds() {
    final result = StorageUtil.get(_recentEmojiKey);
    if (result is List) {
      return result.cast<String>();
    }
    return [];
  }

  /// Add emoji to recent list
  static Future<void> addRecentEmoji(String emojiId) async {
    final recent = getRecentEmojiIds().toList();
    recent.remove(emojiId);
    recent.insert(0, emojiId);
    if (recent.length > _maxRecentCount) {
      recent.removeLast();
    }
    await StorageUtil.set<List<String>>(_recentEmojiKey, recent);
  }

  /// Get quick emojis for reaction picker (6 recent + fill with defaults)
  static List<EmojiPickerModelItem> getQuickEmojis(BuildContext context) {
    final allEmojis = _getAllEmojis(context);
    if (allEmojis.isEmpty) return [];

    final result = <EmojiPickerModelItem>[];
    final recentIds = getRecentEmojiIds();

    // Add recent emojis first
    for (final id in recentIds.take(_quickEmojiCount)) {
      final emoji = allEmojis.firstWhere(
        (e) => e.name == id,
        orElse: () => EmojiPickerModelItem(name: '', path: ''),
      );
      if (emoji.name.isNotEmpty) {
        result.add(emoji);
      }
    }

    // Fill with default emojis if needed
    if (result.length < _quickEmojiCount) {
      for (final emoji in allEmojis) {
        if (result.length >= _quickEmojiCount) break;
        if (!result.any((e) => e.name == emoji.name)) {
          result.add(emoji);
        }
      }
    }

    return result.take(_quickEmojiCount).toList();
  }

  /// Get all available emojis
  static List<EmojiPickerModelItem> _getAllEmojis(BuildContext context) {
    EmojiPickerConfig.loadData(context);
    if (EmojiPickerConfig.customStickerLists.isNotEmpty) {
      final firstGroup = EmojiPickerConfig.customStickerLists.first;
      if (firstGroup.type == 0) {
        // type 0 is default emoji
        return firstGroup.stickers;
      }
    }
    return [];
  }

  /// Get all emojis for full picker
  static List<EmojiPickerModelItem> getAllEmojis(BuildContext context) {
    return _getAllEmojis(context);
  }

  /// Get emoji path by reactionID (name)
  static String? getEmojiPath(String reactionID) {
    for (final entry in emojiPickerDataDefault.entries) {
      if (entry.value == reactionID) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get emoji item by reactionID
  static EmojiPickerModelItem? getEmojiByReactionID(BuildContext context, String reactionID) {
    final allEmojis = _getAllEmojis(context);
    try {
      return allEmojis.firstWhere((e) => e.name == reactionID);
    } catch (_) {
      // If not found in loaded emojis, try to get path from default data
      final path = getEmojiPath(reactionID);
      if (path != null) {
        return EmojiPickerModelItem(name: reactionID, path: path);
      }
      return null;
    }
  }
}
