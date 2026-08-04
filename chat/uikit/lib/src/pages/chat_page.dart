import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:tuikit_atomic_x/base_component/utils/tui_event_bus.dart';
import 'package:tencent_chat_uikit/src/contact_list/pages/add_friend.dart';
import 'package:tencent_chat_uikit/src/message_list/listen/listen_playback_bar.dart';
import 'package:flutter/material.dart' hide IconButton;

class ChatSettingPage extends StatelessWidget {
  final ConversationInfo conversation;
  final ConversationInfo conversationOfChatPage;
  final VoidCallback? onDestroyCallback;

  const ChatSettingPage({
    super.key,
    required this.conversation,
    required this.conversationOfChatPage,
    this.onDestroyCallback,
  });

  void _onSendMessageClick({required BuildContext context, String? userID, String? groupID}) async {
    ConversationListStore conversationListStore = ConversationListStore.create();
    ConversationInfo conversation;
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
      if (conversationOfChatPage.conversationID == conversation.conversationID) {
        Navigator.of(context).pop();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversation: conversation,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (conversation.type == ConversationType.c2c) {
      String userID = conversation.conversationID;
      if (userID.startsWith('c2c_')) {
        userID = userID.substring(4);
      }

      return C2CChatSetting(
        userID: userID,
        onContactDelete: onDestroyCallback,
        onSendMessageClick: ({String? userID, String? groupID}) {
          _onSendMessageClick(context: context, userID: userID);
        },
      );
    } else if (conversation.type == ConversationType.group) {
      String groupID = conversation.conversationID;
      if (groupID.startsWith('group_')) {
        groupID = groupID.substring(6);
      }

      return GroupChatSetting(
        groupID: groupID,
        onGroupDelete: onDestroyCallback,
        onSendMessageClick: ({String? userID, String? groupID}) {
          _onSendMessageClick(context: context, userID: userID, groupID: groupID);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Container(),
    );
  }
}

class ChatPage extends StatefulWidget {
  final ConversationInfo conversation;
  final MessageInfo? message;
  final ChatMessageInputConfig messageInputConfig;
  final ChatMessageListConfig messageListConfig;
  final bool isShowAppBarActions;

  const ChatPage({
    super.key,
    required this.conversation,
    this.message,
    this.messageInputConfig = const ChatMessageInputConfig(
      isShowAudioCall: true,
      isShowVideoCall: true,
    ),
    this.messageListConfig = const ChatMessageListConfig(),
    this.isShowAppBarActions = true,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  // Multi-select mode state
  MultiSelectState? _multiSelectState;

  // MessageInput key for @ mention feature
  final GlobalKey<MessageInputState> _messageInputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);
  }

  void _onDestroyCallback() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onChatSettingsTap() async {
    String userID = ChatUtil.getUserID(widget.conversation.conversationID);
    ContactInfo? contactInfo;
    if (userID.isNotEmpty) {
      final contactStore = ContactStore.shared;
      final result = await contactStore.getContactInfo(userIDList: [userID]);
      if (result.isSuccess && result.contactInfoList.isNotEmpty) {
        contactInfo = result.contactInfoList.first;
      }
    }

    if (!mounted) {
      return;
    }

    if (contactInfo != null && contactInfo.isFriend == false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddFriend(contactInfo: contactInfo),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ChatSettingPage(
            conversation: widget.conversation,
            conversationOfChatPage: widget.conversation,
            onDestroyCallback: _onDestroyCallback,
          ),
        ),
      );
    }
  }

  void _onUserClick(String userID) async {
    final contactStore = ContactStore.shared;
    final result = await contactStore.getContactInfo(userIDList: [userID]);
    ContactInfo? contactInfo = result.isSuccess && result.contactInfoList.isNotEmpty
        ? result.contactInfoList.first
        : null;
    if (contactInfo != null && contactInfo.isFriend == false && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddFriend(contactInfo: contactInfo),
        ),
      );
      return;
    }

    ConversationListStore conversationListStore = ConversationListStore.create();
    String conversationID = '$c2cConversationIDPrefix$userID';
    final convResult = await conversationListStore.getConversationInfo(conversationID: conversationID);
    ConversationInfo conversation = convResult.conversationInfo ?? ConversationInfo(
                  conversationID: conversationID,
                  title: userID,
                  type: ConversationType.c2c,
                );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ChatSettingPage(
            conversation: conversation,
            conversationOfChatPage: widget.conversation,
            onDestroyCallback: _onDestroyCallback,
          ),
        ),
      );
    }
  }

  void _onCallMessageClick(String userID, bool isVideoCall) {
    PublishParams params = PublishParams();
    params.isSticky = false;
    params.data = {
      "participantIds": [userID],
      "mediaType": isVideoCall ? CallMediaType.video : CallMediaType.audio,
      "chatGroupId": null,
      "timeout": 30,
    };
    TUIEventBus.shared.publish("call.startCall", null, params);
    UIKitUtil.reportChatInvokeCall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: colorsTheme.bgColorOperate,
          titleSpacing: 4.0,
          centerTitle: true,
          title: Text(
            widget.conversation.title ?? atomicLocale.chat,
            style: FontScheme.caption2Medium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          scrolledUnderElevation: 0.0,
          leading: IconButton.buttonContent(
            content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
            type: ButtonType.noBorder,
            size: ButtonSize.l,
            onClick: () => Navigator.of(context).pop(),
          ),
          actions: widget.isShowAppBarActions
              ? [
                  IconButton.buttonContent(
                    content: IconOnlyContent(
                      Icon(Icons.more_horiz, color: colorsTheme.buttonColorPrimaryDefault),
                    ),
                    type: ButtonType.noBorder,
                    size: ButtonSize.l,
                    onClick: _onChatSettingsTap,
                  ),
                ]
              : null),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              _messageInputKey.currentState?.collapseAllPanels();
            },
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                MessageList(
                  conversationID: widget.conversation.conversationID,
                  config: widget.messageListConfig,
                  locateMessage: widget.message,
                  onUserClick: (String userID) => _onUserClick(userID),
                  onUserLongPress: (String userID, String displayName) {
                    _messageInputKey.currentState?.insertMention(
                      userID: userID,
                      displayName: displayName,
                    );
                  },
                  onCallMessageClick: _onCallMessageClick,
                  onQuoteMessage: (MessageInfo message) {
                    _messageInputKey.currentState?.setQuotedMessage(message);
                  },
                  onMultiSelectStateChanged: (state) {
                    setState(() {
                      _multiSelectState = state;
                    });
                  },
                  groupAtInfoList: widget.conversation.groupAtInfoList,
                  initialUnreadCount: widget.conversation.unreadCount,
                ),
                if (_multiSelectState != null && _multiSelectState!.isActive)
                  MultiSelectBottomBar(
                    selectedCount: _multiSelectState!.selectedCount,
                    onCancel: _multiSelectState!.onCancel,
                    onDelete: _multiSelectState!.onDelete,
                    onForward: () => _multiSelectState!.onForward(context),
                  )
                else
                  MessageInput(
                    key: _messageInputKey,
                    conversationID: widget.conversation.conversationID,
                    config: widget.messageInputConfig,
                  ),
              ],
            ),
          ),
          // Floating "listen from here" status bar — hovers mid-right over the
          // message list (only visible while listening). Fills the area so the
          // expanded state can show a full-screen tap-to-collapse barrier;
          // collapsed/inactive states don't intercept taps on the chat.
          const Positioned.fill(child: ListenPlaybackBar()),
        ],
      ),
    );
  }
}
