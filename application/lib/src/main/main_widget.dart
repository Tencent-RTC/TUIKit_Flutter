import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../app_store/index.dart';
import '../call/call_main_widget.dart';
import '../live/index.dart';
import '../mine/me_widget.dart';
import '../utils/language/index.dart';
import '../utils/screen/screen_adapter.dart';

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
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.adapter.getWidth(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      child: SizedBox(
                        width: 165.width,
                        child: MenuItemWidget(
                          iconUrl: 'assets/app_video_live.png',
                          title: AppLocalizations.of(context)!.app_video,
                          description: AppLocalizations.of(context)!.app_video_description,
                          onTap: () => _enterLiveWidget(),
                        ),
                      ),
                    ),
                    Card(
                      child: SizedBox(
                        width: 165.width,
                        child: MenuItemWidget(
                          iconUrl: 'assets/app_call.png',
                          title: AppLocalizations.of(context)!.app_call,
                          description: AppLocalizations.of(context)!.app_call_description,
                          onTap: () => _enterCallWidget(),
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
                      width: 60.width,
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.height),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF262b32),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.height, left: 16.width),
                        child: Image.asset(
                          'assets/app_arrow.png',
                          width: 16.radius,
                          height: 16.radius,
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20.height),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.width),
                  child: Text(
                    description,
                    style: const TextStyle(color: Color(0xFF626e84)),
                  ),
                )
              ],
            ),
          )),
    );
  }
}
