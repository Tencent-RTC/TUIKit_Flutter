import 'dart:convert';
import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/login/login_store_impl.dart';
import 'package:atomic_x_core/impl/message/message_action_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_add_opt_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_change_info_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_tips_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/image_types.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_status.dart' as sdk_status;
import 'package:tencent_cloud_chat_sdk/enum/receive_message_opt_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/common_utils.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_change_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_tips_elem.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_extension.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_reaction.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_info.dart';

const c2cConversationIDPrefix = "c2c_";
const groupConversationIDPrefix = "group_";

class ChatUtil {
  static String getHomePath({bool isCache = false}) {
    try {
      if (!isCache) {
        var directory = CommonUtils.appFileDir;
        return '${directory.path}/atomicx_core_data';
      } else {
        var directory = CommonUtils.appCacheDir;
        return directory.path;
      }
    } catch (e) {
      return '/tmp/atomicx_core_data';
    }
  }

  static String getMediaHomePath({required MessageType messageType, bool isCache = false}) {
    if (messageType == MessageType.image) {
      return '${getHomePath(isCache: isCache)}${isCache ? "" : "/image"}';
    } else if (messageType == MessageType.video) {
      return '${getHomePath(isCache: isCache)}${isCache ? "" : "/video"}';
    } else if (messageType == MessageType.audio) {
      return '${getHomePath(isCache: isCache)}${isCache ? "" : "/voice"}';
    } else if (messageType == MessageType.file) {
      return '${getHomePath(isCache: isCache)}${isCache ? "" : "/file"}';
    } else {
      return "";
    }
  }

  static String generateMediaPath(
      {required MessageType messageType, String? prefix, String? withExtension, bool isCache = false}) {
    final sdkAppID = LoginStore.shared.sdkAppID;
    final userID = LoginStoreImpl.instance.loginState.loginUserInfo?.userID;
    final uuid = "${DateTime.now().millisecondsSinceEpoch}";

    final mediaHomePath = getMediaHomePath(messageType: messageType, isCache: isCache);

    String prefixString = "";
    if (prefix != null && prefix.isNotEmpty) {
      prefixString = "${prefix}_";
    }

    String suffixString = "";
    if (withExtension != null && withExtension.isNotEmpty) {
      suffixString = ".$withExtension";
    }

    if (messageType == MessageType.image) {
      return "$mediaHomePath/${prefixString}image_${sdkAppID}_${userID ?? ""}_$uuid$suffixString";
    } else if (messageType == MessageType.video) {
      return "$mediaHomePath/${prefixString}video_${sdkAppID}_${userID ?? ""}_$uuid$suffixString";
    } else if (messageType == MessageType.audio) {
      return "$mediaHomePath/${prefixString}sound_${sdkAppID}_${userID ?? ""}_$uuid$suffixString";
    } else if (messageType == MessageType.file) {
      return "$mediaHomePath/${prefixString}file_${sdkAppID}_${userID ?? ""}_$uuid$suffixString";
    }

    return "";
  }

  static String getUserID(String? conversationID) {
    if (conversationID == null || conversationID.isEmpty) {
      return "";
    }

    if (conversationID.startsWith(c2cConversationIDPrefix)) {
      return conversationID.replaceFirst(c2cConversationIDPrefix, "");
    }
    return "";
  }

  static String getGroupID(String? conversationID) {
    if (conversationID == null || conversationID.isEmpty) {
      return "";
    }

    if (conversationID.startsWith(groupConversationIDPrefix)) {
      return conversationID.replaceFirst(groupConversationIDPrefix, "");
    }
    return "";
  }

  static bool isCommunityGroup(String groupID) {
    return groupID.isNotEmpty && groupID.startsWith('@TGS#_');
  }

  static String getMemberShowName(V2TimGroupMemberInfo? info) {
    if (info == null) return "";
    if (info.nameCard != null && info.nameCard!.isNotEmpty) {
      return info.nameCard!;
    } else if (info.nickName != null && info.nickName!.isNotEmpty) {
      return info.nickName!;
    } else {
      return info.userID ?? "";
    }
  }

  static String getMemberShowNameFromTips(V2TimGroupTipsElem? tips, String? userId) {
    if (tips == null || userId == null) return "";
    if (tips.memberList != null) {
      for (var info in tips.memberList!) {
        if (info?.userID == userId) {
          return getMemberShowName(info);
        }
      }
    }
    return "";
  }

  static List<String> getMembersShowName(List<V2TimGroupMemberInfo?>? infoList) {
    if (infoList == null) return [];
    List<String> userNameList = [];
    for (var info in infoList) {
      if (info != null) {
        userNameList.add(getMemberShowName(info));
      }
    }
    return userNameList;
  }

  /// Convert a V2TimGroupMemberInfo to a GroupMember object.
  static GroupMember toGroupMember(V2TimGroupMemberInfo? info) {
    if (info == null) return GroupMember(userID: "");
    return GroupMember(
      userID: info.userID ?? "",
      nickname: info.nickName,
      avatarURL: info.faceUrl,
      nameCard: info.nameCard,
    );
  }

  /// Convert a list of V2TimGroupMemberInfo to a list of GroupMember objects.
  static List<GroupMember> toGroupMemberList(List<V2TimGroupMemberInfo?>? infoList) {
    if (infoList == null) return [];
    return infoList.where((info) => info != null).map((info) => toGroupMember(info)).toList();
  }

  static String getMessageSenderName(MessageInfo? message) {
    if (message == null) return "";
    final rawMessage = message.rawMessage;
    if (rawMessage == null) return "";
    String showName = rawMessage.sender ?? "";
    if (rawMessage.nameCard != null && rawMessage.nameCard!.isNotEmpty) {
      showName = rawMessage.nameCard!;
    } else if (rawMessage.friendRemark != null && rawMessage.friendRemark!.isNotEmpty) {
      showName = rawMessage.friendRemark!;
    } else if (rawMessage.nickName != null && rawMessage.nickName!.isNotEmpty) {
      showName = rawMessage.nickName!;
    }
    return showName;
  }

  static MessageInfo convertToUIMessage(V2TimMessage imMessage) {
    MessageInfo message = MessageInfo();
    message.msgID = imMessage.msgID ?? "";
    message.status = convertToUIMessageStatus(imMessage);

    MessageSenderInfo sender = MessageSenderInfo();
    sender.userID = imMessage.sender ?? "";
    sender.nickname = imMessage.nickName;
    sender.avatarURL = imMessage.faceUrl;
    sender.friendRemark = imMessage.friendRemark;
    sender.nameCard = imMessage.nameCard;
    message.from = sender;

    message.isSentBySelf = imMessage.isSelf ?? false;
    message.to =
        (imMessage.userID != null && imMessage.userID!.isNotEmpty) ? imMessage.userID! : (imMessage.groupID ?? '');
    message.conversationType = (imMessage.groupID != null && imMessage.groupID!.isNotEmpty)
        ? ConversationType.group
        : (imMessage.userID != null && imMessage.userID!.isNotEmpty)
            ? ConversationType.c2c
            : ConversationType.unknown;
    message.timestamp = imMessage.timestamp;
    message.sequence = imMessage.seq != null ? int.tryParse(imMessage.seq!) : null;
    message.needReadReceipt = imMessage.needReadReceipt ?? false;
    message.isExtensionEnabled = imMessage.isSupportMessageExtension ?? false;
    message.atUserList = imMessage.groupAtUserList ?? [];
    message.messageType = getMessageType(imMessage);
    message.messagePayload = getMessagePayload(imMessage);

    // For revoked messages, set revokerInfo/revokeReason on the MessageInfo
    if (message.status == MessageStatus.revoked) {
      applyRevokeInfo(message, imMessage, null, null);
    }

    message.rawMessage = imMessage;

    final v2QuoteInfo = imMessage.quoteInfo;
    if (v2QuoteInfo != null && (v2QuoteInfo.msgID?.isNotEmpty ?? false)) {
      message.quoteInfo = MessageQuoteInfo(
        msgID: v2QuoteInfo.msgID!,
        timestamp: v2QuoteInfo.messageTime ?? 0,
        sequence: v2QuoteInfo.messageSequence ?? 0,
      );
    }

    return message;
  }

  static MessageStatus convertToUIMessageStatus(V2TimMessage imMessage) {
    if (imMessage.hasRiskContent ?? false) {
      return MessageStatus.violation;
    }

    if (imMessage.status != null) {
      switch (imMessage.status) {
        case sdk_status.MessageStatus.V2TIM_MSG_STATUS_SENDING:
          return MessageStatus.sending;
        case sdk_status.MessageStatus.V2TIM_MSG_STATUS_SEND_SUCC:
          return MessageStatus.sendSuccess;
        case sdk_status.MessageStatus.V2TIM_MSG_STATUS_SEND_FAIL:
          return MessageStatus.sendFail;
        case sdk_status.MessageStatus.V2TIM_MSG_STATUS_HAS_DELETED:
          return MessageStatus.deleted;
        case sdk_status.MessageStatus.V2TIM_MSG_STATUS_LOCAL_IMPORTED:
          return MessageStatus.localImported;
        case sdk_status.MessageStatus.V2TIM_MSG_STATUS_LOCAL_REVOKED:
          return MessageStatus.revoked;
        default:
          return MessageStatus.init;
      }
    }

    return MessageStatus.init;
  }

  static MessageType getMessageType(V2TimMessage imMessage) {
    switch (imMessage.elemType) {
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        return MessageType.text;
      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        return MessageType.image;
      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        return MessageType.audio;
      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        return MessageType.file;
      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        return MessageType.video;
      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        return MessageType.face;
      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        return MessageType.custom;
      case MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS:
        return MessageType.tips;
      case MessageElemType.V2TIM_ELEM_TYPE_MERGER:
        return MessageType.merged;
      case MessageElemType.V2TIM_ELEM_TYPE_STREAM:
        return MessageType.stream;
      default:
        return MessageType.unknown;
    }
  }

  static MessagePayload? getMessagePayload(V2TimMessage imMessage) {
    switch (imMessage.elemType) {
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        String? translateLanguage;
        Map<String, String>? translatedText;
        final localCustomData = imMessage.localCustomData;
        if (localCustomData != null && localCustomData.isNotEmpty) {
          final json = jsonData2Dictionary(localCustomData);
          if (json != null) {
            final translatedTextMap = json['text_translation'] as Map<String, dynamic>?;
            if (translatedTextMap != null && translatedTextMap.isNotEmpty) {
              translatedText = translatedTextMap.map((key, value) => MapEntry(key, value.toString()));
            }
            translateLanguage = json['text_translation_language'] as String?;
          }
        }
        return TextMessagePayload(
          text: imMessage.textElem?.text ?? '',
          translateLanguage: translateLanguage,
          translatedText: translatedText,
        );

      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        if (imMessage.imageElem != null) {
          final payload = ImageMessagePayload();

          if (imMessage.imageElem?.imageList != null) {
            for (var image in imMessage.imageElem!.imageList!) {
              if (image?.type == V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_ORIGIN) {
                payload.originalImageSize = image?.size ?? 0;
                payload.originalImageWidth = image?.width ?? 0;
                payload.originalImageHeight = image?.height ?? 0;
                payload.originalImageURL = image?.url;
                final result =
                    getActualMediaPath(MessageType.image, imMessage.imageElem!.path, image?.uuid ?? "", "origin_");
                if (result[localExistKey]) {
                  payload.originalImagePath = result[filePathKey];
                }
              } else if (image?.type == V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_THUMB) {
                payload.thumbImageURL = image?.url;
                final result =
                    getActualMediaPath(MessageType.image, image?.localUrl ?? "", image?.uuid ?? "", "thumb_");
                if (result[localExistKey]) {
                  payload.thumbImagePath = result[filePathKey];
                }
              } else if (image?.type == V2TIM_IMAGE_TYPE.V2TIM_IMAGE_TYPE_LARGE) {
                payload.largeImageURL = image?.url;
                final result =
                    getActualMediaPath(MessageType.image, image?.localUrl ?? "", image?.uuid ?? '', "large_");
                if (result[localExistKey]) {
                  payload.largeImagePath = result[filePathKey];
                }
              }
            }
          }
          return payload;
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        if (imMessage.soundElem != null) {
          String? audioPath;
          final pathResult = getActualMediaPath(
            MessageType.audio,
            imMessage.soundElem!.path,
            imMessage.soundElem!.UUID ?? '',
            null,
          );
          if (pathResult[localExistKey]) {
            audioPath = pathResult[filePathKey];
          }

          String? asrText;
          final localCustomData = imMessage.localCustomData;
          if (localCustomData != null && localCustomData.isNotEmpty) {
            final json = jsonData2Dictionary(localCustomData);
            if (json != null) {
              asrText = json['voice_to_text'] as String?;
            }
          }

          return AudioMessagePayload(
            audioSize: imMessage.soundElem?.dataSize ?? 0,
            audioDuration: imMessage.soundElem?.duration ?? 0,
            audioPath: audioPath,
            audioURL: imMessage.soundElem?.url,
            asrText: asrText,
          );
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        if (imMessage.fileElem != null) {
          String? filePath;
          final pathResult = getActualMediaPath(
            MessageType.file,
            imMessage.fileElem!.path,
            imMessage.fileElem!.UUID ?? '',
            null,
          );
          if (pathResult[localExistKey]) {
            filePath = pathResult[filePathKey];
          }

          return FileMessagePayload(
            fileName: imMessage.fileElem?.fileName,
            fileSize: imMessage.fileElem?.fileSize ?? 0,
            filePath: filePath,
            fileURL: imMessage.fileElem?.url,
          );
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        if (imMessage.videoElem != null) {
          String? videoSnapshotPath;
          final snapshotResult = getActualMediaPath(
            MessageType.video,
            imMessage.videoElem!.snapshotPath,
            imMessage.videoElem!.snapshotUUID ?? '',
            null,
          );
          if (snapshotResult[localExistKey]) {
            videoSnapshotPath = snapshotResult[filePathKey];
          }

          String? videoPath;
          final videoResult = getActualMediaPath(
            MessageType.video,
            imMessage.videoElem!.videoPath,
            imMessage.videoElem!.UUID ?? '',
            null,
          );
          if (videoResult[localExistKey]) {
            videoPath = videoResult[filePathKey];
          }

          return VideoMessagePayload(
            videoSnapshotWidth: imMessage.videoElem?.snapshotWidth ?? 0,
            videoSnapshotHeight: imMessage.videoElem?.snapshotHeight ?? 0,
            videoSnapshotPath: videoSnapshotPath,
            videoSnapshotURL: imMessage.videoElem?.snapshotUrl,
            videoType: imMessage.videoElem?.videoType,
            videoSize: imMessage.videoElem?.videoSize ?? 0,
            videoDuration: imMessage.videoElem?.duration ?? 0,
            videoPath: videoPath,
            videoURL: imMessage.videoElem?.videoUrl,
          );
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        if (imMessage.faceElem != null) {
          return FaceMessagePayload(
            faceIndex: imMessage.faceElem?.index ?? 0,
            faceData: imMessage.faceElem?.data,
          );
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        if (imMessage.customElem != null) {
          return CustomMessagePayload(
            customData: imMessage.customElem!.data ?? '',
            description: imMessage.customElem!.desc ?? '',
            extensionInfo: imMessage.customElem!.extension ?? '',
          );
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS:
        if (imMessage.groupTipsElem != null) {
          return TipsMessagePayload(groupTips: ChatUtil.convertToSystemInfoFromGroupTips(imMessage.groupTipsElem!));
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_MERGER:
        if (imMessage.mergerElem != null) {
          return MergedMessagePayload(
            title: imMessage.mergerElem!.title ?? '',
            abstractList: imMessage.mergerElem!.abstractList,
          );
        }
        break;

      case MessageElemType.V2TIM_ELEM_TYPE_STREAM:
        if (imMessage.streamElem != null) {
          final streamElem = imMessage.streamElem!;
          return StreamMessagePayload(
            markdown: streamElem.markdown ?? '',
            data: streamElem.data ?? '',
            isStreamEnded: streamElem.isStreamEnded ?? false,
          );
        }
        break;

      default:
        return null;
    }

    return null;
  }

  static Map<String, dynamic> getActualMediaPath(
      MessageType messageType, String? mediaPath, String uuid, String? extension) {
    String actualMediaPath = "";
    bool isLocalExist = false;
    final mediaHomePath = ChatUtil.getMediaHomePath(messageType: messageType);

    if (mediaPath != null && mediaPath.isNotEmpty) {
      actualMediaPath = mediaPath;
      if (File(actualMediaPath).existsSync()) {
        isLocalExist = true;
        return {'filePath': actualMediaPath, 'isLocalExist': isLocalExist};
      }
    }

    if (!isLocalExist) {
      if (messageType == MessageType.image) {
        actualMediaPath = "$mediaHomePath/$extension$uuid";
      } else if (messageType == MessageType.file) {
        actualMediaPath = "$mediaHomePath/$uuid";
      } else if (messageType == MessageType.video || messageType == MessageType.audio) {
        actualMediaPath = "$mediaHomePath/$uuid";
      }

      if (File(actualMediaPath).existsSync()) {
        isLocalExist = true;
      }
    }

    return {'filePath': actualMediaPath, 'isLocalExist': isLocalExist};
  }

  static void applyRevokeInfo(
      MessageInfo messageInfo, V2TimMessage rawMessage, V2TimUserFullInfo? operateUser, String? reason) {
    V2TimUserFullInfo revokerRaw;
    if (rawMessage.revokerInfo != null &&
        rawMessage.revokerInfo!.userID != null &&
        rawMessage.revokerInfo!.userID!.isNotEmpty) {
      revokerRaw = rawMessage.revokerInfo!;
    } else if (operateUser != null) {
      revokerRaw = operateUser;
    } else {
      revokerRaw = V2TimUserFullInfo(userID: rawMessage.sender, nickName: rawMessage.nickName);
    }

    messageInfo.revokerInfo = UserProfile(
      userID: revokerRaw.userID ?? '',
      nickname: revokerRaw.nickName,
      avatarURL: revokerRaw.faceUrl,
    );
    messageInfo.revokeReason = reason;
  }

  static List<GroupTipsInfo> convertToSystemInfoFromGroupTips(V2TimGroupTipsElem tipsElem) {
    final opMember = toGroupMember(tipsElem.opMember);
    final memberList = toGroupMemberList(tipsElem.memberList);

    switch (tipsElem.type) {
      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_JOIN:
        // If memberList is not empty, join members are in the list; otherwise, opMember is the joiner
        if (memberList.isNotEmpty) {
          return memberList.map((m) => JoinGroup(joinMember: m)).toList();
        }
        return [JoinGroup(joinMember: opMember)];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_INVITE:
        return [
          InviteToGroup(
            inviter: opMember,
            invitees: memberList,
          )
        ];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_QUIT:
        return [QuitGroup(quitMember: opMember)];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_KICKED:
        return [
          KickedFromGroup(
            opUser: opMember,
            kickedMembers: memberList,
          )
        ];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_SET_ADMIN:
        return [
          SetGroupAdmin(
            opUser: opMember,
            setAdminMembers: memberList,
          )
        ];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_CANCEL_ADMIN:
        return [
          CancelGroupAdmin(
            opUser: opMember,
            cancelAdminMembers: memberList,
          )
        ];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_GROUP_INFO_CHANGE:
        List<V2TimGroupChangeInfo?>? groupChangeInfoList = tipsElem.groupChangeInfoList;
        if (groupChangeInfoList != null) {
          return convertToSystemInfoFromGroupInfoChangedList(opMember, groupChangeInfoList);
        }
        break;

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE:
        if (tipsElem.memberChangeInfoList != null && tipsElem.memberChangeInfoList!.isNotEmpty) {
          final info = tipsElem.memberChangeInfoList!.first;
          final userId = info?.userID;
          final myUserID = LoginStoreImpl.instance.loginState.loginUserInfo?.userID;
          final isSelfMuted = userId == myUserID;
          final muteTime = info?.muteTime ?? 0;

          // Find the muted member from memberList or construct from tips
          GroupMember mutedMember;
          if (memberList.isNotEmpty) {
            mutedMember = memberList.firstWhere(
              (m) => m.userID == userId,
              orElse: () => GroupMember(userID: userId ?? "", nickname: getMemberShowNameFromTips(tipsElem, userId)),
            );
          } else {
            mutedMember = GroupMember(userID: userId ?? "", nickname: getMemberShowNameFromTips(tipsElem, userId));
          }

          return [
            MuteGroupMember(
              opUser: opMember,
              isSelfMuted: isSelfMuted,
              mutedGroupMembers: [mutedMember],
              muteTime: muteTime,
            )
          ];
        }
        break;

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_PINNED_MESSAGE_ADDED:
        return [PinGroupMessage(opUser: opMember)];

      case GroupTipsElemType.V2TIM_GROUP_TIPS_TYPE_PINNED_MESSAGE_DELETED:
        return [UnpinGroupMessage(opUser: opMember)];

      default:
        break;
    }

    return [Unknown()];
  }

  static List<GroupTipsInfo> convertToSystemInfoFromGroupInfoChangedList(
      GroupMember opMember, List<V2TimGroupChangeInfo?> groupChangeInfoList) {
    List<GroupTipsInfo> results = [];

    for (var info in groupChangeInfoList) {
      switch (info?.type) {
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_NAME:
          if (info?.value != null) {
            results.add(ChangeGroupName(
              opUser: opMember,
              groupName: info!.value!,
            ));
          }
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_INTRODUCTION:
          if (info?.value != null) {
            results.add(ChangeGroupIntroduction(
              opUser: opMember,
              groupIntroduction: info!.value!,
            ));
          }
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_NOTIFICATION:
          results.add(ChangeGroupNotification(
            opUser: opMember,
            groupNotification: info?.value ?? "",
          ));
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_FACE_URL:
          results.add(ChangeGroupAvatar(
            opUser: opMember,
            groupAvatar: info?.value ?? "",
          ));
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_OWNER:
          String groupOwner;
          if (info?.value != null) {
            groupOwner = info!.value!;
          } else {
            groupOwner = "";
          }
          results.add(ChangeGroupOwner(
            opUser: opMember,
            groupOwner: groupOwner,
          ));
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_SHUT_UP_ALL:
          results.add(ChangeGroupMuteAll(
            opUser: opMember,
            isMuteAll: info?.boolValue ?? false,
          ));
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_ADD_OPT:
          final addOpt = info?.intValue;
          GroupJoinOption groupJoinOption;
          if (addOpt == GroupAddOptType.V2TIM_GROUP_ADD_FORBID) {
            groupJoinOption = GroupJoinOption.forbid;
          } else if (addOpt == GroupAddOptType.V2TIM_GROUP_ADD_AUTH) {
            groupJoinOption = GroupJoinOption.auth;
          } else if (addOpt == GroupAddOptType.V2TIM_GROUP_ADD_ANY) {
            groupJoinOption = GroupJoinOption.any;
          } else {
            groupJoinOption = GroupJoinOption.any;
          }

          results.add(ChangeJoinGroupApproval(
            opUser: opMember,
            groupJoinOption: groupJoinOption,
          ));
          break;

        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_APPROVE_OPT:
          final addOpt = info?.intValue;
          GroupInviteOption groupInviteOption;
          if (addOpt == GroupAddOptType.V2TIM_GROUP_ADD_FORBID) {
            groupInviteOption = GroupInviteOption.forbid;
          } else if (addOpt == GroupAddOptType.V2TIM_GROUP_ADD_AUTH) {
            groupInviteOption = GroupInviteOption.auth;
          } else if (addOpt == GroupAddOptType.V2TIM_GROUP_ADD_ANY) {
            groupInviteOption = GroupInviteOption.any;
          } else {
            groupInviteOption = GroupInviteOption.any;
          }

          results.add(ChangeInviteToGroupApproval(
            opUser: opMember,
            groupInviteOption: groupInviteOption,
          ));
          break;

        default:
          break;
      }
    }

    return results;
  }

  static dynamic dictionary2JsonData(Map<String, dynamic>? dictionary) {
    if (dictionary == null) return null;
    try {
      return jsonEncode(dictionary);
    } catch (e) {
      if (kDebugMode) {
        print("jsonEncode failed: $e");
      }
      return null;
    }
  }

  static Map<String, dynamic>? jsonData2Dictionary(dynamic jsonData) {
    if (jsonData == null) return null;
    try {
      if (jsonData is String) {
        return jsonDecode(jsonData) as Map<String, dynamic>;
      } else if (jsonData is List<int>) {
        final jsonString = utf8.decode(jsonData);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("jsonEncode failed: $e");
      }
      return null;
    }
  }

  static String? convertDateToHMStr(DateTime? date) {
    if (date == null || date == DateTime.fromMillisecondsSinceEpoch(0)) {
      return null;
    }

    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // MARK: - Message Read Receipt Conversion

  static MessageReceipt convertToMessageReceipt(V2TimMessageReceipt v2Receipt) {
    return MessageReceipt(
      isPeerRead: v2Receipt.isPeerRead ?? false,
      readCount: v2Receipt.readCount ?? 0,
      unreadCount: v2Receipt.unreadCount ?? 0,
    );
  }

  // MARK: - Message Reaction Conversion

  static List<MessageReaction> convertToMessageReactions(List<V2TimMessageReaction>? v2Reactions) {
    if (v2Reactions == null) return [];

    List<MessageReaction> reactions = [];
    for (final v2Reaction in v2Reactions) {
      final reaction = MessageReaction(
        reactionID: v2Reaction.reactionID,
        totalUserCount: v2Reaction.totalUserCount,
        reactedByMyself: v2Reaction.reactedByMyself,
        partialUserList: v2Reaction.partialUserList.map((v2UserInfo) => convertToUserProfile(v2UserInfo)).toList(),
      );
      reactions.add(reaction);
    }
    return reactions;
  }

  // MARK: - Message Extension Conversion

  static List<MessageExtension> convertToMessageExtensions(List<V2TimMessageExtension>? v2Extensions) {
    if (v2Extensions == null) return [];

    return v2Extensions
        .map((ext) => MessageExtension(
              extensionKey: ext.extensionKey,
              extensionValue: ext.extensionValue,
            ))
        .toList();
  }

  // MARK: - User Profile Conversion

  static UserProfile convertToUserProfile(V2TimUserInfo v2UserInfo) {
    return UserProfile(
      userID: v2UserInfo.userID,
      nickname: v2UserInfo.nickName,
      avatarURL: v2UserInfo.faceUrl,
    );
  }

  static UserProfile convertToUserFullProfile(V2TimUserFullInfo v2UserInfo) {
    return UserProfile(
      userID: v2UserInfo.userID ?? "",
      nickname: v2UserInfo.nickName,
      avatarURL: v2UserInfo.faceUrl,
      gender: convertToGender(v2UserInfo.gender),
      birthday: v2UserInfo.birthday,
      level: v2UserInfo.level,
      role: v2UserInfo.role,
      selfSignature: v2UserInfo.selfSignature,
      allowType: _convertToAllowType(v2UserInfo.allowType),
      customInfo: v2UserInfo.customInfo,
    );
  }

  static Gender convertToGender(int? gender) {
    if (gender == null) return Gender.unknown;
    switch (gender) {
      case 1:
        return Gender.male;
      case 2:
        return Gender.female;
      default:
        return Gender.unknown;
    }
  }

  static int convertGenderToInt(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 1; // V2TIM_GENDER_MALE
      case Gender.female:
        return 2; // V2TIM_GENDER_FEMALE
      case Gender.unknown:
        return 0; // V2TIM_GENDER_UNKNOWN
    }
  }

  static AllowType? _convertToAllowType(int? allowType) {
    if (allowType == null) return null;
    switch (allowType) {
      case 0:
        return AllowType.allowAny;
      case 1:
        return AllowType.needConfirm;
      case 2:
        return AllowType.denyAny;
      default:
        return AllowType.allowAny;
    }
  }

  // MARK: - Group Join Option Conversion

  static GroupJoinOption convertGroupAddOptToJoinOption(int? groupAddOpt) {
    switch (groupAddOpt) {
      case GroupAddOptType.V2TIM_GROUP_ADD_FORBID:
        return GroupJoinOption.forbid;
      case GroupAddOptType.V2TIM_GROUP_ADD_AUTH:
        return GroupJoinOption.auth;
      case GroupAddOptType.V2TIM_GROUP_ADD_ANY:
        return GroupJoinOption.any;
      default:
        return GroupJoinOption.forbid;
    }
  }

  static GroupInviteOption convertApproveOptToInviteOption(int? approveOpt) {
    switch (approveOpt) {
      case GroupAddOptType.V2TIM_GROUP_ADD_FORBID:
        return GroupInviteOption.forbid;
      case GroupAddOptType.V2TIM_GROUP_ADD_AUTH:
        return GroupInviteOption.auth;
      case GroupAddOptType.V2TIM_GROUP_ADD_ANY:
        return GroupInviteOption.any;
      default:
        return GroupInviteOption.forbid;
    }
  }

  // MARK: - Group Member Conversion

  static GroupMember convertToGroupMember(V2TimGroupMemberInfo v2Member) {
    return GroupMember(
      userID: v2Member.userID ?? "",
      nickname: v2Member.nickName,
      avatarURL: v2Member.faceUrl,
      nameCard: v2Member.nameCard,
      friendRemark: v2Member.friendRemark,
    );
  }

  static ReceiveMessageOption convertToReceiveMessageOpt(int v2Opt) {
    switch (v2Opt) {
      case 0: // V2TIM_RECEIVE_MESSAGE
        return ReceiveMessageOption.receive;
      case 1: // V2TIM_NOT_RECEIVE_MESSAGE
        return ReceiveMessageOption.notReceive;
      case 2: // V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE
        return ReceiveMessageOption.notNotify;
      case 3: // V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT
        return ReceiveMessageOption.notNotifyExceptMention;
      case 4: // V2TIM_NOT_RECEIVE_MESSAGE_EXCEPT_AT
        return ReceiveMessageOption.notReceiveExceptMention;
      default:
        return ReceiveMessageOption.receive;
    }
  }

  static ReceiveMsgOptEnum convertToV2TIMReceiveMessageOpt(ReceiveMessageOption opt) {
    switch (opt) {
      case ReceiveMessageOption.receive:
        return ReceiveMsgOptEnum.V2TIM_RECEIVE_MESSAGE;
      case ReceiveMessageOption.notReceive:
        return ReceiveMsgOptEnum.V2TIM_NOT_RECEIVE_MESSAGE;
      case ReceiveMessageOption.notNotify:
        return ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE;
      case ReceiveMessageOption.notNotifyExceptMention:
        return ReceiveMsgOptEnum.V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT;
      case ReceiveMessageOption.notReceiveExceptMention:
        return ReceiveMsgOptEnum.V2TIM_NOT_RECEIVE_MESSAGE_EXCEPT_AT;
    }
  }
}
