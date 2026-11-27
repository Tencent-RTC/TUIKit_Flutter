import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' as chat;
import '../../common/app_strings.dart';
import 'mine_page_header.dart';

class LanguageSelectView extends StatelessWidget {
  const LanguageSelectView({super.key, required this.locale});
  final chat.LocaleProvider locale;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: MinePageHeader(title: AppStrings.of(context, 'changeLanguage')),
    body: ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        for (final entry in {'zh': '简体中文', 'en': 'English'}.entries)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await locale.changeLanguage(entry.key);
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 16))),
                    if (Localizations.localeOf(context).languageCode == entry.key)
                      Image.asset('assets/main_mine_choose.png', width: 20, height: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
