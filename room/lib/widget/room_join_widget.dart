import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import 'room_main_widget.dart';

class RoomJoinWidget extends StatefulWidget {
  const RoomJoinWidget({super.key});

  @override
  State<RoomJoinWidget> createState() => _RoomJoinWidgetState();
}

class _RoomJoinWidgetState extends State<RoomJoinWidget> {
  final TextEditingController _roomIdController = TextEditingController();
  final ValueNotifier<bool> _isAudioEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isSpeakerEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isVideoEnabled = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    RoomStore.shared;
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _isAudioEnabled.dispose();
    _isSpeakerEnabled.dispose();
    _isVideoEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.g8,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              SizedBox(height: 5),
              _buildRoomIdCard(),
              SizedBox(height: 20),
              _buildFormCard(),
              SizedBox(height: 48),
              _buildJoinButton(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBackButtonTapped,
            child: Image.asset(
              RoomImages.backArrow,
              width: 16.radius,
              height: 16.radius,
              package: RoomConstants.pluginName,
            ),
          ),
          SizedBox(width: 12),
          Text(
            RoomLocalizations.of(context)!.roomkit_join_room,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.g2),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomIdCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: RoomColors.cardBackground,
        borderRadius: BorderRadius.circular(RadiusScheme.largeRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17.height),
            child: Row(
              children: [
                SizedBox(
                  width: 88.width,
                  child: Text(
                    RoomLocalizations.of(context)!.roomkit_room_id,
                    style: const TextStyle(fontSize: 16, color: RoomColors.g3),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _roomIdController,
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.g2),
                    decoration: InputDecoration(
                      hintText: RoomLocalizations.of(context)!.roomkit_enter_room_id,
                      hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.g6),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(margin: EdgeInsets.symmetric(horizontal: 20), height: 1, color: RoomColors.g8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17.height),
            child: Row(
              children: [
                SizedBox(
                  width: 88.width,
                  child: Text(
                    RoomLocalizations.of(context)!.roomkit_your_name,
                    style: const TextStyle(fontSize: 16, color: RoomColors.g3),
                  ),
                ),
                Expanded(
                  child: Text(
                    LoginStore.shared.loginState.loginUserInfo?.nickname ?? '',
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.g2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: RoomColors.cardBackground,
        borderRadius: BorderRadius.circular(RadiusScheme.largeRadius),
      ),
      child: Column(
        children: [
          _buildSwitchItem(
            label: RoomLocalizations.of(context)!.roomkit_enable_audio,
            valueNotifier: _isAudioEnabled,
            onChanged: (value) {
              _isAudioEnabled.value = value;
            },
          ),
          Container(margin: EdgeInsets.symmetric(horizontal: 20), height: 1, color: RoomColors.g8),
          _buildSwitchItem(
            label: RoomLocalizations.of(context)!.roomkit_enable_speaker,
            valueNotifier: _isSpeakerEnabled,
            onChanged: (value) {
              _isSpeakerEnabled.value = value;
            },
          ),
          Container(margin: EdgeInsets.symmetric(horizontal: 20), height: 1, color: RoomColors.g8),
          _buildSwitchItem(
            label: RoomLocalizations.of(context)!.roomkit_enable_video,
            valueNotifier: _isVideoEnabled,
            onChanged: (value) {
              _isVideoEnabled.value = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required String label,
    required ValueNotifier<bool> valueNotifier,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15.height),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: RoomColors.g3)),
          ValueListenableBuilder(
            valueListenable: valueNotifier,
            builder: (context, value, _) {
              return SizedBox(
                height: 24.height,
                width: 42.width,
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: RoomColors.b1,
                  inactiveTrackColor: RoomColors.g7,
                  inactiveThumbColor: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return Center(
      child: GestureDetector(
        onTap: _handleJoinRoomButtonTapped,
        child: Container(
          width: 200.width,
          height: 52.height,
          decoration: BoxDecoration(color: RoomColors.brandBlue, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(
            RoomLocalizations.of(context)!.roomkit_join_room,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _handleBackButtonTapped() {
    Navigator.of(context).pop();
  }

  void _handleJoinRoomButtonTapped() async {
    final roomID = _roomIdController.text;
    if (roomID.isEmpty) {
      Toast.error(context, RoomLocalizations.of(context)!.roomkit_input_can_not_empty);
      return;
    }
    final behavior = RoomBehavior.enter();
    final config = ConnectConfig(
      autoEnableCamera: _isVideoEnabled.value,
      autoEnableMicrophone: _isAudioEnabled.value,
      autoEnableSpeaker: _isSpeakerEnabled.value,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoomMainWidget(roomID: roomID, behavior: behavior, config: config),
      ),
    );
  }
}
