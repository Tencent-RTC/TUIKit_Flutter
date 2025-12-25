import 'package:application/src/live/voice_room_widget.dart';
import 'package:application/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import 'video_live_widget.dart';

class LiveMainWidget extends StatefulWidget {
  const LiveMainWidget({super.key});

  @override
  State<LiveMainWidget> createState() => _LiveMainWidgetState();
}

class _LiveMainWidgetState extends State<LiveMainWidget> {
  late double _screenWidth;

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Container(
              padding: EdgeInsets.only(left: context.adapter.getWidth(80)),
              child: Text(AppLocalizations.of(context)!.app_video, textAlign: TextAlign.center)),
        ),
        body: Container(
          color: Colors.white,
          width: _screenWidth,
          height: double.infinity,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: SizedBox(
                    width: _screenWidth,
                    child: MenuItemWidget(
                      iconUrl: 'assets/app_main_item_video_live.png',
                      title: AppLocalizations.of(context)!.app_video,
                      description: AppLocalizations.of(context)!.app_live_content,
                      onTap: () => _enterVideoLiveWidget(),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: SizedBox(
                    width: _screenWidth,
                    child: MenuItemWidget(
                      iconUrl: 'assets/app_main_item_voice_room.png',
                      title: AppLocalizations.of(context)!.app_voice,
                      description: AppLocalizations.of(context)!.app_voice_content,
                      onTap: () => _enterVoiceRoomWidget(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  void _enterVideoLiveWidget() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const VideoLiveWidget();
      },
    ));
  }

  void _enterVoiceRoomWidget() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const VoiceRoomWidget();
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
            child: Stack(
              children: [
                Image.asset(iconUrl),
                Column(
                  children: [
                    SizedBox(height: 8),
                    Text(title,
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16),
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        width: 180,
                        child: Text(description, style: TextStyle(color: Colors.white, fontSize: 12)))
                  ],
                )
              ],
            ),
          )),
    );
  }
}
