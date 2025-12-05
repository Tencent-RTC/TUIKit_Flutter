import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/base_component/utils/tui_event_bus.dart';
import 'package:tuikit_atomic_x/chat_setting/pages/group_member_picker.dart';
import 'package:tuikit_atomic_x/contact_list/pages/add_friend.dart';
import 'package:flutter/material.dart' hide IconButton;

class ChatSettingPage extends StatelessWidget {
  final ConversationInfo conversation;
  final VoidCallback? onDestroyCallback;
  final bool isFromChatPage;

  const ChatSettingPage({
    super.key,
    required this.conversation,
    this.onDestroyCallback,
    this.isFromChatPage = false,
  });

  void _onSendMessageClick({required BuildContext context, String? userID, String? groupID}) async {
    ConversationInfo conversation;
    if (isFromChatPage) {
      Navigator.of(context).pop();
    } else {
      ConversationListStore conversationListStore = ConversationListStore.create();
      if (userID != null) {
        String conversationID = '$c2cConversationIDPrefix$userID';
        await conversationListStore.fetchConversationInfo(conversationID: conversationID);
        conversation = conversationListStore.conversationListState.conversationList
            .firstWhere((item) => item.conversationID == conversationID,
                orElse: () => ConversationInfo(
                      conversationID: conversationID,
                      title: userID,
                      type: ConversationType.c2c,
                    ));
      } else if (groupID != null) {
        String conversationID = '$groupConversationIDPrefix$groupID';
        await conversationListStore.fetchConversationInfo(conversationID: conversationID);
        conversation = conversationListStore.conversationListState.conversationList
            .firstWhere((item) => item.conversationID == conversationID,
                orElse: () => ConversationInfo(
                      conversationID: conversationID,
                      title: groupID,
                      type: ConversationType.group,
                    ));
      } else {
        return;
      }

      if (context.mounted) {
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

  const ChatPage({
    super.key,
    required this.conversation,
    this.message,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

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

  void _onTitleTap() async {
    String userID = ChatUtil.getUserID(widget.conversation.conversationID);
    ContactInfo? contactInfo;
    if (userID.isNotEmpty) {
      ContactListStore contactListStore = ContactListStore.create();
      await contactListStore.fetchUserInfo(userID: userID);
      contactInfo = contactListStore.contactListState.addFriendInfo;
    }

    if (!mounted) {
      return;
    }

    if (contactInfo != null && contactInfo.isContact == false) {
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
            onDestroyCallback: _onDestroyCallback,
            isFromChatPage: true,
          ),
        ),
      );
    }
  }

  void _onUserClick(String userID) async {
    ContactListStore contactListStore = ContactListStore.create();
    await contactListStore.fetchUserInfo(userID: userID);
    ContactInfo? contactInfo = contactListStore.contactListState.addFriendInfo;
    if (contactInfo != null && contactInfo.isContact == false && mounted) {
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
    await conversationListStore.fetchConversationInfo(conversationID: conversationID);
    ConversationInfo conversation = conversationListStore.conversationListState.conversationList
        .firstWhere((item) => item.conversationID == conversationID,
            orElse: () => ConversationInfo(
                  conversationID: conversationID,
                  title: userID,
                  type: ConversationType.c2c,
                ));

    bool isFromChatPage = false;
    if (ChatUtil.getUserID(widget.conversation.conversationID) == userID) {
      isFromChatPage = true;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ChatSettingPage(
            conversation: conversation,
            onDestroyCallback: _onDestroyCallback,
            isFromChatPage: isFromChatPage,
          ),
        ),
      );
    }
  }

  void _onVoiceCallClick() async {
    List<String> participantIds = [];
    String? chatGroupId;
    if (widget.conversation.type == ConversationType.c2c) {
      String participantId = ChatUtil.getUserID(widget.conversation.conversationID);
      participantIds.add(participantId);
    } else {
      chatGroupId = ChatUtil.getGroupID(widget.conversation.conversationID);
      final selectedMembers = await Navigator.push<List<UserPickerData>>(
        context,
        MaterialPageRoute(
          builder: (context) => GroupMemberPicker(groupID: chatGroupId!),
        ),
      );

      if (selectedMembers != null && selectedMembers.isNotEmpty) {
        participantIds = selectedMembers.map((member) => member.key).toList();
      }
    }

    PublishParams params = PublishParams();
    params.isSticky = false;
    params.data = {
      "participantIds": participantIds,
      "mediaType": CallMediaType.audio,
      "chatGroupId": chatGroupId,
      "timeout": 30,};
    TUIEventBus.shared.publish("call.startCall", null, params);
  }

  void _onVideoCallClick() async {
    List<String> participantIds = [];
    String? chatGroupId;
    if (widget.conversation.type == ConversationType.c2c) {
      String participantId = ChatUtil.getUserID(widget.conversation.conversationID);
      participantIds.add(participantId);
    } else {
      chatGroupId = ChatUtil.getGroupID(widget.conversation.conversationID);
      final selectedMembers = await Navigator.push<List<UserPickerData>>(
        context,
        MaterialPageRoute(
          builder: (context) => GroupMemberPicker(groupID: chatGroupId!),
        ),
      );

      if (selectedMembers != null && selectedMembers.isNotEmpty) {
        participantIds = selectedMembers.map((member) => member.key).toList();
      }
    }
    PublishParams params = PublishParams();
    params.isSticky = false;
    params.data = {
      "participantIds": participantIds,
      "mediaType": CallMediaType.video,
      "chatGroupId": chatGroupId,
      "timeout": 30,};
    TUIEventBus.shared.publish("call.startCall", null, params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: colorsTheme.bgColorOperate,
          titleSpacing: 4.0,
          centerTitle: false,
          title: GestureDetector(
            onTap: _onTitleTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Avatar.image(
                    name: widget.conversation.title,
                    url: widget.conversation.avatarURL,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.conversation.title ?? atomicLocale.chat,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          scrolledUnderElevation: 0.0,
          leading: IconButton.buttonContent(
            content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
            type: ButtonType.noBorder,
            size: ButtonSize.l,
            onClick: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton.buttonContent(
              content: IconOnlyContent(Icon(Icons.call, color: colorsTheme.buttonColorPrimaryDefault)),
              type: ButtonType.noBorder,
              size: ButtonSize.l,
              onClick: _onVoiceCallClick,
            ),
            IconButton.buttonContent(
              content: IconOnlyContent(Icon(Icons.videocam, color: colorsTheme.buttonColorPrimaryDefault)),
              type: ButtonType.noBorder,
              size: ButtonSize.l,
              onClick: _onVideoCallClick,
            ),
          ]),
      body: Column(
        children: [
          MessageList(
            conversationID: widget.conversation.conversationID,
            locateMessage: widget.message,
            onUserClick: (String userID) => _onUserClick(userID),
          ),
          MessageInput(
            conversationID: widget.conversation.conversationID,
          ),
        ],
      ),
    );
  }
}
