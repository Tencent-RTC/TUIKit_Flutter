import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';

class FriendApplicationList extends StatefulWidget {
  const FriendApplicationList({super.key});

  @override
  State<FriendApplicationList> createState() => _FriendApplicationListState();
}

class _FriendApplicationListState extends State<FriendApplicationList> {
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
    await contactListStore.fetchFriendApplicationList();
    await contactListStore.clearFriendApplicationUnreadCount();
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
          onClick: () => Navigator.pop(context),
        ),
        title: Text(
          atomicLocale.newFriend,
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
          if (store.contactListState.friendApplicationList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: colorsTheme.textColorSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    atomicLocale.noFriendApplicationList,
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
            itemCount: store.contactListState.friendApplicationList.length,
            itemBuilder: (context, index) {
              final application = store.contactListState.friendApplicationList[index];
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
    FriendApplicationInfo application,
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
                name: application.title ?? application.applicationID,
                url: application.avatarURL,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      application.title ?? application.applicationID,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorsTheme.textColorPrimary,
                      ),
                    ),
                    if (application.addWording != null && application.addWording!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        application.addWording!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorsTheme.textColorSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                text: atomicLocale.agree,
                backgroundColor: colorsTheme.buttonColorPrimaryDefault,
                textColor: colorsTheme.textColorButton,
                onPressed: () => _acceptFriendApplication(store, application),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                text: atomicLocale.refuse,
                backgroundColor: colorsTheme.buttonColorSecondaryDefault,
                textColor: colorsTheme.textColorPrimary,
                onPressed: () => _refuseFriendApplication(store, application),
              ),
            ],
          ),
        ],
      ),
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

  Future<void> _acceptFriendApplication(
    ContactListStore store,
    FriendApplicationInfo application,
  ) async {
    final result = await store.acceptFriendApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, '${result.errorMessage}');
      }
    }
  }

  Future<void> _refuseFriendApplication(
    ContactListStore store,
    FriendApplicationInfo application,
  ) async {
    final result = await store.refuseFriendApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, '${result.errorMessage}');
      }
    }
  }
}
