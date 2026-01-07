import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_manager.dart';
import 'package:tuikit_atomic_x/message_input/mention/mention_info.dart';

/// Parser for text translation that handles emoji and @ mentions.
/// This implementation mirrors iOS/Android TranslationTextParser logic.
class TranslationTextParser {
  static const String kSplitStringResultKey = 'result';
  static const String kSplitStringTextKey = 'text';
  static const String kSplitStringTextIndexKey = 'textIndex';

  /// Parse text message and return components for translation.
  /// - [text]: The original text to parse
  /// - [atUserNames]: List of @ user names (without @ prefix)
  /// Returns: Map with "result", "text", and "textIndex" keys
  static Map<String, dynamic>? splitTextByEmojiAndAtUsers(
    String text, {
    List<String>? atUserNames,
  }) {
    if (text.isEmpty) return null;

    List<String> result = [];

    // Build @user strings with @ prefix and trailing space
    List<String> atUsers = [];
    atUserNames?.forEach((user) {
      atUsers.add('@$user ');
    });

    // Find @user ranges in string
    List<_TextRange> atUserRanges = _rangeOfAtUsers(atUsers, text);

    // Split text using @user ranges
    var splitResult = _splitArrayWithRanges(atUserRanges, text);
    if (splitResult == null) return null;

    List<String> splitArrayByAtUser = splitResult.strings;
    Set<int> atUserIndex = splitResult.specialIndexes.toSet();

    // Iterate split array to match emoji in non-@ parts
    int k = -1;
    List<int> textIndexArray = [];

    for (int i = 0; i < splitArrayByAtUser.length; i++) {
      String str = splitArrayByAtUser[i];
      if (atUserIndex.contains(i)) {
        // str is @user info, keep as-is
        result.add(str);
        k++;
      } else {
        // str is not @user info, parse emoji
        List<_TextRange> emojiRanges = _matchTextByEmoji(str);
        var emojiSplitResult = _splitArrayWithRanges(emojiRanges, str);
        if (emojiSplitResult != null) {
          List<String> splitArrayByEmoji = emojiSplitResult.strings;
          Set<int> emojiIndex = emojiSplitResult.specialIndexes.toSet();

          for (int j = 0; j < splitArrayByEmoji.length; j++) {
            String tmp = splitArrayByEmoji[j];
            result.add(tmp);
            k++;
            if (!emojiIndex.contains(j)) {
              // This is text that needs translation
              textIndexArray.add(k);
            }
          }
        }
      }
    }

    // Extract text array from result using indices
    List<String> textArray = [];
    for (int n in textIndexArray) {
      if (n < result.length) {
        textArray.add(result[n]);
      }
    }

    return {
      kSplitStringResultKey: result,
      kSplitStringTextKey: textArray,
      kSplitStringTextIndexKey: textIndexArray,
    };
  }

  /// Reconstruct translated text by replacing text segments with translations.
  static String? replacedStringWithArray(
    List<String> array,
    List<int> indexArray,
    Map<String, String>? replaceDict,
  ) {
    if (replaceDict == null) return null;
    List<String> mutableArray = List.from(array);

    for (int value in indexArray) {
      if (value < 0 || value >= mutableArray.length) continue;
      String? replacement = replaceDict[mutableArray[value]];
      if (replacement != null) {
        mutableArray[value] = replacement;
      }
    }

    return mutableArray.join();
  }

  /// Get @ user names from message's atUserList.
  /// Returns a list of user display names (without @ prefix)
  /// [allMembersText] - The localized text for "All" (e.g., "All", "所有人")
  static Future<List<String>?> getAtUserNames(
    MessageInfo? messageInfo, {
    String allMembersText = 'All',
  }) async {
    if (messageInfo == null || messageInfo.atUserList.isEmpty) {
      return null;
    }

    List<String> atUserIDs = messageInfo.atUserList;

    // Separate @All from regular users
    List<String> regularUserIDs = [];
    List<int> atAllIndexes = [];

    for (int i = 0; i < atUserIDs.length; i++) {
      String userID = atUserIDs[i];
      if (userID == MentionInfo.atAllUserID) {
        atAllIndexes.add(i);
      } else {
        regularUserIDs.add(userID);
      }
    }

    // If only @All
    if (regularUserIDs.isEmpty) {
      // Use localized "All" as the display name for @All
      return List.filled(atAllIndexes.length, allMembersText);
    }

    // Fetch user info for regular users using C2CSettingStore
    List<String> names = List.filled(regularUserIDs.length, '');
    
    // Use Future.wait to fetch all user info in parallel
    List<Future<void>> futures = [];
    
    for (int index = 0; index < regularUserIDs.length; index++) {
      final userID = regularUserIDs[index];
      final settingStore = C2CSettingStore.create(userID: userID);
      
      futures.add(
        settingStore.fetchUserInfo().then((result) {
          if (result.isSuccess) {
            final nickname = settingStore.c2cSettingState.nickname;
            names[index] = nickname.isNotEmpty ? nickname : userID;
          } else {
            names[index] = userID;
          }
          settingStore.dispose();
        }).catchError((_) {
          names[index] = userID;
          settingStore.dispose();
        }),
      );
    }
    
    await Future.wait(futures);

    // Restore @All at original positions
    for (int idx in atAllIndexes) {
      if (idx <= names.length) {
        names.insert(idx, allMembersText);
      }
    }

    return names;
  }

  // Private helpers

  static List<_TextRange> _rangeOfAtUsers(List<String> atUsers, String string) {
    if (atUsers.isEmpty) return [];

    // Find all '@' positions
    List<int> atPositions = [];
    for (int i = 0; i < string.length; i++) {
      if (string[i] == '@') {
        atPositions.add(i);
      }
    }

    List<_TextRange> result = [];
    Set<int> usedPositions = {};

    for (String user in atUsers) {
      for (int idx in atPositions) {
        if (usedPositions.contains(idx)) continue;
        if (string.length >= user.length && idx <= string.length - user.length) {
          String substring = string.substring(idx, idx + user.length);
          if (substring == user) {
            result.add(_TextRange(idx, user.length));
            usedPositions.add(idx);
          }
        }
      }
    }
    return result;
  }

  static _SplitResult? _splitArrayWithRanges(List<_TextRange> ranges, String string) {
    if (ranges.isEmpty) return _SplitResult([string], []);
    if (string.isEmpty) return null;

    // Sort by location
    ranges.sort((a, b) => a.location.compareTo(b.location));

    List<String> result = [];
    List<int> indexes = [];
    int prev = 0;
    int j = -1;

    for (int i = 0; i < ranges.length; i++) {
      _TextRange cur = ranges[i];

      // Add text before current range
      if (cur.location > prev) {
        String str = string.substring(prev, cur.location);
        result.add(str);
        j++;
      }

      // Add content within current range (special element)
      String str = string.substring(cur.location, cur.location + cur.length);
      result.add(str);
      j++;
      indexes.add(j);

      prev = cur.location + cur.length;

      // Handle text after last range
      if (i == ranges.length - 1 && prev < string.length) {
        String last = string.substring(prev);
        result.add(last);
      }
    }

    return _SplitResult(result, indexes);
  }

  /// Match emoji in text using EmojiManager.findEmojiKeyListFromText.
  /// Returns ranges of emoji positions in the text.
  static List<_TextRange> _matchTextByEmoji(String text) {
    List<_TextRange> result = [];

    // Get emoji list from EmojiManager
    List<String> emojiList = EmojiManager.findEmojiKeyListFromText(text);
    if (emojiList.isEmpty) return result;

    // Find positions of each emoji in text
    Set<int> usedPositions = {};

    for (String emoji in emojiList) {
      int searchStart = 0;
      while (searchStart < text.length) {
        int index = text.indexOf(emoji, searchStart);
        if (index == -1) break;

        // Skip if this position is already used
        if (!usedPositions.contains(index)) {
          result.add(_TextRange(index, emoji.length));
          usedPositions.add(index);
          searchStart = index + emoji.length;
        } else {
          searchStart = index + 1;
        }
      }
    }

    return result;
  }

  /// Build translated display text from original text and translation map.
  /// This handles emoji and @ reconstruction.
  static String buildTranslatedDisplayText(
    String originalText,
    Map<String, String> translatedTextMap,
    List<String>? atUserNames,
  ) {
    if (translatedTextMap.isEmpty) return originalText;

    // Parse the original text
    final splitResult = splitTextByEmojiAndAtUsers(
      originalText,
      atUserNames: atUserNames,
    );

    if (splitResult == null) {
      // If parsing fails, try direct lookup
      return translatedTextMap[originalText] ?? originalText;
    }

    final resultArray = splitResult[kSplitStringResultKey] as List<String>? ?? [];
    final textIndexArray = splitResult[kSplitStringTextIndexKey] as List<int>? ?? [];

    // Reconstruct with translations
    final translated = replacedStringWithArray(
      resultArray,
      textIndexArray,
      translatedTextMap,
    );

    return translated ?? originalText;
  }
}

class _TextRange {
  final int location;
  final int length;
  _TextRange(this.location, this.length);
}

class _SplitResult {
  final List<String> strings;
  final List<int> specialIndexes;
  _SplitResult(this.strings, this.specialIndexes);
}
