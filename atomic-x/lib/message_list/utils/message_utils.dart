import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

import 'calling_message_data_provider.dart';

class MessageUtil {
  static String getSystemInfoDisplayString(List<SystemMessageInfo> systemMessages, BuildContext context) {
    if (systemMessages.isEmpty) {
      return '';
    }

    List<String> displayStrings = [];
    for (SystemMessageInfo systemMessage in systemMessages) {
      String displayString = getSingleSystemInfoDisplayString(systemMessage, context);
      if (displayString.isNotEmpty) {
        displayStrings.add(displayString);
      }
    }

    return displayStrings.join(',');
  }

  static String getSingleSystemInfoDisplayString(SystemMessageInfo systemMessage, BuildContext context) {
    return switch (systemMessage) {
      UnknownSystemMessage() => AtomicLocalizations.of(context).unknown,
      RecallMessageSystemMessage() => getRevokeDisplayString(systemMessage, context),
      JoinGroupSystemMessage() => getJoinGroupDisplayString(systemMessage, context),
      InviteToGroupSystemMessage() => getInviteToGroupDisplayString(systemMessage, context),
      QuitGroupSystemMessage() => getQuitGroupDisplayString(systemMessage, context),
      KickedFromGroupSystemMessage() => getKickedFromGroupDisplayString(systemMessage, context),
      SetGroupAdminSystemMessage() => getSetGroupAdminDisplayString(systemMessage, context),
      CancelGroupAdminSystemMessage() => getCancelGroupAdminDisplayString(systemMessage, context),
      ChangeGroupNameSystemMessage() => getChangeGroupNameDisplayString(systemMessage, context),
      ChangeGroupAvatarSystemMessage() => getChangeGroupAvatarDisplayString(systemMessage, context),
      ChangeGroupNotificationSystemMessage() => getChangeGroupNotificationDisplayString(systemMessage, context),
      ChangeGroupIntroductionSystemMessage() => getChangeGroupIntroductionDisplayString(systemMessage, context),
      ChangeGroupOwnerSystemMessage() => getChangeGroupOwnerDisplayString(systemMessage, context),
      ChangeGroupMuteAllSystemMessage() => getChangeGroupMuteAllDisplayString(systemMessage, context),
      ChangeJoinGroupApprovalSystemMessage() => getChangeJoinGroupApprovalDisplayString(systemMessage, context),
      ChangeInviteToGroupApprovalSystemMessage() => getChangeInviteToGroupApprovalDisplayString(systemMessage, context),
      MuteGroupMemberSystemMessage() => getMuteGroupMemberDisplayString(systemMessage, context),
      PinGroupMessageSystemMessage() => getPinGroupMessageDisplayString(systemMessage, context),
      UnpinGroupMessageSystemMessage() => getUnpinGroupMessageDisplayString(systemMessage, context),
    };
  }

  static String getRevokeDisplayString(RecallMessageSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations? localizations = AtomicLocalizations.of(context);
    String content = '';

    String reason = systemMessage.recallReason;
    if (systemMessage.isRecalledBySelf) {
      content = localizations.messageRevokedBySelf;
    } else {
      if (systemMessage.isInGroup) {
        String recallOperator = systemMessage.recallMessageOperator;
        content = localizations.messageRevokedByUser(recallOperator);
      } else {
        content = localizations.messageRevokedByOther;
      }
    }

    if (reason.isNotEmpty) {
      content = '$content: $reason';
    }

    return content;
  }

  static String getJoinGroupDisplayString(JoinGroupSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupMemberJoined(systemMessage.joinMember);
  }

  static String getInviteToGroupDisplayString(InviteToGroupSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupMemberInvited(systemMessage.inviter, systemMessage.inviteesShowName);
  }

  static String getQuitGroupDisplayString(QuitGroupSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupMemberQuit(systemMessage.quitMember);
  }

  static String getKickedFromGroupDisplayString(KickedFromGroupSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupMemberKicked(systemMessage.kickOperator, systemMessage.kickedMembersShowName);
  }

  static String getSetGroupAdminDisplayString(SetGroupAdminSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupAdminSet(systemMessage.setAdminMembersShowName);
  }

  static String getCancelGroupAdminDisplayString(CancelGroupAdminSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupAdminCancelled(systemMessage.cancelAdminMembersShowName);
  }

  static String getMuteGroupMemberDisplayString(MuteGroupMemberSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    int muteTime = systemMessage.muteTime;
    String memberShowName = systemMessage.mutedGroupMembersShowName;
    bool isSelfMuted = systemMessage.isSelfMuted;
    String actualShowName = isSelfMuted ? localizations.you : memberShowName;

    if (muteTime == 0) {
      final action = localizations.unmuted;
      return "$actualShowName $action";
    } else {
      final action = localizations.muted;
      final duration = formatMuteTime(muteTime, context);
      return "$actualShowName $action$duration";
    }
  }

  static String getPinGroupMessageDisplayString(PinGroupMessageSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupMessagePinned(systemMessage.pinGroupMessageOperator);
  }

  static String getUnpinGroupMessageDisplayString(UnpinGroupMessageSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return localizations.groupMessageUnpinned(systemMessage.unpinGroupMessageOperator);
  }

  static String getChangeGroupNameDisplayString(ChangeGroupNameSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return '${systemMessage.groupNameOperator} ${localizations.groupNameChangedTo} ${systemMessage.groupName}';
  }

  static String getChangeGroupAvatarDisplayString(ChangeGroupAvatarSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return '${systemMessage.groupAvatarOperator} ${localizations.groupAvatarChanged}';
  }

  static String getChangeGroupNotificationDisplayString(
      ChangeGroupNotificationSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    String operator = systemMessage.groupNotificationOperator;
    String groupNotice = systemMessage.groupNotification;
    if (groupNotice.isNotEmpty) {
      return '$operator ${localizations.groupNoticeChangedTo} $groupNotice';
    } else {
      return '$operator ${localizations.groupNoticeDeleted}';
    }
  }

  static String getChangeGroupIntroductionDisplayString(
      ChangeGroupIntroductionSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    String operator = systemMessage.groupIntroductionOperator;
    String groupIntroduction = systemMessage.groupIntroduction;
    if (groupIntroduction.isNotEmpty) {
      return '$operator ${localizations.groupIntroChangedTo} $groupIntroduction';
    } else {
      return '$operator ${localizations.groupIntroDeleted}';
    }
  }

  static String getChangeGroupOwnerDisplayString(ChangeGroupOwnerSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    return '${systemMessage.groupOwnerOperator} ${localizations.groupOwnerTransferredTo} ${systemMessage.groupOwner}';
  }

  static String getChangeGroupMuteAllDisplayString(
      ChangeGroupMuteAllSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    String operator = systemMessage.groupMuteAllOperator;
    bool isMuteAll = systemMessage.isMuteAll;
    return '$operator ${isMuteAll ? localizations.groupMuteAllEnabled : localizations.groupMuteAllDisabled}';
  }

  static String getChangeJoinGroupApprovalDisplayString(
      ChangeJoinGroupApprovalSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    String operator = systemMessage.groupJoinApprovalOperator;
    String approvalDesc;
    switch (systemMessage.groupJoinOption) {
      case GroupJoinOption.forbid:
        approvalDesc = localizations.groupJoinForbidden;
        break;
      case GroupJoinOption.auth:
        approvalDesc = localizations.groupJoinApproval;
        break;
      case GroupJoinOption.any:
        approvalDesc = localizations.groupJoinFree;
        break;
    }
    return '$operator ${localizations.groupJoinMethodChangedTo} $approvalDesc';
  }

  static String getChangeInviteToGroupApprovalDisplayString(
      ChangeInviteToGroupApprovalSystemMessage systemMessage, BuildContext context) {
    AtomicLocalizations localizations = AtomicLocalizations.of(context);
    String operator = systemMessage.groupInviteApprovalOperator;
    String approvalDesc;
    switch (systemMessage.groupInviteOption) {
      case GroupJoinOption.forbid:
        approvalDesc = localizations.groupInviteForbidden;
        break;
      case GroupJoinOption.auth:
        approvalDesc = localizations.groupInviteApproval;
        break;
      case GroupJoinOption.any:
        approvalDesc = localizations.groupInviteFree;
        break;
    }
    return '$operator ${localizations.groupInviteMethodChangedTo} $approvalDesc';
  }

  static String getMessageAbstract(MessageInfo? messageInfo, BuildContext context, {bool showMergedTitle = false}) {
    if (messageInfo == null) return '';

    if (!context.mounted) {
      return '';
    }

    AtomicLocalizations? localizations = AtomicLocalizations.of(context);

    switch (messageInfo.messageType) {
      case MessageType.text:
        return messageInfo.messageBody?.text ?? '';

      case MessageType.image:
        return localizations.messageTypeImage;

      case MessageType.sound:
        return localizations.messageTypeVoice;

      case MessageType.file:
        return localizations.messageTypeFile;

      case MessageType.video:
        return localizations.messageTypeVideo;

      case MessageType.face:
        return localizations.messageTypeSticker;

      case MessageType.custom:
        final customMessage = messageInfo.messageBody?.customMessage;
        if (customMessage == null) {
          return localizations.messageTypeCustom;
        }

        CallingMessageDataProvider provider = CallingMessageDataProvider(messageInfo, context);
        if (provider.isCallingSignal) {
          return provider.content;
        }

        final customInfo = ChatUtil.jsonData2Dictionary(customMessage.data);
        if (customInfo != null && customInfo['businessID'] == 'group_create') {
          final sender = customInfo['opUser'] ?? '';
          final cmd = customInfo['cmd'] is int ? customInfo['cmd'] : 0;
          if (cmd == 1) {
            return '$sender ${localizations.createCommunity}';
          } else {
            return '$sender ${localizations.createGroupTips}';
          }
        }

        return localizations.messageTypeCustom;

      case MessageType.system:
        return getSystemInfoDisplayString(messageInfo.messageBody?.systemMessage ?? [], context);

      case MessageType.merged:
        if (showMergedTitle) {
          final title = messageInfo.messageBody?.mergedMessage?.title;
          if (title != null && title.isNotEmpty) {
            return title;
          }
        }
        return '[${localizations.chatHistory}]';

      default:
        return '';
    }
  }

  static String formatMuteTime(int seconds, BuildContext context) {
    if (seconds <= 0) return '';

    if (!context.mounted) {
      return '';
    }

    AtomicLocalizations localizations = AtomicLocalizations.of(context);

    String timeStr = '$seconds${localizations.second}';

    if (seconds > 60) {
      int second = seconds % 60;
      int min = seconds ~/ 60;
      timeStr = '$min${localizations.min}$second${localizations.second}';

      if (min > 60) {
        min = (seconds ~/ 60) % 60;
        int hour = (seconds ~/ 60) ~/ 60;
        timeStr = '$hour${localizations.hour}$min${localizations.min}$second${localizations.second}';

        if (hour % 24 == 0) {
          int day = ((seconds ~/ 60) ~/ 60) ~/ 24;
          timeStr = '$day${localizations.day}';
        } else if (hour > 24) {
          hour = ((seconds ~/ 60) ~/ 60) % 24;
          int day = ((seconds ~/ 60) ~/ 60) ~/ 24;
          timeStr =
              '$day${localizations.day}$hour${localizations.hour}$min${localizations.min}$second${localizations.second}';
        }
      }
    }

    return timeStr;
  }

  static bool isSystemStyleCustomMessage(MessageInfo message, BuildContext context) {
    if (message.messageType == MessageType.custom) {
      try {
        final customMessage = message.messageBody?.customMessage?.data;
        final customInfo = ChatUtil.jsonData2Dictionary(customMessage);
        if (customInfo != null) {
          if (customInfo['businessID'] == 'group_create') {
            return true;
          }

          final callingProvider = CallingMessageDataProvider(message, context);
          if (callingProvider.isCallingSignal && callingProvider.participantType == CallParticipantType.group) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('isSystemStyleCustomMessage error: $e');
      }
    }

    return false;
  }
}
