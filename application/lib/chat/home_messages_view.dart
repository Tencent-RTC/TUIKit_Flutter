import 'package:flutter/widgets.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' as chat;

class HomeMessagesView extends StatelessWidget {
  const HomeMessagesView({super.key});
  @override
  Widget build(BuildContext context) => const chat.ConversationsPage(
    messageInputConfig: chat.ChatMessageInputConfig(isShowAudioCall: false, isShowVideoCall: false),
  );
}
