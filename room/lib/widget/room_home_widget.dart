import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import 'room_create_widget.dart';
import 'room_join_widget.dart';

class RoomHomeWidget extends StatefulWidget {
  const RoomHomeWidget({super.key});

  @override
  State<RoomHomeWidget> createState() => _RoomHomeWidgetState();
}

class _RoomHomeWidgetState extends State<RoomHomeWidget> {
  final _userName = LoginStore.shared.loginState.loginUserInfo?.nickname ?? "";
  final _userAvatar = LoginStore.shared.loginState.loginUserInfo?.avatarURL ?? "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const Spacer(),
                _buildActionButtons(),
                SizedBox(height: 154.height),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBackButtonTapped,
            child: Image.asset(
              RoomImages.backArrow,
              width: 22.radius,
              height: 22.radius,
              package: RoomConstants.pluginName,
            ),
          ),
          SizedBox(width: 22),
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        Avatar.image(url: _userAvatar),
        SizedBox(width: 12),
        SizedBox(
          width: 200.width,
          child: Text(
            _userName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF676C80)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 56.width),
      child: Column(
        children: [
          _buildActionButton(
            title: RoomLocalizations.of(context)!.roomkit_join_room,
            iconPath: RoomImages.joinRoom,
            onTap: _handleJoinRoomButtonTapped,
          ),
          SizedBox(height: 24),
          _buildActionButton(
            title: RoomLocalizations.of(context)!.roomkit_create_room,
            iconPath: RoomImages.createRoom,
            onTap: _handleCreateRoomButtonTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String title, required String iconPath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54.height,
        decoration: BoxDecoration(
          color: RoomColors.brandBlue,
          borderRadius: BorderRadius.circular(RadiusScheme.smallRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 20.radius,
              height: 20.radius,
              color: Colors.white,
              package: RoomConstants.pluginName,
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackButtonTapped() {
    Navigator.of(context).pop();
  }

  void _handleJoinRoomButtonTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const RoomJoinWidget();
        },
      ),
    );
  }

  void _handleCreateRoomButtonTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const RoomCreateWidget();
        },
      ),
    );
  }
}
