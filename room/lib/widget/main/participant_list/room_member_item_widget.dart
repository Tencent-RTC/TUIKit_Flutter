import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import '../room_participant_manager_widget.dart';

class RoomMemberItemWidget extends StatefulWidget {
  final String roomId;
  final RoomParticipant? participant;
  final RoomUser? audience;

  const RoomMemberItemWidget.participant({super.key, required this.roomId, required RoomParticipant this.participant})
      : audience = null;

  const RoomMemberItemWidget.audience({super.key, required this.roomId, required RoomUser this.audience})
      : participant = null;

  @override
  State<RoomMemberItemWidget> createState() => _RoomMemberItemWidgetState();
}

class _RoomMemberItemWidgetState extends State<RoomMemberItemWidget> {
  late final RoomParticipantStore _participantStore;

  bool get _isParticipant => widget.participant != null;

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isParticipant) {
      return _buildParticipantItem();
    } else {
      return _buildAudienceItem();
    }
  }

  Widget _buildParticipantItem() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _participantStore.state.participantList,
        _participantStore.state.localParticipant,
      ]),
      builder: (context, _) {
        final participants = _participantStore.state.participantList.value;
        final localParticipant = _participantStore.state.localParticipant.value;
        final currentParticipant = participants.firstWhere(
          (p) => p.userID == widget.participant!.userID,
          orElse: () => widget.participant!,
        );
        return _buildParticipantContent(currentParticipant, localParticipant);
      },
    );
  }

  Widget _buildAudienceItem() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _participantStore.state.audienceList,
        _participantStore.state.adminList,
        _participantStore.state.localParticipant,
      ]),
      builder: (context, _) {
        final audienceList = _participantStore.state.audienceList.value;
        final adminList = _participantStore.state.adminList.value;
        final localParticipant = _participantStore.state.localParticipant.value;
        final currentAudience = audienceList.firstWhere(
          (a) => a.userID == widget.audience!.userID,
          orElse: () => widget.audience!,
        );
        final isAdmin = adminList.any((admin) => admin.userID == currentAudience.userID);
        return _buildAudienceContent(currentAudience, isAdmin, localParticipant);
      },
    );
  }
}

extension _RoomMemberItemWidgetStatePrivate on _RoomMemberItemWidgetState {
  Widget _buildParticipantContent(RoomParticipant participant, RoomParticipant? localParticipant) {
    final isLocal = localParticipant?.userID == participant.userID;
    final canControl = _canControlUser(participant, localParticipant, isLocal);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canControl
          ? () {
              popupWidget(
                RoomParticipantManagerWidget(roomId: widget.roomId, participant: participant, parentContext: context),
                backgroundColor: RoomColors.g2,
              );
            }
          : null,
      child: Column(
        children: [
          Container(
            height: 50.height,
            padding: EdgeInsets.symmetric(horizontal: 16.width),
            child: Row(
              children: [
                _buildAvatar(participant.avatarURL),
                SizedBox(width: 12.width),
                Expanded(child: _buildParticipantUserInfo(participant, isLocal)),
                SizedBox(width: 12.width),
                _buildStatusIcons(participant),
              ],
            ),
          ),
          SizedBox(height: 10.height),
        ],
      ),
    );
  }

  Widget _buildAudienceContent(RoomUser audience, bool isAdmin, RoomParticipant? localParticipant) {
    final isLocal = localParticipant?.userID == audience.userID;
    final canControl = _canControlAudience(audience, isAdmin, localParticipant);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canControl
          ? () {
              popupWidget(
                RoomParticipantManagerWidget.audience(
                    roomId: widget.roomId, audience: audience, parentContext: context),
                backgroundColor: RoomColors.g2,
              );
            }
          : null,
      child: Column(
        children: [
          Container(
            height: 50.height,
            padding: EdgeInsets.symmetric(horizontal: 16.width),
            child: Row(
              children: [
                _buildAvatar(audience.avatarURL),
                SizedBox(width: 12.width),
                Expanded(child: _buildAudienceUserInfo(audience, isAdmin, isLocal)),
              ],
            ),
          ),
          SizedBox(height: 10.height),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarURL) {
    return Avatar.image(url: avatarURL, shape: AvatarShape.round);
  }

  Widget _buildParticipantUserInfo(RoomParticipant participant, bool isLocal) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                participant.displayName,
                style: TextStyle(fontSize: 16.width, color: RoomColors.g7, fontWeight: FontWeight.w400),
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
          SizedBox(height: 2.height),
          _buildRoleBadge(participant.role),
        ],
      ],
    );
  }

  Widget _buildAudienceUserInfo(RoomUser audience, bool isAdmin, bool isLocal) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                audience.displayName,
                style: TextStyle(fontSize: 16.width, color: RoomColors.g7, fontWeight: FontWeight.w400),
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
        if (isAdmin) ...[
          SizedBox(height: 2.height),
          _buildRoleBadge(ParticipantRole.admin),
        ],
      ],
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

  Widget _buildStatusIcons(RoomParticipant participant) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (participant.screenShareStatus == DeviceStatus.on && !widget.roomId.isWebinar) ...[
          Image.asset(RoomImages.screenShare, package: RoomConstants.pluginName, width: 20.width, height: 20.height),
          SizedBox(width: 20.width),
        ],
        Image.asset(
          participant.microphoneStatus == DeviceStatus.on ? RoomImages.userMicOn : RoomImages.userMicOff,
          package: RoomConstants.pluginName,
          width: 20.width,
          height: 20.height,
        ),
        if (!widget.roomId.isWebinar) ...[
          SizedBox(width: 20.width),
          Image.asset(
            participant.cameraStatus == DeviceStatus.on ? RoomImages.userCameraOn : RoomImages.userCameraOff,
            package: RoomConstants.pluginName,
            width: 20.width,
            height: 20.height,
          ),
        ],
      ],
    );
  }

  bool _canControlUser(RoomParticipant participant, RoomParticipant? localParticipant, bool isLocal) {
    if (localParticipant == null || isLocal) return false;
    if (localParticipant.role == ParticipantRole.owner) return true;
    if (localParticipant.role == ParticipantRole.admin && participant.role == ParticipantRole.generalUser) {
      return true;
    }
    return false;
  }

  bool _canControlAudience(RoomUser audience, bool isAudienceAdmin, RoomParticipant? localParticipant) {
    if (localParticipant == null) return false;
    if (localParticipant.userID == audience.userID) return false;
    if (localParticipant.role == ParticipantRole.owner) return true;
    if (localParticipant.role == ParticipantRole.admin && !isAudienceAdmin) return true;
    return false;
  }
}
