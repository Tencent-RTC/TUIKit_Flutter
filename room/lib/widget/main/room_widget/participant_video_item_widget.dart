import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import 'participant_user_info_widget.dart';

class ParticipantVideoItemWidget extends StatefulWidget {
  final String roomId;
  final RoomParticipant participant;
  final double? width;
  final double? height;
  final bool isScreenStream;
  final double radius;

  const ParticipantVideoItemWidget({
    super.key,
    required this.roomId,
    required this.participant,
    this.width,
    this.height,
    this.isScreenStream = false,
    this.radius = 16,
  });

  @override
  State<ParticipantVideoItemWidget> createState() => _ParticipantVideoItemWidgetState();
}

class _ParticipantVideoItemWidgetState extends State<ParticipantVideoItemWidget> {
  late final RoomParticipantController _controller;
  late final RoomParticipantStore _participantStore;

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
    _controller = RoomParticipantController.create(
      streamType: widget.isScreenStream ? VideoStreamType.screen : VideoStreamType.camera,
      participant: widget.participant,
    );
    _controller.setFillMode(widget.isScreenStream ? FillMode.fit : FillMode.fill);
    _controller.setActive(true);
  }

  @override
  void didUpdateWidget(covariant ParticipantVideoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.participant.userID != oldWidget.participant.userID ||
        widget.isScreenStream != oldWidget.isScreenStream) {
      _controller.updateParticipant(widget.participant);
      _controller.updateStreamType(widget.isScreenStream ? VideoStreamType.screen : VideoStreamType.camera);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _participantStore.state.participantList,
      builder: (context, participantList, _) {
        final currentParticipant = participantList.firstWhere(
          (p) => p.userID == widget.participant.userID,
          orElse: () => widget.participant,
        );
        _controller.updateParticipant(currentParticipant);
        return _buildContent(currentParticipant);
      },
    );
  }

  @override
  void dispose() {
    _controller.setActive(false);
    super.dispose();
  }
}

extension _ParticipantVideoItemWidgetStatePrivate on _ParticipantVideoItemWidgetState {
  Widget _buildContent(RoomParticipant currentParticipant) {
    final hasVideo = widget.isScreenStream
        ? currentParticipant.screenShareStatus == DeviceStatus.on
        : currentParticipant.cameraStatus == DeviceStatus.on;

    return IgnorePointer(
      ignoring: !widget.isScreenStream,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              RoomParticipantWidget(controller: _controller),
              Visibility(
                visible: !hasVideo && !widget.isScreenStream,
                child: Container(color: const Color(0x8022262E)),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Visibility(
                    visible: !widget.isScreenStream && !hasVideo,
                    child: Avatar.image(
                      url: currentParticipant.avatarURL,
                      shape: AvatarShape.round,
                      size: AvatarSize.xxl,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _participantStore.state.speakingUsers,
                builder: (context, speakingUsers, _) {
                  final volume = speakingUsers[widget.participant.userID] ?? 0;
                  final isSpeaking = volume >= 10;
                  return Visibility(
                    visible: isSpeaking && !widget.isScreenStream,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.radius),
                        border: Border.all(color: RoomColors.fluorescentGreen, width: 3),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 4,
                left: 7,
                right: 7,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ParticipantUserInfoWidget(roomId: widget.roomId, participant: currentParticipant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
