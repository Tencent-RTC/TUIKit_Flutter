import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import '../../common/language/gen/chat_localizations.dart';

class FriendApplicationList extends StatefulWidget {
  const FriendApplicationList({super.key});

  @override
  State<FriendApplicationList> createState() => _FriendApplicationListState();
}

class _FriendApplicationListState extends State<FriendApplicationList> {
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
    await _contactStore.loadFriendApplications();
    await _contactStore.clearFriendApplicationUnreadCount();
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
          onClick: () => Navigator.pop(context),
        ),
        title: Text(
          chatLocale.newFriend,
          style: FontScheme.body4Medium.copyWith(
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
      body: ValueListenableBuilder<List<FriendApplicationInfo>>(
        valueListenable: _contactStore.state.friendApplicationList,
        builder: (context, applicationList, child) {
          if (applicationList.isEmpty) {
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
                    chatLocale.noFriendApplicationList,
                    style: FontScheme.caption1Regular.copyWith(
                      color: colorsTheme.textColorSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: applicationList.length,
            itemBuilder: (context, index) {
              final application = applicationList[index];
              return _buildApplicationTile(context, application);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationTile(
    BuildContext context,
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
                name: application.title ?? application.userID,
                url: application.avatarURL,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      application.title ?? application.userID,
                      style: FontScheme.caption1Medium.copyWith(
                        color: colorsTheme.textColorPrimary,
                      ),
                    ),
                    if (application.addWording != null && application.addWording!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        application.addWording!,
                        style: FontScheme.caption2Regular.copyWith(
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
                text: chatLocale.agree,
                backgroundColor: colorsTheme.buttonColorPrimaryDefault,
                textColor: colorsTheme.textColorButton,
                onPressed: () => _acceptFriendApplication(application),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                text: chatLocale.refuse,
                backgroundColor: colorsTheme.buttonColorSecondaryDefault,
                textColor: colorsTheme.textColorPrimary,
                onPressed: () => _refuseFriendApplication(application),
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
          style: FontScheme.caption2Medium.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptFriendApplication(FriendApplicationInfo application) async {
    final result = await _contactStore.acceptFriendApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, '${result.errorMessage}');
      }
    }
  }

  Future<void> _refuseFriendApplication(FriendApplicationInfo application) async {
    final result = await _contactStore.refuseFriendApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, '${result.errorMessage}');
      }
    }
  }
}
