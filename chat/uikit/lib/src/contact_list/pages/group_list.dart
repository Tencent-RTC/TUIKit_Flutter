import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/api/group/group_store.dart' as group_api;
import 'package:flutter/material.dart' hide IconButton;

import '../contact_list.dart';
import 'package:tencent_chat_uikit/src/widgets/az_ordered_list.dart';
import '../../common/language/gen/chat_localizations.dart';

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
  final group_api.GroupStore _groupStore = group_api.GroupStore.shared;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
  }

  Future<void> _loadData() async {
    await _groupStore.loadJoinedGroups();
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

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
          chatLocale.myGroups,
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
      body: ValueListenableBuilder<List<group_api.GroupInfo>>(
        valueListenable: _groupStore.state.joinedGroupList,
        builder: (context, groupList, child) {
          final dataSource = groupList
              .map((group) => AZOrderedListItem(
                    key: group.groupID,
                    label: (group.groupName?.isNotEmpty == true ? group.groupName! : group.groupID),
                    avatarURL: group.avatarURL,
                    extraData: group,
                  ))
              .toList();

          return AZOrderedList(
            dataSource: dataSource,
            config: AZOrderedListConfig(
              emptyText: chatLocale.noGroupList,
              onItemClick: (item) {
                if (widget.onGroupClick != null) {
                  // Convert GroupInfo back to ContactInfo for backward compatibility with OnGroupClick callback
                  ContactInfo contactInfo = ContactInfo(
                    userID: item.key,
                    nickname: item.label,
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
