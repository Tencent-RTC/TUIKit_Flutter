import 'dart:async';

import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../../state/co_guest_state.dart';

class CoGuestWaitingAgreeWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const CoGuestWaitingAgreeWidget({
    super.key,
    required this.liveStreamManager,
  });

  @override
  State<CoGuestWaitingAgreeWidget> createState() => _CoGuestWaitingAgreeWidgetState();
}

class _CoGuestWaitingAgreeWidgetState extends State<CoGuestWaitingAgreeWidget> {
  final ValueNotifier<String> _text = ValueNotifier<String>("");
  int _index = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.liveStreamManager.coGuestState.coGuestStatus,
      builder: (BuildContext context, coGuestStatus, _) {
        return Visibility(
          visible: coGuestStatus == CoGuestStatus.applying,
          child: GestureDetector(
            onTap: _showCancelRequestPanelWidget,
            child: Container(
              width: 86.width,
              height: 86.width,
              decoration: BoxDecoration(
                color: LiveColors.designStandardG2,
                border: Border.all(color: LiveColors.notStandardWhite20Transparency, width: 1.width),
                borderRadius: BorderRadius.all(Radius.circular(10.radius)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 14.height),
                  _buildUserAvatarWidget(),
                  SizedBox(height: 6.height),
                  _buildWaitingAgreeTextWidget(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatarWidget() {
    return Container(
      width: 40.width,
      height: 40.width,
      decoration: BoxDecoration(
        color: LiveColors.designStandardG2,
        borderRadius: BorderRadius.circular(18.radius),
      ),
      child: ClipOval(
        child: Image.network(
          TUIRoomEngine.getSelfInfo().avatarUrl ?? "",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              LiveImages.defaultAvatar,
              package: Constants.pluginName,
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingAgreeTextWidget() {
    return ValueListenableBuilder(
      valueListenable: _text,
      builder: (BuildContext context, text, Widget? child) {
        return Container(
          margin: EdgeInsets.only(top: 3.height),
          child: Text(
            text,
            style: const TextStyle(
              color: LiveColors.designStandardFlowkitWhite,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  void _showCancelRequestPanelWidget() {
    List<ActionSheetModel> list = [
      ActionSheetModel(
          isCenter: true,
          text: LiveKitLocalizations.of(Global.appContext())!.common_text_cancel_link_mic_apply,
          textStyle: const TextStyle(
            color: LiveColors.designStandardFlowkitRed,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          lineHeight: 3.height,
          bingData: 1),
      ActionSheetModel(
          isCenter: true,
          text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
          isShowBottomLine: false,
          bingData: 2),
    ];
    ActionSheet.show(list, (ActionSheetModel model) async {
      if (model.bingData == 1) {
        final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
        if (liveID.isEmpty) return;
        CoGuestStore coGuestStore = CoGuestStore.create(liveID);
        coGuestStore.cancelApplication();
        widget.liveStreamManager.coGuestManager.onCancelIntraRoomConnection();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      _index = (_index + 1) % 4;
      String text = LiveKitLocalizations.of(Global.appContext())!.common_waiting_pass;
      _text.value = text + '.' * _index;
    });
  }
}
