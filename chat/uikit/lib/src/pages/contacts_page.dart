import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';
import 'package:tencent_chat_uikit/src/contact_list/pages/add_friend.dart';
import 'package:tencent_chat_uikit/src/contact_list/pages/add_group.dart';

import 'chat_page.dart';
import '../common/language/gen/chat_localizations.dart';

const String addFriendMenuString = "addFriend";
const String addGroupMenuString = "addGroup";

class ContactsPage extends StatelessWidget {
  final VoidCallback? onBackPressed;

  /// Forwarded to every [ChatPage] opened from this page, so a host can add
  /// more-panel actions no matter how the user reached the conversation.
  final ChatMessageInputConfig messageInputConfig;

  /// Forwarded to every [ChatPage] opened from this page, so a host can render
  /// custom messages no matter how the user reached the conversation.
  final ChatMessageListConfig messageListConfig;

  const ContactsPage({
    super.key,
    this.onBackPressed,
    this.messageInputConfig = const ChatMessageInputConfig(
      isShowAudioCall: true,
      isShowVideoCall: true,
    ),
    this.messageListConfig = const ChatMessageListConfig(),
  });

  ChatPage _chatPage(ConversationInfo conversation) {
    return ChatPage(
      conversation: conversation,
      messageInputConfig: messageInputConfig,
      messageListConfig: messageListConfig,
    );
  }

  void _onSendMessageClick(BuildContext context, {String? userID, String? groupID}) async {
    ConversationInfo conversation;
    ConversationListStore conversationListStore = ConversationListStore.create();
    if (userID != null) {
      String conversationID = '$c2cConversationIDPrefix$userID';
      final convResult = await conversationListStore.getConversationInfo(conversationID: conversationID);
      conversation = convResult.conversationInfo ?? ConversationInfo(
                    conversationID: conversationID,
                    title: userID,
                    type: ConversationType.c2c,
                  );
    } else if (groupID != null) {
      String conversationID = '$groupConversationIDPrefix$groupID';
      final convResult = await conversationListStore.getConversationInfo(conversationID: conversationID);
      conversation = convResult.conversationInfo ?? ConversationInfo(
                    conversationID: conversationID,
                    title: groupID,
                    type: ConversationType.group,
                  );
    } else {
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _chatPage(conversation),
        ),
      );
    }
  }

  void _onGroupClick(BuildContext context, ContactInfo contactInfo) {
    ConversationInfo conversationInfo = ConversationInfo(
      conversationID: 'group_${contactInfo.userID}',
      type: ConversationType.group,
      avatarURL: contactInfo.avatarURL,
      title: contactInfo.nickname,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _chatPage(conversationInfo),
      ),
    );
  }

  void _onContactClick(BuildContext context, ContactInfo contactInfo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => C2CChatSetting(
          userID: contactInfo.userID,
          onSendMessageClick: ({String? userID, String? groupID}) {
            _onSendMessageClick(context, userID: userID);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ChatLocalizations chatLocale = ChatLocalizations.of(context);
    SemanticColorScheme colorsScheme = BaseThemeProvider.colorsOf(context);
    return Scaffold(
      backgroundColor: colorsScheme.bgColorInput,
      appBar: AppBar(
        backgroundColor: colorsScheme.bgColorOperate,
        automaticallyImplyLeading: false,
        leading: onBackPressed != null
            ? IconButton.buttonContent(
                content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsScheme.textColorPrimary)),
                type: ButtonType.noBorder,
                size: ButtonSize.l,
                onClick: onBackPressed,
              )
            : null,
        title: Text(chatLocale.contact,
            style: FontScheme.body4Bold.copyWith(color: colorsScheme.textColorPrimary)),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: SvgPicture.asset(
              'chat_assets/icon/create_chat.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(colorsScheme.textColorPrimary, BlendMode.srcIn),
              package: 'tencent_chat_uikit',
            ),
            offset: const Offset(0, 40),
            color: colorsScheme.bgColorDialog,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: addFriendMenuString,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'chat_assets/icon/create_c2c_chat.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(colorsScheme.textColorPrimary, BlendMode.srcIn),
                      package: 'tencent_chat_uikit',
                    ),
                    const SizedBox(width: 8),
                    Text(chatLocale.addFriend,
                        style: FontScheme.caption1Regular.copyWith(color: colorsScheme.textColorPrimary)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                padding: EdgeInsets.zero,
                value: addGroupMenuString,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'chat_assets/icon/create_group_chat.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(colorsScheme.textColorPrimary, BlendMode.srcIn),
                      package: 'tencent_chat_uikit',
                    ),
                    const SizedBox(width: 8),
                    Text(chatLocale.addGroup,
                        style: FontScheme.caption1Regular.copyWith(color: colorsScheme.textColorPrimary)),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case addFriendMenuString:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFriend(),
                    ),
                  );
                  break;
                case addGroupMenuString:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddGroup(),
                    ),
                  );
                  break;
              }
            },
          ),
        ],
      ),
      body: ContactList(
        onGroupClick: (ContactInfo contactInfo) {
          _onGroupClick(context, contactInfo);
        },
        onContactClick: (ContactInfo contactInfo) {
          _onContactClick(context, contactInfo);
        },
      ),
    );
  }
}
