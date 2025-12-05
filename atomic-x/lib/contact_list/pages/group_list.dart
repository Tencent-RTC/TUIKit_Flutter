import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';

import '../contact_list.dart';

class GroupList extends StatefulWidget {
  final OnGroupClick? onGroupClick;

  const GroupList({
    super.key,
    this.onGroupClick,
  });

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
  }

  Future<void> _loadData() async {
    final contactListStore = Provider.of<ContactListStore>(context, listen: false);
    await contactListStore.fetchJoinedGroupList();
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
          atomicLocale.myGroups,
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
          final dataSource = store.contactListState.groupList
              .map((group) => AZOrderedListItem(
                    key: group.contactID,
                    label: group.title ?? group.contactID,
                    avatarURL: group.avatarURL,
                    extraData: group,
                  ))
              .toList();

          return AZOrderedList(
            dataSource: dataSource,
            config: AZOrderedListConfig(
              emptyText: atomicLocale.noGroupList,
              onItemClick: (item) {
                if (widget.onGroupClick != null) {
                  ContactInfo contactInfo = ContactInfo(
                    contactID: item.key,
                    type: ContactType.group,
                    title: item.label,
                    avatarURL: item.avatarURL,
                  );

                  widget.onGroupClick!(contactInfo);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
