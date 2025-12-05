import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/utils/calling_message_data_provider.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../message_list.dart';

class MessageItem extends StatelessWidget {
  final MessageInfo message;
  final String conversationID;
  final bool isGroup;
  final double maxWidth;
  final MessageListStore? messageListStore;
  final bool isHighlighted;
  final VoidCallback? onHighlightComplete;
  final OnUserClick? onUserClick;
  final List<MessageCustomAction> customActions;
  final MessageListConfigProtocol config;

  const MessageItem({
    super.key,
    required this.message,
    required this.conversationID,
    this.isGroup = false,
    this.maxWidth = 200,
    this.messageListStore,
    required this.isHighlighted,
    this.onHighlightComplete,
    this.onUserClick,
    this.customActions = const [],
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelf = message.isSelf;
    String? avatarURL = message.rawMessage?.faceUrl;
    String senderName = ChatUtil.getMessageSenderName(message.rawMessage);
    CallingMessageDataProvider provider = CallingMessageDataProvider(message, context);
    
    if (provider.isCallingSignal && provider.participantType == CallParticipantType.c2c) {
      if (provider.content.isEmpty) {
        return Container();
      }

      isSelf = provider.direction == CallMessageDirection.outcoming;
      if (!isSelf) {
        return _buildWithConversationInfo(isSelf, avatarURL, senderName);
      }
    }

    Widget messageBubble = MessageBubble(
      message: message,
      conversationID: conversationID,
      isSelf: isSelf,
      maxWidth: maxWidth,
      config: config,
      messageListStore: messageListStore,
      isHighlighted: isHighlighted,
      onHighlightComplete: onHighlightComplete,
      customActions: customActions,
    );

    if (message.messageType == MessageType.system || MessageUtil.isSystemStyleCustomMessage(message, context)) {
      // Check if system messages should be shown
      if (!config.isShowSystemMessage) {
        return const SizedBox.shrink();
      }
      return messageBubble;
    }

    switch (config.alignment) {
      case AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED:
        return _buildTwoSidedLayout(messageBubble, isSelf, avatarURL, senderName);
      case AppBuilder.MESSAGE_ALIGNMENT_LEFT:
        return _buildLeftAlignedLayout(messageBubble, isSelf, avatarURL, senderName);
      case AppBuilder.MESSAGE_ALIGNMENT_RIGHT:
        return _buildRightAlignedLayout(messageBubble, isSelf, avatarURL, senderName);
      default:
        return _buildTwoSidedLayout(messageBubble, isSelf, avatarURL, senderName);
    }
  }

  Widget _buildWithConversationInfo(bool isSelf, String? defaultAvatarURL, String defaultSenderName) {
    return FutureBuilder<ConversationInfo?>(
      future: _fetchConversationInfo(),
      builder: (context, snapshot) {
        String? avatarURL = defaultAvatarURL;
        String senderName = defaultSenderName;
        
        if (snapshot.hasData && snapshot.data != null) {
          final conversationInfo = snapshot.data!;
          avatarURL = conversationInfo.avatarURL ?? defaultAvatarURL;
          senderName = conversationInfo.title ?? defaultSenderName;
        }
        
        return _buildMessageLayout(isSelf, avatarURL, senderName, context);
      },
    );
  }

  Future<ConversationInfo?> _fetchConversationInfo() async {
    try {
      ConversationListStore conversationListStore = ConversationListStore.create();
      final result = await conversationListStore.fetchConversationInfo(conversationID: conversationID);
      
      if (result.isSuccess) {
        final conversationList = conversationListStore.conversationListState.conversationList;
        return conversationList.firstWhere(
          (conv) => conv.conversationID == conversationID,
          orElse: () => ConversationInfo(conversationID: conversationID),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching conversation info: $e');
      return null;
    }
  }

  Widget _buildMessageLayout(bool isSelf, String? avatarUrl, String senderName, BuildContext context) {
    Widget messageBubble = MessageBubble(
      message: message,
      conversationID: conversationID,
      isSelf: isSelf,
      maxWidth: maxWidth,
      config: config,
      messageListStore: messageListStore,
      isHighlighted: isHighlighted,
      onHighlightComplete: onHighlightComplete,
      customActions: customActions,
    );

    if (message.messageType == MessageType.system || MessageUtil.isSystemStyleCustomMessage(message, context)) {
      // Check if system messages should be shown
      if (!config.isShowSystemMessage) {
        return const SizedBox.shrink();
      }
      return messageBubble;
    }

    switch (config.alignment) {
      case AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED:
        return _buildTwoSidedLayout(messageBubble, isSelf, avatarUrl, senderName);
      case AppBuilder.MESSAGE_ALIGNMENT_LEFT:
        return _buildLeftAlignedLayout(messageBubble, isSelf, avatarUrl, senderName);
      case AppBuilder.MESSAGE_ALIGNMENT_RIGHT:
        return _buildRightAlignedLayout(messageBubble, isSelf, avatarUrl, senderName);
      default:
        return _buildTwoSidedLayout(messageBubble, isSelf, avatarUrl, senderName);
    }
  }

  Widget _buildTwoSidedLayout(Widget messageBubble, bool isSelf, [String? avatarUrl, String? senderName]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isSelf ? _buildSelfMessage(messageBubble, avatarUrl, senderName) : _buildOtherMessage(messageBubble, avatarUrl, senderName),
      ),
    );
  }

  Widget _buildLeftAlignedLayout(Widget messageBubble, bool isSelf, [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.rawMessage?.faceUrl;
    final displaySenderName = senderName ?? message.sender ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.isShowLeftAvatar)
            GestureDetector(
              onTap: () {
                if (!isSelf && onUserClick != null) {
                  onUserClick!(message.sender ?? '');
                }
              },
              child: Avatar(
                content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
              ),
            ),
          if (config.isShowLeftAvatar) SizedBox(width: config.avatarSpacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.isShowLeftNickname && displaySenderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 8, bottom: 4),
                    child: Text(
                      '$displaySenderName:',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                messageBubble,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightAlignedLayout(Widget messageBubble, bool isSelf, [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.rawMessage?.faceUrl;
    final displaySenderName = senderName ?? message.sender ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (config.isShowRightNickname && displaySenderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 2, top: 8, bottom: 4),
                    child: Text(
                      '$displaySenderName:',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                messageBubble,
              ],
            ),
          ),
          if (config.isShowLeftAvatar) SizedBox(width: config.avatarSpacing),
          if (config.isShowLeftAvatar)
            GestureDetector(
              onTap: () {
                if (!isSelf && onUserClick != null) {
                  onUserClick!(message.sender ?? '');
                }
              },
              child: Avatar(
                content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSelfMessage(Widget messageBubble, [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.rawMessage?.faceUrl;
    final displaySenderName = senderName ?? message.sender ?? '';

    return [
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (config.isShowRightNickname && displaySenderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 2, top: 8, bottom: 4),
                child: Text(
                  '$displaySenderName:',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            messageBubble,
          ],
        ),
      ),
      if (config.isShowRightAvatar) SizedBox(width: config.avatarSpacing),
      if (config.isShowRightAvatar)
        Avatar(
          content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
        ),
    ];
  }

  List<Widget> _buildOtherMessage(Widget messageBubble, [String? avatarUrl, String? senderName]) {
    final displayAvatarUrl = avatarUrl ?? message.rawMessage?.faceUrl;
    final displaySenderName = senderName ?? message.sender ?? '';

    return [
      if (config.isShowLeftAvatar)
        GestureDetector(
          onTap: () {
            if (onUserClick != null) {
              onUserClick!(message.sender ?? '');
            }
          },
          child: Avatar(
            content: AvatarImageContent(url: displayAvatarUrl, name: displaySenderName),
          ),
        ),
      if (config.isShowLeftAvatar) SizedBox(width: config.avatarSpacing),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.isShowLeftNickname && displaySenderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 8, bottom: 4),
                child: Text(
                  '$displaySenderName:',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            messageBubble,
          ],
        ),
      ),
    ];
  }
}
