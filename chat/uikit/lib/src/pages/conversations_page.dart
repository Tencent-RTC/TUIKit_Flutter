import 'package:flutter/material.dart' hide SearchBar, IconButton;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';
import 'package:tencent_chat_uikit/src/contact_list/pages/start_c2c_chat.dart';
import 'package:tencent_chat_uikit/src/contact_list/pages/start_group_chat.dart';
import 'package:tencent_chat_uikit/src/search/search_bar.dart';

import 'chat_page.dart';
import '../common/language/gen/chat_localizations.dart';

const String startC2CChatMenuString = "startC2CChat";
const String startGroupChatMenuString = "startGroupChat";

class ConversationsPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  /// Forwarded to every [ChatPage] opened from this page, so a host can add
  /// more-panel actions no matter how the user reached the conversation.
  final ChatMessageInputConfig messageInputConfig;

  /// Forwarded to every [ChatPage] opened from this page, so a host can render
  /// custom messages no matter how the user reached the conversation.
  final ChatMessageListConfig messageListConfig;

  const ConversationsPage({
    super.key,
    this.onBackPressed,
    this.messageInputConfig = const ChatMessageInputConfig(
      isShowAudioCall: true,
      isShowVideoCall: true,
    ),
    this.messageListConfig = const ChatMessageListConfig(),
  });

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late ChatLocalizations chatLocale;
  late SemanticColorScheme colorsTheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  ChatPage _chatPage(ConversationInfo conversation, {MessageInfo? message}) {
    return ChatPage(
      conversation: conversation,
      message: message,
      messageInputConfig: widget.messageInputConfig,
      messageListConfig: widget.messageListConfig,
    );
  }

  void _startC2CChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartC2CChat(
          onSelect: (AZOrderedListItem item) {
            ContactInfo contactInfo = item.extraData;
            final conversation = ConversationInfo(
              conversationID: 'c2c_${contactInfo.userID}',
              title: contactInfo.nickname,
              avatarURL: contactInfo.avatarURL,
              type: ConversationType.c2c,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _chatPage(conversation),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startGroupChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartGroupChat(
          onGroupCreated: (String groupID, String groupName, String? avatar) {
            final conversation = ConversationInfo(
              conversationID: 'group_$groupID',
              title: groupName,
              avatarURL: avatar,
              type: ConversationType.group,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _chatPage(conversation),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSelectContact(FriendSearchInfo friendSearchInfo) {
    final displayName = friendSearchInfo.friendRemark?.isNotEmpty == true
        ? friendSearchInfo.friendRemark!
        : (friendSearchInfo.userInfo?.nickname?.isNotEmpty == true
            ? friendSearchInfo.userInfo!.nickname!
            : friendSearchInfo.userID);
    final conversation = ConversationInfo(
      conversationID: 'c2c_${friendSearchInfo.userID}',
      title: displayName,
      avatarURL: friendSearchInfo.userInfo?.avatarURL,
      type: ConversationType.c2c,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _chatPage(conversation),
      ),
    );
  }

  void _onSelectGroup(GroupSearchInfo groupSearchInfo) {
    final conversation = ConversationInfo(
      conversationID: 'group_${groupSearchInfo.groupID}',
      title: (groupSearchInfo.groupName?.isNotEmpty == true) ? groupSearchInfo.groupName! : groupSearchInfo.groupID,
      avatarURL: groupSearchInfo.groupAvatarURL,
      type: ConversationType.group,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _chatPage(conversation),
      ),
    );
  }

  void _onSelectConversation(MessageSearchResultItem messageSearchResultItem) {
    final conversation = ConversationInfo(
      conversationID: messageSearchResultItem.conversationID,
      title: messageSearchResultItem.conversationShowName,
      avatarURL: messageSearchResultItem.conversationAvatarURL,
      type: messageSearchResultItem.conversationID.startsWith('c2c_') ? ConversationType.c2c : ConversationType.group,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _chatPage(conversation),
      ),
    );
  }

  void _onSelectMessage(MessageInfo messageInfo) async {
    // Build conversationID from MessageInfo's conversationType and to
    final conversationID = messageInfo.conversationType == ConversationType.group
        ? 'group_${messageInfo.to}'
        : 'c2c_${messageInfo.to.isNotEmpty ? messageInfo.to : messageInfo.from.userID}';

    // Fetch conversation info from store
    ConversationListStore conversationListStore = ConversationListStore.create();
    final convResult = await conversationListStore.getConversationInfo(conversationID: conversationID);
    ConversationInfo conversation = convResult.conversationInfo ?? ConversationInfo(
                  conversationID: conversationID,
                  title: messageInfo.from.nickname ?? messageInfo.from.userID,
                  avatarURL: messageInfo.from.avatarURL,
                  type: conversationID.startsWith('c2c_') ? ConversationType.c2c : ConversationType.group,
                );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _chatPage(conversation, message: messageInfo),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorTopBar,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        automaticallyImplyLeading: false,
        leading: widget.onBackPressed != null
            ? IconButton.buttonContent(
                content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorPrimary)),
                type: ButtonType.noBorder,
                size: ButtonSize.l,
                onClick: widget.onBackPressed,
              )
            : null,
        title: Text(chatLocale.chat,
            style: FontScheme.body4Bold.copyWith(color: colorsTheme.textColorPrimary)),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: SvgPicture.asset(
              'chat_assets/icon/create_chat.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
              package: 'tencent_chat_uikit',
            ),
            offset: const Offset(0, 40),
            padding: EdgeInsets.zero,
            color: colorsTheme.bgColorDialog,
            onSelected: (String result) {
              switch (result) {
                case startC2CChatMenuString:
                  _startC2CChat();
                  break;
                case startGroupChatMenuString:
                  _startGroupChat();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: startC2CChatMenuString,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'chat_assets/icon/create_c2c_chat.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
                      package: 'tencent_chat_uikit',
                    ),
                    const SizedBox(width: 8),
                    Text(chatLocale.startConversation, style: FontScheme.caption1Regular.copyWith(color: colorsTheme.textColorPrimary)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: startGroupChatMenuString,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'chat_assets/icon/create_group_chat.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
                      package: 'tencent_chat_uikit',
                    ),
                    const SizedBox(width: 8),
                    Text(chatLocale.createGroupChat, style: FontScheme.caption1Regular.copyWith(color: colorsTheme.textColorPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!AppBuilder.getInstance().searchConfig.hideSearch)
            Container(
              color: colorsTheme.bgColorOperate,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SearchBar(
                onContactSelect: _onSelectContact,
                onGroupSelect: _onSelectGroup,
                onConversationSelect: _onSelectConversation,
                onMessageSelect: _onSelectMessage,
              ),
            ),
          Expanded(
            child: ConversationList(
              onConversationClick: (conversation) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _chatPage(conversation),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
