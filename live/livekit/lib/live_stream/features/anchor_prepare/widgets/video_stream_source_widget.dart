import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/live_define.dart';

class VideoStreamSourceWidget extends StatefulWidget {
  final ValueChanged<VideoStreamSource>? videoStreamSourceChanged;

  const VideoStreamSourceWidget({super.key, required this.videoStreamSourceChanged});

  @override
  State<StatefulWidget> createState() => _VideoStreamSourceWidgetState();
}

class _VideoStreamSourceWidgetState extends State<VideoStreamSourceWidget> {
  int _currentLiveTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabItem(
            index: 0,
            title: LiveKitLocalizations.of(Global.appContext())!.common_preview_video_live,
          ),
          SizedBox(width: 32.width),
          _buildTabItem(
            index: 1,
            title: LiveKitLocalizations.of(Global.appContext())!.common_game_live,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String title}) {
    final isSelected = _currentLiveTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentLiveTabIndex = index;
          VideoStreamSource videoStreamSource = VideoStreamSource.camera;
          if (index == 1) {
            videoStreamSource = VideoStreamSource.screenShare;
          }
          widget.videoStreamSourceChanged?.call(videoStreamSource);
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? LiveColors.designStandardFlowkitWhite : LiveColors.designStandardG6,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          SizedBox(height: 4.height),
          Container(
            height: 2.height,
            width: 24.width,
            decoration: BoxDecoration(
              color: isSelected ? LiveColors.designStandardFlowkitWhite : Colors.transparent,
              borderRadius: BorderRadius.circular(1.radius),
            ),
          ),
        ],
      ),
    );
  }
}
