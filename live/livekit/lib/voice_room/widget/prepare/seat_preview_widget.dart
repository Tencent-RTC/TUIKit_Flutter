import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

class SeatPreviewWidget extends StatelessWidget {
  final Size itemSize;
  final int seatCount;

  const SeatPreviewWidget({super.key, Size? size, int? seatCount})
      : itemSize = size ?? const Size(70, 70),
        seatCount = seatCount ?? 10;

  @override
  Widget build(BuildContext context) {
    final perRow = _itemsPerRow(seatCount);
    final rowCount = (seatCount / perRow).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : 12.height),
          child: _buildRow(perRow),
        );
      }),
    );
  }

  Widget _buildRow(int perRow) {
    return SizedBox(
      width: double.infinity,
      height: itemSize.height,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(perRow, (_) => _buildSeatItem()),
      ),
    );
  }

  Widget _buildSeatItem() {
    return Container(
      decoration: BoxDecoration(
          color: LiveColors.designStandardWhite7.withAlpha(0x1A),
          border: Border.all(color: LiveColors.designStandardWhite7.withAlpha(0x1A), width: 0.5.width),
          shape: BoxShape.circle),
      width: 50.radius,
      height: 50.radius,
      child: Center(
        child: Image.asset(LiveImages.emptySeat, package: Constants.pluginName, width: 22.radius, height: 22.radius),
      ),
    );
  }

  int _itemsPerRow(int count) {
    switch (count) {
      case 3:
      case 6:
      case 9:
        return 3;
      case 4:
      case 8:
      case 12:
      case 16:
        return 4;
      case 5:
      case 10:
      case 15:
        return 5;
      default:
        return 5;
    }
  }
}
