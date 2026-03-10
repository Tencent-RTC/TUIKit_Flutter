import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/atomicx.dart' hide IconButton;
import 'package:tencent_conference_uikit/base/index.dart';

import 'participant_list/room_member_item_widget.dart';

enum ParticipantTab { participant, audience }

class RoomParticipantListWidget extends StatefulWidget {
  final String roomId;

  const RoomParticipantListWidget({super.key, required this.roomId});

  @override
  State<RoomParticipantListWidget> createState() => _RoomParticipantListWidgetState();
}

class _RoomParticipantListWidgetState extends State<RoomParticipantListWidget> {
  late final RoomParticipantStore _participantStore;
  late final RoomStore _roomStore;
  final ValueNotifier<ParticipantTab> _currentTab = ValueNotifier(ParticipantTab.participant);

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
    _roomStore = RoomStore.shared;
  }

  @override
  void dispose() {
    _currentTab.dispose();
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
        valueListenable: _participantStore.state.localParticipant,
        builder: (context, localParticipant, _) {
          final isOwner = localParticipant?.role == ParticipantRole.owner;
          final isAdmin = localParticipant?.role == ParticipantRole.admin;

          return Column(
            children: [
              _buildDropDownButton(),
              SizedBox(height: 10.height),
              if (widget.roomId.isWebinar) ...[
                _buildTabBar(),
              ] else ...[
                _buildTitle(),
              ],
              SizedBox(height: 15.height),
              _buildMemberList(),
              SizedBox(height: 15.height),
              if ((isOwner || isAdmin) && !widget.roomId.isWebinar) _buildBottomButtons(isOwner),
              SizedBox(height: orientation == Orientation.portrait ? 34.height : 22.height),
            ],
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

  Widget _buildTitle() {
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

  Widget _buildTabBar() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _currentTab,
        _roomStore.state.currentRoom,
      ]),
      builder: (context, _) {
        final currentTab = _currentTab.value;
        final participantCount = _roomStore.state.currentRoom.value?.participantCount ?? 0;
        final audienceCount = _roomStore.state.currentRoom.value?.audienceCount ?? 0;

        return Container(
          height: 36.height,
          margin: EdgeInsets.symmetric(horizontal: 16.width),
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: RoomColors.dividerGrey,
            borderRadius: BorderRadius.circular(6.radius),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabItem(
                  title: RoomLocalizations.of(context)!.roomkit_participant.replaceAll('xxx', '$participantCount'),
                  isSelected: currentTab == ParticipantTab.participant,
                  onTap: () => _currentTab.value = ParticipantTab.participant,
                ),
              ),
              Expanded(
                child: _buildTabItem(
                  title: RoomLocalizations.of(context)!.roomkit_audience.replaceAll('xxx', '$audienceCount'),
                  isSelected: currentTab == ParticipantTab.audience,
                  onTap: () => _currentTab.value = ParticipantTab.audience,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? RoomColors.g3 : Colors.transparent,
          borderRadius: BorderRadius.circular(6.radius),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : RoomColors.g6,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: _currentTab,
        builder: (context, currentTab, _) {
          if (currentTab == ParticipantTab.participant) {
            return _buildParticipantListView();
          } else {
            return _buildAudienceListView();
          }
        },
      ),
    );
  }

  Widget _buildParticipantListView() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _participantStore.state.participantList,
        _participantStore.state.localParticipant,
      ]),
      builder: (context, _) {
        final participantList = _participantStore.state.participantList.value;
        final localParticipant = _participantStore.state.localParticipant.value;
        final sortedList = _sortParticipantList(participantList, localParticipant);

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: sortedList.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: RoomColors.dividerGrey, indent: 66.width, endIndent: 16.width),
          itemBuilder: (context, index) {
            return RoomMemberItemWidget.participant(roomId: widget.roomId, participant: sortedList[index]);
          },
        );
      },
    );
  }

  Widget _buildAudienceListView() {
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
        final sortedList = _sortAudienceList(audienceList, adminList, localParticipant);

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: sortedList.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: RoomColors.dividerGrey, indent: 66.width, endIndent: 16.width),
          itemBuilder: (context, index) {
            return RoomMemberItemWidget.audience(roomId: widget.roomId, audience: sortedList[index]);
          },
        );
      },
    );
  }

  List<RoomParticipant> _sortParticipantList(List<RoomParticipant> list, RoomParticipant? localParticipant) {
    final sortedList = List<RoomParticipant>.from(list);
    sortedList.sort((a, b) => _compareParticipants(a, b, localParticipant));
    return sortedList;
  }

  int _compareParticipants(RoomParticipant a, RoomParticipant b, RoomParticipant? localParticipant) {
    int result;

    result = _compareBool(
      localParticipant != null && a.userID == localParticipant.userID,
      localParticipant != null && b.userID == localParticipant.userID,
    );
    if (result != 0) return result;

    result = _compareBool(
      a.role == ParticipantRole.owner,
      b.role == ParticipantRole.owner,
    );
    if (result != 0) return result;

    result = _compareBool(
      a.role == ParticipantRole.admin,
      b.role == ParticipantRole.admin,
    );
    if (result != 0) return result;

    result = _compareBool(
      a.screenShareStatus == DeviceStatus.on,
      b.screenShareStatus == DeviceStatus.on,
    );
    if (result != 0) return result;

    result = _compareBool(
      a.cameraStatus == DeviceStatus.on && a.microphoneStatus == DeviceStatus.on,
      b.cameraStatus == DeviceStatus.on && b.microphoneStatus == DeviceStatus.on,
    );
    if (result != 0) return result;

    result = _compareBool(
      a.cameraStatus == DeviceStatus.on && a.microphoneStatus != DeviceStatus.on,
      b.cameraStatus == DeviceStatus.on && b.microphoneStatus != DeviceStatus.on,
    );
    if (result != 0) return result;

    result = _compareBool(
      a.cameraStatus != DeviceStatus.on && a.microphoneStatus == DeviceStatus.on,
      b.cameraStatus != DeviceStatus.on && b.microphoneStatus == DeviceStatus.on,
    );
    if (result != 0) return result;

    return a.userName.compareTo(b.userName);
  }

  List<RoomUser> _sortAudienceList(List<RoomUser> list, List<RoomUser> adminList, RoomParticipant? localParticipant) {
    final adminIds = adminList.map((e) => e.userID).toSet();
    final sortedList = List<RoomUser>.from(list);
    sortedList.sort((a, b) => _compareAudience(a, b, adminIds, localParticipant));
    return sortedList;
  }

  int _compareAudience(RoomUser a, RoomUser b, Set<String> adminIds, RoomParticipant? localParticipant) {
    final localUserId = localParticipant?.userID;

    if (a.userID == localUserId) return -1;
    if (b.userID == localUserId) return 1;

    final result = _compareBool(
      adminIds.contains(a.userID),
      adminIds.contains(b.userID),
    );
    if (result != 0) return result;

    return a.userName.compareTo(b.userName);
  }

  int _compareBool(bool a, bool b) {
    if (a == b) return 0;
    return a ? -1 : 1;
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
