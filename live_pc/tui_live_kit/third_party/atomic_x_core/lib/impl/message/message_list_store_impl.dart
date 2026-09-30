import 'dart:async';

import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/common/chat_util.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/common/notification_center.dart';
import 'package:atomic_x_core/impl/conversation/conversation_list_store_impl.dart';
import 'package:atomic_x_core/impl/message/message_action_store_impl.dart';
import 'package:atomic_x_core/impl/message/message_input_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/history_msg_get_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_download_progress.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_extension.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_reaction_change_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_reaction_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

const _mergedForwardMessageLimit = 300;
const _messageReactionUserCount = 10;

// LocalCustomData keys for message
class LocalCustomDataKey {
  static const String textTranslation = 'text_translation';
  static const String textTranslationLanguage = 'text_translation_language';
  static const String voiceToText = 'voice_to_text';
}

// Message event data classes
class MessageSendEventData {
  final String conversationID;
  final dynamic message;
  final int? progress;
  final int? code;
  final String? desc;

  MessageSendEventData({
    required this.conversationID,
    this.message,
    this.progress,
    this.code,
    this.desc,
  });
}

class MessageInsertEventData {
  final String conversationID;
  final MessageInfo message;

  MessageInsertEventData({
    required this.conversationID,
    required this.message,
  });
}

class MessageDeleteEventData {
  final List<String> messageIDList;

  MessageDeleteEventData({required this.messageIDList});
}

class MessageRevokeEventData {
  final String messageID;

  MessageRevokeEventData({required this.messageID});
}

class MessageEditEventData {
  final dynamic message;

  MessageEditEventData({this.message});
}

class MessagePinEventData {
  final String messageID;
  final String groupID;
  final bool isPinned;

  MessagePinEventData({
    required this.messageID,
    required this.groupID,
    required this.isPinned,
  });
}

class _MessageListenerHandle {
  V2TimAdvancedMsgListener? advancedMsgListener;
  List<StreamSubscription>? eventSubscriptions;
  StreamController<MessageEvent>? messageEventController;

  void addMessageListener(V2TimAdvancedMsgListener listener) {
    advancedMsgListener = listener;
    TencentImSDKPlugin.v2TIMManager.getMessageManager().addAdvancedMsgListener(listener: listener);
  }

  void removeMessageListener() {
    if (advancedMsgListener != null) {
      TencentImSDKPlugin.v2TIMManager.getMessageManager().removeAdvancedMsgListener(listener: advancedMsgListener!);
      advancedMsgListener = null;
    }
  }

  void removeNotificationListeners() {
    if (eventSubscriptions != null) {
      for (var subscription in eventSubscriptions!) {
        subscription.cancel();
      }
      eventSubscriptions = null;
    }
  }

  void closeMessageEventController() {
    messageEventController?.close();
    messageEventController = null;
  }
}

class _MessageStateImpl implements MessageListState {
  final ValueNotifier<List<MessageInfo>> messageListValue = ValueNotifier([]);
  final ValueNotifier<bool> hasOlderMessagesValue = ValueNotifier(false);
  final ValueNotifier<bool> hasNewerMessagesValue = ValueNotifier(false);
  final ValueNotifier<List<MessageInfo>> pinnedMessageListValue = ValueNotifier([]);

  @override
  ValueListenable<List<MessageInfo>> get messageList => messageListValue;

  @override
  ValueListenable<bool> get hasOlderMessages => hasOlderMessagesValue;

  @override
  ValueListenable<bool> get hasNewerMessages => hasNewerMessagesValue;

  @override
  ValueListenable<List<MessageInfo>> get pinnedMessageList => pinnedMessageListValue;
}

class MessageListStoreImpl extends MessageListStore {
  static final Finalizer<_MessageListenerHandle> _finalizer = Finalizer((handle) {
    handle.removeMessageListener();
    handle.removeNotificationListeners();
    handle.closeMessageEventController();
  });

  final _handle = _MessageListenerHandle();
  final _messageState = _MessageStateImpl();

  List<MessageInfo> _messageList = [];

  final String _conversationID;
  MessageLoadOption? _option;

  // Serial queue for new message processing to preserve order
  Future<void> _newMessageQueue = Future.value();

  // Message event stream controller
  final StreamController<MessageEvent> _messageEventController = StreamController<MessageEvent>.broadcast();

  MessageListStoreImpl({
    required String conversationID,
  }) : _conversationID = conversationID {
    _addMessageListener();
    _addNotificationListeners();
    _handle.messageEventController = _messageEventController;
    _finalizer.attach(this, _handle, detach: this);
  }

  @override
  Stream<MessageEvent> get messageEventStream => _messageEventController.stream;

  @override
  MessageListState get state => _messageState;



  late List<StreamSubscription> _eventSubscriptions;

  void _addNotificationListeners() {
    _eventSubscriptions = [
      notificationCenter.addListener<MessageSendEventData>(
          MessageSendNotifyKey.messageSendBegin, _handleMessageSendBegin),
      notificationCenter.addListener<MessageSendEventData>(
          MessageSendNotifyKey.messageSendSuccess, _handleMessageSendSuccess),
      notificationCenter.addListener<MessageSendEventData>(
          MessageSendNotifyKey.messageSendFailed, _handleMessageSendFailed),
      notificationCenter.addListener<MessageInsertEventData>(
          MessageInsertNotifyKey.messageInserted, _handleMessageInserted),
      notificationCenter.addListener<MessageDeleteEventData>(
          MessageActionNotifyKey.messageDelete, _handleMessageDeleteEvent),
      notificationCenter.addListener<MessageRevokeEventData>(
          MessageActionNotifyKey.messageRevoke, _handleMessageRevokeEvent),
      notificationCenter.addListener<MessageEditEventData>(MessageActionNotifyKey.messageEdit, _handleMessageEditEvent),
      notificationCenter.addListener<MessagePinEventData>(MessageActionNotifyKey.messagePin, _handleMessagePinEvent),
      notificationCenter.addListener<MessageListClearEventData>(
          ConversationNotificationNames.clearChatHistoryMessage, _handleMessageListClear),
      notificationCenter.addListener<MessageTranslateEventData>(
          MessageActionNotifyKey.messageTranslate, _handleTranslateMessage),
      notificationCenter.addListener<VoiceConvertToTextEventData>(
          MessageActionNotifyKey.voiceConvertToText, _handleVoiceConvertToText),
      notificationCenter.addListener<MessageMediaDownloadEventData>(
          MessageActionNotifyKey.messageMediaDownload, _handleMessageMediaDownload),
    ];
    _handle.eventSubscriptions = _eventSubscriptions;
  }


  @override
  Future<CompletionHandler> loadMessages({MessageLoadOption? option}) async {
    return _loadMessagesInternal(option);
  }

  @override
  Future<CompletionHandler> loadOlderMessages() async {
    return _loadMoreMessagesInternal(MessageLoadDirection.older);
  }

  @override
  Future<CompletionHandler> loadNewerMessages() async {
    return _loadMoreMessagesInternal(MessageLoadDirection.newer);
  }

  @override
  Future<CompletionHandler> sendMessageReadReceipts({required List<MessageInfo> messageList}) async {
    return _sendMessageReadReceiptsInternal(messageList);
  }

  @override
  Future<CompletionHandler> deleteMessages({required List<MessageInfo> messageList}) async {
    return _deleteMessagesInternal(messageList);
  }

  @override
  Future<CompletionHandler> forwardMessages({
    required List<MessageInfo> messageList,
    required ForwardMessageOption option,
    required String conversationID,
  }) async {
    return _forwardMessagesInternal(messageList, option, conversationID);
  }

  void _addMessageListener() {
    final advancedMsgListener = V2TimAdvancedMsgListener(
      onRecvNewMessage: _onRecvNewMessage,
      onRecvMessageReadReceipts: _onRecvMessageReadReceipts,
      onRecvMessageRevokedWithInfo: _onRecvMessageRevoked,
      onRecvMessageModified: _onRecvMessageModified,
      onRecvMessageReactionsChanged: _onRecvMessageReactionsChanged,
      onRecvMessageExtensionsChanged: _onRecvMessageExtensionsChanged,
      onRecvMessageExtensionsDeleted: _onRecvMessageExtensionsDeleted,
      onGroupMessagePinned: _onGroupMessagePinned,
      onSendMessageProgress: _onSendMessageProgress,
      onMessageDownloadProgressCallback: _onMessageDownloadProgress,
    );

    _handle.addMessageListener(advancedMsgListener);
  }

  void _handleNewMessages(List<MessageInfo> messages) {
    final messagesNeedReceipt = messages.where((msg) => msg.needReadReceipt && msg.rawMessage != null).toList();
    final messagesNeedExtension = messages.where((msg) => msg.isExtensionEnabled && msg.rawMessage != null).toList();
    final messagesNeedReaction = messages.where((msg) => msg.rawMessage != null).toList();

    if (messagesNeedReceipt.isNotEmpty) {
      _fetchMessageReadReceiptsInternal(messagesNeedReceipt);
    }
    if (messagesNeedExtension.isNotEmpty) {
      _fetchMessageExtensionsInternal(messagesNeedExtension);
    }
    if (messagesNeedReaction.isNotEmpty) {
      _fetchMessageReactionsInternal(messagesNeedReaction);
    }
  }

  Future<void> _fetchMessageReadReceiptsInternal(List<MessageInfo> messageList) async {
    final v2Messages = messageList.map((msg) => msg.rawMessage!).toList();
    if (v2Messages.isEmpty) return;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getMessageReadReceipts(
          messageList: v2Messages,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      for (final receipt in result.data!) {
        if (receipt.msgID == null) continue;

        final index = _messageList.indexWhere((msg) => msg.msgID == receipt.msgID);
        if (index != -1) {
          _messageList[index].readReceiptInfo = ChatUtil.convertToMessageReceipt(receipt);
        }
      }
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  Future<void> _fetchMessageExtensionsInternal(List<MessageInfo> messageList) async {
    for (final message in messageList) {
      if (message.rawMessage == null) continue;

      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getMessageExtensions(
            message: message.rawMessage,
          );

      if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
        final index = _messageList.indexWhere((msg) => msg.msgID == message.msgID);
        if (index != -1) {
          _messageList[index].extensionList = ChatUtil.convertToMessageExtensions(result.data);
          _messageState.messageListValue.value = List.unmodifiable(_messageList);
        }
      }
    }
  }

  Future<void> _fetchMessageReactionsInternal(List<MessageInfo> messageList) async {
    final v2Messages = messageList.map((msg) => msg.rawMessage!).toList();
    if (v2Messages.isEmpty) return;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getMessageReactions(
          messageList: v2Messages,
          maxUserCountPerReaction: _messageReactionUserCount,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value || result.data == null) {
      debugPrint("Failed to get message reactions: code=${result.code}, desc=${result.desc}");
      return;
    }

    final reactionMap = <String, List<MessageReaction>>{};
    for (final V2TimMessageReactionResult reactionResult in result.data!) {
      if (reactionResult.resultCode != TIMErrCode.ERR_SUCC.value) continue;
      reactionMap[reactionResult.messageID] =
          ChatUtil.convertToMessageReactions(reactionResult.reactionList);
    }
    if (reactionMap.isEmpty) return;

    bool hasUpdate = false;
    for (int i = 0; i < _messageList.length; i++) {
      final reactions = reactionMap[_messageList[i].msgID];
      if (reactions != null) {
        _messageList[i].reactionList = reactions;
        hasUpdate = true;
      }
    }
    if (hasUpdate) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  // ======== Quote Info Completion ========

  List<MessageInfo> _fillQuoteInfoLocally(List<MessageInfo> messages) {
    final messagesWithQuote = <MessageInfo>[];
    for (final message in messages) {
      final quoteInfo = message.quoteInfo;
      if (quoteInfo != null && quoteInfo.msgID.isNotEmpty) {
        messagesWithQuote.add(message);
      }
    }
    if (messagesWithQuote.isEmpty) return const [];

    final knownMessageMap = _buildMessageMap([..._messageList, ...messages]);
    final needsStorageResolve = <MessageInfo>[];
    for (final message in messagesWithQuote) {
      final quoteInfo = message.quoteInfo!;
      final found = knownMessageMap[quoteInfo.msgID];
      if (found == null) {
        needsStorageResolve.add(message);
      } else {
        final resolved = _buildFullQuoteInfo(found, quoteInfo);
        if (quoteInfo.messagePayload != null &&
            _isFinalUnavailableStatus(quoteInfo.status) &&
            !_isFinalUnavailableStatus(resolved.status)) {
          // Keep existing — already marked unavailable, don't regress.
        } else {
          message.quoteInfo = resolved;
        }
      }
    }
    return needsStorageResolve;
  }

  Future<void> _fillQuoteInfoFromStorageOrCloud(List<MessageInfo> messages) async {
    if (messages.isEmpty) return;

    final msgIDsToFind = <String>{};
    for (final message in messages) {
      final id = message.quoteInfo?.msgID;
      if (id != null && id.isNotEmpty) msgIDsToFind.add(id);
    }
    if (msgIDsToFind.isEmpty) return;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().findMessages(
      messageIDList: msgIDsToFind.toList(),
    );

    final foundMap = <String, V2TimMessage>{};
    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      for (final msg in result.data!) {
        if (msg.msgID != null) {
          foundMap[msg.msgID!] = msg;
        }
      }
    }

    final needCloudFetch = <MessageInfo>[];
    bool hasUpdate = false;
    for (final message in messages) {
      final quoteInfo = message.quoteInfo;
      if (quoteInfo == null) continue;
      final found = foundMap[quoteInfo.msgID];
      if (found == null) {
        needCloudFetch.add(message);
        continue;
      }
      final index = _messageList.indexWhere((m) => m.msgID == message.msgID);
      if (index == -1) continue;
      final resolved = _buildFullQuoteInfoFromRaw(found, quoteInfo);
      if (_mergeResolvedQuoteInfo(_messageList[index], resolved)) {
        hasUpdate = true;
      }
    }
    if (hasUpdate) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }

    if (needCloudFetch.isNotEmpty) {
      await _fillQuoteInfoFromCloud(needCloudFetch);
    }
  }

  Future<void> _fillQuoteInfoFromCloud(List<MessageInfo> messages) async {
    if (messages.isEmpty) return;

    bool hasUpdate = false;
    for (final message in messages) {
      final quoteInfo = message.quoteInfo;
      if (quoteInfo == null || quoteInfo.msgID.isEmpty) continue;

      final foundMessage = await _findQuotedMessageFromCloud(quoteInfo);

      final index = _messageList.indexWhere((msg) => msg.msgID == message.msgID);
      if (index == -1) continue;

      if (foundMessage != null) {
        final resolved = _buildFullQuoteInfoFromRaw(foundMessage, quoteInfo);
        if (_mergeResolvedQuoteInfo(_messageList[index], resolved)) {
          hasUpdate = true;
        }
      } else if (quoteInfo.status != MessageStatus.deleted) {
        quoteInfo.status = MessageStatus.deleted;
        hasUpdate = true;
      }
    }

    if (hasUpdate) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  Future<V2TimMessage?> _findQuotedMessageFromCloud(MessageQuoteInfo quoteInfo) async {
    final isGroup = ChatUtil.getGroupID(_conversationID).isNotEmpty;

    if (isGroup) {
      return await _findQuotedMessageBySequence(quoteInfo);
    } else {
      return await _findQuotedMessageByTimestamp(quoteInfo);
    }
  }

  /// Group: fetch cloud history by messageSeqList containing the target sequence.
  Future<V2TimMessage?> _findQuotedMessageBySequence(MessageQuoteInfo quoteInfo) async {
    if (quoteInfo.sequence <= 0) return null;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getHistoryMessageList(
      count: 1,
      getType: HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
      groupID: ChatUtil.getGroupID(_conversationID),
      messageSeqList: [quoteInfo.sequence],
    );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      for (final msg in result.data!) {
        if (msg.msgID == quoteInfo.msgID) {
          return msg;
        }
      }
    }
    return null;
  }

  Future<V2TimMessage?> _findQuotedMessageByTimestamp(MessageQuoteInfo quoteInfo) async {
    if (quoteInfo.timestamp <= 0) return null;

    final userID = ChatUtil.getUserID(_conversationID);
    if (userID.isEmpty) return null;

    // Try fetching 1 message at the timestamp
    V2TimMessage? found = await _fetchC2CMessagesByTimestamp(userID, quoteInfo, 1);
    if (found != null) return found;

    // If not found, try fetching 5 messages around the timestamp
    found = await _fetchC2CMessagesByTimestamp(userID, quoteInfo, 5);
    return found;
  }

  Future<V2TimMessage?> _fetchC2CMessagesByTimestamp(
    String userID,
    MessageQuoteInfo quoteInfo,
    int count,
  ) async {
    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getHistoryMessageList(
      count: count,
      getType: HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
      userID: userID,
      timeBegin: quoteInfo.timestamp,
      timePeriod: 1,
    );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      for (final msg in result.data!) {
        if (msg.msgID == quoteInfo.msgID) {
          return msg;
        }
      }
    }
    return null;
  }

  MessageQuoteInfo _buildFullQuoteInfoFromRaw(V2TimMessage foundMessage, MessageQuoteInfo partialInfo) {
    return _buildFullQuoteInfo(ChatUtil.convertToUIMessage(foundMessage), partialInfo);
  }

  MessageQuoteInfo _buildFullQuoteInfo(MessageInfo found, MessageQuoteInfo partialInfo) {
    return MessageQuoteInfo(
      msgID: partialInfo.msgID,
      status: found.status,
      timestamp: partialInfo.timestamp,
      sequence: partialInfo.sequence,
      sender: found.from,
      messageType: found.messageType,
      messagePayload: found.messagePayload,
    );
  }

  bool _mergeResolvedQuoteInfo(MessageInfo message, MessageQuoteInfo resolved) {
    final current = message.quoteInfo;
    if (current != null &&
        _isFinalUnavailableStatus(current.status) &&
        !_isFinalUnavailableStatus(resolved.status)) {
      return false;
    }
    if (identical(current, resolved)) return false;
    message.quoteInfo = resolved;
    return true;
  }

  bool _isFinalUnavailableStatus(MessageStatus status) {
    return status == MessageStatus.revoked || status == MessageStatus.deleted;
  }

  Map<String, MessageInfo> _buildMessageMap(List<MessageInfo> messages) {
    final map = <String, MessageInfo>{};
    for (final message in messages) {
      final id = message.msgID;
      if (id.isNotEmpty) {
        map[id] = message;
      }
    }
    return map;
  }

  Future<CompletionHandler> _loadMessagesInternal(MessageLoadOption? option) async {
    DataReport.reportAtomicMetrics(AtomicMetrics.messageList);

    final loadOption = option ?? MessageLoadOption();
    switch (loadOption.messageListType) {
      case MessageListType.history:
        _option = loadOption;
        _messageList.clear();
        _newMessageQueue = Future.value();
        _messageState.hasOlderMessagesValue.value = false;
        _messageState.hasNewerMessagesValue.value = false;
        return await _loadHistoryMessageList(loadOption);
      case MessageListType.pinned:
        _messageState.pinnedMessageListValue.value = const [];
        return await _loadPinnedMessageList();
    }
  }

  Future<CompletionHandler> _loadHistoryMessageList(MessageLoadOption option) async {
    if (option.direction == MessageLoadDirection.older || option.direction == MessageLoadDirection.newer) {
      return await _loadOneSideMessageList(option, isLoadMore: false);
    } else {
      return await _loadTwoSideMessageList(option);
    }
  }

  Future<CompletionHandler> _loadPinnedMessageList() async {
    final handler = CompletionHandler();
    final groupID = ChatUtil.getGroupID(_conversationID);
    if (groupID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = 'Only group conversations support pinned message list';
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .getPinnedGroupMessageList(groupID: groupID);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final pinned = (result.data ?? []).map((raw) {
      final m = ChatUtil.convertToUIMessage(raw);
      m.isPinned = true;
      return m;
    }).toList();

    _messageState.pinnedMessageListValue.value = List.unmodifiable(pinned);
    return handler;
  }

  Future<CompletionHandler> _loadMoreMessagesInternal(MessageLoadDirection direction) async {
    final handler = CompletionHandler();
    if (_option == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Please call fetchMessages first";
      return handler;
    }

    if (direction == MessageLoadDirection.older) {
      if (!_messageState.hasOlderMessagesValue.value) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "No more older message";
        return handler;
      }

      MessageInfo? firstMessage;
      for (var msg in _messageList) {
        if (msg.rawMessage != null) {
          firstMessage = msg;
          break;
        }
      }

      if (firstMessage == null) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "No more older message";
        return handler;
      }

      _option!.cursor = firstMessage;
    } else if (direction == MessageLoadDirection.newer) {
      if (!_messageState.hasNewerMessagesValue.value) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "No more newer message";
        return handler;
      }

      MessageInfo? lastMessage;
      for (var i = _messageList.length - 1; i >= 0; i--) {
        if (_messageList[i].rawMessage != null) {
          lastMessage = _messageList[i];
          break;
        }
      }

      if (lastMessage == null) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "No more newer message";
        return handler;
      }

      _option!.cursor = lastMessage;
    }

    _option!.direction = direction;

    return await _loadOneSideMessageList(_option!, isLoadMore: true);
  }

  Future<CompletionHandler> _loadOneSideMessageList(MessageLoadOption option, {required bool isLoadMore}) async {
    final handler = CompletionHandler();

    final messageTypeList = _getMessageTypeList(option);
    HistoryMsgGetTypeEnum getType = HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG;
    if (option.direction == MessageLoadDirection.newer) {
      getType = messageTypeList.isNotEmpty
          ? HistoryMsgGetTypeEnum.V2TIM_GET_LOCAL_NEWER_MSG
          : HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_NEWER_MSG;
    } else if (option.direction == MessageLoadDirection.older) {
      getType = messageTypeList.isNotEmpty
          ? HistoryMsgGetTypeEnum.V2TIM_GET_LOCAL_OLDER_MSG
          : HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG;
    }

    final hasRealCursorMessage = option.cursor?.rawMessage != null &&
        (option.cursor!.rawMessage!.msgID?.isNotEmpty ?? false);

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getHistoryMessageList(
          count: option.pageCount,
          getType: getType,
          userID: ChatUtil.getUserID(_conversationID),
          groupID: ChatUtil.getGroupID(_conversationID),
          lastMsg: hasRealCursorMessage ? option.cursor?.rawMessage : null,
          lastMsgSeq: hasRealCursorMessage ? -1 : (option.cursor?.sequence ?? -1),
          timeBegin: hasRealCursorMessage ? null : option.cursor?.timestamp,
          messageTypeList: messageTypeList,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    List<MessageInfo> fetchedMessages = [];
    if (option.direction == MessageLoadDirection.older) {
      final reversedMessages = result.data != null ? List<V2TimMessage>.from(result.data!.reversed) : <V2TimMessage>[];
      fetchedMessages = _convertToUIMessageList(reversedMessages);
      final needsStorageResolve = _fillQuoteInfoLocally(fetchedMessages);
      _messageList.insertAll(0, fetchedMessages);
      _messageState.hasOlderMessagesValue.value = (result.data?.length ?? 0) >= option.pageCount;
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
      _handleNewMessages(fetchedMessages);
      unawaited(_fillQuoteInfoFromStorageOrCloud(needsStorageResolve));
    } else {
      fetchedMessages = result.data != null ? _convertToUIMessageList(result.data!) : [];
      final needsStorageResolve = _fillQuoteInfoLocally(fetchedMessages);
      _messageList.addAll(fetchedMessages);
      _messageState.hasNewerMessagesValue.value = (result.data?.length ?? 0) >= option.pageCount;
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
      _handleNewMessages(fetchedMessages);
      unawaited(_fillQuoteInfoFromStorageOrCloud(needsStorageResolve));
    }

    return handler;
  }

  Future<CompletionHandler> _loadTwoSideMessageList(MessageLoadOption option) async {
    final handler = CompletionHandler();

    final messageTypeList = _getMessageTypeList(option);
    List<V2TimMessage> olderMsgs = [];
    List<V2TimMessage> newerMsgs = [];

    final hasRealCursorMessage = option.cursor?.rawMessage != null &&
        (option.cursor!.rawMessage!.msgID?.isNotEmpty ?? false);
    final V2TimMessage? lastMsg = hasRealCursorMessage ? option.cursor?.rawMessage : null;
    final int lastMsgSeq = hasRealCursorMessage ? -1 : (option.cursor?.sequence ?? -1);
    final int? timeBegin = hasRealCursorMessage ? null : option.cursor?.timestamp;

    final olderResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getHistoryMessageList(
          count: option.pageCount,
          getType: messageTypeList.isNotEmpty
              ? HistoryMsgGetTypeEnum.V2TIM_GET_LOCAL_OLDER_MSG
              : HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
          userID: ChatUtil.getUserID(_conversationID),
          groupID: ChatUtil.getGroupID(_conversationID),
          lastMsg: lastMsg,
          lastMsgSeq: lastMsgSeq,
          timeBegin: timeBegin,
          messageTypeList: messageTypeList,
        );

    final newerResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getHistoryMessageList(
          count: option.pageCount,
          getType: messageTypeList.isNotEmpty
              ? HistoryMsgGetTypeEnum.V2TIM_GET_LOCAL_NEWER_MSG
              : HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_NEWER_MSG,
          userID: ChatUtil.getUserID(_conversationID),
          groupID: ChatUtil.getGroupID(_conversationID),
          lastMsg: lastMsg,
          lastMsgSeq: lastMsgSeq,
          timeBegin: timeBegin,
          messageTypeList: messageTypeList,
        );

    final olderOk = olderResult.code == TIMErrCode.ERR_SUCC.value && olderResult.data != null;
    final newerOk = newerResult.code == TIMErrCode.ERR_SUCC.value && newerResult.data != null;

    if (!olderOk && !newerOk) {
      handler.errorCode = TIMErrCode.ERR_LOADMSG_FAILED.value;
      handler.errorMessage = 'Failed to load messages. '
          'Older error: ${olderResult.desc}, Newer error: ${newerResult.desc}';
      return handler;
    }

    if (olderOk) {
      olderMsgs = List.from(olderResult.data!.reversed);
      _messageState.hasOlderMessagesValue.value = olderResult.data!.length >= option.pageCount;
    }
    if (newerOk) {
      newerMsgs = newerResult.data!;
      _messageState.hasNewerMessagesValue.value = newerResult.data!.length >= option.pageCount;
    }

    final List<V2TimMessage> results = [...olderMsgs];

    if (hasRealCursorMessage) {
      results.add(option.cursor!.rawMessage!);
    }

    final seenIDs = <String>{};
    for (final m in results) {
      final id = m.msgID;
      if (id != null && id.isNotEmpty) seenIDs.add(id);
    }
    for (final m in newerMsgs) {
      final id = m.msgID;
      if (id != null && id.isNotEmpty && seenIDs.contains(id)) continue;
      results.add(m);
    }

    final converted = _convertToUIMessageList(results);
    final needsStorageResolve = _fillQuoteInfoLocally(converted);
    _messageList = converted;

    _messageState.messageListValue.value = List.unmodifiable(_messageList);
    _handleNewMessages(_messageList);
    unawaited(_fillQuoteInfoFromStorageOrCloud(needsStorageResolve));

    return handler;
  }

  List<int> _getMessageTypeList(MessageLoadOption option) {
    if (option.messageTypeList.isEmpty) return [];
    final List<int> messageTypeList = [];
    for (final type in option.messageTypeList) {
      switch (type) {
        case MessageType.text:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_TEXT);
          break;
        case MessageType.image:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_IMAGE);
          break;
        case MessageType.video:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_VIDEO);
          break;
        case MessageType.audio:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_SOUND);
          break;
        case MessageType.file:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_FILE);
          break;
        case MessageType.face:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_FACE);
          break;
        case MessageType.tips:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS);
          break;
        case MessageType.custom:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_CUSTOM);
          break;
        case MessageType.merged:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_MERGER);
          break;
        case MessageType.stream:
          messageTypeList.add(MessageElemType.V2TIM_ELEM_TYPE_STREAM);
          break;
        default:
          break;
      }
    }
    return messageTypeList;
  }

  List<MessageInfo> _convertToUIMessageList(List<V2TimMessage> imMessages) {
    final messageList = <MessageInfo>[];
    for (final imMessage in imMessages) {
      messageList.add(ChatUtil.convertToUIMessage(imMessage));
    }
    return messageList;
  }

  void onMessageSendBegin(String conversationID, MessageInfo message) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    if (conversationID != this._conversationID) return;

    final isResend = (message.status != MessageStatus.init);
    if (isResend) {
      final index = _messageList.indexWhere((msg) => msg.msgID == message.msgID);
      if (index != -1) {
        _messageList.removeAt(index);
      }
    }

    final quoteInfo = message.quoteInfo;
    if (quoteInfo != null && quoteInfo.msgID.isNotEmpty) {
      final foundIndex = _messageList.indexWhere((m) => m.msgID == quoteInfo.msgID);
      if (foundIndex != -1) {
        message.quoteInfo = _buildFullQuoteInfo(_messageList[foundIndex], quoteInfo);
      }
    }

    _messageList.add(message);
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  void onMessageSendSuccess(String conversationID, MessageInfo message) {
    _updateSentMessage(conversationID, message, MessageStatus.sendSuccess);
  }

  void onMessageSendFailed(String conversationID, MessageInfo message, int code, String desc) {
    _updateSentMessage(conversationID, message, MessageStatus.sendFail);
  }

  void _updateSentMessage(String conversationID, MessageInfo message, MessageStatus status) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;
    if (conversationID != _conversationID) return;

    final index = _messageList.indexWhere((msg) => msg.msgID == message.msgID);
    if (index == -1) return;

    final existing = _messageList[index];
    MessageInfo updated;
    if (existing.rawMessage != null) {
      final existingQuoteInfo = existing.quoteInfo;
      updated = ChatUtil.convertToUIMessage(existing.rawMessage!);
      if (existingQuoteInfo != null && existingQuoteInfo.messagePayload != null) {
        updated.quoteInfo = existingQuoteInfo;
      }
    } else {
      updated = existing;
      updated.status = status;
    }

    final updatedQuoteInfo = updated.quoteInfo;
    if (updatedQuoteInfo != null && updatedQuoteInfo.msgID.isNotEmpty) {
      final foundIndex = _messageList.indexWhere((m) => m.msgID == updatedQuoteInfo.msgID);
      if (foundIndex != -1) {
        updated.quoteInfo = _buildFullQuoteInfo(_messageList[foundIndex], updatedQuoteInfo);
      }
    }

    _messageList[index] = updated;
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  void _handleMessageDelete(List<String> messageIDList) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;
    if (messageIDList.isEmpty) return;

    final messageIDSet = messageIDList.toSet();

    final historyBeforeLength = _messageList.length;
    _messageList.removeWhere((message) => messageIDSet.contains(message.msgID));
    final historyQuoteChanged = _updateQuotedStatusInList(_messageList, messageIDSet, MessageStatus.deleted);
    if (_messageList.length != historyBeforeLength || historyQuoteChanged) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }

    final pinnedBefore = _messageState.pinnedMessageListValue.value;
    final pinnedAfter = pinnedBefore.where((m) => !messageIDSet.contains(m.msgID)).toList();
    final pinnedQuoteChanged = _updateQuotedStatusInList(pinnedAfter, messageIDSet, MessageStatus.deleted);
    if (pinnedAfter.length != pinnedBefore.length || pinnedQuoteChanged) {
      _messageState.pinnedMessageListValue.value = List.unmodifiable(pinnedAfter);
    }
  }

  void _handleMessageRevoke(String msgID) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    var didChange = false;
    final index = _messageList.indexWhere((message) => message.msgID == msgID);
    if (index != -1) {
      if (_messageList[index].status != MessageStatus.revoked) {
        _messageList[index].status = MessageStatus.revoked;
        final loginUser = LoginStore.shared.loginState.loginUserInfo;
        if (loginUser != null) {
          _messageList[index].revokerInfo = loginUser;
          _messageList[index].revokeReason = null;
        } else {
          ChatUtil.applyRevokeInfo(_messageList[index], _messageList[index].rawMessage!, null, null);
        }
        didChange = true;
      }
    }

    if (_updateQuotedStatusInList(_messageList, {msgID}, MessageStatus.revoked)) {
      didChange = true;
    }

    if (didChange) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  bool _updateQuotedStatusInList(
    Iterable<MessageInfo> list,
    Set<String> quotedMsgIDs,
    MessageStatus newStatus,
  ) {
    if (quotedMsgIDs.isEmpty) return false;
    var changed = false;
    for (final message in list) {
      final qi = message.quoteInfo;
      if (qi == null) continue;
      if (!quotedMsgIDs.contains(qi.msgID)) continue;
      if (qi.status == newStatus) continue;
      qi.status = newStatus;
      changed = true;
    }
    return changed;
  }

  void _handleMessageEdit(V2TimMessage receivedMessage) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final index = _messageList.indexWhere((message) => message.msgID == receivedMessage.msgID);
    if (index != -1) {
      _applyMessageEdit(index, receivedMessage);
    }
  }

  void _applyMessageEdit(int index, V2TimMessage receivedMessage) {
    final old = _messageList[index];
    final updated = ChatUtil.convertToUIMessage(receivedMessage);
    updated.readReceiptInfo = old.readReceiptInfo;
    updated.extensionList = old.extensionList;
    updated.reactionList = old.reactionList;
    updated.quoteInfo = old.quoteInfo;
    updated.isPinned = old.isPinned;
    _messageList[index] = updated;
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  /// ****** V2TIMAdvancedMsgListener ******
  void _onRecvNewMessage(V2TimMessage message) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    if (!_messageBelongsToConversation(message)) return;

    final messageInfo = ChatUtil.convertToUIMessage(message);

    if (_messageState.hasNewerMessagesValue.value) {
      _messageEventController.add(OnReceiveNewMessage(message: messageInfo));
      return;
    }

    // Chain on serial queue to preserve message order
    _newMessageQueue = _newMessageQueue.then((_) => _handleReceivedNewMessage(messageInfo));
  }

  Future<void> _handleReceivedNewMessage(MessageInfo messageInfo) async {
    final needsStorageResolve = _fillQuoteInfoLocally([messageInfo]);

    _messageList.add(messageInfo);
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
    _handleNewMessages([messageInfo]);

    // Emit recv message event
    _messageEventController.add(OnReceiveNewMessage(message: messageInfo));

    // Async storage→cloud quote resolve (off the UI hot path)
    if (needsStorageResolve.isNotEmpty) {
      unawaited(_fillQuoteInfoFromStorageOrCloud(needsStorageResolve));
    }
  }

  void _onRecvMessageReadReceipts(List<V2TimMessageReceipt> receiptList) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    for (final receipt in receiptList) {
      if (receipt.msgID == null) continue;

      final index = _messageList.indexWhere((msg) => msg.msgID == receipt.msgID);
      if (index != -1) {
        _messageList[index].readReceiptInfo = ChatUtil.convertToMessageReceipt(receipt);
        _messageState.messageListValue.value = List.unmodifiable(_messageList);
      }
    }
  }

  void _onRecvMessageRevoked(String msgID, V2TimUserFullInfo operateUser, String reason) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    var didChange = false;
    final index = _messageList.indexWhere((message) => message.msgID == msgID);
    if (index != -1) {
      if (_messageList[index].status != MessageStatus.revoked) {
        _messageList[index].status = MessageStatus.revoked;
        ChatUtil.applyRevokeInfo(_messageList[index], _messageList[index].rawMessage!, operateUser, reason);
        didChange = true;
      }
    }

    if (_updateQuotedStatusInList(_messageList, {msgID}, MessageStatus.revoked)) {
      didChange = true;
    }

    if (didChange) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  void _onRecvMessageModified(V2TimMessage receivedMessage) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    if (!_messageBelongsToConversation(receivedMessage)) return;

    final index = _messageList.indexWhere((message) => message.msgID == receivedMessage.msgID);
    if (index != -1) {
      _applyMessageEdit(index, receivedMessage);
    }
  }

  bool _messageBelongsToConversation(V2TimMessage message) {
    final groupID = message.groupID;
    if (groupID != null && groupID.isNotEmpty) {
      return groupID == ChatUtil.getGroupID(_conversationID);
    }
    final userID = message.userID;
    if (userID != null && userID.isNotEmpty) {
      return userID == ChatUtil.getUserID(_conversationID);
    }
    return false;
  }

  void _onRecvMessageReactionsChanged(List<V2TIMMessageReactionChangeInfo> changeInfos) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final ids = changeInfos.map((info) => info.messageID).whereType<String>().toSet();
    if (ids.isEmpty) return;

    bool hasUpdate = false;
    for (int i = 0; i < _messageList.length; i++) {
      final message = _messageList[i];
      if (ids.contains(message.msgID)) {
        final changeInfo = changeInfos.cast<V2TIMMessageReactionChangeInfo?>().firstWhere(
              (info) => info?.messageID == message.msgID,
              orElse: () => null,
            );
        if (changeInfo != null) {
          final changedReactions = ChatUtil.convertToMessageReactions(changeInfo.reactionList);
          final mergedReactions = _mergeReactions(message.reactionList, changedReactions);
          _messageList[i].reactionList = mergedReactions;
          hasUpdate = true;
        }
      }
    }

    if (hasUpdate) {
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  List<MessageReaction> _mergeReactions(
    List<MessageReaction> existingReactions,
    List<MessageReaction> changedReactions,
  ) {
    final reactionMap = <String, MessageReaction>{};
    for (final reaction in existingReactions) {
      reactionMap[reaction.reactionID] = reaction;
    }

    for (final changedReaction in changedReactions) {
      if (changedReaction.totalUserCount == 0) {
        reactionMap.remove(changedReaction.reactionID);
      } else {
        reactionMap[changedReaction.reactionID] = changedReaction;
      }
    }

    return reactionMap.values.toList();
  }

  void _onRecvMessageExtensionsChanged(String msgID, List<V2TimMessageExtension> extensions) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final index = _messageList.indexWhere((msg) => msg.msgID == msgID);
    if (index != -1) {
      _messageList[index].extensionList = ChatUtil.convertToMessageExtensions(extensions);
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  void _onRecvMessageExtensionsDeleted(String msgID, List<String> extensionKeys) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final index = _messageList.indexWhere((msg) => msg.msgID == msgID);
    if (index != -1) {
      _messageList[index]
          .extensionList
          .removeWhere((ext) => ext.extensionKey != null && extensionKeys.contains(ext.extensionKey!));
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  void _onGroupMessagePinned(String groupID, V2TimMessage message, bool isPinned, V2TimGroupMemberInfo opUser) {
    final currentGroupID = ChatUtil.getGroupID(_conversationID);
    if (currentGroupID != groupID) return;

    final msgID = message.msgID;
    if (msgID == null || msgID.isEmpty) return;

    _updatePinnedState(msgID, isPinned, rawMessage: message);
  }

  void _onSendMessageProgress(V2TimMessage receivedMessage, int progress) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) {
      debugPrint("messageListType is not history");
      return;
    }

    final index = _messageList.indexWhere((message) => message.msgID == receivedMessage.msgID);
    if (index != -1) {
      _messageList[index].uploadMediaProgress = progress;
      _messageState.messageListValue.value = List.unmodifiable(_messageList);
    }
  }

  void _onMessageDownloadProgress(V2TimMessageDownloadProgress progress) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final msgID = progress.msgID;
    if (msgID.isEmpty) return;
    final index = _messageList.indexWhere((message) => message.msgID == msgID);
    if (index == -1) return;

    if (progress.isFinish) return;

    final total = progress.totalSize;
    if (total <= 0) return;
    final percent = ((progress.currentSize * 100) ~/ total).clamp(0, 99);

    if (_messageList[index].downloadMediaProgress == percent) return;
    _messageList[index].downloadMediaProgress = percent;
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  void _handleMessageSendBegin(MessageSendEventData data) {
    if (data.conversationID != _conversationID) return;
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final message = data.message as MessageInfo?;
    if (message != null) {
      onMessageSendBegin(data.conversationID, message);
    }
  }

  void _handleMessageSendSuccess(MessageSendEventData data) {
    if (data.conversationID != _conversationID) return;
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final message = data.message as MessageInfo?;
    if (message != null) {
      onMessageSendSuccess(data.conversationID, message);
    }
  }

  void _handleMessageSendFailed(MessageSendEventData data) {
    if (data.conversationID != _conversationID) return;
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final message = data.message as MessageInfo?;
    if (message != null) {
      onMessageSendFailed(data.conversationID, message, data.code ?? -1, data.desc ?? "");
    }
  }

  void _handleMessageInserted(MessageInsertEventData data) {
    if (data.conversationID != _conversationID) return;
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    _newMessageQueue = _newMessageQueue.then((_) => _handleReceivedNewMessage(data.message));
  }

  void _handleMessageDeleteEvent(MessageDeleteEventData data) {
    _handleMessageDelete(data.messageIDList);
  }

  void _handleMessageRevokeEvent(MessageRevokeEventData data) {
    _handleMessageRevoke(data.messageID);
  }

  void _handleMessageEditEvent(MessageEditEventData data) {
    if (data.message != null) {
      _handleMessageEdit(data.message as V2TimMessage);
    }
  }

  void _handleMessagePinEvent(MessagePinEventData data) {
    final currentGroupID = ChatUtil.getGroupID(_conversationID);
    if (currentGroupID != data.groupID) return;

    _updatePinnedState(data.messageID, data.isPinned);
  }

  void _updatePinnedState(
    String messageID,
    bool isPinned, {
    V2TimMessage? rawMessage,
  }) {
    MessageInfo? pinnedFromHistory;
    for (final msg in _messageList) {
      if (msg.msgID != messageID) continue;
      if (msg.isPinned != isPinned) {
        msg.isPinned = isPinned;
        _messageState.messageListValue.value = List.unmodifiable(_messageList);
      }
      if (isPinned) pinnedFromHistory = msg;
      break;
    }

    final current = _messageState.pinnedMessageListValue.value;
    final withoutTarget = current.where((m) => m.msgID != messageID).toList();
    final wasInPinned = withoutTarget.length != current.length;

    if (!isPinned) {
      if (wasInPinned) {
        _messageState.pinnedMessageListValue.value = List.unmodifiable(withoutTarget);
      }
      return;
    }

    MessageInfo? toAppend;
    if (pinnedFromHistory != null) {
      toAppend = pinnedFromHistory;
    } else if (wasInPinned) {
      toAppend = current.firstWhere((m) => m.msgID == messageID)..isPinned = true;
    } else if (rawMessage != null) {
      toAppend = ChatUtil.convertToUIMessage(rawMessage)..isPinned = true;
    }
    if (toAppend == null) return;

    _messageState.pinnedMessageListValue.value = List.unmodifiable([
      ...withoutTarget,
      toAppend,
    ]);
  }

  void _handleMessageListClear(MessageListClearEventData data) {
    if (data.conversationID != _conversationID) return;
    _messageList.clear();
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
    if (_messageState.pinnedMessageListValue.value.isNotEmpty) {
      _messageState.pinnedMessageListValue.value = const [];
    }
  }

  void _handleTranslateMessage(MessageTranslateEventData data) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final messageID = data.messageID;
    final targetLanguage = data.targetLanguage;
    final translatedTextMap = data.translatedText;

    if (messageID == null || targetLanguage == null || translatedTextMap == null) return;

    final index = _messageList.indexWhere((msg) => msg.msgID == messageID);
    if (index == -1) return;

    final message = _messageList[index];
    final payload = message.messagePayload;
    if (payload is! TextMessagePayload) return;

    // Update translatedText in payload
    payload.translatedText ??= {};
    payload.translatedText!.addAll(translatedTextMap);
    payload.translateLanguage = targetLanguage;

    // Save translated text map to localCustomData for persistence
    final rawMessage = message.rawMessage;
    if (rawMessage != null) {
      Map<String, dynamic> dict = {};
      final localCustomData = rawMessage.localCustomData;
      if (localCustomData != null && localCustomData.isNotEmpty) {
        final existingDict = ChatUtil.jsonData2Dictionary(localCustomData);
        if (existingDict != null) {
          dict = existingDict;
        }
      }
      dict[LocalCustomDataKey.textTranslation] = translatedTextMap;
      dict[LocalCustomDataKey.textTranslationLanguage] = targetLanguage;
      final newLocalCustomData = ChatUtil.dictionary2JsonData(dict);
      rawMessage.localCustomData = newLocalCustomData;
      // Flutter needs to call an API to save the data.
      TencentImSDKPlugin.v2TIMManager.getMessageManager().setLocalCustomData(
            message: rawMessage,
            localCustomData: newLocalCustomData ?? '',
          );
    }

    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  void _handleVoiceConvertToText(VoiceConvertToTextEventData data) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;

    final messageID = data.messageID;
    final language = data.language;
    final convertedText = data.convertedText;

    if (messageID == null || convertedText == null) return;

    final index = _messageList.indexWhere((msg) => msg.msgID == messageID);
    if (index == -1) return;

    final message = _messageList[index];
    final payload = message.messagePayload;
    if (payload is AudioMessagePayload) {
      payload.asrLanguage = language;
      payload.asrText = convertedText;
    }

    // Save asrText to localCustomData for persistence
    final rawMessage = message.rawMessage;
    if (rawMessage != null && convertedText.isNotEmpty) {
      Map<String, dynamic> dict = {};
      final localCustomData = rawMessage.localCustomData;
      if (localCustomData != null && localCustomData.isNotEmpty) {
        final existingDict = ChatUtil.jsonData2Dictionary(localCustomData);
        if (existingDict != null) {
          dict = existingDict;
        }
      }
      dict[LocalCustomDataKey.voiceToText] = convertedText;
      final newLocalCustomData = ChatUtil.dictionary2JsonData(dict);
      rawMessage.localCustomData = newLocalCustomData;
      // Flutter needs to call an API to save the data.
      TencentImSDKPlugin.v2TIMManager.getMessageManager().setLocalCustomData(
            message: rawMessage,
            localCustomData: newLocalCustomData ?? '',
          );
    }

    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  void _handleMessageMediaDownload(MessageMediaDownloadEventData data) {
    if ((_option?.messageListType ?? MessageListType.history) != MessageListType.history) return;
    if (data.messageID.isEmpty) return;

    final index = _messageList.indexWhere((msg) => msg.msgID == data.messageID);
    if (index == -1) return;

    if (data.messagePayload != null) {
      _messageList[index].messagePayload = data.messagePayload;
    }
    _messageList[index].downloadMediaProgress = 100;
    _messageState.messageListValue.value = List.unmodifiable(_messageList);
  }

  // Send message read receipts
  Future<CompletionHandler> _sendMessageReadReceiptsInternal(List<MessageInfo> messageList) async {
    final handler = CompletionHandler();

    if (messageList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "messageList cannot be empty";
      return handler;
    }

    final v2MessageList = <V2TimMessage>[];
    for (final messageInfo in messageList) {
      if (messageInfo.rawMessage == null) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "MessageInfo.rawMessage cannot be null";
        return handler;
      }
      v2MessageList.add(messageInfo.rawMessage!);
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessageReadReceipts(
          messageList: v2MessageList,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  // Delete messages
  Future<CompletionHandler> _deleteMessagesInternal(List<MessageInfo> messageList) async {
    final handler = CompletionHandler();

    if (messageList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "messageList cannot be empty";
      return handler;
    }

    List<V2TimMessage> v2MessageList = [];
    List<String> messageIDList = [];

    for (final messageInfo in messageList) {
      if (messageInfo.rawMessage == null) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "MessageInfo.rawMessage cannot be null";
        return handler;
      }

      if (messageInfo.msgID.isEmpty) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "MessageInfo.msgID cannot be empty";
        return handler;
      }

      v2MessageList.add(messageInfo.rawMessage!);
      messageIDList.add(messageInfo.msgID);
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().deleteMessages(
          messageList: v2MessageList,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      NotificationCenter().post(
        MessageActionNotifyKey.messageDelete,
        MessageDeleteEventData(messageIDList: messageIDList),
      );
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  // Forward messages
  Future<CompletionHandler> _forwardMessagesInternal(
    List<MessageInfo> messageList,
    ForwardMessageOption forwardOption,
    String conversationID,
  ) async {
    final handler = CompletionHandler();

    if (messageList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "messageList cannot be empty";
      return handler;
    }

    for (final message in messageList) {
      if (message.rawMessage == null) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "MessageInfo.rawMessage cannot be null";
        return handler;
      }

      if (message.status != MessageStatus.sendSuccess) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "Only successfully sent messages can be forwarded";
        return handler;
      }

      if (message.messageType == MessageType.tips || message.messageType == MessageType.unknown) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "System messages and unknown messages cannot be forwarded";
        return handler;
      }
    }

    if (conversationID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "conversationID cannot be empty";
      return handler;
    }

    if (forwardOption.forwardType == MessageForwardType.merged) {
      if (messageList.length > _mergedForwardMessageLimit) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "messageList count cannot exceed 300 when forwardType is .merged";
        return handler;
      }

      if (forwardOption.mergedForwardInfo == null || forwardOption.mergedForwardInfo!.title.isEmpty) {
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage =
            "mergedForwardInfo and mergedForwardInfo.title cannot be empty when forwardType is .merged";
        return handler;
      }

      return await _forwardMergedMessagePayloads(messageList, forwardOption, conversationID);
    } else {
      return await _forwardSeparateMessages(messageList, conversationID);
    }
  }

  Future<CompletionHandler> _forwardMergedMessagePayloads(
    List<MessageInfo> messageList,
    ForwardMessageOption forwardOption,
    String conversationID,
  ) async {
    final mergedForwardInfo = forwardOption.mergedForwardInfo!;
    final sendOption = forwardOption.sendMessageOption;
    final v2MessageList = messageList.map((msg) => msg.rawMessage!).toList();

    final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createMergerMessage(
          messageList: v2MessageList,
          title: mergedForwardInfo.title,
          abstractList: mergedForwardInfo.abstractList ?? [],
          compatibleText: mergedForwardInfo.compatibleText,
        );

    if (createResult.code != TIMErrCode.ERR_SUCC.value || createResult.data?.messageInfo == null) {
      return CompletionHandler()
        ..errorCode = createResult.code
        ..errorMessage = createResult.desc.isEmpty ? "Failed to create merger message" : createResult.desc;
    }

    final mergerMessage = createResult.data!.messageInfo!;

    var messageInfo = MessageInfo();
    messageInfo.messagePayload = MergedMessagePayload(
      title: mergedForwardInfo.title,
      abstractList: mergedForwardInfo.abstractList,
    );
    messageInfo.messageType = MessageType.merged;
    messageInfo.needReadReceipt = sendOption?.needReadReceipt ?? false;
    messageInfo.isExtensionEnabled = sendOption?.isExtensionEnabled ?? false;
    messageInfo.offlinePushInfo = sendOption?.offlinePushInfo;
    messageInfo.rawMessage = mergerMessage;

    return await _sendMessageToConversation(messageInfo, conversationID);
  }

  Future<CompletionHandler> _forwardSeparateMessages(
    List<MessageInfo> messageList,
    String conversationID,
  ) async {
    CompletionHandler? lastError;
    bool hasError = false;

    for (var i = 0; i < messageList.length; i++) {
      final message = messageList[i];
      if (message.rawMessage == null) continue;

      final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createForwardMessage(
            message: message.rawMessage,
          );

      if (createResult.code != TIMErrCode.ERR_SUCC.value || createResult.data?.messageInfo == null) {
        return CompletionHandler()
          ..errorCode = createResult.code
          ..errorMessage = createResult.desc.isEmpty ? "Failed to create forward message" : createResult.desc;
      }

      final forwardMessage = createResult.data!.messageInfo!;

      var messageInfo = MessageInfo();
      messageInfo.messageType = message.messageType;
      messageInfo.messagePayload = message.messagePayload;
      messageInfo.needReadReceipt = message.needReadReceipt;
      messageInfo.isExtensionEnabled = message.isExtensionEnabled;
      messageInfo.offlinePushInfo = message.offlinePushInfo;
      messageInfo.rawMessage = forwardMessage;

      // Add delay between messages to avoid rate limiting
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final result = await _sendMessageToConversation(messageInfo, conversationID);
      if (result.errorCode != TIMErrCode.ERR_SUCC.value) {
        hasError = true;
        lastError = result;
      }
    }

    if (hasError && lastError != null) {
      return lastError;
    }

    return CompletionHandler();
  }

  Future<CompletionHandler> _sendMessageToConversation(
    MessageInfo messageInfo,
    String conversationID,
  ) async {
    final inputStore = MessageInputStoreImpl(conversationID);
    return await inputStore.sendMessageInternal(messageInfo);
  }
}
