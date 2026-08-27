import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/api/group/group_store.dart';
import 'package:flutter/material.dart' hide IconButton;
import '../../common/language/gen/chat_localizations.dart';

class GroupApplicationList extends StatefulWidget {
  const GroupApplicationList({super.key});

  @override
  State<GroupApplicationList> createState() => _GroupApplicationListState();
}

class _GroupApplicationListState extends State<GroupApplicationList> {
  final GroupStore _groupStore = GroupStore.shared;
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
    await _groupStore.loadApplications();
    await _groupStore.clearApplicationUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        elevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.pop(context),
        ),
        title: Text(
          chatLocale.groupChatNotifications,
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
      body: ValueListenableBuilder<List<GroupApplicationInfo>>(
        valueListenable: _groupStore.state.applicationList,
        builder: (context, applicationList, child) {
          if (applicationList.isEmpty) {
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
                    chatLocale.noGroupApplicationList,
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
    GroupApplicationInfo application,
  ) {
    final joinContent = _getJoinGroupContent(application);
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
                      style: FontScheme.caption1Medium.copyWith(
                        color: colorsTheme.textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hide the join-content row entirely when there's no
                    // request message / invite info, otherwise an empty
                    // Text widget would still reserve a line of height,
                    // leaving an awkward gap between the nickname and the
                    // Group ID line.
                    if (joinContent.isNotEmpty) ...[
                      Text(
                        joinContent,
                        style: FontScheme.caption2Regular.copyWith(
                          color: colorsTheme.textColorSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      'Group ID: ${application.groupID}',
                      style: FontScheme.caption3Regular.copyWith(
                        color: colorsTheme.textColorTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButtons(application),
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
      final toUser = application.toUser;
      if (toUser == null || toUser.isEmpty) return '';
      return '${chatLocale.invite} $toUser';
    }
    // Use ?? to avoid the literal string "null" leaking into the UI when
    // requestMsg is missing.
    return application.requestMsg ?? '';
  }

  Widget _buildActionButtons(GroupApplicationInfo application) {
    if (application.handledStatus != GroupApplicationHandledStatus.unhandled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorsTheme.strokeColorPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          application.handledResult == GroupApplicationHandledResult.agreed
              ? chatLocale.accepted
              : chatLocale.refused,
          style: FontScheme.caption2Medium.copyWith(
            color: colorsTheme.textColorSecondary,
          ),
        ),
      );
    }

    return Row(
      children: [
        _buildActionButton(
          text: chatLocale.agree,
          backgroundColor: colorsTheme.buttonColorPrimaryDefault,
          textColor: colorsTheme.textColorButton,
          onPressed: () => _acceptGroupApplication(application),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          text: chatLocale.refuse,
          backgroundColor: colorsTheme.buttonColorSecondaryDefault,
          textColor: colorsTheme.textColorPrimary,
          onPressed: () => _refuseGroupApplication(application),
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
          style: FontScheme.caption2Medium.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptGroupApplication(GroupApplicationInfo application) async {
    final result = await _groupStore.acceptApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, chatLocale.groupApplicationAllReadyBeenProcessed);
      }
    }
  }

  Future<void> _refuseGroupApplication(GroupApplicationInfo application) async {
    final result = await _groupStore.refuseApplication(info: application);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, chatLocale.groupApplicationAllReadyBeenProcessed);
      }
    }
  }
}
