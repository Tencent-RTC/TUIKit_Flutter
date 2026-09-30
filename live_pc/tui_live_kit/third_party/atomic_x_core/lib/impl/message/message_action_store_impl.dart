import 'package:atomic_x_core/api/conversation/conversation_list_store.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/message/message_action_store.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/common/chat_util.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/common/notification_center.dart';
import 'package:atomic_x_core/impl/message/message_list_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/get_group_message_read_member_list_filter.dart';
import 'package:tencent_cloud_chat_sdk/enum/image_types.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_extension.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_reaction_result.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

const String localExistKey = "isLocalExist";
const String filePathKey = "filePath";
const int _messageReactionUserCount = 10;

// Message action notification keys
class MessageActionNotifyKey {
  static const String messageDelete = 'message_delete';
  static const String messageRevoke = 'message_revoke';
  static const String messageEdit = 'message_edit';
  static const String messagePin = 'message_pin';
  static const String messageTranslate = 'message_translate';
  static const String voiceConvertToText = 'voice_convert_to_text';
  static const String messageMediaDownload = 'message_media_download';
}

// Message action notification data keys
class MessageActionNotifyDataKey {
  static const String messageID = 'messageID';
  static const String targetLanguage = 'targetLanguage';
  static const String translatedText = 'translatedText';
  static const String language = 'language';
  static const String convertedText = 'convertedText';
}

// Voice convert to text event data
class VoiceConvertToTextEventData {
  final String? messageID;
  final String? language;
  final String? convertedText;

  VoiceConvertToTextEventData({
    this.messageID,
    this.language,
    this.convertedText,
  });
}

// Message translate event data
class MessageTranslateEventData {
  final String? messageID;
  final String? targetLanguage;
  final Map<String, String>? translatedText;

  MessageTranslateEventData({
    this.messageID,
    this.targetLanguage,
    this.translatedText,
  });
}

class MessageMediaDownloadEventData {
  final String messageID;
  final MediaQuality? quality;
  final MessagePayload? messagePayload;

  MessageMediaDownloadEventData({
    required this.messageID,
    this.quality,
    this.messagePayload,
  });
}

class _MessageActionStateImpl implements MessageActionState {
  final ValueNotifier<List<GroupMember>> readMemberListValue = ValueNotifier([]);
  final ValueNotifier<bool> hasMoreReadMembersValue = ValueNotifier(true);

  final ValueNotifier<List<GroupMember>> unreadMemberListValue = ValueNotifier([]);
  final ValueNotifier<bool> hasMoreUnreadMembersValue = ValueNotifier(true);

  final ValueNotifier<List<UserProfile>> reactionUserListValue = ValueNotifier([]);
  final ValueNotifier<bool> hasMoreReactionUsersValue = ValueNotifier(true);

  @override
  ValueListenable<List<GroupMember>> get readMemberList => readMemberListValue;

  @override
  ValueListenable<bool> get hasMoreReadMembers => hasMoreReadMembersValue;

  @override
  ValueListenable<List<GroupMember>> get unreadMemberList => unreadMemberListValue;

  @override
  ValueListenable<bool> get hasMoreUnreadMembers => hasMoreUnreadMembersValue;

  @override
  ValueListenable<List<UserProfile>> get reactionUserList => reactionUserListValue;

  @override
  ValueListenable<bool> get hasMoreReactionUsers => hasMoreReactionUsersValue;
}

class MessageActionStoreImpl extends MessageActionStore {
  final _state = _MessageActionStateImpl();

  // Pagination state for read/unread members
  int _nextSeqOfReadMembers = 0;
  int _nextSeqOfUnReadMembers = 0;
  int _countOfReadMembers = 0;
  int _countOfUnReadMembers = 0;

  // Pagination state for reaction users
  String _currentReactionID = "";
  int _nextSeqOfReactionUsers = 0;
  int _countOfReactionUsers = 0;

  final MessageInfo _message;
  bool _hasReported = false;

  MessageActionStoreImpl(this._message);

  @override
  MessageActionState get state => _state;

  @override
  Future<CompletionHandler> revoke() async {
    return await _revokeMessageInternal();
  }

  @override
  Future<CompletionHandler> delete() async {
    return await _deleteMessageInternal();
  }

  @override
  Future<CompletionHandler> pin({required bool isPinned}) async {
    return await _pinMessageInternal(isPinned: isPinned);
  }

  @override
  Future<CompletionHandler> loadReadMembers({int count = 100}) async {
    return await _loadReadMembersInternal(count: count);
  }

  @override
  Future<CompletionHandler> loadUnreadMembers({int count = 100}) async {
    return await _loadUnreadMembersInternal(count: count);
  }

  @override
  Future<CompletionHandler> loadMoreMembers({required bool isRead}) async {
    return await _loadMoreMembersInternal(isRead: isRead);
  }

  @override
  Future<CompletionHandler> addReaction({required String reactionID}) async {
    return await _addMessageReactionInternal(reactionID: reactionID);
  }

  @override
  Future<CompletionHandler> removeReaction({required String reactionID}) async {
    return await _removeMessageReactionInternal(reactionID: reactionID);
  }

  @override
  Future<CompletionHandler> loadReactionUsers({required String reactionID, int count = 100}) async {
    return await _fetchMessageReactionUsersInternal(reactionID: reactionID, count: count);
  }

  @override
  Future<CompletionHandler> loadMoreReactionUsers() async {
    return await _fetchMoreMessageReactionUsersInternal();
  }

  @override
  Future<CompletionHandler> setExtensions({required List<MessageExtension> extensions}) async {
    return await _setMessageExtensionsInternal(extensions: extensions);
  }

  @override
  Future<CompletionHandler> deleteExtensions({List<String>? keys}) async {
    return await _deleteMessageExtensionsInternal(keys: keys);
  }

  @override
  Future<CompletionHandler> translateText({
    required List<String> sourceTextList,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    return await _translateTextInternal(
        sourceTextList: sourceTextList, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage);
  }

  @override
  Future<CompletionHandler> convertVoiceToText({required String language}) async {
    return await _convertVoiceToTextInternal(language: language);
  }

  @override
  Future<CompletionHandler> downloadMedia({MediaQuality? quality}) async {
    return await _downloadMediaInternal(quality: quality);
  }

  @override
  Future<MergedMessageListCompletionHandler> downloadMergedMessageList() async {
    return await _downloadMergedMessageListInternal();
  }

  Future<CompletionHandler> _deleteMessageInternal() async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final msgID = _message.msgID!;
    final imMessage = _message.rawMessage!;
    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().deleteMessages(
      messageList: [imMessage],
    );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      notificationCenter.post(MessageActionNotifyKey.messageDelete, MessageDeleteEventData(messageIDList: [msgID]));
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _revokeMessageInternal() async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final result =
        await TencentImSDKPlugin.v2TIMManager.getMessageManager().revokeMessage(message: _message.rawMessage);
    if (result.code == TIMErrCode.ERR_SUCC.value) {
      notificationCenter.post(MessageActionNotifyKey.messageRevoke, MessageRevokeEventData(messageID: _message.msgID!));
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _pinMessageInternal({required bool isPinned}) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    final msgID = _message.msgID;
    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final groupID = _message.conversationType == ConversationType.group ? _message.to : null;
    if (groupID == null || groupID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Only group messages can be pinned";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().pinGroupMessage(
          groupID: groupID,
          message: _message.rawMessage!,
          isPinned: isPinned,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      notificationCenter.post(
          MessageActionNotifyKey.messagePin,
          MessagePinEventData(
            messageID: msgID,
            groupID: groupID,
            isPinned: isPinned,
          ));
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _loadReadMembersInternal({required int count}) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (count <= 0) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "count cannot be 0";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    _countOfReadMembers = count;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getGroupMessageReadMemberList(
          message: _message.rawMessage,
          filter: GetGroupMessageReadMemberListFilter.V2TIM_GROUP_MESSAGE_READ_MEMBERS_FILTER_READ,
          nextSeq: 0,
          count: count,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      _nextSeqOfReadMembers = result.data!.nextSeq;

      List<GroupMember> groupMembers = [];
      final members = result.data!.memberInfoList;
      for (final v2Member in members) {
        final member = ChatUtil.convertToGroupMember(v2Member);
        groupMembers.add(member);
      }

      _state.readMemberListValue.value = groupMembers;
      _state.hasMoreReadMembersValue.value = !result.data!.isFinished;
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _loadUnreadMembersInternal({required int count}) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (count <= 0) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "count cannot be 0";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    _countOfUnReadMembers = count;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getGroupMessageReadMemberList(
          message: _message.rawMessage,
          filter: GetGroupMessageReadMemberListFilter.V2TIM_GROUP_MESSAGE_READ_MEMBERS_FILTER_UNREAD,
          nextSeq: 0,
          count: count,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      _nextSeqOfUnReadMembers = result.data!.nextSeq;

      List<GroupMember> groupMembers = [];
      final members = result.data!.memberInfoList;
      for (final v2Member in members) {
        final member = ChatUtil.convertToGroupMember(v2Member);
        groupMembers.add(member);
      }

      _state.unreadMemberListValue.value = groupMembers;
      _state.hasMoreUnreadMembersValue.value = !result.data!.isFinished;
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _loadMoreMembersInternal({required bool isRead}) async {
    final handler = CompletionHandler();

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    if (isRead) {
      if (!_state.hasMoreReadMembersValue.value) {
        return handler;
      }

      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getGroupMessageReadMemberList(
            message: _message.rawMessage,
            filter: GetGroupMessageReadMemberListFilter.V2TIM_GROUP_MESSAGE_READ_MEMBERS_FILTER_READ,
            nextSeq: _nextSeqOfReadMembers,
            count: _countOfReadMembers,
          );

      if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
        _nextSeqOfReadMembers = result.data!.nextSeq;

        final members = result.data!.memberInfoList;
        if (members.isNotEmpty) {
          List<GroupMember> groupMembers = [];
          for (final v2Member in members) {
            final member = ChatUtil.convertToGroupMember(v2Member);
            groupMembers.add(member);
          }
          _state.readMemberListValue.value = List.from(_state.readMemberListValue.value)..addAll(groupMembers);
        }

        _state.hasMoreReadMembersValue.value = !result.data!.isFinished;
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    } else {
      if (!_state.hasMoreUnreadMembersValue.value) {
        return handler;
      }

      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getGroupMessageReadMemberList(
            message: _message.rawMessage,
            filter: GetGroupMessageReadMemberListFilter.V2TIM_GROUP_MESSAGE_READ_MEMBERS_FILTER_UNREAD,
            nextSeq: _nextSeqOfUnReadMembers,
            count: _countOfUnReadMembers,
          );

      if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
        _nextSeqOfUnReadMembers = result.data!.nextSeq;

        final members = result.data!.memberInfoList;
        if (members.isNotEmpty) {
          List<GroupMember> groupMembers = [];
          for (final v2Member in members) {
            final member = ChatUtil.convertToGroupMember(v2Member);
            groupMembers.add(member);
          }
          _state.unreadMemberListValue.value = List.from(_state.unreadMemberListValue.value)..addAll(groupMembers);
        }

        _state.hasMoreUnreadMembersValue.value = !result.data!.isFinished;
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    }

    return handler;
  }

  Future<CompletionHandler> _addMessageReactionInternal({required String reactionID}) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (reactionID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "reactionID cannot be empty";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().addMessageReaction(
          message: _message.rawMessage,
          reactionID: reactionID,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _removeMessageReactionInternal({required String reactionID}) async {
    final handler = CompletionHandler();

    if (reactionID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "reactionID cannot be empty";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().removeMessageReaction(
          message: _message.rawMessage,
          reactionID: reactionID,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _fetchMessageReactionUsersInternal({
    required String reactionID,
    required int count,
  }) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (reactionID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "reactionID cannot be empty";
      return handler;
    }

    if (count <= 0) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "count cannot be 0";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    _currentReactionID = reactionID;
    _countOfReactionUsers = count;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getAllUserListOfMessageReaction(
          message: _message.rawMessage,
          reactionID: reactionID,
          nextSeq: 0,
          count: count,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      _nextSeqOfReactionUsers = result.data!.nextSeq;

      List<UserProfile> userProfiles = [];
      final userList = result.data!.userInfoList;
      for (final v2UserInfo in userList) {
        final userProfile = ChatUtil.convertToUserProfile(v2UserInfo);
        userProfiles.add(userProfile);
      }

      _state.reactionUserListValue.value = userProfiles;
      _state.hasMoreReactionUsersValue.value = !result.data!.isFinished;
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _fetchMoreMessageReactionUsersInternal() async {
    final handler = CompletionHandler();

    if (!_state.hasMoreReactionUsersValue.value) {
      return handler;
    }

    if (_currentReactionID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Please call fetchMessageReactionUsers first";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getAllUserListOfMessageReaction(
          message: _message.rawMessage,
          reactionID: _currentReactionID,
          nextSeq: _nextSeqOfReactionUsers,
          count: _countOfReactionUsers,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      _nextSeqOfReactionUsers = result.data!.nextSeq;

      final userList = result.data!.userInfoList;
      if (userList.isNotEmpty) {
        List<UserProfile> userProfiles = [];
        for (final v2UserInfo in userList) {
          final userProfile = ChatUtil.convertToUserProfile(v2UserInfo);
          userProfiles.add(userProfile);
        }
        _state.reactionUserListValue.value = List.from(_state.reactionUserListValue.value)..addAll(userProfiles);
      }

      _state.hasMoreReactionUsersValue.value = !result.data!.isFinished;
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _setMessageExtensionsInternal({
    required List<MessageExtension> extensions,
  }) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (extensions.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "extensions cannot be empty";
      return handler;
    }

    if (_message.rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    List<V2TimMessageExtension> v2Extensions = [];
    for (final ext in extensions) {
      final v2Ext = V2TimMessageExtension(
        extensionKey: ext.extensionKey ?? "",
        extensionValue: ext.extensionValue ?? "",
      );
      v2Extensions.add(v2Ext);
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().setMessageExtensions(
          message: _message.rawMessage,
          extensions: v2Extensions,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      // Check if any extension failed to set
      for (final extResult in result.data!) {
        if (extResult.resultCode != TIMErrCode.ERR_SUCC.value) {
          print(
              "[MessageActionStore] Failed to set extension: key=${extResult.extension?.extensionKey ?? ""}, code=${extResult.resultCode}, message=${extResult.resultInfo}");
        }
      }
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _deleteMessageExtensionsInternal({List<String>? keys}) async {
    final handler = CompletionHandler();

    if (_message.rawMessage == null || _message.msgID == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().deleteMessageExtensions(
          message: _message.rawMessage,
          keys: keys ?? [],
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      // Check if any extension failed to delete
      for (final extResult in result.data!) {
        if (extResult.resultCode != TIMErrCode.ERR_SUCC.value) {
          print(
              "[MessageActionStore] Failed to delete extension: key=${extResult.extension?.extensionKey ?? ""}, code=${extResult.resultCode}, message=${extResult.resultInfo}");
        }
      }
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _translateTextInternal({
    required List<String> sourceTextList,
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    if (sourceTextList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "sourceTextList cannot be empty";
      return handler;
    }

    if (targetLanguage.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "targetLanguage cannot be empty";
      return handler;
    }

    final msgID = _message.msgID;
    if (msgID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message ID not found";
      return handler;
    }

    final rawMessage = _message.rawMessage;
    if (rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    // Check if already translated (cached in localCustomData)
    final localCustomData = rawMessage.localCustomData;
    if (localCustomData != null && localCustomData.isNotEmpty) {
      final json = ChatUtil.jsonData2Dictionary(localCustomData);
      if (json != null) {
        final cachedMap = json[LocalCustomDataKey.textTranslation] as Map<String, dynamic>?;
        final cachedLanguage = json[LocalCustomDataKey.textTranslationLanguage] as String?;
        if (cachedMap != null && cachedMap.isNotEmpty && cachedLanguage == targetLanguage) {
          // Convert to Map<String, String>
          final translatedTextMap = cachedMap.map((key, value) => MapEntry(key, value.toString()));
          notificationCenter.post(
              MessageActionNotifyKey.messageTranslate,
              MessageTranslateEventData(
                messageID: _message.msgID,
                targetLanguage: targetLanguage,
                translatedText: translatedTextMap,
              ));
          return handler;
        }
      }
    }

    // The SDK API only supports translating one text at a time
    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().translateText(
          texts: sourceTextList,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage ?? '',
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      notificationCenter.post(
          MessageActionNotifyKey.messageTranslate,
          MessageTranslateEventData(
            messageID: _message.msgID,
            targetLanguage: targetLanguage,
            translatedText: result.data,
          ));
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<CompletionHandler> _convertVoiceToTextInternal({required String language}) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();

    final msgID = _message.msgID;
    if (msgID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message ID not found";
      return handler;
    }

    final rawMessage = _message.rawMessage;
    if (rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    if (_message.messageType != MessageType.audio) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "This is not a voice message";
      return handler;
    }

    // Check if already converted (cached in localCustomData)
    final localCustomData = rawMessage.localCustomData;
    if (localCustomData != null && localCustomData.isNotEmpty) {
      final json = ChatUtil.jsonData2Dictionary(localCustomData);
      if (json != null) {
        final cachedText = json[LocalCustomDataKey.voiceToText] as String?;
        if (cachedText != null && cachedText.isNotEmpty) {
          notificationCenter.post(
              MessageActionNotifyKey.voiceConvertToText,
              VoiceConvertToTextEventData(
                messageID: msgID,
                language: language,
                convertedText: cachedText,
              ));
          return handler;
        }
      }
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().convertVoiceToText(
          message: rawMessage,
          language: language,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final convertedText = result.data;
    if (convertedText == null || convertedText.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Conversion result is null";
      return handler;
    }

    notificationCenter.post(
        MessageActionNotifyKey.voiceConvertToText,
        VoiceConvertToTextEventData(
          messageID: msgID,
          language: language,
          convertedText: convertedText,
        ));

    return handler;
  }

  void _reportAtomicMetricsIfNeeded() {
    if (_hasReported) return;
    _hasReported = true;
    DataReport.reportAtomicMetrics(AtomicMetrics.messageAction);
  }

  void _postMessageMediaDownload({MediaQuality? quality}) {
    notificationCenter.post(
      MessageActionNotifyKey.messageMediaDownload,
      MessageMediaDownloadEventData(
        messageID: _message.msgID,
        quality: quality,
        messagePayload: _message.messagePayload,
      ),
    );
  }

  Future<CompletionHandler> _downloadMediaInternal({MediaQuality? quality}) async {
    _reportAtomicMetricsIfNeeded();

    final handler = CompletionHandler();
    final rawMessage = _message.rawMessage;
    if (rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    switch (_message.messageType) {
      case MessageType.image:
        return await _downloadImageMedia(rawMessage, quality);
      case MessageType.video:
        return await _downloadVideoMedia(rawMessage, quality);
      case MessageType.audio:
        return await _downloadAudioMedia(rawMessage);
      case MessageType.file:
        return await _downloadFileMedia(rawMessage);
      default:
        handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
        handler.errorMessage = "Unsupported message type for download";
        return handler;
    }
  }

  Future<CompletionHandler> _downloadImageMedia(V2TimMessage rawMessage, MediaQuality? quality) async {
    final handler = CompletionHandler();
    final imagePayload = _message.messagePayload as ImageMessagePayload?;

    // Determine which image type to download based on quality
    int imageType;
    String? existingPath;
    String prefix;
    switch (quality ?? MediaQuality.original) {
      case MediaQuality.thumbnail:
        imageType = V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_THUMB;
        existingPath = imagePayload?.thumbImagePath;
        prefix = "thumb_";
      case MediaQuality.standard:
        imageType = V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_LARGE;
        existingPath = imagePayload?.largeImagePath;
        prefix = "large_";
      case MediaQuality.original:
        imageType = V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_ORIGIN;
        existingPath = imagePayload?.originalImagePath;
        prefix = "origin_";
    }

    String? uuid;
    for (final image in rawMessage.imageElem?.imageList ?? []) {
      if (image.type == imageType) {
        uuid = image.uuid;
        break;
      }
    }
    if (uuid == null || uuid.isEmpty) uuid = _message.msgID;

    final pathResult = ChatUtil.getActualMediaPath(MessageType.image, existingPath, uuid, prefix);
    final downloadPath =
        pathResult[localExistKey] as bool ? pathResult[filePathKey] as String : pathResult[filePathKey] as String;

    if (pathResult[localExistKey] as bool) {
      _updateImageField(quality, downloadPath);
      _message.downloadMediaProgress = 100;
      _postMessageMediaDownload(quality: quality);

      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().downloadMessage(
          message: rawMessage,
          messageType: MessageElemType.V2TIM_ELEM_TYPE_IMAGE,
          imageType: imageType,
          isSnapshot: false,
          downloadPath: downloadPath,
        );
    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }
    _updateImageField(quality, downloadPath);
    _message.downloadMediaProgress = 100;
    _postMessageMediaDownload(quality: quality);

    return handler;
  }

  void _updateImageField(MediaQuality? quality, String path) {
    if (_message.messagePayload is! ImageMessagePayload) {
      _message.messagePayload = ImageMessagePayload();
    }
    final p = _message.messagePayload as ImageMessagePayload;
    switch (quality ?? MediaQuality.original) {
      case MediaQuality.thumbnail:
        p.thumbImagePath = path;
      case MediaQuality.standard:
        p.largeImagePath = path;
      case MediaQuality.original:
        p.originalImagePath = path;
    }
  }

  Future<CompletionHandler> _downloadVideoMedia(V2TimMessage rawMessage, MediaQuality? quality) async {
    final handler = CompletionHandler();
    final videoPayload = _message.messagePayload as VideoMessagePayload?;

    // For video, quality=thumbnail means snapshot, others mean full video
    if (quality == MediaQuality.thumbnail) {
      var uuid = rawMessage.videoElem?.snapshotUUID;
      if (uuid == null || uuid.isEmpty) uuid = _message.msgID;
      final pathResult = ChatUtil.getActualMediaPath(MessageType.video, videoPayload?.videoSnapshotPath, uuid, null);
      final downloadPath = pathResult[filePathKey] as String;
      if (pathResult[localExistKey] as bool) {
        _updateVideoPayload((p) => p.videoSnapshotPath = downloadPath);
        _message.downloadMediaProgress = 100;
        _postMessageMediaDownload(quality: MediaQuality.thumbnail);

        return handler;
      }
      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().downloadMessage(
            message: rawMessage,
            messageType: MessageElemType.V2TIM_ELEM_TYPE_VIDEO,
            imageType: V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_ORIGIN,
            isSnapshot: true,
            downloadPath: downloadPath,
          );
      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
        return handler;
      }
      _updateVideoPayload((p) => p.videoSnapshotPath = downloadPath);
      _message.downloadMediaProgress = 100;
      _postMessageMediaDownload(quality: MediaQuality.thumbnail);

      return handler;
    } else {
      var uuid = rawMessage.videoElem?.UUID;
      final ext = rawMessage.videoElem?.videoType;
      if (uuid == null || uuid.isEmpty) uuid = _message.msgID;
      final pathResult = ChatUtil.getActualMediaPath(MessageType.video, videoPayload?.videoPath, uuid, ext);
      final downloadPath = pathResult[filePathKey] as String;
      if (pathResult[localExistKey] as bool) {
        _updateVideoPayload((p) => p.videoPath = downloadPath);
        _message.downloadMediaProgress = 100;
        _postMessageMediaDownload(quality: quality);

        return handler;
      }
      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().downloadMessage(
            message: rawMessage,
            messageType: MessageElemType.V2TIM_ELEM_TYPE_VIDEO,
            imageType: V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_ORIGIN,
            isSnapshot: false,
            downloadPath: downloadPath,
          );
      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
        return handler;
      }
      _updateVideoPayload((p) => p.videoPath = downloadPath);
      _message.downloadMediaProgress = 100;
      _postMessageMediaDownload(quality: quality);

      return handler;
    }
  }

  void _updateVideoPayload(void Function(VideoMessagePayload) updater) {
    if (_message.messagePayload is! VideoMessagePayload) {
      _message.messagePayload = VideoMessagePayload();
    }
    updater(_message.messagePayload as VideoMessagePayload);
  }

  Future<CompletionHandler> _downloadAudioMedia(V2TimMessage rawMessage) async {
    final handler = CompletionHandler();
    final audioPayload = _message.messagePayload as AudioMessagePayload?;
    var uuid = rawMessage.soundElem?.UUID;
    if (uuid == null || uuid.isEmpty) uuid = _message.msgID;
    final pathResult = ChatUtil.getActualMediaPath(MessageType.audio, audioPayload?.audioPath, uuid, null);
    final downloadPath = pathResult[filePathKey] as String;
    if (pathResult[localExistKey] as bool) {
      if (_message.messagePayload is! AudioMessagePayload) _message.messagePayload = AudioMessagePayload();
      (_message.messagePayload as AudioMessagePayload).audioPath = downloadPath;
      _message.downloadMediaProgress = 100;
      _postMessageMediaDownload();

      return handler;
    }
    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().downloadMessage(
          message: rawMessage,
          messageType: MessageElemType.V2TIM_ELEM_TYPE_SOUND,
          imageType: V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_ORIGIN,
          isSnapshot: false,
          downloadPath: downloadPath,
        );
    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }
    if (_message.messagePayload is! AudioMessagePayload) _message.messagePayload = AudioMessagePayload();
    (_message.messagePayload as AudioMessagePayload).audioPath = downloadPath;
    _message.downloadMediaProgress = 100;
    _postMessageMediaDownload();

    return handler;
  }

  Future<CompletionHandler> _downloadFileMedia(V2TimMessage rawMessage) async {
    final handler = CompletionHandler();
    final filePayload = _message.messagePayload as FileMessagePayload?;
    var uuid = rawMessage.fileElem?.UUID;
    if (uuid == null || uuid.isEmpty) uuid = _message.msgID;
    final pathResult = ChatUtil.getActualMediaPath(MessageType.file, filePayload?.filePath, uuid, null);
    final downloadPath = pathResult[filePathKey] as String;
    if (pathResult[localExistKey] as bool) {
      if (_message.messagePayload is! FileMessagePayload) _message.messagePayload = FileMessagePayload();
      (_message.messagePayload as FileMessagePayload).filePath = downloadPath;
      _message.downloadMediaProgress = 100;
      _postMessageMediaDownload();

      return handler;
    }
    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().downloadMessage(
          message: rawMessage,
          messageType: MessageElemType.V2TIM_ELEM_TYPE_FILE,
          imageType: V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_ORIGIN,
          isSnapshot: false,
          downloadPath: downloadPath,
        );
    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }
    if (_message.messagePayload is! FileMessagePayload) _message.messagePayload = FileMessagePayload();
    (_message.messagePayload as FileMessagePayload).filePath = downloadPath;
    _message.downloadMediaProgress = 100;
    _postMessageMediaDownload();

    return handler;
  }

  Future<MergedMessageListCompletionHandler> _downloadMergedMessageListInternal() async {
    _reportAtomicMetricsIfNeeded();

    final handler = MergedMessageListCompletionHandler();
    final rawMessage = _message.rawMessage;
    if (rawMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Message not found for operation";
      return handler;
    }

    if (rawMessage.elemType != MessageElemType.V2TIM_ELEM_TYPE_MERGER || rawMessage.mergerElem == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Not a merged message";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().downloadMergerMessage(
          message: rawMessage,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      final messageList = <MessageInfo>[];
      for (final imMessage in result.data!) {
        messageList.add(ChatUtil.convertToUIMessage(imMessage));
      }
      await Future.wait([
        _fillQuoteInfoForMergedMessages(messageList),
        _fillReactionInfoForMergedMessages(messageList),
      ]);
      handler.messageList = messageList;
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }
    return handler;
  }

  Future<void> _fillReactionInfoForMergedMessages(
      List<MessageInfo> messages) async {
    final v2Messages = <V2TimMessage>[];
    for (final message in messages) {
      final raw = message.rawMessage;
      if (raw != null) {
        v2Messages.add(raw);
      }
    }
    if (v2Messages.isEmpty) return;

    final result =
        await TencentImSDKPlugin.v2TIMManager.getMessageManager().getMessageReactions(
              messageList: v2Messages,
              maxUserCountPerReaction: _messageReactionUserCount,
            );
    if (result.code != TIMErrCode.ERR_SUCC.value || result.data == null) return;

    final reactionMap = <String, List<MessageReaction>>{};
    for (final V2TimMessageReactionResult reactionResult in result.data!) {
      if (reactionResult.resultCode != TIMErrCode.ERR_SUCC.value) continue;
      reactionMap[reactionResult.messageID] =
          ChatUtil.convertToMessageReactions(reactionResult.reactionList);
    }
    if (reactionMap.isEmpty) return;

    for (final message in messages) {
      final reactions = reactionMap[message.msgID];
      if (reactions != null) {
        message.reactionList = reactions;
      }
    }
  }

  Future<void> _fillQuoteInfoForMergedMessages(
      List<MessageInfo> messages) async {
    final msgIDsToFind = <String>{};
    final messagesWithQuote = <MessageInfo>[];
    for (final message in messages) {
      final quoteInfo = message.quoteInfo;
      if (quoteInfo != null &&
          quoteInfo.messagePayload == null &&
          quoteInfo.msgID.isNotEmpty) {
        msgIDsToFind.add(quoteInfo.msgID);
        messagesWithQuote.add(message);
      }
    }
    if (msgIDsToFind.isEmpty) return;

    final result =
        await TencentImSDKPlugin.v2TIMManager.getMessageManager().findMessages(
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

    for (final message in messagesWithQuote) {
      final quoteInfo = message.quoteInfo!;
      final foundMessage = foundMap[quoteInfo.msgID];
      if (foundMessage != null) {
        message.quoteInfo =
            _buildFullQuoteInfoForMerged(foundMessage, quoteInfo);
      } else if (quoteInfo.status != MessageStatus.deleted) {
        quoteInfo.status = MessageStatus.deleted;
      }
    }
  }

  MessageQuoteInfo _buildFullQuoteInfoForMerged(
      V2TimMessage foundMessage, MessageQuoteInfo partialInfo) {
    return MessageQuoteInfo(
      msgID: partialInfo.msgID,
      status: ChatUtil.convertToUIMessageStatus(foundMessage),
      timestamp: partialInfo.timestamp,
      sequence: partialInfo.sequence,
      sender: MessageSenderInfo(
        userID: foundMessage.sender ?? '',
        nickname: foundMessage.nickName,
        avatarURL: foundMessage.faceUrl,
        friendRemark: foundMessage.friendRemark,
        nameCard: foundMessage.nameCard,
      ),
      messageType: ChatUtil.getMessageType(foundMessage),
      messagePayload: ChatUtil.getMessagePayload(foundMessage),
    );
  }
}
