import 'dart:math';

import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:tencent_conference_uikit/widget/room_main_widget.dart';

class RoomCreateWidget extends StatefulWidget {
  const RoomCreateWidget({super.key});

  @override
  State<RoomCreateWidget> createState() => _RoomCreateWidgetState();
}

class _RoomCreateWidgetState extends State<RoomCreateWidget> {
  final ValueNotifier<bool> _isAudioEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isSpeakerEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isVideoEnabled = ValueNotifier(true);

  final int numberOfDigits = 6;

  @override
  void initState() {
    super.initState();
    RoomStore.shared;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
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
              _buildRoomTypeCard(),
              SizedBox(height: 20),
              _buildFormCard(),
              SizedBox(height: 48),
              _buildCreateButton(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

extension _RoomCreateWidgetStatePrivate on _RoomCreateWidgetState {
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
            RoomLocalizations.of(context)!.roomkit_create_room,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.g2),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(RadiusScheme.largeRadius)),
      child: Padding(
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
                style: const TextStyle(fontSize: 16, color: RoomColors.g2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(RadiusScheme.largeRadius)),
      child: Column(
        children: [
          _buildSwitchItem(
            label: RoomLocalizations.of(context)!.roomkit_enable_audio,
            valueNotifier: _isAudioEnabled,
            onChanged: (value) {
              _isAudioEnabled.value = value;
            },
          ),
          Container(margin: EdgeInsets.symmetric(horizontal: 16), height: 1, color: RoomColors.g8),
          _buildSwitchItem(
            label: RoomLocalizations.of(context)!.roomkit_enable_speaker,
            valueNotifier: _isSpeakerEnabled,
            onChanged: (value) {
              _isSpeakerEnabled.value = value;
            },
          ),
          Container(margin: EdgeInsets.symmetric(horizontal: 16), height: 1, color: RoomColors.g8),
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

  Widget _buildCreateButton() {
    return Center(
      child: GestureDetector(
        onTap: _handleCreateRoomButtonTapped,
        child: Container(
          height: 52.height,
          width: 200.width,
          decoration: BoxDecoration(color: RoomColors.brandBlue, borderRadius: BorderRadius.circular(10.radius)),
          alignment: Alignment.center,
          child: Text(
            RoomLocalizations.of(context)!.roomkit_create_room,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _handleBackButtonTapped() {
    Navigator.of(context).pop();
  }

  void _handleCreateRoomButtonTapped() async {
    final roomID = _getRoomID();
    final loginUser = LoginStore.shared.loginState.loginUserInfo;
    final options = CreateRoomOptions(
      roomName: RoomLocalizations.of(
        context,
      )!
          .roomkit_user_room
          .replaceAll('xxx', loginUser?.nickname ?? loginUser?.userID ?? roomID),
    );
    final behavior = RoomBehavior.create(options);
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

  String _getRoomID() {
    Random random = Random();
    int minNumber = pow(10, numberOfDigits - 1).toInt();
    int maxNumber = pow(10, numberOfDigits).toInt() - 1;
    int randomNumber = random.nextInt(maxNumber - minNumber) + minNumber;
    String roomID = randomNumber.toString();
    return roomID;
  }
}
