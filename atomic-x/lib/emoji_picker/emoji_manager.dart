import 'dart:core';

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:flutter/widgets.dart';

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

  static List<String> findEmojiKeyListFromText(String text) {
    if (text == null || text.isEmpty) {
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
    String regexOfUniversalEmoji = getRegexOfUniversalEmoji();
    Pattern patternOfUniversalEmoji = RegExp(regexOfUniversalEmoji);
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
    String ri = "[\\U0001F1E6-\\U0001F1FF]";
    // \u0023(#), \u002A(*), \u0030(keycap 0), \u0039(keycap 9), \u00A9(©), \u00AE(®) couldn't be added to NSString directly, need to transform a little bit.
    String support =
        "\\U000000A9|\\U000000AE|\\u203C|\\u2049|\\u2122|\\u2139|[\\u2194-\\u2199]|[\\u21A9-\\u21AA]|[\\u21B0-\\u21B1]|\\u21C4|\\u21C5|\\u21C8|[\\u21CD-\\u21CF]|\\u21D1|[\\u21D3-\\u21D4]|[\\u21E9-\\u21EA]|[\\u21F0-\\u21F5]|[\\u21F7-\\u21FA]|\\u21FD|\\u2702|\\u2705|[\\u2708-\\u270D]|\\u270F|\\u2712|\\u2714|\\u2716|\\u271D|\\u2721|\\u2728|[\\u2733-\\u2734]|\\u2744|\\u2747|\\u274C|\\u274E|[\\u2753-\\u2755]|\\u2757|[\\u2763-\\u2764]|[\\u2795-\\u2797]|\\u27A1|\\u27B0|\\u27BF|[\\u2934-\\u2935]|[\\u2B05-\\u2B07]|[\\u2B1B-\\u2B1C]|\\u2B50|\\u2B55|\\u3030|\\u303D|\\u3297|\\u3299|\\U0001F004|\\U0001F0CF|[\\U0001F170-\\U0001F171]|[\\U0001F17E-\\U0001F17F]|\\U0001F18E|[\\U0001F191-\\U0001F19A]|[\\U0001F1E6-\\U0001F1FF]|[\\U0001F201-\\U0001F202]|\\U0001F21A|\\U0001F22F|[\\U0001F232-\\U0001F23A]|[\\U0001F250-\\U0001F251]|[\\U0001F300-\\U0001F30F]|[\\U0001F310-\\U0001F31F]|[\\U0001F320-\\U0001F321]|[\\U0001F324-\\U0001F32F]|[\\U0001F330-\\U0001F33F]|[\\U0001F340-\\U0001F34F]|[\\U0001F350-\\U0001F35F]|[\\U0001F360-\\U0001F36F]|[\\U0001F370-\\U0001F37F]|[\\U0001F380-\\U0001F38F]|[\\U0001F390-\\U0001F393]|[\\U0001F396-\\U0001F397]|[\\U0001F399-\\U0001F39B]|[\\U0001F39E-\\U0001F39F]|[\\U0001F3A0-\\U0001F3AF]|[\\U0001F3B0-\\U0001F3BF]|[\\U0001F3C0-\\U0001F3CF]|[\\U0001F3D0-\\U0001F3DF]|[\\U0001F3E0-\\U0001F3EF]|\\U0001F3F0|[\\U0001F3F3-\\U0001F3F5]|[\\U0001F3F7-\\U0001F3FF]|[\\U0001F400-\\U0001F40F]|[\\U0001F410-\\U0001F41F]|[\\U0001F420-\\U0001F42F]|[\\U0001F430-\\U0001F43F]|[\\U0001F440-\\U0001F44F]|[\\U0001F450-\\U0001F45F]|[\\U0001F460-\\U0001F46F]|[\\U0001F470-\\U0001F47F]|[\\U0001F480-\\U0001F48F]|[\\U0001F490-\\U0001F49F]|[\\U0001F4A0-\\U0001F4AF]|[\\U0001F4B0-\\U0001F4BF]|[\\U0001F4C0-\\U0001F4CF]|[\\U0001F4D0-\\U0001F4DF]|[\\U0001F4E0-\\U0001F4EF]|[\\U0001F4F0-\\U0001F4FF]|[\\U0001F500-\\U0001F50F]|[\\U0001F510-\\U0001F51F]|[\\U0001F520-\\U0001F52F]|[\\U0001F530-\\U0001F53D]|[\\U0001F549-\\U0001F54E]|[\\U0001F550-\\U0001F55F]|[\\U0001F560-\\U0001F567]|\\U0001F56F|\\U0001F570|[\\U0001F573-\\U0001F57A]|\\U0001F587|[\\U0001F58A-\\U0001F58D]|\\U0001F590|[\\U0001F595-\\U0001F596]|[\\U0001F5A4-\\U0001F5A5]|\\U0001F5A8|[\\U0001F5B1-\\U0001F5B2]|\\U0001F5BC|[\\U0001F5C2-\\U0001F5C4]|[\\U0001F5D1-\\U0001F5D3]|[\\U0001F5DC-\\U0001F5DE]|\\U0001F5E1|\\U0001F5E3|\\U0001F5E8|\\U0001F5EF|\\U0001F5F3|[\\U0001F5FA-\\U0001F5FF]|[\\U0001F600-\\U0001F60F]|[\\U0001F610-\\U0001F61F]|[\\U0001F620-\\U0001F62F]|[\\U0001F630-\\U0001F63F]|[\\U0001F640-\\U0001F64F]|[\\U0001F650-\\U0001F65F]|[\\U0001F660-\\U0001F66F]|[\\U0001F670-\\U0001F67F]|[\\U0001F680-\\U0001F68F]|[\\U0001F690-\\U0001F69F]|[\\U0001F6A0-\\U0001F6AF]|[\\U0001F6B0-\\U0001F6BF]|[\\U0001F6C0-\\U0001F6C5]|[\\U0001F6CB-\\U0001F6CF]|[\\U0001F6D0-\\U0001F6D2]|[\\U0001F6D5-\\U0001F6D7]|[\\U0001F6DD-\\U0001F6DF]|[\\U0001F6E0-\\U0001F6E5]|\\U0001F6E9|[\\U0001F6EB-\\U0001F6EC]|\\U0001F6F0|[\\U0001F6F3-\\U0001F6FC]|[\\U0001F7E0-\\U0001F7EB]|\\U0001F7F0|[\\U0001F90C-\\U0001F90F]|[\\U0001F910-\\U0001F91F]|[\\U0001F920-\\U0001F92F]|[\\U0001F930-\\U0001F93A]|[\\U0001F93C-\\U0001F93F]|[\\U0001F940-\\U0001F945]|[\\U0001F947-\\U0001F94C]|[\\U0001F94D-\\U0001F94F]|[\\U0001F950-\\U0001F95F]|[\\U0001F960-\\U0001F96F]|[\\U0001F970-\\U0001F97F]|[\\U0001F980-\\U0001F98F]|[\\U0001F990-\\U0001F99F]|[\\U0001F9A0-\\U0001F9AF]|[\\U0001F9B0-\\U0001F9BF]|[\\U0001F9C0-\\U0001F9CF]|[\\U0001F9D0-\\U0001F9DF]|[\\U0001F9E0-\\U0001F9EF]|[\\U0001F9F0-\\U0001F9FF]|[\\U0001FA70-\\U0001FA74]|[\\U0001FA78-\\U0001FA7C]|[\\U0001FA80-\\U0001FA86]|[\\U0001FA90-\\U0001FA9F]|[\\U0001FAA0-\\U0001FAAC]|[\\U0001FAB0-\\U0001FABA]|[\\U0001FAC0-\\U0001FAC5]|[\\U0001FAD0-\\U0001FAD9]|[\\U0001FAE0-\\U0001FAE7]|[\\U0001FAF0-\\U0001FAF6]";
    String unsupport = "\\u0023|\\u002A|[\\u0030-\\u0039]|";
    String emoji = unsupport + support;

    // Construct regex of emoji by the rules above.
    String eMod = "[\\U0001F3FB-\\U0001F3FF]";

    String variationSelector = "\\uFE0F";
    String keycap = "\\u20E3";
    String tags = "[\\U000E0020-\\U000E007E]";
    String termTag = "\\U000E007F";
    String zwj = "\\u200D";

    String risequence = "[$ri][$ri]";
    String element = "[$emoji]([$eMod]|$variationSelector$keycap?|[$tags]+$termTag?)?";
    String regexEmoji = "$risequence|$element($zwj($risequence|$element))*";

    return regexEmoji;
  }
}
