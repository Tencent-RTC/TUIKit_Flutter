import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:tuikit_atomic_x/atomicx.dart' hide IconButton;

import 'participant_manager/name_card_input_sheet.dart';

class RoomParticipantManagerWidget extends StatefulWidget {
  final String roomId;
  final RoomParticipant? participant;
  final RoomUser? audience;
  final BuildContext? parentContext;

  const RoomParticipantManagerWidget({
    super.key,
    required this.roomId,
    required RoomParticipant this.participant,
    this.parentContext,
  }) : audience = null;

  const RoomParticipantManagerWidget.audience({
    super.key,
    required this.roomId,
    required RoomUser this.audience,
    this.parentContext,
  }) : participant = null;

  @override
  State<RoomParticipantManagerWidget> createState() => _RoomParticipantManagerWidgetState();
}

class _RoomParticipantManagerWidgetState extends State<RoomParticipantManagerWidget> {
  late final RoomParticipantStore _participantStore;
  final _timeout = 30;

  bool get _isParticipant => widget.participant != null;

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Container(
          height: orientation == Orientation.portrait ? null : MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: RoomColors.g2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.radius)),
          ),
          child: _isParticipant ? _buildParticipantContent(orientation) : _buildAudienceContent(orientation),
        );
      },
    );
  }
}

extension _RoomMemberControlWidgetStatePrivate on _RoomParticipantManagerWidgetState {
  Widget _buildParticipantContent(Orientation orientation) {
    return ValueListenableBuilder(
      valueListenable: _participantStore.state.participantList,
      builder: (context, participants, _) {
        final participant = participants.firstWhere(
          (p) => p.userID == widget.participant!.userID,
          orElse: () => widget.participant!,
        );
        return ValueListenableBuilder(
          valueListenable: _participantStore.state.localParticipant,
          builder: (context, localParticipant, _) {
            return _buildParticipantControlPanel(participant, localParticipant, orientation);
          },
        );
      },
    );
  }

  Widget _buildAudienceContent(Orientation orientation) {
    return ValueListenableBuilder(
      valueListenable: _participantStore.state.adminList,
      builder: (context, adminList, _) {
        final isAdmin = adminList.any((admin) => admin.userID == widget.audience!.userID);
        return ValueListenableBuilder(
          valueListenable: _participantStore.state.localParticipant,
          builder: (context, localParticipant, _) {
            return _buildAudienceControlPanel(isAdmin, localParticipant, orientation);
          },
        );
      },
    );
  }

  Widget _buildParticipantControlPanel(
      RoomParticipant participant, RoomParticipant? localParticipant, Orientation orientation) {
    final isLocal = localParticipant?.userID == participant.userID;
    final isOwner = localParticipant?.role == ParticipantRole.owner;
    final isAdmin = localParticipant?.role == ParticipantRole.admin;
    final canManage = isOwner || isAdmin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: orientation == Orientation.landscape ? 20.height : 10.height),
        _buildDropDownButton(),
        _buildUserHeader(
            displayName: participant.displayName,
            avatarURL: participant.avatarURL,
            isLocal: isLocal,
            role: participant.role),
        SizedBox(height: 10.height),
        SizedBox(
          height: orientation == Orientation.landscape ? 295.height : null,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.roomId.isWebinar) ...[
                  _buildSetParticipantControl(userID: participant.userID, isParticipant: true),
                  _buildDivider(),
                ],
                if (!isLocal) ...[
                  _buildAudioControl(participant),
                  _buildDivider(),
                  Visibility(
                    visible: !widget.roomId.isWebinar,
                    child: _buildVideoControl(participant),
                  ),
                  _buildDivider(),
                ],
                if (isOwner && !isLocal) ...[
                  _buildTransferOwnerControl(participant),
                  _buildDivider(),
                  _buildAdminControl(
                      userID: participant.userID,
                      displayName: participant.displayName,
                      isAdmin: participant.role == ParticipantRole.admin),
                  _buildDivider(),
                ],
                if (canManage && !isLocal)
                  _buildKickControl(userID: participant.userID, displayName: participant.displayName),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.height),
      ],
    );
  }

  Widget _buildAudienceControlPanel(bool isAdmin, RoomParticipant? localParticipant, Orientation orientation) {
    final audience = widget.audience!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: orientation == Orientation.landscape ? 20.height : 10.height),
        _buildDropDownButton(),
        _buildUserHeader(
            displayName: audience.displayName,
            avatarURL: audience.avatarURL,
            role: isAdmin ? ParticipantRole.admin : null),
        SizedBox(height: 10.height),
        SizedBox(
          height: orientation == Orientation.landscape ? 295.height : null,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSetParticipantControl(userID: audience.userID, isParticipant: false),
                _buildDivider(),
                _buildKickControl(userID: audience.userID, displayName: audience.displayName),
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

  Widget _buildDivider() {
    return Divider(height: 1, color: RoomColors.dividerGreyWith10Alpha, indent: 16, endIndent: 16);
  }

  Widget _buildUserHeader(
      {required String displayName, required String avatarURL, bool isLocal = false, ParticipantRole? role}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.width),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40.radius,
              height: 40.radius,
              child: Image.network(
                avatarURL,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Image.asset(RoomImages.roomDefaultAvatar, package: RoomConstants.pluginName),
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
                        displayName,
                        style: TextStyle(fontSize: 16.width, color: RoomColors.g7, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLocal) ...[
                      SizedBox(width: 4.width),
                      Text('(${RoomLocalizations.of(context)!.roomkit_me})',
                          style: TextStyle(fontSize: 14.width, color: RoomColors.g7)),
                    ],
                  ],
                ),
                if (role != null && role != ParticipantRole.generalUser) ...[
                  SizedBox(height: 4.height),
                  _buildRoleBadge(role),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(ParticipantRole role) {
    final isOwner = role == ParticipantRole.owner;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          isOwner ? RoomImages.ownerIcon : RoomImages.adminIcon,
          package: RoomConstants.pluginName,
          width: 14.width,
          height: 14.height,
        ),
        SizedBox(width: 2.width),
        Text(
          isOwner
              ? RoomLocalizations.of(context)!.roomkit_role_owner
              : RoomLocalizations.of(context)!.roomkit_role_admin,
          style: TextStyle(fontSize: 12.width, color: isOwner ? RoomColors.b1d : RoomColors.adminOrange),
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
            Text(displayText, style: textStyle ?? TextStyle(fontSize: 16.width, color: RoomColors.white)),
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

  Widget _buildTransferOwnerControl(RoomParticipant participant) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_transfer_owner,
      icon: RoomImages.transferOwner,
      isSelected: false,
      onPressed: () {
        Navigator.of(context).pop();
        _handleTransferOwner(participant);
      },
    );
  }

  Widget _buildAdminControl({required String userID, required String displayName, required bool isAdmin}) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_set_admin,
      selectedText: RoomLocalizations.of(context)!.roomkit_revoke_admin,
      icon: RoomImages.setAdmin,
      isSelected: isAdmin,
      onPressed: () {
        Navigator.of(context).pop();
        _handleAdminControl(userID: userID, displayName: displayName, isAdmin: isAdmin);
      },
    );
  }

  Widget _buildKickControl({required String userID, required String displayName}) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_remove_member,
      icon: RoomImages.roomKickOut,
      isSelected: false,
      textStyle: TextStyle(fontSize: 16.width, color: RoomColors.exitRed),
      onPressed: () {
        Navigator.of(context).pop();
        _handleKick(userID: userID, displayName: displayName);
      },
    );
  }

  Widget _buildSetParticipantControl({required String userID, required bool isParticipant}) {
    return _buildControlItem(
      text: RoomLocalizations.of(context)!.roomkit_set_participant,
      selectedText: RoomLocalizations.of(context)!.roomkit_set_audience,
      icon: RoomImages.setAdmin,
      isSelected: isParticipant,
      onPressed: () {
        Navigator.of(context).pop();
        _handleSetParticipant(userID: userID, isParticipant: isParticipant);
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
      Toast.info(widget.parentContext ?? context,
          RoomLocalizations.of(widget.parentContext ?? context)!.roomkit_toast_audio_invite_sent,
          useRootOverlay: true);
      final result = await _participantStore.inviteToOpenDevice(
          userID: participant.userID, device: DeviceType.microphone, timeout: _timeout);
      if (!result.isSuccess) {
        Toast.info(widget.parentContext ?? context,
            ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
            useRootOverlay: true);
      }
    }
  }

  void _handleVideoControl(RoomParticipant participant) async {
    if (participant.cameraStatus == DeviceStatus.on) {
      await _participantStore.closeParticipantDevice(userID: participant.userID, device: DeviceType.camera);
    } else {
      Toast.info(widget.parentContext ?? context,
          RoomLocalizations.of(widget.parentContext ?? context)!.roomkit_toast_video_invite_sent,
          useRootOverlay: true);
      final result = await _participantStore.inviteToOpenDevice(
          userID: participant.userID, device: DeviceType.camera, timeout: _timeout);
      if (!result.isSuccess) {
        Toast.info(widget.parentContext ?? context,
            ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
            useRootOverlay: true);
      }
    }
  }

  void _handleTransferOwner(RoomParticipant participant) {
    AtomicAlertDialog.show(
      context,
      title: RoomLocalizations.of(context)!.roomkit_msg_transfer_owner_to.replaceAll('xxx', participant.displayName),
      content: '${RoomLocalizations.of(context)!.roomkit_msg_transfer_owner_tip}？',
      confirmText: RoomLocalizations.of(context)!.roomkit_confirm,
      cancelText: RoomLocalizations.of(context)!.roomkit_cancel,
      onConfirm: () async {
        final result = await _participantStore.transferOwner(participant.userID);
        if (result.isSuccess) {
          Toast.success(
              widget.parentContext ?? context,
              RoomLocalizations.of(widget.parentContext ?? context)!
                  .roomkit_toast_owner_transferred
                  .replaceAll('xxx', participant.displayName),
              useRootOverlay: true);
        }
      },
    );
  }

  void _handleAdminControl({required String userID, required String displayName, required bool isAdmin}) async {
    if (isAdmin) {
      final result = await _participantStore.revokeAdmin(userID);
      if (result.isSuccess) {
        Toast.success(
            widget.parentContext ?? context,
            RoomLocalizations.of(widget.parentContext ?? context)!
                .roomkit_toast_admin_revoked
                .replaceAll('xxx', displayName),
            useRootOverlay: true);
      }
    } else {
      final result = await _participantStore.setAdmin(userID);
      if (result.isSuccess) {
        Toast.success(
            widget.parentContext ?? context,
            RoomLocalizations.of(widget.parentContext ?? context)!
                .roomkit_toast_admin_set
                .replaceAll('xxx', displayName),
            useRootOverlay: true);
      }
    }
  }

  void _handleKick({required String userID, required String displayName}) {
    AtomicAlertDialog.show(
      context,
      title: RoomLocalizations.of(context)!.roomkit_remove_member,
      content: RoomLocalizations.of(context)!.roomkit_confirm_remove_member.replaceAll('xxx', displayName),
      confirmText: RoomLocalizations.of(context)!.roomkit_confirm,
      cancelText: RoomLocalizations.of(context)!.roomkit_cancel,
      onConfirm: () async {
        await _participantStore.kickUser(userID);
      },
    );
  }

  void _handleSetParticipant({required String userID, required bool isParticipant}) async {
    CompletionHandler result;
    if (isParticipant) {
      result = await _participantStore.demoteParticipantToAudience(userID);
    } else {
      result = await _participantStore.promoteAudienceToParticipant(userID);
    }

    if (!result.isSuccess && mounted) {
      Toast.error(context, ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage),
          useRootOverlay: true);
    }
  }

  void _handleModifyNameCard() {
    final currentName =
        widget.participant!.nameCard.isEmpty ? widget.participant!.userName : widget.participant!.nameCard;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NameCardInputSheet(currentNameCard: currentName),
    ).then((nameCard) async {
      if (nameCard != null && nameCard is String && nameCard.isNotEmpty) {
        final result =
            await _participantStore.updateParticipantNameCard(userID: widget.participant!.userID, nameCard: nameCard);
        if (!result.isSuccess && mounted) {
          Toast.error(context, ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage));
        }
      }
    });
  }
}
