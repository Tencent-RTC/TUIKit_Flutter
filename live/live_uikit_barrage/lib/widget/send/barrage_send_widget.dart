import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';

import '../../common/index.dart';
import 'barrage_input_panel_widget.dart';
import 'barrage_send_controller.dart';

class BarrageSendWidget extends StatefulWidget {
  final BarrageSendController controller;
  final BuildContext? parentContext;

  const BarrageSendWidget({super.key, required this.controller, this.parentContext});

  @override
  State<BarrageSendWidget> createState() => _BarrageSendWidgetState();
}

class _BarrageSendWidgetState extends State<BarrageSendWidget> {
  BuildContext? _sheetContext;
  late final LiveListListener liveListListener;
  late final VoidCallback _floatWindowModeChangedListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    widget.controller.isFloatWindowMode.addListener(_floatWindowModeChangedListener);
    liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _autoCloseInputWidget();
    });
    LiveListStore.shared.addLiveListListener(liveListListener);
  }

  @override
  void dispose() {
    _autoCloseInputWidget();
    widget.controller.isFloatWindowMode.removeListener(_floatWindowModeChangedListener);
    LiveListStore.shared.removeLiveListListener(liveListListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () async {
          showInputWidget(widget.parentContext ?? context, widget.controller);
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
          backgroundColor:
          WidgetStateProperty.all<Color>(BarrageColors.barrageLightGrey),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              width: 18.33,
              height: 18.33,
            ),
          ],
        ),
      ),
    );
  }

  void showInputWidget(BuildContext context, BarrageSendController controller) {
    showModalBottomSheet(
      useRootNavigator: true,
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