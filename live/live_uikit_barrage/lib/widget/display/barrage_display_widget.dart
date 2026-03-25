import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../state/store.dart';
import 'barrage_display_controller.dart';
import 'barrage_item_widget.dart';

class SenderTagConfig {
  final Color backgroundColor;

  final String text;

  const SenderTagConfig({
    required this.backgroundColor,
    required this.text,
  });
}

typedef SenderTagProvider = SenderTagConfig? Function(String userId);

class BarrageDisplayWidget extends StatelessWidget {
  final BarrageDisplayController controller;
  final void Function(Barrage)? onClickBarrageItem;
  final SenderTagProvider? itemSenderTagProvider;

  const BarrageDisplayWidget({
    super.key,
    required this.controller,
    this.onClickBarrageItem,
    this.itemSenderTagProvider,
  });

  @override
  Widget build(BuildContext context) {
    return _buildBarrageList(context);
  }

  Widget _buildBarrageList(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Store().manager.barrageStore.barrageState.messageList,
      builder: (BuildContext context, value, Widget? child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.scrollToBottom();
        });
        return Container(
          color: Colors.transparent,
          child: ListView.builder(
            controller: controller.scrollController,
            itemCount: Store().manager.barrageStore.barrageState.messageList.value.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              Barrage barrage = Store().manager.barrageStore.barrageState.messageList.value[index];
              if (controller.customBarrageBuilder != null &&
                  controller.customBarrageBuilder!.shouldCustomizeBarrageItem(barrage)) {
                return controller.customBarrageBuilder?.buildWidget(context, barrage);
              }
              return GestureDetector(
                onTap: () => onClickBarrageItem?.call(barrage),
                child: BarrageItemWidget(
                  barrage: barrage,
                  senderTagConfig: itemSenderTagProvider?.call(barrage.sender.userID),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
