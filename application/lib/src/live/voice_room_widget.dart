import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/widget/toast.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import 'package:tencent_live_uikit/voice_room/voice_room_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_store/index.dart';
import '../module_assembly/module_assembly.dart';
import '../utils/language/index.dart';

class VoiceRoomWidget extends StatefulWidget {
  const VoiceRoomWidget({super.key});

  @override
  State<VoiceRoomWidget> createState() => _VoiceRoomWidgetState();
}

class _VoiceRoomWidgetState extends State<VoiceRoomWidget> {
  late double _screenWidth;
  final ValueNotifier<LiveListViewStyle> _liveListStyle =
      ValueNotifier<LiveListViewStyle>(LiveListViewStyle.doubleColumn);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _liveListStyle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Container(
            color: Colors.black,
            width: _screenWidth,
            height: double.infinity,
            child: ValueListenableBuilder<LiveListViewStyle>(
              valueListenable: _liveListStyle,
              builder: (context, liveListStyle, _) {
                final isDoubleColumn = liveListStyle == LiveListViewStyle.doubleColumn;
                return Stack(
                  children: [
                    if (isDoubleColumn) _initAppBarWidget(liveListStyle),
                    Positioned(
                      key: const ValueKey('live_list'),
                      top: isDoubleColumn ? 80 : 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LiveListWidget(
                        style: liveListStyle,
                        onBackPressed: isDoubleColumn ? null : () => Navigator.of(context).pop(),
                        onStyleToggle: isDoubleColumn ? null : _toggleLiveListStyle,
                      ),
                    ),
                    if (isDoubleColumn) _initBroadcastWidget(),
                  ],
                );
              },
            ),
          ),
        ));
  }

  Widget _initAppBarWidget(LiveListViewStyle liveListStyle) {
    return Positioned(
      left: 10,
      top: 40,
      right: 10,
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                AppLocalizations.of(context)!.app_voice,
                style: const TextStyle(
                    fontSize: 18, fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 24,
                    color: Colors.white,
                  )),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _toggleLiveListStyle,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Image.asset(
                      liveListStyle == LiveListViewStyle.doubleColumn
                          ? 'assets/app_live_single_column.png'
                          : 'assets/app_live_double_column.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initBroadcastWidget() {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: SizedBox(
        width: double.infinity,
        height: 80,
        child: Container(
          alignment: Alignment.topCenter,
          child: GestureDetector(
              onTap: () {
                _enterVoiceRoomWidget();
              },
              child: Container(
                width: 154,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFF1C66E5), borderRadius: BorderRadius.circular(24)),
                child: Text(
                  AppLocalizations.of(context)!.app_broadcast('+'),
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              )),
        ),
      ),
    );
  }
}

extension _VoiceRoomWidgetStateLogicExtension on _VoiceRoomWidgetState {
  void _toggleLiveListStyle() {
    _liveListStyle.value = _liveListStyle.value == LiveListViewStyle.doubleColumn
        ? LiveListViewStyle.singleColumn
        : LiveListViewStyle.doubleColumn;
  }

  void _enterVoiceRoomWidget() {
    if (!ModuleAssembly.canStartNewRoom()) {
      makeToast(context, AppLocalizations.of(context)!.app_can_not_start_room_during_call);
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        final roomId = LiveIdentityGenerator.instance.generateId(AppStore.userId, RoomType.voice);
        final params = RoomParams();
        params.maxSeatCount = 10;
        // You can use TUIVoiceRoomWidget, but note that it does not support floating window mode.
        return TUIVoiceRoomOverlay(roomId: roomId, behavior: RoomBehavior.prepareCreate, params: params);
      },
    ));
  }

  void _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }
}
