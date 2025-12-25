library seat_grid_widget;

export 'seat_grid_controller.dart';
export 'seat_grid_define.dart';
export 'state/index.dart';

import 'package:flutter/material.dart';

import 'index.dart';

class SeatGridWidget extends StatefulWidget {
  final SeatGridController controller;
  final SeatWidgetBuilder? seatWidgetBuilder;
  final OnSeatWidgetTap? onSeatWidgetTap;

  const SeatGridWidget(
      {super.key,
      required this.controller,
      this.seatWidgetBuilder,
      this.onSeatWidgetTap});

  @override
  State<SeatGridWidget> createState() => _SeatGridWidgetState();
}

class _SeatGridWidgetState extends State<SeatGridWidget> {
  late final SeatGridController controller;
  late final SeatWidgetBuilder? seatWidgetBuilder;
  late final OnSeatWidgetTap? onSeatWidgetTap;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    seatWidgetBuilder = widget.seatWidgetBuilder;
    onSeatWidgetTap = widget.onSeatWidgetTap;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: Listenable.merge([controller.widgetState.layoutConfig, controller.onSeatWidgetStateSynced]),
        builder: (context, child) {
          final layoutConfig = controller.widgetState.layoutConfig.value;
          return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: layoutConfig.rowConfigs.length,
              itemBuilder: (context, row) {
                final rowConfig = layoutConfig.rowConfigs[row];
                final alignment =
                    _convertToMainAxisAlignment(rowConfig.alignment);
                return Padding(
                  padding: EdgeInsets.only(
                      top: row != 0 ? layoutConfig.rowSpacing : 0),
                  child: Row(
                    spacing: rowConfig.seatSpacing,
                    mainAxisAlignment: alignment,
                    children: List.generate(rowConfig.count, (column) {
                      final seatWidgetState = controller.getSeatWidgetState(
                          layoutConfig, row, column);

                      return GestureDetector(
                        onTap: () {
                          final index = controller.getSeatIndex(
                              layoutConfig, row, column);
                          seatWidgetState.seatInfoNotifier.value.index = index;
                          onSeatWidgetTap
                              ?.call(seatWidgetState.seatInfoNotifier.value);
                        },
                        child: SizedBox(
                            width: rowConfig.seatSize.width,
                            height: rowConfig.seatSize.height,
                            child: seatWidgetBuilder != null
                                ? seatWidgetBuilder!(
                                    context,
                                    seatWidgetState.seatInfoNotifier,
                                    seatWidgetState.volumeNotifier)
                                : DefaultSeatWidget(
                                    seatWidgetState: seatWidgetState)),
                      );
                    }),
                  ),
                );
              });
        });
  }

  MainAxisAlignment _convertToMainAxisAlignment(
      SeatWidgetLayoutRowAlignment seatAlignment) {
    MainAxisAlignment alignment = MainAxisAlignment.start;
    switch (seatAlignment) {
      case SeatWidgetLayoutRowAlignment.spaceAround:
        alignment = MainAxisAlignment.spaceAround;
        break;
      case SeatWidgetLayoutRowAlignment.spaceBetween:
        alignment = MainAxisAlignment.spaceBetween;
        break;
      case SeatWidgetLayoutRowAlignment.spaceEvenly:
        alignment = MainAxisAlignment.spaceEvenly;
        break;
      case SeatWidgetLayoutRowAlignment.start:
        alignment = MainAxisAlignment.start;
        break;
      case SeatWidgetLayoutRowAlignment.end:
        alignment = MainAxisAlignment.end;
        break;
      case SeatWidgetLayoutRowAlignment.center:
        alignment = MainAxisAlignment.center;
        break;
      default:
        break;
    }
    return alignment;
  }
}