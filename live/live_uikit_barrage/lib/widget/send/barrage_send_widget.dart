import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../common/index.dart';
import 'barrage_input_panel_widget.dart';
import 'barrage_send_controller.dart';

enum BarrageSceneType {
  live,
  room,
}

class BarrageSendWidget extends StatefulWidget {
  final BarrageSendController controller;
  final BuildContext? parentContext;
  final BarrageSceneType sceneType;

  const BarrageSendWidget(
      {super.key, required this.controller, this.parentContext, this.sceneType = BarrageSceneType.live});

  @override
  State<BarrageSendWidget> createState() => _BarrageSendWidgetState();
}

class _BarrageSendWidgetState extends State<BarrageSendWidget> {
  BuildContext? _sheetContext;
  late final LiveListListener liveListListener;
  late final RoomListener roomListener;
  late final VoidCallback _floatWindowModeChangedListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    widget.controller.isFloatWindowMode.addListener(_floatWindowModeChangedListener);
    liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _autoCloseInputWidget();
    });
    roomListener = RoomListener(onRoomEnded: (RoomInfo roomInfo) {
      _autoCloseInputWidget();
    });
    switch (widget.sceneType) {
      case BarrageSceneType.live:
        LiveListStore.shared.addLiveListListener(liveListListener);
        break;
      case BarrageSceneType.room:
        RoomStore.shared.addRoomListener(roomListener);
        break;
    }
  }

  @override
  void dispose() {
    _autoCloseInputWidget();
    widget.controller.isFloatWindowMode.removeListener(_floatWindowModeChangedListener);
    switch (widget.sceneType) {
      case BarrageSceneType.live:
        LiveListStore.shared.removeLiveListListener(liveListListener);
        break;
      case BarrageSceneType.room:
        RoomStore.shared.removeRoomListener(roomListener);
        break;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          showInputWidget(widget.parentContext ?? context, widget.controller);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
          backgroundColor: WidgetStateProperty.all<Color>(BarrageColors.barrageLightGrey),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.sceneType == BarrageSceneType.live ? 18 : 8),
              side: const BorderSide(color: BarrageColors.barrageBorderColor, width: 1),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                BarrageLocalizations.of(context)!.barrage_let_us_chat,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: BarrageColors.barrageTextGrey,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Image.asset(
                BarrageImages.emojiIcon,
                package: Constants.pluginName,
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showInputWidget(BuildContext context, BarrageSendController controller) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      builder: (builderContext) {
        _sheetContext = builderContext;
        return BarrageInputPanelWidget(controller: controller);
      },
    ).then((value) => _sheetContext == null);
  }

  void _autoCloseInputWidget() {
    if (_sheetContext != null && _sheetContext!.mounted) {
      Navigator.pop(_sheetContext!);
      _sheetContext = null;
    }
  }

  void _onFloatWindowModeChanged() {
    if (widget.controller.isFloatWindowMode.value) {
      _autoCloseInputWidget();
    }
  }
}
