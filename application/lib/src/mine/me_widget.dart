import 'dart:io';

import 'package:application/src/utils/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_live_uikit/common/widget/global.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import '../app_store/index.dart';
import '../login/index.dart';
import 'log_file_browser.dart';
import 'update_nickname_widget.dart';

class MeWidget extends StatefulWidget {
  const MeWidget({super.key});

  @override
  State<MeWidget> createState() => _MeWidgetState();
}

class _MeWidgetState extends State<MeWidget> {
  late double _screenWidth;

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: Colors.white,
      width: _screenWidth,
      child: Stack(
        children: [
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTitleWidget(),
                SizedBox(height: context.adapter.getHeight(20)),
                _buildUserAvatarWidget(),
                _buildUserNameWidget(),
                SizedBox(height: context.adapter.getHeight(10)),
                _buildLogWidget(),
                SizedBox(height: context.adapter.getHeight(10)),
                // _buildLogoutWidget()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleWidget() {
    return Row(
      children: [
        IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Image.asset('assets/app_back.png',
                width: context.adapter.getWidth(20), height: context.adapter.getWidth(20))),
        Spacer(),
        Text(AppLocalizations.of(context)!.app_self_center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(width: context.adapter.getWidth(162))
      ],
    );
  }

  Widget _buildUserAvatarWidget() {
    return Container(
        margin: const EdgeInsets.only(top: 27),
        child: GestureDetector(
          onTap: () => _showDialog(),
          child: Container(
              width: 100,
              height: 100,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(27.5)),
              ),
              child: ClipOval(
                child: Image(
                  image: NetworkImage(AppStore.userAvatar.isNotEmpty ? AppStore.userAvatar : AppStore.defaultAvatar),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stackTrace) => Image.asset('assets/people.webp'),
                ),
              )),
        ));
  }

  Widget _buildUserNameWidget() {
    return Container(
        margin: const EdgeInsets.only(top: 16),
        child: GestureDetector(
          onTap: () {
            _showUpdateNicknameWidget();
          },
          child: ValueListenableBuilder(
            valueListenable: AppStore.userName,
            builder: (BuildContext context, String value, Widget? child) {
              return Text(
                AppStore.userName.value.isNotEmpty ? AppStore.userName.value : AppStore.userId,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF0F1014)),
              );
            },
          ),
        ));
  }

  void _showFileBrowser() async {
    Directory? startDirectory;
    if (Platform.isIOS) {
      startDirectory = await getApplicationDocumentsDirectory();
    } else {
      startDirectory = await getExternalStorageDirectory();
    }
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) {
          return LogFileBrowser(startDirectory: startDirectory);
        },
      ));
    }
  }

  Widget _buildLogWidget() {
    return SizedBox(
      width: _screenWidth - 20,
      height: 60,
      child: GestureDetector(
        onTap: () => _showFileBrowser(),
        child: Card(
            color: Colors.white,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.app_log,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            )),
      ),
    );
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(AppLocalizations.of(context)!.app_logout),
            actions: [
              CupertinoDialogAction(
                child: Text(AppLocalizations.of(context)!.app_cancel),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoDialogAction(
                child: Text(AppLocalizations.of(context)!.app_confirm),
                onPressed: () => _logout(context),
              ),
            ],
          );
        });
  }
}

extension _MeWidgetStateLogicExtension on _MeWidgetState {
  void _showUpdateNicknameWidget() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white,
        ),
        child: const UpdateNicknameWidget(),
      ),
    );
  }

  void _logout(BuildContext context) {
    GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    Future.delayed(const Duration(milliseconds: 500), () {
      TUIRoomEngine.logout().then((result) {
        TUILogin.instance.logout(TUICallback(onSuccess: () {}));
      });
    });
    Navigator.of(context).pop();
    NavigatorState navigatorState = Global.secondaryNavigatorKey.currentState ?? Navigator.of(context);
    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (widget) => const LoginWidget()),
      (route) => false,
    );
  }
}
