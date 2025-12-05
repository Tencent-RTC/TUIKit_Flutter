import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';

class GroupApplicationList extends StatefulWidget {
  const GroupApplicationList({super.key});

  @override
  State<GroupApplicationList> createState() => _GroupApplicationListState();
}

class _GroupApplicationListState extends State<GroupApplicationList> {
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
    await contactListStore.fetchGroupApplicationList();
    await contactListStore.clearGroupApplicationUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        elevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.pop(context),
        ),
        title: Text(
          atomicLocale.groupChatNotifications,
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 18,
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
          if (store.contactListState.groupApplicationList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 80,
                    color: colorsTheme.textColorSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    atomicLocale.noGroupApplicationList,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorsTheme.textColorSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: store.contactListState.groupApplicationList.length,
            itemBuilder: (context, index) {
              final application = store.contactListState.groupApplicationList[index];
              return _buildApplicationTile(context, store, application);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationTile(
    BuildContext context,
    ContactListStore store,
    GroupApplicationInfo application,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorsTheme.strokeColorPrimary,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Avatar.image(
                name: _getDisplayUserName(application),
                url: application.fromUserAvatarURL,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getDisplayUserName(application),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorsTheme.textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getJoinGroupContent(application),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorsTheme.textColorSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Group ID: ${application.groupID}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorsTheme.textColorTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButtons(store, application),
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayUserName(GroupApplicationInfo application) {
    if (application.fromUserNickname != null && application.fromUserNickname!.isNotEmpty) {
      return application.fromUserNickname!;
    } else {
      return application.fromUser ?? '';
    }
  }

  String _getJoinGroupContent(GroupApplicationInfo application) {
    if (application.type == GroupApplicationType.inviteApprovedByAdmin) {
      return '${atomicLocale.invite} ${application.toUser}';
    } else {
      return '${application.requestMsg}';
    }
  }

  Widget _buildActionButtons(ContactListStore store, GroupApplicationInfo application) {
    if (application.handledStatus != GroupApplicationHandledStatus.unhandled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorsTheme.strokeColorPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          application.handledResult == GroupApplicationHandledResult.agreed
              ? atomicLocale.accepted
              : atomicLocale.refused,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorsTheme.textColorSecondary,
          ),
        ),
      );
    }

    return Row(
      children: [
        _buildActionButton(
          text: atomicLocale.agree,
          backgroundColor: colorsTheme.buttonColorPrimaryDefault,
          textColor: colorsTheme.textColorButton,
          onPressed: () => _acceptGroupApplication(store, application),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          text: atomicLocale.refuse,
          backgroundColor: colorsTheme.buttonColorSecondaryDefault,
          textColor: colorsTheme.textColorPrimary,
          onPressed: () => _refuseGroupApplication(store, application),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptGroupApplication(
    ContactListStore store,
    GroupApplicationInfo application,
  ) async {
    final result = await store.acceptGroupApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, atomicLocale.groupApplicationAllReadyBeenProcessed);
      }
    }
  }

  Future<void> _refuseGroupApplication(
    ContactListStore store,
    GroupApplicationInfo application,
  ) async {
    final result = await store.refuseGroupApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, atomicLocale.groupApplicationAllReadyBeenProcessed);
      }
    }
  }
}
