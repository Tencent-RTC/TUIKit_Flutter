import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

import 'search_page.dart';
import '../common/language/gen/chat_localizations.dart';

typedef OnContactSelect = void Function(FriendSearchInfo friendSearchInfo);
typedef OnGroupSelect = void Function(GroupSearchInfo groupSearchInfo);
typedef OnConversationSelect = void Function(MessageSearchResultItem messageSearchResultItem);
typedef OnMessageSelect = void Function(MessageInfo messageInfo);

class SearchBar extends StatelessWidget {
  final OnContactSelect? onContactSelect;
  final OnGroupSelect? onGroupSelect;
  final OnConversationSelect? onConversationSelect;
  final OnMessageSelect? onMessageSelect;

  const SearchBar({
    super.key,
    this.onContactSelect,
    this.onGroupSelect,
    this.onConversationSelect,
    this.onMessageSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final chatLocale = ChatLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SearchPage(
                    onContactSelect: onContactSelect,
                    onGroupSelect: onGroupSelect,
                    onConversationSelect: onConversationSelect,
                    onMessageSelect: onMessageSelect,
                  )),
        );
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colorsTheme.bgColorInput,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'chat_assets/icon/search.svg',
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(colorsTheme.textColorTertiary, BlendMode.srcIn),
              package: 'tencent_chat_uikit',
            ),
            const SizedBox(width: 4),
            Text(
              chatLocale.search,
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
