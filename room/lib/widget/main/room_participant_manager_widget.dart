import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:tuikit_atomic_x/atomicx.dart' hide IconButton;

import 'participant_manager/name_card_input_sheet.dart';

class RoomParticipantManagerWidget extends StatefulWidget {
  final String roomId;
  final RoomParticipant participant;
  final BuildContext? parentContext;

  const RoomParticipantManagerWidget({super.key, required this.roomId, required this.participant, this.parentContext});

  @override
  State<RoomParticipantManagerWidget> createState() => _RoomParticipantManagerWidgetState();
}

class _RoomParticipantManagerWidgetState extends State<RoomParticipantManagerWidget> {
  late final RoomParticipantStore _participantStore;
  final _timeout = 30;

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return _buildContent(orientation);
      },
    );
  }
}

extension _RoomMemberControlWidgetStatePrivate on _RoomParticipantManagerWidgetState {
  Widget _buildContent(Orientation orientation) {
    return Container(
      height: orientation == Orientation.portrait ? null : MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: RoomColors.g2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.radius)),
      ),
      child: ValueListenableBuilder(
        valueListenable: _participantStore.state.participantList,
        builder: (context, participants, _) {
          final currentParticipant = participants.firstWhere(
            (p) => p.userID == widget.participant.userID,
            orElse: () => widget.participant,
          );

          return ValueListenableBuilder(
            valueListenable: _participantStore.state.localParticipant,
            builder: (context, localParticipant, _) {
              return _buildControlPanel(currentParticipant, localParticipant, orientation);
            },
          );
        },
      ),
    );
  }

  Widget _buildControlPanel(RoomParticipant participant, RoomParticipant? localParticipant, Orientation orientation) {
    final isLocal = localParticipant?.userID == participant.userID;
    final isOwner = localParticipant?.role == ParticipantRole.owner;
    final isAdmin = localParticipant?.role == ParticipantRole.admin;
    final canManage = isOwner || isAdmin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: orientation == Orientation.landscape ? 20.height : 10.height),
        _buildDropDownButton(),
        _buildUserHeader(participant, isLocal),
        SizedBox(height: 10.height),
        SizedBox(
          height: orientation == Orientation.landscape ? 295.height : null,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // if (isLocal) _buildModifyNameCardControl(),
                if (!isLocal) ...[
                  _buildAudioControl(participant),
                  Divider(height: 1, color: RoomColors.dividerGreyWith10Alpha, indent: 16, endIndent: 16),
                  _buildVideoControl(participant),
                  Divider(height: 1, color: RoomColors.dividerGreyWith10Alpha, indent: 16, endIndent: 16),
                ],
                if (isOwner && !isLocal) ...[
                  _buildTransferOwnerControl(),
                  Divider(height: 1, color: RoomColors.dividerGreyWith10Alpha, indent: 16, endIndent: 16),
                  _buildAdministratorControl(participant),
                  Divider(height: 1, color: RoomColors.dividerGreyWith10Alpha, indent: 16, endIndent: 16),
                ],
                if (canManage && !isLocal) ...[
                  // _buildModifyNameCardControl(),
                  // Divider(height: 3, thickness: 3, color: RoomColors.dividerGreyWith20Alpha),
                  // _buildMessageControl(participant),
                  // Divider(height: 1, color: RoomColors.dividerGreyWith10Alpha, indent: 16, endIndent: 16),
                  _buildKickControl(),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 20.height),
      ],
    );
  }

  Widget _buildDropDownButton() {
    return SizedBox(
      height: 35.height,
      width: double.infinity,
      child: IconButton(
        icon: Image.asset(RoomImages.roomLine, package: RoomConstants.pluginName, width: 24.width, height: 24.height),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildUserHeader(RoomParticipant participant, bool isLocal) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.width),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40.radius,
              height: 40.radius,
              child: Image.network(
                participant.avatarURL,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(RoomImages.roomDefaultAvatar, package: RoomConstants.pluginName);
                },
              ),
            ),
          ),
          SizedBox(width: 12.width),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.displayName,
                        style: TextStyle(fontSize: 16.width, color: RoomColors.g7, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLocal) ...[
                      SizedBox(width: 4.width),
                      Text(
                        '(${RoomLocalizations.of(context)!.roomkit_me})',
                        style: TextStyle(fontSize: 14.width, color: RoomColors.g7),
                      ),
                    ],
                  ],
                ),
                if (participant.role != ParticipantRole.generalUser) ...[
                  SizedBox(height: 4.height),
                  _buildRoleBadge(participant.role),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(ParticipantRole role) {
    final text = role == ParticipantRole.owner
        ? RoomLocalizations.of(context)!.roomkit_role_owner
        : RoomLocalizations.of(context)!.roomkit_role_admin;
    final icon = role == ParticipantRole.owner ? RoomImages.ownerIcon : RoomImages.adminIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, package: RoomConstants.pluginName, width: 14.width, height: 14.height),
        SizedBox(width: 2.width),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.width,
            color: role == ParticipantRole.owner ? RoomColors.b1d : RoomColors.adminOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildControlItem({
    required String text,
    String? selectedText,
    required VoidCallback onPressed,
    required bool isSelected,
    String? icon,
    String? selectedIcon,
    TextStyle? textStyle,
  }) {
    final displayText = isSelected && selectedText != null ? selectedText : text;
    final displayIcon = isSelected && selectedIcon != null ? selectedIcon : icon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: 50.height,
        padding: EdgeInsets.symmetric(horizontal: 16.width),
        child: Row(
          children: [
            if (displayIcon != null) ...[
              Image.asset(displayIcon, package: RoomConstants.pluginName, width: 20.width, height: 20.height),
              SizedBox(width: 12.width),
            ],
            Text(
              displayText,
              style: textStyle ?? TextStyle(fontSize: 16.width, color: RoomColors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControl(RoomParticipant participant) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_request_unmute_audio,
      selectedText: RoomLocalizations.of(context)!.roomkit_mute,
      isSelected: participant.microphoneStatus == DeviceStatus.on,
      icon: RoomImages.roomMicOff,
      selectedIcon: RoomImages.unmuteAudio,
      onPressed: () {
        Navigator.of(context).pop();
        _handleAudioControl(participant);
      },
    );
  }

  Widget _buildVideoControl(RoomParticipant participant) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_request_start_video,
      selectedText: RoomLocalizations.of(context)!.roomkit_stop_video,
      isSelected: participant.cameraStatus == DeviceStatus.on,
      icon: RoomImages.roomCameraOff,
      selectedIcon: RoomImages.roomCameraOn,
      onPressed: () {
        Navigator.of(context).pop();
        _handleVideoControl(participant);
      },
    );
  }

  Widget _buildTransferOwnerControl() {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_transfer_owner,
      icon: RoomImages.transferOwner,
      isSelected: false,
      onPressed: () {
        Navigator.of(context).pop();
        _handleTransferOwner();
      },
    );
  }

  Widget _buildAdministratorControl(RoomParticipant participant) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_set_admin,
      selectedText: RoomLocalizations.of(context)!.roomkit_revoke_admin,
      icon: RoomImages.setAdmin,
      isSelected: participant.role == ParticipantRole.admin,
      onPressed: () {
        Navigator.of(context).pop();
        _handleAdministratorControl(participant);
      },
    );
  }

  // ignore: unused_element
  Widget _buildMessageControl(RoomParticipant participant) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_unmute_text_chat,
      selectedText: RoomLocalizations.of(context)!.roomkit_mute_text_chat,
      icon: RoomImages.roomEnableMessage,
      selectedIcon: RoomImages.roomDisableMessage,
      isSelected: !participant.isMessageDisabled,
      onPressed: () {
        Navigator.of(context).pop();
        _handleMessageControl(participant);
      },
    );
  }

  Widget _buildKickControl() {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_remove_member,
      icon: RoomImages.roomKickOut,
      isSelected: false,
      textStyle: TextStyle(fontSize: 16.width, color: RoomColors.exitRed),
      onPressed: () {
        Navigator.of(context).pop();
        _handleKick();
      },
    );
  }

  // ignore: unused_element
  Widget _buildModifyNameCardControl() {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_modify_name,
      icon: RoomImages.roomModifyNameCard,
      isSelected: false,
      onPressed: () {
        Navigator.of(context).pop();
        _handleModifyNameCard();
      },
    );
  }

  void _handleAudioControl(RoomParticipant participant) async {
    if (participant.microphoneStatus == DeviceStatus.on) {
      await _participantStore.closeParticipantDevice(userID: participant.userID, device: DeviceType.microphone);
    } else {
      Toast.info(
        widget.parentContext ?? context,
        RoomLocalizations.of(widget.parentContext ?? context)!.roomkit_toast_audio_invite_sent,
        useRootOverlay: true,
      );
      final result = await _participantStore.inviteToOpenDevice(
        userID: participant.userID,
        device: DeviceType.microphone,
        timeout: 30,
      );
      if (!result.isSuccess) {
        Toast.info(
          widget.parentContext ?? context,
          ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
          useRootOverlay: true,
        );
      }
    }
  }

  void _handleVideoControl(RoomParticipant participant) async {
    if (participant.cameraStatus == DeviceStatus.on) {
      await _participantStore.closeParticipantDevice(userID: participant.userID, device: DeviceType.camera);
    } else {
      Toast.info(
        widget.parentContext ?? context,
        RoomLocalizations.of(widget.parentContext ?? context)!.roomkit_toast_video_invite_sent,
        useRootOverlay: true,
      );
      final result = await _participantStore.inviteToOpenDevice(
        userID: participant.userID,
        device: DeviceType.camera,
        timeout: _timeout,
      );
      if (!result.isSuccess) {
        Toast.info(
          widget.parentContext ?? context,
          ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
          useRootOverlay: true,
        );
      }
    }
  }

  void _handleTransferOwner() async {
    AtomicAlertDialog.show(
      context,
      title: RoomLocalizations.of(
        context,
      )!
          .roomkit_msg_transfer_owner_to
          .replaceAll('xxx', widget.participant.displayName),
      content: '${RoomLocalizations.of(context)!.roomkit_msg_transfer_owner_tip}？',
      confirmText: RoomLocalizations.of(context)!.roomkit_confirm,
      cancelText: RoomLocalizations.of(context)!.roomkit_cancel,
      onConfirm: () async {
        final result = await _participantStore.transferOwner(widget.participant.userID);
        if (result.isSuccess) {
          Toast.info(
            widget.parentContext ?? context,
            RoomLocalizations.of(
              widget.parentContext ?? context,
            )!
                .roomkit_toast_owner_transferred
                .replaceAll('xxx', widget.participant.displayName),
            useRootOverlay: true,
          );
        }
      },
    );
  }

  void _handleAdministratorControl(RoomParticipant participant) async {
    if (participant.role == ParticipantRole.admin) {
      final result = await _participantStore.revokeAdmin(participant.userID);
      if (result.isSuccess) {
        Toast.info(
          widget.parentContext ?? context,
          RoomLocalizations.of(
            widget.parentContext ?? context,
          )!
              .roomkit_toast_admin_revoked
              .replaceAll('xxx', participant.displayName),
          useRootOverlay: true,
        );
      }
    } else {
      final result = await _participantStore.setAdmin(participant.userID);
      if (result.isSuccess) {
        Toast.info(
          widget.parentContext ?? context,
          RoomLocalizations.of(
            widget.parentContext ?? context,
          )!
              .roomkit_toast_admin_set
              .replaceAll('xxx', participant.displayName),
          useRootOverlay: true,
        );
      }
    }
  }

  void _handleMessageControl(RoomParticipant participant) async {
    await _participantStore.disableUserMessage(userID: participant.userID, disable: !participant.isMessageDisabled);
  }

  void _handleKick() {
    AtomicAlertDialog.show(
      context,
      title: RoomLocalizations.of(context)!.roomkit_remove_member,
      content: RoomLocalizations.of(
        context,
      )!
          .roomkit_confirm_remove_member
          .replaceAll('xxx', widget.participant.displayName),
      confirmText: RoomLocalizations.of(context)!.roomkit_confirm,
      cancelText: RoomLocalizations.of(context)!.roomkit_cancel,
      onConfirm: () async {
        await _participantStore.kickUser(widget.participant.userID);
      },
    );
  }

  void _handleModifyNameCard() {
    final currentName = widget.participant.nameCard.isEmpty ? widget.participant.userName : widget.participant.nameCard;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NameCardInputSheet(currentNameCard: currentName),
    ).then((nameCard) async {
      if (nameCard != null && nameCard is String && nameCard.isNotEmpty) {
        final result = await _participantStore.updateParticipantNameCard(
          userID: widget.participant.userID,
          nameCard: nameCard,
        );
        if (!result.isSuccess && mounted) {
          Toast.error(context, ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage));
        }
      }
    });
  }
}
