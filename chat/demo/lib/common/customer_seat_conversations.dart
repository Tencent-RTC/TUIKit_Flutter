import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

/// 用户和人工客服坐席的 C2C 会话，坐席 userID 固定以 [userIDPrefix] 开头，不在消息列表里展示。
class CustomerSeatConversations {
  CustomerSeatConversations._();

  static const String userIDPrefix = '@customer_seat#';
  static const String _conversationIDPrefix = 'c2c_$userIDPrefix';

  static bool isCustomerSeat(ConversationInfo conversation) =>
      conversation.conversationID.startsWith(_conversationIDPrefix);
}
