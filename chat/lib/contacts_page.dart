import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/contact_list/pages/add_friend.dart';
import 'package:tuikit_atomic_x/contact_list/pages/add_group.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

const String addFriendMenuString = "addFriend";
const String addGroupMenuString = "addGroup";

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  void _onSendMessageClick(BuildContext context, {String? userID, String? groupID}) async {
    ConversationInfo conversation;
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

  void _onGroupClick(BuildContext context, ContactInfo contactInfo) {
    ConversationInfo conversationInfo = ConversationInfo(
      conversationID: 'group_${contactInfo.contactID}',
      type: ConversationType.group,
      avatarURL: contactInfo.avatarURL,
      title: contactInfo.title,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: conversationInfo,
        ),
      ),
    );
  }

  void _onContactClick(BuildContext context, ContactInfo contactInfo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => C2CChatSetting(
          userID: contactInfo.contactID,
          onSendMessageClick: ({String? userID, String? groupID}) {
            _onSendMessageClick(context, userID: userID);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AtomicLocalizations atomicLocale = AtomicLocalizations.of(context);
    SemanticColorScheme colorsScheme = BaseThemeProvider.colorsOf(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorsScheme.bgColorOperate,
        title: Text(atomicLocale.contact, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600),),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.black),
            offset: const Offset(0, 40),
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
                    const Icon(Icons.person_add),
                    const SizedBox(width: 8),
                    Text(atomicLocale.addFriend),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                padding: EdgeInsets.zero,
                value: addGroupMenuString,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_add),
                    const SizedBox(width: 8),
                    Text(atomicLocale.addGroup),
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
