import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/contact_list/pages/start_c2c_chat.dart';
import 'package:tuikit_atomic_x/contact_list/pages/start_group_chat.dart';
import 'package:flutter/material.dart';

// import 'package:io_trtc_tuikit_atomicxcore/api/chat/search_store.dart';

import 'chat_page.dart';

const String startC2CChatMenuString = "startC2CChat";
const String startGroupChatMenuString = "startGroupChat";

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late AtomicLocalizations atomicLocale;
  late SemanticColorScheme colorsTheme;

  // bool _hideSearch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  void _startC2CChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartC2CChat(
          onSelect: (AZOrderedListItem item) {
            ContactInfo contactInfo = item.extraData;
            final conversation = ConversationInfo(
              conversationID: 'c2c_${contactInfo.contactID}',
              title: contactInfo.title,
              avatarURL: contactInfo.avatarURL,
              type: ConversationType.c2c,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  conversation: conversation,
                ),
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
                builder: (context) => ChatPage(
                  conversation: conversation,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        title: Text(atomicLocale.chat, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600)),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.create_outlined),
            offset: const Offset(0, 40),
            padding: EdgeInsets.zero,
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
                    const Icon(Icons.chat_outlined),
                    const SizedBox(width: 8),
                    Text(atomicLocale.startConversation),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: startGroupChatMenuString,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_add_outlined),
                    const SizedBox(width: 8),
                    Text(atomicLocale.createGroupChat),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ConversationList(
              onConversationClick: (conversation) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      conversation: conversation,
                    ),
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
