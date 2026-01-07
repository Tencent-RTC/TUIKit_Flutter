import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

class ParticipantUserInfoWidget extends StatefulWidget {
  final String roomId;
  final RoomParticipant participant;

  const ParticipantUserInfoWidget({super.key, required this.roomId, required this.participant});

  @override
  State<ParticipantUserInfoWidget> createState() => _ParticipantUserInfoWidgetState();
}

class _ParticipantUserInfoWidgetState extends State<ParticipantUserInfoWidget> {
  late final RoomParticipantStore _participantStore;

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
    _participantStore.state.speakingUsers.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _participantStore.state.speakingUsers.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.participant.role == ParticipantRole.owner;
    final isAdmin = widget.participant.role == ParticipantRole.admin;
    final hasAudio = widget.participant.microphoneStatus == DeviceStatus.on;

    return Container(
      decoration: BoxDecoration(color: RoomColors.translucentLightBlack, borderRadius: BorderRadius.circular(12)),
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Visibility(
            visible: isOwner || isAdmin,
            child: SizedBox(
              width: 24,
              height: 24,
              child: ClipOval(
                child: isOwner
                    ? Image.asset(RoomImages.roomOwner, package: RoomConstants.pluginName)
                    : Image.asset(RoomImages.roomAdministrator, package: RoomConstants.pluginName),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 14,
            height: 14,
            child: Image.asset(
              hasAudio ? RoomImages.roomMicOnEmpty : RoomImages.roomMicOff,
              package: RoomConstants.pluginName,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              widget.participant.displayName,
              style: const TextStyle(color: RoomColors.white, fontSize: 12, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
