import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../app_store/index.dart';
import '../call/call_main_widget.dart';
import '../live/index.dart';
import '../mine/me_widget.dart';
import '../utils/language/index.dart';

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  late double _screenWidth;

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = _screenWidth / 2 - 12.width;
    final cardHeight = 106.0.height;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Image.asset(
                'assets/app_tencent_cloud.png',
                width: 30.radius,
                height: 30.radius,
                fit: BoxFit.fitWidth,
              ),
              SizedBox(width: 4.width),
              Text(
                AppLocalizations.of(context)!.app_trtc,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _enterMeWidget(),
                    child: ClipOval(
                      child: Image.network(AppStore.userAvatar, width: 30.radius),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          width: _screenWidth,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.height),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.width),
                child: Row(
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: MenuItemWidget(
                          iconUrl: 'assets/app_call.png',
                          title: AppLocalizations.of(context)!.app_call,
                          description: AppLocalizations.of(context)!.app_call_description,
                          onTap: () => _enterCallWidget(),
                        ),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                    Card(
                      margin: EdgeInsets.zero,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: MenuItemWidget(
                          iconUrl: 'assets/app_video_live.png',
                          title: AppLocalizations.of(context)!.app_live,
                          description: AppLocalizations.of(context)!.app_video_description,
                          onTap: () => _enterLiveWidget(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.height),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.width),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: MenuItemWidget(
                          iconUrl: 'assets/app_conference.png',
                          title: AppLocalizations.of(context)!.app_conference,
                          description: AppLocalizations.of(context)!.app_conference_description,
                          onTap: () => _enterRoomWidget(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  void _enterMeWidget() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const MeWidget();
      },
    ));
  }

  void _enterLiveWidget() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const LiveMainWidget();
      },
    ));
  }

  void _enterRoomWidget() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const RoomHomeWidget();
      },
    ));
  }

  void _enterCallWidget() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const CallMainWidget();
      },
    ));
  }
}

class MenuItemWidget extends StatelessWidget {
  final String iconUrl;
  final String title;
  final String description;
  final void Function()? onTap;

  const MenuItemWidget({super.key, required this.iconUrl, required this.title, required this.description, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10.width),
          child: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFD9E8FE), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter)),
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 16.height, left: 16.width),
                      child: Image.asset(
                        iconUrl,
                        width: 24.radius,
                        height: 24.radius,
                      ),
                    ),
                    SizedBox(width: 6.width),
                    SizedBox(
                      width: 80.width,
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.height),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF262b32),
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    Expanded(child: SizedBox()),
                    Padding(
                      padding: EdgeInsets.only(top: 16.height, right: 16.width),
                      child: Image.asset(
                        'assets/app_arrow.png',
                        width: 16.radius,
                        height: 16.radius,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.height),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.width),
                  child: Text(
                    description,
                    style: const TextStyle(color: Color(0xFF626e84), fontSize: 12),
                  ),
                )
              ],
            ),
          )),
    );
  }
}
