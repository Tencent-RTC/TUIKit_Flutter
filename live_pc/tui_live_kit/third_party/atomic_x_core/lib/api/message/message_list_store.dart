import 'dart:async';

import 'package:meta/meta.dart';
import 'package:atomic_x_core/api/conversation/conversation_list_store.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:atomic_x_core/api/group/group_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/message/message_input_store.dart';
import 'package:atomic_x_core/impl/message/message_list_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

sealed class MessageEvent {}

class OnReceiveNewMessage extends MessageEvent {
  final MessageInfo message;

  OnReceiveNewMessage({required this.message});
}

abstract class MessageListState {
  ValueListenable<List<MessageInfo>> get messageList;

  ValueListenable<bool> get hasOlderMessages;

  ValueListenable<bool> get hasNewerMessages;

  ValueListenable<List<MessageInfo>> get pinnedMessageList;
}

abstract class MessageListStore {
  static MessageListStore create({required String conversationID}) {
    return MessageListStoreImpl(conversationID: conversationID);
  }

  MessageListState get state;

  Stream<MessageEvent> get messageEventStream;

  Future<CompletionHandler> loadMessages({MessageLoadOption? option});

  Future<CompletionHandler> loadOlderMessages();

  Future<CompletionHandler> loadNewerMessages();

  Future<CompletionHandler> sendMessageReadReceipts({required List<MessageInfo> messageList});

  Future<CompletionHandler> deleteMessages({required List<MessageInfo> messageList});

  Future<CompletionHandler> forwardMessages({
    required List<MessageInfo> messageList,
    required ForwardMessageOption option,
    required String conversationID,
  });
}

class MessageInfo {
  String msgID;
  MessageStatus status;
  int? timestamp; // seconds
  int? sequence;
  MessageSenderInfo from;
  String to;
  bool isSentBySelf;
  ConversationType conversationType;

  MessageType messageType;
  MessagePayload? messagePayload;

  int uploadMediaProgress; // (0-100)
  int downloadMediaProgress; // (0-100)

  List<String> atUserList;
  MessageQuoteInfo? quoteInfo;
  bool isPinned;

  // Message read receipt
  bool needReadReceipt;
  MessageReceipt? readReceiptInfo;

  // Message extension
  bool isExtensionEnabled;
  List<MessageExtension> extensionList;

  // Message reaction
  List<MessageReaction> reactionList;

  // Message revoke
  UserProfile? revokerInfo;
  String? revokeReason;

  // Offline Push Info
  OfflinePushInfo? offlinePushInfo;

  @internal
  V2TimMessage? rawMessage;

  MessageInfo({
    this.msgID = "",
    this.status = MessageStatus.init,
    this.timestamp,
    this.sequence,
    MessageSenderInfo? from,
    this.to = "",
    this.isSentBySelf = false,
    this.conversationType = ConversationType.unknown,
    this.messageType = MessageType.unknown,
    this.messagePayload,
    this.uploadMediaProgress = 0,
    this.downloadMediaProgress = 0,
    this.atUserList = const [],
    this.quoteInfo,
    this.isPinned = false,
    this.needReadReceipt = false,
    this.readReceiptInfo,
    this.isExtensionEnabled = false,
    this.extensionList = const [],
    this.reactionList = const [],
    this.revokerInfo,
    this.revokeReason,
    this.offlinePushInfo,
    this.rawMessage,
  }) : from = from ?? MessageSenderInfo();
}

enum MessageStatus {
  init,
  sending,
  sendSuccess,
  sendFail,
  revoked,
  deleted,
  localImported,
  violation,
}

class MessageSenderInfo {
  String userID;
  String? avatarURL;
  String? nickname;
  String? friendRemark;
  String? nameCard;

  MessageSenderInfo({
    this.userID = "",
    this.avatarURL,
    this.nickname,
    this.friendRemark,
    this.nameCard,
  });
}

enum MessageType {
  unknown,
  text,
  image,
  video,
  audio,
  file,
  face,
  tips,
  custom,
  merged,
  stream,
}

sealed class MessagePayload {
  const MessagePayload();
}

class TextMessagePayload extends MessagePayload {
  String text;
  String? translateLanguage;
  Map<String, String>? translatedText;

  TextMessagePayload({
    this.text = '',
    this.translateLanguage,
    this.translatedText,
  });
}

class ImageMessagePayload extends MessagePayload {
  int originalImageWidth;
  int originalImageHeight;
  int originalImageSize;
  String? originalImagePath;
  String? originalImageURL;
  String? largeImagePath;
  String? largeImageURL;
  String? thumbImagePath;
  String? thumbImageURL;

  ImageMessagePayload({
    this.originalImageWidth = 0,
    this.originalImageHeight = 0,
    this.originalImageSize = 0,
    this.originalImagePath,
    this.originalImageURL,
    this.largeImagePath,
    this.largeImageURL,
    this.thumbImagePath,
    this.thumbImageURL,
  });
}

class VideoMessagePayload extends MessagePayload {
  int videoSnapshotWidth;
  int videoSnapshotHeight;
  String? videoSnapshotPath;
  String? videoSnapshotURL;
  String? videoType;
  int videoSize;
  int videoDuration;
  String? videoPath;
  String? videoURL;

  VideoMessagePayload({
    this.videoSnapshotWidth = 0,
    this.videoSnapshotHeight = 0,
    this.videoSnapshotPath,
    this.videoSnapshotURL,
    this.videoType,
    this.videoSize = 0,
    this.videoDuration = 0,
    this.videoPath,
    this.videoURL,
  });
}

class AudioMessagePayload extends MessagePayload {
  int audioSize;
  int audioDuration;
  String? audioPath;
  String? audioURL;
  String? asrLanguage;
  String? asrText;

  AudioMessagePayload({
    this.audioSize = 0,
    this.audioDuration = 0,
    this.audioPath,
    this.audioURL,
    this.asrLanguage,
    this.asrText,
  });
}

class FileMessagePayload extends MessagePayload {
  String? fileName;
  int fileSize;
  String? filePath;
  String? fileURL;

  FileMessagePayload({
    this.fileName,
    this.fileSize = 0,
    this.filePath,
    this.fileURL,
  });
}

class FaceMessagePayload extends MessagePayload {
  int faceIndex;
  String? faceData;

  FaceMessagePayload({
    this.faceIndex = 0,
    this.faceData,
  });
}

class TipsMessagePayload extends MessagePayload {
  List<GroupTipsInfo>? groupTips;

  TipsMessagePayload({this.groupTips});
}

class CustomMessagePayload extends MessagePayload {
  String customData;
  String? description;
  String? extensionInfo;

  CustomMessagePayload({
    this.customData = '',
    this.description,
    this.extensionInfo,
  });
}

class MergedMessagePayload extends MessagePayload {
  String title;
  List<String>? abstractList;

  MergedMessagePayload({
    this.title = '',
    this.abstractList,
  });
}

class StreamMessagePayload extends MessagePayload {
  String markdown;
  String data;
  bool isStreamEnded;

  StreamMessagePayload({
    this.markdown = '',
    this.data = '',
    this.isStreamEnded = false,
  });
}

sealed class GroupTipsInfo {}

class Unknown extends GroupTipsInfo {}

class JoinGroup extends GroupTipsInfo {
  final GroupMember joinMember;

  JoinGroup({required this.joinMember});
}

class InviteToGroup extends GroupTipsInfo {
  final GroupMember inviter;
  final List<GroupMember> invitees;

  InviteToGroup({required this.inviter, this.invitees = const []});
}

class QuitGroup extends GroupTipsInfo {
  final GroupMember quitMember;

  QuitGroup({required this.quitMember});
}

class KickedFromGroup extends GroupTipsInfo {
  final GroupMember opUser;
  final List<GroupMember> kickedMembers;

  KickedFromGroup({required this.opUser, this.kickedMembers = const []});
}

class SetGroupAdmin extends GroupTipsInfo {
  final GroupMember opUser;
  final List<GroupMember> setAdminMembers;

  SetGroupAdmin({required this.opUser, this.setAdminMembers = const []});
}

class CancelGroupAdmin extends GroupTipsInfo {
  final GroupMember opUser;
  final List<GroupMember> cancelAdminMembers;

  CancelGroupAdmin({required this.opUser, this.cancelAdminMembers = const []});
}

class ChangeGroupName extends GroupTipsInfo {
  final GroupMember opUser;
  final String groupName;

  ChangeGroupName({required this.opUser, required this.groupName});
}

class ChangeGroupAvatar extends GroupTipsInfo {
  final GroupMember opUser;
  final String groupAvatar;

  ChangeGroupAvatar({required this.opUser, required this.groupAvatar});
}

class ChangeGroupNotification extends GroupTipsInfo {
  final GroupMember opUser;
  final String groupNotification;

  ChangeGroupNotification({required this.opUser, required this.groupNotification});
}

class ChangeGroupIntroduction extends GroupTipsInfo {
  final GroupMember opUser;
  final String groupIntroduction;

  ChangeGroupIntroduction({required this.opUser, required this.groupIntroduction});
}

class ChangeGroupOwner extends GroupTipsInfo {
  final GroupMember opUser;
  final String groupOwner;

  ChangeGroupOwner({required this.opUser, required this.groupOwner});
}

class ChangeGroupMuteAll extends GroupTipsInfo {
  final GroupMember opUser;
  final bool isMuteAll;

  ChangeGroupMuteAll({required this.opUser, required this.isMuteAll});
}

class ChangeJoinGroupApproval extends GroupTipsInfo {
  final GroupMember opUser;
  final GroupJoinOption groupJoinOption;

  ChangeJoinGroupApproval({required this.opUser, required this.groupJoinOption});
}

class ChangeInviteToGroupApproval extends GroupTipsInfo {
  final GroupMember opUser;
  final GroupInviteOption groupInviteOption;

  ChangeInviteToGroupApproval({required this.opUser, required this.groupInviteOption});
}

class MuteGroupMember extends GroupTipsInfo {
  final GroupMember opUser;
  final bool isSelfMuted;
  final List<GroupMember> mutedGroupMembers;
  final int muteTime;

  MuteGroupMember({
    required this.opUser,
    required this.isSelfMuted,
    this.mutedGroupMembers = const [],
    required this.muteTime,
  });
}

class PinGroupMessage extends GroupTipsInfo {
  final GroupMember opUser;

  PinGroupMessage({required this.opUser});
}

class UnpinGroupMessage extends GroupTipsInfo {
  final GroupMember opUser;

  UnpinGroupMessage({required this.opUser});
}

class MessageQuoteInfo {
  String msgID;
  MessageStatus status;
  int timestamp;
  int sequence;
  MessageSenderInfo sender;

  MessageType messageType;
  MessagePayload? messagePayload;

  MessageQuoteInfo({
    this.msgID = "",
    this.status = MessageStatus.init,
    this.timestamp = 0,
    this.sequence = 0,
    MessageSenderInfo? sender,
    this.messageType = MessageType.unknown,
    this.messagePayload,
  }) : sender = sender ?? MessageSenderInfo();
}

class MessageReceipt {
  bool isPeerRead;
  int readCount;
  int unreadCount;

  MessageReceipt({
    this.isPeerRead = false,
    this.readCount = 0,
    this.unreadCount = 0,
  });
}

class MessageReaction {
  String reactionID;
  int totalUserCount;
  List<UserProfile> partialUserList;
  bool reactedByMyself;

  MessageReaction({
    required this.reactionID,
    this.totalUserCount = 0,
    this.partialUserList = const [],
    this.reactedByMyself = false,
  });
}

class MessageExtension {
  String? extensionKey;
  String? extensionValue;

  MessageExtension({this.extensionKey, this.extensionValue});
}

class OfflinePushInfo {
  String title;
  String description;
  Map<String, dynamic> extensionInfo;

  OfflinePushInfo({
    this.title = "",
    this.description = "",
    this.extensionInfo = const {},
  });
}

class MessageLoadOption {
  MessageListType messageListType;
  MessageInfo? cursor;
  MessageLoadDirection direction;
  int pageCount;
  List<MessageType> messageTypeList;

  MessageLoadOption({
    this.messageListType = MessageListType.history,
    this.cursor,
    this.direction = MessageLoadDirection.older,
    this.pageCount = 20,
    this.messageTypeList = const [],
  });
}

enum MessageListType {
  history,
  pinned,
}

enum MessageLoadDirection {
  older,
  newer,
  both,
}

class ForwardMessageOption {
  MessageForwardType forwardType;
  MergedForwardInfo? mergedForwardInfo;
  SendMessageOption? sendMessageOption;

  ForwardMessageOption({
    this.forwardType = MessageForwardType.separate,
    this.mergedForwardInfo,
    this.sendMessageOption,
  });
}

enum MessageForwardType {
  separate,
  merged,
}

class MergedForwardInfo {
  String title;
  List<String>? abstractList;
  String compatibleText;

  MergedForwardInfo({
    this.title = "",
    this.abstractList,
    this.compatibleText = "",
  });
}
