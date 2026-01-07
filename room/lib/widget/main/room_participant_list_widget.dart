import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/atomicx.dart' hide IconButton;
import 'package:tencent_conference_uikit/base/index.dart';

import 'participant_list/room_member_item_widget.dart';

class RoomParticipantListWidget extends StatefulWidget {
  final String roomId;

  const RoomParticipantListWidget({super.key, required this.roomId});

  @override
  State<RoomParticipantListWidget> createState() => _RoomParticipantListWidgetState();
}

class _RoomParticipantListWidgetState extends State<RoomParticipantListWidget> {
  late final RoomParticipantStore _participantStore;
  late final RoomStore _roomStore;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchKeyword = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
    _roomStore = RoomStore.shared;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchKeyword.dispose();
    super.dispose();
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

extension _RoomMemberListWidgetStatePrivate on _RoomParticipantListWidgetState {
  Widget _buildContent(Orientation orientation) {
    final height = orientation == Orientation.portrait ? 650.height : MediaQuery.of(context).size.height;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: RoomColors.g2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.radius)),
      ),
      child: ValueListenableBuilder(
        valueListenable: _participantStore.state.participantList,
        builder: (context, participantList, _) {
          return ValueListenableBuilder(
            valueListenable: _participantStore.state.localParticipant,
            builder: (context, localParticipant, _) {
              final isOwner = localParticipant?.role == ParticipantRole.owner;
              final isAdmin = localParticipant?.role == ParticipantRole.admin;

              return Column(
                children: [
                  _buildDropDownButton(),
                  SizedBox(height: 10.height),
                  _buildTitle(participantList.length),
                  SizedBox(height: 15.height),
                  _buildMemberList(participantList),
                  SizedBox(height: 15.height),
                  if (isOwner || isAdmin) _buildBottomButtons(isOwner),
                  SizedBox(height: orientation == Orientation.portrait ? 34.height : 22.height),
                ],
              );
            },
          );
        },
      ),
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

  Widget _buildTitle(int memberCount) {
    return ValueListenableBuilder(
      valueListenable: _roomStore.state.currentRoom,
      builder: (context, currentRoom, _) {
        return Container(
          height: 24.height,
          width: MediaQuery.of(context).size.width - 32.width,
          alignment: Alignment.centerLeft,
          child: Text(
            RoomLocalizations.of(context)!
                .roomkit_member_count
                .replaceAll("xxx", (currentRoom?.participantCount ?? 0).toString()),
            style: TextStyle(fontSize: 16, color: RoomColors.g7, fontWeight: FontWeight.w500),
          ),
        );
      },
    );
  }

  Widget _buildMemberList(List<RoomParticipant> participantList) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: _searchKeyword,
        builder: (context, keyword, _) {
          final filteredList = keyword.isEmpty
              ? participantList
              : participantList.where((p) {
                  return p.displayName.toLowerCase().contains(keyword.toLowerCase());
                }).toList();

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: filteredList.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: RoomColors.dividerGrey, indent: 66.width, endIndent: 16.width),
            itemBuilder: (context, index) {
              return RoomMemberItemWidget(roomId: widget.roomId, participant: filteredList[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(bool isOwner) {
    return ValueListenableBuilder(
      valueListenable: _roomStore.state.currentRoom,
      builder: (context, currentRoom, _) {
        final isAllMicMuted = currentRoom?.isAllMicrophoneDisabled ?? false;
        final isAllVideoDisabled = currentRoom?.isAllCameraDisabled ?? false;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.width),
          child: Row(
            children: [
              Expanded(
                child: _buildDynamicButton(
                  text: isAllMicMuted
                      ? RoomLocalizations.of(context)!.roomkit_unmute_all_audio
                      : RoomLocalizations.of(context)!.roomkit_mute_all_audio,
                  onPressed: () => _handleAllMuteAudio(isAllMicMuted),
                  textColor: isAllMicMuted ? Color(0xFFF2504B) : RoomColors.g6,
                ),
              ),
              SizedBox(width: 9.width),
              Expanded(
                child: _buildDynamicButton(
                  text: isAllVideoDisabled
                      ? RoomLocalizations.of(context)!.roomkit_enable_all_video
                      : RoomLocalizations.of(context)!.roomkit_disable_all_video,
                  onPressed: () => _handleAllDisableVideo(isAllVideoDisabled),
                  textColor: isAllVideoDisabled ? RoomColors.exitRed : RoomColors.g6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicButton({required String text, required VoidCallback onPressed, required Color textColor}) {
    return SizedBox(
      height: 40.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(RoomColors.g3),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.radius)),
          ),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14.width, color: textColor),
        ),
      ),
    );
  }

  void _handleAllMuteAudio(bool isCurrentlyMuted) async {
    AtomicAlertDialog.show(
      context,
      title: isCurrentlyMuted
          ? RoomLocalizations.of(context)!.roomkit_msg_all_members_will_be_unmuted
          : RoomLocalizations.of(context)!.roomkit_msg_all_members_will_be_muted,
      content: isCurrentlyMuted
          ? RoomLocalizations.of(context)!.roomkit_msg_members_can_unmute
          : RoomLocalizations.of(context)!.roomkit_msg_members_cannot_unmute,
      confirmText: isCurrentlyMuted
          ? RoomLocalizations.of(context)!.roomkit_confirm_release
          : RoomLocalizations.of(context)!.roomkit_mute_all_audio,
      cancelText: RoomLocalizations.of(context)!.roomkit_cancel,
      onConfirm: () async {
        await _participantStore.disableAllDevices(device: DeviceType.microphone, disable: !isCurrentlyMuted);
      },
    );
  }

  void _handleAllDisableVideo(bool isCurrentlyDisabled) async {
    AtomicAlertDialog.show(
      context,
      title: isCurrentlyDisabled
          ? RoomLocalizations.of(context)!.roomkit_msg_all_members_video_enabled
          : RoomLocalizations.of(context)!.roomkit_msg_all_members_video_disabled,
      content: isCurrentlyDisabled
          ? RoomLocalizations.of(context)!.roomkit_msg_members_can_start_video
          : RoomLocalizations.of(context)!.roomkit_msg_members_cannot_start_video,
      cancelText: RoomLocalizations.of(context)!.roomkit_cancel,
      confirmText: isCurrentlyDisabled
          ? RoomLocalizations.of(context)!.roomkit_confirm_release
          : RoomLocalizations.of(context)!.roomkit_disable_all_video,
      onConfirm: () async {
        await _participantStore.disableAllDevices(device: DeviceType.camera, disable: !isCurrentlyDisabled);
      },
    );
  }
}
