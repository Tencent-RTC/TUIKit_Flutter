import 'dart:async';

import 'package:atomic_x_core/api/conversation/conversation_list_store.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/message/message_input_store.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/common/chat_util.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/common/notification_center.dart';
import 'package:atomic_x_core/impl/login/login_store_impl.dart';
import 'package:atomic_x_core/impl/message/message_list_store_impl.dart';
import 'package:meta/meta.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_priority_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/offlinePushInfo.dart' as sdk;
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class MessageSendNotifyKey {
  static const String messageSendBegin = 'message_send_begin';
  static const String messageSendProgress = 'message_send_progress';
  static const String messageSendSuccess = 'message_send_success';
  static const String messageSendFailed = 'message_send_failed';
}

class MessageInsertNotifyKey {
  static const String messageInserted = 'message_inserted';
}

class MessageInputStoreImpl extends MessageInputStore {
  String conversationID;

  MessageInputStoreImpl(this.conversationID);

  @override
  Future<CompletionHandler> sendMessage({
    required SendMessagePayload payload,
    SendMessageOption? option,
  }) async {
    final message = _convertPayloadToMessageInfo(payload, option);
    return await sendMessageInternal(
      message,
      quotedRawMessage: option?.quotedMessage?.rawMessage,
      onlineUserOnly: option?.onlineUserOnly ?? false,
    );
  }

  @override
  Future<CompletionHandler> insertLocalMessage({
    required SendMessagePayload payload,
    String? sender,
  }) async {
    final handler = CompletionHandler();

    final message = _convertPayloadToMessageInfo(payload, null);
    final imMessage = await _createIMMessage(message);
    if (imMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = 'Failed to create im message';
      return handler;
    }

    final receiver = ChatUtil.getUserID(conversationID);
    final groupID = ChatUtil.getGroupID(conversationID);

    final senderID = (sender != null && sender.isNotEmpty)
        ? sender
        : LoginStoreImpl.instance.loginState.loginUserInfo?.userID;
    if (senderID == null || senderID.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = 'sender is empty';
      return handler;
    }

    if (groupID.isEmpty && receiver.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = 'Invalid conversationID: $conversationID';
      return handler;
    }

    final V2TimValueCallback<V2TimMessage> result;
    if (groupID.isNotEmpty) {
      result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().insertGroupMessageToLocalStorageV2(
            message: imMessage,
            groupID: groupID,
            senderID: senderID,
          );
    } else {
      result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().insertC2CMessageToLocalStorageV2(
            message: imMessage,
            userID: receiver,
            senderID: senderID,
          );
    }

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      final insertedRawMessage = result.data ?? imMessage;
      final insertedUIMessage = ChatUtil.convertToUIMessage(insertedRawMessage);
      notificationCenter.post(
        MessageInsertNotifyKey.messageInserted,
        MessageInsertEventData(conversationID: conversationID, message: insertedUIMessage),
      );
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  MessageInfo _convertPayloadToMessageInfo(SendMessagePayload payload, SendMessageOption? option) {
    final message = MessageInfo();

    switch (payload) {
      case TextSendMessagePayload p:
        message.messageType = MessageType.text;
        message.messagePayload = TextMessagePayload(text: p.text);
      case CustomSendMessagePayload p:
        message.messageType = MessageType.custom;
        message.messagePayload =
            CustomMessagePayload(customData: p.customData, description: p.description, extensionInfo: p.extensionInfo);
      case ImageSendMessagePayload p:
        message.messageType = MessageType.image;
        message.messagePayload = ImageMessagePayload(
          originalImagePath: p.imagePath,
          originalImageWidth: p.imageWidth,
          originalImageHeight: p.imageHeight,
        );
      case AudioSendMessagePayload p:
        message.messageType = MessageType.audio;
        message.messagePayload = AudioMessagePayload(audioPath: p.audioFilePath, audioDuration: p.duration);
      case VideoSendMessagePayload p:
        message.messageType = MessageType.video;
        message.messagePayload = VideoMessagePayload(
          videoPath: p.videoFilePath,
          videoType: p.videoType,
          videoDuration: p.duration,
          videoSnapshotPath: p.snapshotPath,
          videoSnapshotWidth: p.snapshotWidth,
          videoSnapshotHeight: p.snapshotHeight,
        );
      case FileSendMessagePayload p:
        message.messageType = MessageType.file;
        message.messagePayload = FileMessagePayload(filePath: p.filePath, fileName: p.fileName, fileSize: p.fileSize);
      case FaceSendMessagePayload p:
        message.messageType = MessageType.face;
        message.messagePayload = FaceMessagePayload(faceIndex: p.index, faceData: p.data);
    }

    if (option != null) {
      message.atUserList = option.atUserList ?? [];
      message.needReadReceipt = option.needReadReceipt;
      message.isExtensionEnabled = option.isExtensionEnabled;
      message.offlinePushInfo = option.offlinePushInfo;

      if (option.quotedMessage != null) {
        final quoted = option.quotedMessage!;
        message.quoteInfo = MessageQuoteInfo(
          msgID: quoted.msgID,
          status: quoted.status,
          timestamp: quoted.timestamp ?? 0,
          sequence: quoted.sequence ?? 0,
          sender: quoted.from,
          messageType: quoted.messageType,
          messagePayload: quoted.messagePayload,
        );
      }
    }

    return message;
  }

  @internal
  Future<CompletionHandler> sendMessageInternal(
    MessageInfo message, {
    V2TimMessage? quotedRawMessage,
    bool onlineUserOnly = false,
  }) async {
    DataReport.reportAtomicMetrics(AtomicMetrics.messageInput);

    final handler = CompletionHandler();

    var imMessage = message.rawMessage;
    imMessage ??= await _createIMMessage(message, quotedRawMessage: quotedRawMessage);

    if (imMessage == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Failed to create im message";
      return handler;
    }

    imMessage.isSupportMessageExtension = message.isExtensionEnabled;

    final receiver = ChatUtil.getUserID(conversationID);
    final groupID = ChatUtil.getGroupID(conversationID);

    // Community groups do not support read receipts
    final correctedNeedReadReceipt = message.needReadReceipt && !ChatUtil.isCommunityGroup(groupID);
    imMessage.needReadReceipt = correctedNeedReadReceipt;

    final imPushInfo = _convertToOfflinePushInfo(message.offlinePushInfo);

    final ConversationType conversationType;
    final String targetID;
    if (groupID.isNotEmpty) {
      conversationType = ConversationType.group;
      targetID = groupID;
    } else if (receiver.isNotEmpty) {
      conversationType = ConversationType.c2c;
      targetID = receiver;
    } else {
      conversationType = ConversationType.unknown;
      targetID = '';
    }

    var copyMessage = message;
    copyMessage.isSentBySelf = true;
    copyMessage.rawMessage = imMessage;
    copyMessage.timestamp = imMessage.timestamp;
    copyMessage.status = MessageStatus.sending;
    copyMessage.to = targetID;
    copyMessage.conversationType = conversationType;
    copyMessage.needReadReceipt = correctedNeedReadReceipt;

    final userInfo = LoginStoreImpl.instance.loginState.loginUserInfo;
    if (userInfo != null) {
      MessageSenderInfo senderInfo = MessageSenderInfo();
      senderInfo.userID = userInfo.userID;
      senderInfo.avatarURL = userInfo.avatarURL;
      senderInfo.nickname = userInfo.nickname;
      copyMessage.from = senderInfo;
      // flutter sdk need set sender
      copyMessage.rawMessage!.sender = userInfo.userID;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
          message: imMessage,
          receiver: receiver,
          groupID: groupID,
          priority: MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
          onlineUserOnly: onlineUserOnly,
          offlinePushInfo: imPushInfo,
          onSyncMsgID: (String syncMsgID) {
            copyMessage.msgID = syncMsgID;
            copyMessage.rawMessage?.msgID = syncMsgID;

            notificationCenter.post(MessageSendNotifyKey.messageSendBegin,
                MessageSendEventData(conversationID: conversationID, message: copyMessage));
          },
        );

    if (result.data != null) {
      copyMessage.rawMessage = result.data;
    }

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      copyMessage.status = MessageStatus.sendSuccess;
      notificationCenter.post(MessageSendNotifyKey.messageSendSuccess,
          MessageSendEventData(conversationID: conversationID, message: copyMessage));
    } else {
      copyMessage.status = MessageStatus.sendFail;
      notificationCenter.post(
          MessageSendNotifyKey.messageSendFailed,
          MessageSendEventData(
              conversationID: conversationID, message: copyMessage, code: result.code, desc: result.desc));

      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  Future<V2TimMessage?> _createIMMessage(
    MessageInfo message, {
    V2TimMessage? quotedRawMessage,
  }) async {
    final payload = message.messagePayload;
    if (payload == null) return null;

    V2TimMessage? imMsg;

    switch (payload) {
      case TextMessagePayload p:
        final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createTextMessage(
              text: p.text,
            );
        imMsg = createResult.data?.messageInfo;
        if (createResult.code == TIMErrCode.ERR_SUCC.value && imMsg != null && message.atUserList.isNotEmpty) {
          final atResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createAtSignedGroupMessage(
                message: imMsg,
                atUserList: message.atUserList,
              );
          if (atResult.code == TIMErrCode.ERR_SUCC.value && atResult.data != null) {
            imMsg = atResult.data;
          } else {
            imMsg = null;
          }
        }

      case ImageMessagePayload p:
        if (p.originalImagePath != null) {
          final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createImageMessage(
                imagePath: p.originalImagePath!,
              );
          imMsg = createResult.data?.messageInfo;
        }

      case AudioMessagePayload p:
        if (p.audioPath != null) {
          final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createSoundMessage(
                soundPath: p.audioPath!,
                duration: p.audioDuration,
              );
          imMsg = createResult.data?.messageInfo;
        }

      case FileMessagePayload p:
        if (p.filePath != null && p.fileName != null) {
          final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createFileMessage(
                filePath: p.filePath!,
                fileName: p.fileName!,
              );
          imMsg = createResult.data?.messageInfo;
        }

      case VideoMessagePayload p:
        if (p.videoPath != null && p.videoSnapshotPath != null && p.videoType != null) {
          final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createVideoMessage(
                videoFilePath: p.videoPath!,
                type: p.videoType!,
                duration: p.videoDuration,
                snapshotPath: p.videoSnapshotPath!,
              );
          imMsg = createResult.data?.messageInfo;
        }

      case FaceMessagePayload p:
        if (p.faceData != null) {
          final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createFaceMessage(
                index: p.faceIndex,
                data: p.faceData!,
              );
          imMsg = createResult.data?.messageInfo;
        }

      case CustomMessagePayload p:
        final createResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createCustomMessage(
              data: p.customData,
              desc: p.description ?? '',
              extension: p.extensionInfo ?? '',
            );
        imMsg = createResult.data?.messageInfo;

      default:
        return null;
    }

    if (imMsg != null && quotedRawMessage != null) {
      final quoteResult = await TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .createQuoteMessage(message: imMsg, quotedMessage: quotedRawMessage);
      if (quoteResult.code == TIMErrCode.ERR_SUCC.value && quoteResult.data != null) {
        imMsg = quoteResult.data;
      }
    }

    return imMsg;
  }

  sdk.OfflinePushInfo? _convertToOfflinePushInfo(OfflinePushInfo? offlinePushInfo) {
    if (offlinePushInfo == null) {
      return null;
    }

    final imPushInfo = sdk.OfflinePushInfo();
    imPushInfo.title = offlinePushInfo.title;
    imPushInfo.desc = offlinePushInfo.description;

    final extensionInfo = offlinePushInfo.extensionInfo;

    // String
    if (extensionInfo['ext'] is String) {
      imPushInfo.ext = extensionInfo['ext'] as String;
    }
    if (extensionInfo['iOSSound'] is String) {
      imPushInfo.iOSSound = extensionInfo['iOSSound'] as String;
    }
    if (extensionInfo['iOSInterruptionLevel'] is String) {
      imPushInfo.iOSInterruptionLevel = extensionInfo['iOSInterruptionLevel'] as String;
    }
    if (extensionInfo['iOSImage'] is String) {
      imPushInfo.iOSImage = extensionInfo['iOSImage'] as String;
    }
    if (extensionInfo['AndroidSound'] is String) {
      imPushInfo.androidSound = extensionInfo['AndroidSound'] as String;
    }
    if (extensionInfo['AndroidOPPOChannelID'] is String) {
      imPushInfo.androidOPPOChannelID = extensionInfo['AndroidOPPOChannelID'] as String;
    }
    if (extensionInfo['AndroidFCMChannelID'] is String) {
      imPushInfo.androidFCMChannelID = extensionInfo['AndroidFCMChannelID'] as String;
    }
    if (extensionInfo['AndroidXiaoMiChannelID'] is String) {
      imPushInfo.androidXiaoMiChannelID = extensionInfo['AndroidXiaoMiChannelID'] as String;
    }
    if (extensionInfo['AndroidVIVOCategory'] is String) {
      imPushInfo.androidVIVOCategory = extensionInfo['AndroidVIVOCategory'] as String;
    }
    if (extensionInfo['AndroidHuaWeiCategory'] is String) {
      imPushInfo.androidHuaWeiCategory = extensionInfo['AndroidHuaWeiCategory'] as String;
    }
    if (extensionInfo['AndroidOPPOCategory'] is String) {
      imPushInfo.androidOPPOCategory = extensionInfo['AndroidOPPOCategory'] as String;
    }
    if (extensionInfo['AndroidHonorImportance'] is String) {
      imPushInfo.androidHonorImportance = extensionInfo['AndroidHonorImportance'] as String;
    }
    if (extensionInfo['AndroidHuaWeiImage'] is String) {
      imPushInfo.androidHuaWeiImage = extensionInfo['AndroidHuaWeiImage'] as String;
    }
    if (extensionInfo['AndroidHonorImage'] is String) {
      imPushInfo.androidHonorImage = extensionInfo['AndroidHonorImage'] as String;
    }
    if (extensionInfo['AndroidFCMImage'] is String) {
      imPushInfo.androidFCMImage = extensionInfo['AndroidFCMImage'] as String;
    }
    if (extensionInfo['HarmonyImage'] is String) {
      imPushInfo.harmonyImage = extensionInfo['HarmonyImage'] as String;
    }
    if (extensionInfo['HarmonyCategory'] is String) {
      imPushInfo.harmonyCategory = extensionInfo['HarmonyCategory'] as String;
    }

    // Bool
    if (extensionInfo['disablePush'] is bool) {
      imPushInfo.disablePush = extensionInfo['disablePush'] as bool;
    }
    if (extensionInfo['ignoreIOSBadge'] is bool) {
      imPushInfo.ignoreIOSBadge = extensionInfo['ignoreIOSBadge'] as bool;
    }
    if (extensionInfo['enableIOSBackgroundNotification'] is bool) {
      imPushInfo.enableIOSBackgroundNotification = extensionInfo['enableIOSBackgroundNotification'] as bool;
    }
    if (extensionInfo['ignoreHarmonyBadge'] is bool) {
      imPushInfo.ignoreHarmonyBadge = extensionInfo['ignoreHarmonyBadge'] as bool;
    }

    // Int
    if (extensionInfo['AndroidVIVOClassification'] is int) {
      imPushInfo.androidVIVOClassification = extensionInfo['AndroidVIVOClassification'] as int;
    }
    if (extensionInfo['AndroidOPPONotifyLevel'] is int) {
      imPushInfo.androidOPPONotifyLevel = extensionInfo['AndroidOPPONotifyLevel'] as int;
    }
    if (extensionInfo['AndroidMeizuNotifyType'] is int) {
      imPushInfo.androidMeizuNotifyType = extensionInfo['AndroidMeizuNotifyType'] as int;
    }
    if (extensionInfo['iOSPushType'] is int) {
      imPushInfo.iOSPushType = extensionInfo['iOSPushType'] as int;
    }

    return imPushInfo;
  }
}
