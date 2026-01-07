import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

class EmojiManager {
  static Map<String, String> getEmojiMap(BuildContext context) {
    final atomicLocale = AtomicLocalizations.of(context);
    return {
      '[TUIEmoji_Smile]': atomicLocale.tuiEmojiSmile,
      '[TUIEmoji_Expect]': atomicLocale.tuiEmojiExpect,
      '[TUIEmoji_Blink]': atomicLocale.tuiEmojiBlink,
      '[TUIEmoji_Guffaw]': atomicLocale.tuiEmojiGuffaw,
      '[TUIEmoji_KindSmile]': atomicLocale.tuiEmojiKindSmile,
      '[TUIEmoji_Haha]': atomicLocale.tuiEmojiHaha,
      '[TUIEmoji_Cheerful]': atomicLocale.tuiEmojiCheerful,
      '[TUIEmoji_Speechless]': atomicLocale.tuiEmojiSpeechless,
      '[TUIEmoji_Amazed]': atomicLocale.tuiEmojiAmazed,
      '[TUIEmoji_Sorrow]': atomicLocale.tuiEmojiSorrow,
      '[TUIEmoji_Complacent]': atomicLocale.tuiEmojiComplacent,
      '[TUIEmoji_Silly]': atomicLocale.tuiEmojiSilly,
      '[TUIEmoji_Lustful]': atomicLocale.tuiEmojiLustful,
      '[TUIEmoji_Giggle]': atomicLocale.tuiEmojiGiggle,
      '[TUIEmoji_Kiss]': atomicLocale.tuiEmojiKiss,
      '[TUIEmoji_Wail]': atomicLocale.tuiEmojiWail,
      '[TUIEmoji_TearsLaugh]': atomicLocale.tuiEmojiTearsLaugh,
      '[TUIEmoji_Trapped]': atomicLocale.tuiEmojiTrapped,
      '[TUIEmoji_Mask]': atomicLocale.tuiEmojiMask,
      '[TUIEmoji_Fear]': atomicLocale.tuiEmojiFear,
      '[TUIEmoji_BareTeeth]': atomicLocale.tuiEmojiBareTeeth,
      '[TUIEmoji_FlareUp]': atomicLocale.tuiEmojiFlareUp,
      '[TUIEmoji_Yawn]': atomicLocale.tuiEmojiYawn,
      '[TUIEmoji_Tact]': atomicLocale.tuiEmojiTact,
      '[TUIEmoji_Stareyes]': atomicLocale.tuiEmojiStareyes,
      '[TUIEmoji_ShutUp]': atomicLocale.tuiEmojiShutUp,
      '[TUIEmoji_Sigh]': atomicLocale.tuiEmojiSigh,
      '[TUIEmoji_Hehe]': atomicLocale.tuiEmojiHehe,
      '[TUIEmoji_Silent]': atomicLocale.tuiEmojiSilent,
      '[TUIEmoji_Surprised]': atomicLocale.tuiEmojiSurprised,
      '[TUIEmoji_Askance]': atomicLocale.tuiEmojiAskance,
      '[TUIEmoji_Ok]': atomicLocale.tuiEmojiOk,
      '[TUIEmoji_Shit]': atomicLocale.tuiEmojiShit,
      '[TUIEmoji_Monster]': atomicLocale.tuiEmojiMonster,
      '[TUIEmoji_Daemon]': atomicLocale.tuiEmojiDaemon,
      '[TUIEmoji_Rage]': atomicLocale.tuiEmojiRage,
      '[TUIEmoji_Fool]': atomicLocale.tuiEmojiFool,
      '[TUIEmoji_Pig]': atomicLocale.tuiEmojiPig,
      '[TUIEmoji_Cow]': atomicLocale.tuiEmojiCow,
      '[TUIEmoji_Ai]': atomicLocale.tuiEmojiAi,
      '[TUIEmoji_Skull]': atomicLocale.tuiEmojiSkull,
      '[TUIEmoji_Bombs]': atomicLocale.tuiEmojiBombs,
      '[TUIEmoji_Coffee]': atomicLocale.tuiEmojiCoffee,
      '[TUIEmoji_Cake]': atomicLocale.tuiEmojiCake,
      '[TUIEmoji_Beer]': atomicLocale.tuiEmojiBeer,
      '[TUIEmoji_Flower]': atomicLocale.tuiEmojiFlower,
      '[TUIEmoji_Watermelon]': atomicLocale.tuiEmojiWatermelon,
      '[TUIEmoji_Rich]': atomicLocale.tuiEmojiRich,
      '[TUIEmoji_Heart]': atomicLocale.tuiEmojiHeart,
      '[TUIEmoji_Moon]': atomicLocale.tuiEmojiMoon,
      '[TUIEmoji_Sun]': atomicLocale.tuiEmojiSun,
      '[TUIEmoji_Star]': atomicLocale.tuiEmojiStar,
      '[TUIEmoji_RedPacket]': atomicLocale.tuiEmojiRedPacket,
      '[TUIEmoji_Celebrate]': atomicLocale.tuiEmojiCelebrate,
      '[TUIEmoji_Bless]': atomicLocale.tuiEmojiBless,
      '[TUIEmoji_Fortune]': atomicLocale.tuiEmojiFortune,
      '[TUIEmoji_Convinced]': atomicLocale.tuiEmojiConvinced,
      '[TUIEmoji_Prohibit]': atomicLocale.tuiEmojiProhibit,
      '[TUIEmoji_666]': atomicLocale.tuiEmoji666,
      '[TUIEmoji_857]': atomicLocale.tuiEmoji857,
      '[TUIEmoji_Knife]': atomicLocale.tuiEmojiKnife,
      '[TUIEmoji_Like]': atomicLocale.tuiEmojiLike,
    };
  }

  /// Convert emoji codes in text to localized names
  /// e.g., "abc[TUIEmoji_Smile]def" -> "abc[微笑]def" (Chinese) or "abc[Smile]def" (English)
  static String createLocalizedStringFromEmojiCodes(BuildContext context, String text) {
    if (text.isEmpty) {
      return text;
    }

    final emojiMap = getEmojiMap(context);
    String result = text;

    // Sort by key length descending to handle longer keys first
    final sortedKeys = emojiMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (result.contains(key)) {
        result = result.replaceAll(key, emojiMap[key]!);
      }
    }

    return result;
  }

  static List<String> findEmojiKeyListFromText(String text) {
    if (text.isEmpty) {
      return [];
    }

    List<String> emojiKeyList = [];
    // TUIKit custom emoji.
    String regexOfCustomEmoji = "\\[(\\S+?)\\]";
    Pattern patternOfCustomEmoji = RegExp(regexOfCustomEmoji);
    Iterable<Match> matcherOfCustomEmoji = patternOfCustomEmoji.allMatches(text);

    for (Match match in matcherOfCustomEmoji) {
      String? emojiName = match.group(0);
      if (emojiName != null && emojiName.isNotEmpty) {
        emojiKeyList.add(emojiName);
      }
    }

    // Universal standard emoji.
    RegExp patternOfUniversalEmoji = getUniversalEmojiRegex();
    Iterable<Match> matcherOfUniversalEmoji = patternOfUniversalEmoji.allMatches(text);

    for (Match match in matcherOfUniversalEmoji) {
      String? emojiKey = match.group(0);
      if (text.isNotEmpty && emojiKey != null && emojiKey.isNotEmpty) {
        emojiKeyList.add(emojiKey);
      }
    }

    return emojiKeyList;
  }

  static String getRegexOfUniversalEmoji() {
    // Note: Dart uses \u{XXXX} syntax for Unicode code points, not \UXXXXXXXX like Java.
    // For code points > 0xFFFF, use \u{1XXXX} format.
    String ri = "[\\u{1F1E6}-\\u{1F1FF}]";

    // Standard emoji that can stand alone or with modifiers
    String support = "\\u{A9}|\\u{AE}|\\u203C|\\u2049|\\u2122|\\u2139|[\\u2194-\\u2199]|[\\u21A9-\\u21AA]"
        "|[\\u231A-\\u231B]|\\u2328|\\u23CF|[\\u23E9-\\u23EF]|[\\u23F0-\\u23F3]|[\\u23F8-\\u23FA]|\\u24C2"
        "|[\\u25AA-\\u25AB]|\\u25B6|\\u25C0|[\\u25FB-\\u25FE]|[\\u2600-\\u2604]|\\u260E|\\u2611|[\\u2614-\\u2615]"
        "|\\u2618|\\u261D|\\u2620|[\\u2622-\\u2623]|\\u2626|\\u262A|[\\u262E-\\u262F]|[\\u2638-\\u263A]|\\u2640"
        "|\\u2642|[\\u2648-\\u264F]|[\\u2650-\\u2653]|\\u265F|\\u2660|\\u2663|[\\u2665-\\u2666]|\\u2668|\\u267B"
        "|[\\u267E-\\u267F]|[\\u2692-\\u2697]|\\u2699|[\\u269B-\\u269C]|[\\u26A0-\\u26A1]|\\u26A7|[\\u26AA-\\u26AB]"
        "|[\\u26B0-\\u26B1]|[\\u26BD-\\u26BE]|[\\u26C4-\\u26C5]|\\u26C8|[\\u26CE-\\u26CF]|\\u26D1|[\\u26D3-\\u26D4]"
        "|[\\u26E9-\\u26EA]|[\\u26F0-\\u26F5]|[\\u26F7-\\u26FA]|\\u26FD|\\u2702|\\u2705|[\\u2708-\\u270D]|\\u270F|\\u2712"
        "|\\u2714|\\u2716|\\u271D|\\u2721|\\u2728|[\\u2733-\\u2734]|\\u2744|\\u2747|\\u274C|\\u274E|[\\u2753-\\u2755]"
        "|\\u2757|[\\u2763-\\u2764]|[\\u2795-\\u2797]|\\u27A1|\\u27B0|\\u27BF|[\\u2934-\\u2935]|[\\u2B05-\\u2B07]"
        "|[\\u2B1B-\\u2B1C]|\\u2B50|\\u2B55|\\u3030|\\u303D|\\u3297|\\u3299|\\u{1F004}|\\u{1F0CF}|[\\u{1F170}-\\u{1F171}]"
        "|[\\u{1F17E}-\\u{1F17F}]|\\u{1F18E}|[\\u{1F191}-\\u{1F19A}]|[\\u{1F1E6}-\\u{1F1FF}]|[\\u{1F201}-\\u{1F202}]"
        "|\\u{1F21A}|\\u{1F22F}|[\\u{1F232}-\\u{1F23A}]|[\\u{1F250}-\\u{1F251}]|[\\u{1F300}-\\u{1F30F}]"
        "|[\\u{1F310}-\\u{1F31F}]|[\\u{1F320}-\\u{1F321}]|[\\u{1F324}-\\u{1F32F}]|[\\u{1F330}-\\u{1F33F}]"
        "|[\\u{1F340}-\\u{1F34F}]|[\\u{1F350}-\\u{1F35F}]|[\\u{1F360}-\\u{1F36F}]|[\\u{1F370}-\\u{1F37F}]"
        "|[\\u{1F380}-\\u{1F38F}]|[\\u{1F390}-\\u{1F393}]|[\\u{1F396}-\\u{1F397}]|[\\u{1F399}-\\u{1F39B}]"
        "|[\\u{1F39E}-\\u{1F39F}]|[\\u{1F3A0}-\\u{1F3AF}]|[\\u{1F3B0}-\\u{1F3BF}]|[\\u{1F3C0}-\\u{1F3CF}]"
        "|[\\u{1F3D0}-\\u{1F3DF}]|[\\u{1F3E0}-\\u{1F3EF}]|\\u{1F3F0}|[\\u{1F3F3}-\\u{1F3F5}]|[\\u{1F3F7}-\\u{1F3FF}]"
        "|[\\u{1F400}-\\u{1F40F}]|[\\u{1F410}-\\u{1F41F}]|[\\u{1F420}-\\u{1F42F}]|[\\u{1F430}-\\u{1F43F}]"
        "|[\\u{1F440}-\\u{1F44F}]|[\\u{1F450}-\\u{1F45F}]|[\\u{1F460}-\\u{1F46F}]|[\\u{1F470}-\\u{1F47F}]"
        "|[\\u{1F480}-\\u{1F48F}]|[\\u{1F490}-\\u{1F49F}]|[\\u{1F4A0}-\\u{1F4AF}]|[\\u{1F4B0}-\\u{1F4BF}]"
        "|[\\u{1F4C0}-\\u{1F4CF}]|[\\u{1F4D0}-\\u{1F4DF}]|[\\u{1F4E0}-\\u{1F4EF}]|[\\u{1F4F0}-\\u{1F4FF}]"
        "|[\\u{1F500}-\\u{1F50F}]|[\\u{1F510}-\\u{1F51F}]|[\\u{1F520}-\\u{1F52F}]|[\\u{1F530}-\\u{1F53D}]"
        "|[\\u{1F549}-\\u{1F54E}]|[\\u{1F550}-\\u{1F55F}]|[\\u{1F560}-\\u{1F567}]|\\u{1F56F}|\\u{1F570}"
        "|[\\u{1F573}-\\u{1F57A}]|\\u{1F587}|[\\u{1F58A}-\\u{1F58D}]|\\u{1F590}|[\\u{1F595}-\\u{1F596}]"
        "|[\\u{1F5A4}-\\u{1F5A5}]|\\u{1F5A8}|[\\u{1F5B1}-\\u{1F5B2}]|\\u{1F5BC}|[\\u{1F5C2}-\\u{1F5C4}]"
        "|[\\u{1F5D1}-\\u{1F5D3}]|[\\u{1F5DC}-\\u{1F5DE}]|\\u{1F5E1}|\\u{1F5E3}|\\u{1F5E8}|\\u{1F5EF}|\\u{1F5F3}"
        "|[\\u{1F5FA}-\\u{1F5FF}]|[\\u{1F600}-\\u{1F60F}]|[\\u{1F610}-\\u{1F61F}]|[\\u{1F620}-\\u{1F62F}]"
        "|[\\u{1F630}-\\u{1F63F}]|[\\u{1F640}-\\u{1F64F}]|[\\u{1F650}-\\u{1F65F}]|[\\u{1F660}-\\u{1F66F}]"
        "|[\\u{1F670}-\\u{1F67F}]|[\\u{1F680}-\\u{1F68F}]|[\\u{1F690}-\\u{1F69F}]|[\\u{1F6A0}-\\u{1F6AF}]"
        "|[\\u{1F6B0}-\\u{1F6BF}]|[\\u{1F6C0}-\\u{1F6C5}]|[\\u{1F6CB}-\\u{1F6CF}]|[\\u{1F6D0}-\\u{1F6D2}]"
        "|[\\u{1F6D5}-\\u{1F6D7}]|[\\u{1F6DD}-\\u{1F6DF}]|[\\u{1F6E0}-\\u{1F6E5}]|\\u{1F6E9}|[\\u{1F6EB}-\\u{1F6EC}]"
        "|\\u{1F6F0}|[\\u{1F6F3}-\\u{1F6FC}]|[\\u{1F7E0}-\\u{1F7EB}]|\\u{1F7F0}|[\\u{1F90C}-\\u{1F90F}]"
        "|[\\u{1F910}-\\u{1F91F}]|[\\u{1F920}-\\u{1F92F}]|[\\u{1F930}-\\u{1F93A}]|[\\u{1F93C}-\\u{1F93F}]"
        "|[\\u{1F940}-\\u{1F945}]|[\\u{1F947}-\\u{1F94C}]|[\\u{1F94D}-\\u{1F94F}]|[\\u{1F950}-\\u{1F95F}]"
        "|[\\u{1F960}-\\u{1F96F}]|[\\u{1F970}-\\u{1F97F}]|[\\u{1F980}-\\u{1F98F}]|[\\u{1F990}-\\u{1F99F}]"
        "|[\\u{1F9A0}-\\u{1F9AF}]|[\\u{1F9B0}-\\u{1F9BF}]|[\\u{1F9C0}-\\u{1F9CF}]|[\\u{1F9D0}-\\u{1F9DF}]"
        "|[\\u{1F9E0}-\\u{1F9EF}]|[\\u{1F9F0}-\\u{1F9FF}]|[\\u{1FA70}-\\u{1FA74}]|[\\u{1FA78}-\\u{1FA7C}]"
        "|[\\u{1FA80}-\\u{1FA86}]|[\\u{1FA90}-\\u{1FA9F}]|[\\u{1FAA0}-\\u{1FAAC}]|[\\u{1FAB0}-\\u{1FABA}]"
        "|[\\u{1FAC0}-\\u{1FAC5}]|[\\u{1FAD0}-\\u{1FAD9}]|[\\u{1FAE0}-\\u{1FAE7}]|[\\u{1FAF0}-\\u{1FAF6}]";

    // Keycap base characters: #, *, 0-9
    // These ONLY form emoji when followed by \uFE0F\u20E3 (variation selector + keycap combining mark)
    // e.g., #️⃣ = # + \uFE0F + \u20E3
    String keycapBase = "[\\u0023\\u002A\\u0030-\\u0039]";

    // Construct regex of emoji by the rules above.
    String eMod = "[\\u{1F3FB}-\\u{1F3FF}]";

    String variationSelector = "\\uFE0F";
    String keycap = "\\u20E3";
    String tags = "[\\u{E0020}-\\u{E007E}]";
    String termTag = "\\u{E007F}";
    String zwj = "\\u200D";

    String risequence = "$ri$ri";

    // Keycap emoji: base character + optional variation selector + keycap combining mark
    String keycapEmoji = "$keycapBase$variationSelector?$keycap";

    // Standard emoji element with optional modifiers
    String element = "(?:$support)(?:$eMod|$variationSelector|$tags+$termTag?)?";

    // Full regex: keycap emoji | RI sequence | standard emoji (with ZWJ sequences)
    String regexEmoji = "$keycapEmoji|$risequence|$element(?:$zwj(?:$risequence|$element))*";

    return regexEmoji;
  }

  static RegExp? _universalEmojiRegex;

  static RegExp getUniversalEmojiRegex() {
    _universalEmojiRegex ??= RegExp(getRegexOfUniversalEmoji(), unicode: true);
    return _universalEmojiRegex!;
  }
}
