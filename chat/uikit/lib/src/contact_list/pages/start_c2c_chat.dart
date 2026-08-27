import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tencent_chat_uikit/src/widgets/az_ordered_list.dart';
import '../../common/language/gen/chat_localizations.dart';

class StartC2CChat extends StatefulWidget {
  final void Function(AZOrderedListItem user)? onSelect;

  const StartC2CChat({super.key, this.onSelect});

  @override
  State<StartC2CChat> createState() => _StartC2CChatState();
}

class _StartC2CChatState extends State<StartC2CChat> {
  final ContactStore _contactStore = ContactStore.shared;
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    chatLocale = ChatLocalizations.of(context);
  }

  Future<void> _loadData() async {
    await _contactStore.loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          chatLocale.startConversation,
          style: FontScheme.caption1Medium.copyWith(
            color: colorsTheme.textColorPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<ContactInfo>>(
        valueListenable: _contactStore.state.friendList,
        builder: (context, friendList, child) {
          final dataSource = friendList
              .map((contact) => AZOrderedListItem(
                    key: contact.userID,
                    label: (contact.nickname?.isNotEmpty == true ? contact.nickname! : contact.userID),
                    avatarURL: contact.avatarURL,
                    extraData: contact,
                  ))
              .toList();

          return AZOrderedList(
            dataSource: dataSource,
            config: AZOrderedListConfig(
              showIndexBar: true,
              emptyText: '',
              emptyIcon: Icon(
                Icons.people_outline,
                size: 80,
                color: colorsTheme.textColorSecondary,
              ),
              onItemClick: (item) {
                Navigator.pop(context);
                widget.onSelect?.call(item);
              },
            ),
          );
        },
      ),
    );
  }
}
