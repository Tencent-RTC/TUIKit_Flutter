import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';

import '../contact_list.dart';

class Blacklist extends StatefulWidget {
  final OnContactClick? onContactClick;

  const Blacklist({
    super.key,
    this.onContactClick,
  });

  @override
  State<Blacklist> createState() => _BlacklistState();
}

class _BlacklistState extends State<Blacklist> {
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);
  }

  Future<void> _loadData() async {
    final contactListStore = Provider.of<ContactListStore>(context, listen: false);
    await contactListStore.fetchBlackList();
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Scaffold(
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
          atomicLocale.blackList,
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
      body: Consumer<ContactListStore>(
        builder: (context, store, child) {
          final dataSource = store.contactListState.blackList
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
              emptyText: atomicLocale.noBlackList,
              onItemClick: (item) {
                if (widget.onContactClick != null) {
                  ContactInfo contactInfo = ContactInfo(
                    contactID: item.key,
                    type: ContactType.user,
                    title: item.label,
                    avatarURL: item.avatarURL,
                  );

                  widget.onContactClick!(contactInfo);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
