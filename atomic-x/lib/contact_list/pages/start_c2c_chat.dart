import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';

class StartC2CChat extends StatefulWidget {
  final void Function(AZOrderedListItem user)? onSelect;

  const StartC2CChat({super.key, this.onSelect});

  @override
  State<StartC2CChat> createState() => _StartC2CChatState();
}

class _StartC2CChatState extends State<StartC2CChat> {
  late ContactListStore _contactListStore;
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _contactListStore = ContactListStore.create();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);
  }

  @override
  void dispose() {
    _contactListStore.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _contactListStore.fetchFriendList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          atomicLocale.startConversation,
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
      body: ChangeNotifierProvider.value(
        value: _contactListStore,
        child: Consumer<ContactListStore>(
          builder: (context, store, child) {
            final dataSource = store.contactListState.friendList
                .map((contact) => AZOrderedListItem(
                      key: contact.contactID,
                      label: contact.title ?? contact.contactID,
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
      ),
    );
  }
}
