import 'package:atomic_x_core/atomicxcore.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/state/store.dart';

import '../../common/index.dart';
import '../emoji/index.dart';
import 'barrage_display_widget.dart';

class BarrageItemWidget extends StatelessWidget {
  const BarrageItemWidget({super.key, required this.barrage, this.senderTagConfig});

  final Barrage barrage;
  final SenderTagConfig? senderTagConfig;

  bool get _needTag => senderTagConfig != null || barrage.sender.userID == Store().ownerId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3, bottom: 3),
          padding: const EdgeInsets.only(left: 6, top: 4, right: 6, bottom: 4),
          decoration: BoxDecoration(
            color: BarrageColors.barrageItemBackgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [const SizedBox(width: 4), _buildBarrageContentWidget(context)],
          ),
        ),
      ],
    );
  }

  Widget _buildBarrageContentWidget(BuildContext context) {
    final spaceHolder = _needTag ? _getSpacesStringByDp() : '';

    return Flexible(
      child: Stack(
        children: [
          ExtendedText(
            "$spaceHolder"
            "${barrage.sender.userName.isNotEmpty ? barrage.sender.userName : barrage.sender.userID}: "
            "${barrage.textContent}",
            specialTextSpanBuilder: EmojiTextSpanBuilder(context: context),
            style: const TextStyle(
              color: BarrageColors.barrageDisplayItemWhite,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_needTag)
            Container(
              width: 42,
              height: 14,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: _getTagColor()),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 1.5),
              child: Baseline(
                baseline: 10.0,
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  _getTagText(context),
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTagColor() {
    if (senderTagConfig != null) {
      return senderTagConfig!.backgroundColor;
    }

    return BarrageColors.barrageAnchorFlagBackground;
  }

  String _getTagText(BuildContext context) {
    if (senderTagConfig != null) {
      return senderTagConfig!.text;
    }

    return BarrageLocalizations.of(context)!.barrage_anchor;
  }

  String _getSpacesStringByDp() {
    TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: ' ',
        style: TextStyle(color: BarrageColors.barrageDisplayItemWhite, fontSize: 12, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    double spacesWidth = textPainter.width;

    int spacesCount = (42 / spacesWidth).ceil();
    return ' ' * spacesCount;
  }
}
