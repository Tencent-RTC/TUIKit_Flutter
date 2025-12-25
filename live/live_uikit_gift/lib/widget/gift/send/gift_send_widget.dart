import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';

import '../../../common/index.dart';
import 'gift_list_controller.dart';
import 'gift_list_widget.dart';

class GiftSendWidget extends StatefulWidget {
  final GiftListController controller;
  final BuildContext? parentContext;
  final Widget? icon;

  const GiftSendWidget({super.key, required this.controller, this.parentContext, this.icon});

  @override
  State<GiftSendWidget> createState() => _GiftSendWidgetState();
}

class _GiftSendWidgetState extends State<GiftSendWidget> {
  BuildContext? _sheetContext;
  late final LiveListListener liveListListener;
  late final VoidCallback _floatWindowModeChangedListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    widget.controller.isFloatWindowMode.addListener(_floatWindowModeChangedListener);
    liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _autoCloseGiftPanelWidget();
    });
    LiveListStore.shared.addLiveListListener(liveListListener);
  }

  @override
  void dispose() {
    _autoCloseGiftPanelWidget();
    widget.controller.isFloatWindowMode.removeListener(_floatWindowModeChangedListener);
    LiveListStore.shared.removeLiveListListener(liveListListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () => showGiftPanelWidget(widget.parentContext ?? context, widget.controller),
        padding: EdgeInsets.zero,
        icon: widget.icon ?? Image.asset(
          GiftImages.giftSendIcon,
          package: Constants.pluginName,
          fit: BoxFit.fill,
        ));
  }

  void showGiftPanelWidget(BuildContext context, GiftListController controller) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.transparent,
      builder: (builderContext) {
        _sheetContext = builderContext;
        return GiftListWidget(giftListController: controller);
      },
    ).then((value) => _sheetContext = null);
  }

  void _autoCloseGiftPanelWidget() {
    if (_sheetContext != null && _sheetContext!.mounted) {
      Navigator.pop(_sheetContext!);
      _sheetContext = null;
    }
  }

  void _onFloatWindowModeChanged() {
    if (widget.controller.isFloatWindowMode.value) {
      _autoCloseGiftPanelWidget();
    }
  }
}
