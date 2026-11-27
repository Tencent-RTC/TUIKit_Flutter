part of 'pusher_live_status_view.dart';

class PusherLiveStatisticsView extends StatelessWidget {
  const PusherLiveStatisticsView({super.key, required this.values});

  final List<int> values;

  static const List<(String, String)> _metrics = [
    ('gift_score', 'points'),
    ('gift_senders', 'people'),
    ('gifts', 'count'),
    ('online', 'people'),
    ('likes', 'times'),
    ('messages', 'messages'),
  ];
  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.maxWidth - 36;
        final double columnWidth = (cardWidth - 42) / 3;

        return SizedBox(
            height: 515,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 18,
                  top: 0,
                  width: cardWidth,
                  height: 232,
                  child: _StatusCard(
                    radius: 18,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 16,
                          top: 18,
                          width: 110,
                          height: 23,
                          child: Text(
                            LiveKitResources.localizedString('tuilivekit.pusher.status.realtime'),
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 21,
                          height: 15,
                          child: Text(
                            LiveKitResources.localizedString('tuilivekit.pusher.status.cumulative'),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0x61FFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 125,
                          width: cardWidth - 32,
                          height: 1 / MediaQuery.of(context).devicePixelRatio,
                          child: const ColoredBox(
                            color: _LiveStatusStyle.separator,
                            child: SizedBox.expand(),
                          ),
                        ),
                        for (int index = 0; index < _metrics.length; index++)
                          Positioned(
                            left: 21 + (index % 3) * columnWidth,
                            top: 55 + (index ~/ 3) * 84,
                            width: columnWidth,
                            height: 68,
                            child: _LiveStatusMetricView(
                              title: LiveKitResources.localizedString(
                                  'tuilivekit.pusher.status.metric.${_metrics[index].$1}'),
                              unit: LiveKitResources.localizedString(
                                  'tuilivekit.pusher.status.unit.${_metrics[index].$2}'),
                              value: values[index],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 244,
                  width: cardWidth,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x12FFFFFF))),
                    child: Stack(children: [
                      Positioned(
                          left: 15,
                          top: 0,
                          bottom: 0,
                          width: 34,
                          child: Center(
                              child: Image(
                                  image: LiveKitResources.image('livekit_status_realtime'),
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.contain))),
                      Padding(
                          padding: const EdgeInsets.only(left: 61, top: 13, bottom: 13),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding: const EdgeInsets.only(right: 83),
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(minHeight: 18),
                                        child: Text(
                                            LiveKitResources.localizedString('tuilivekit.pusher.status.updating'),
                                            style: const TextStyle(
                                                color: Color(0xD1FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)))),
                                const SizedBox(height: 5),
                                Padding(
                                    padding: const EdgeInsets.only(right: 43),
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(minHeight: 15),
                                        child: Text(
                                            LiveKitResources.localizedString('tuilivekit.pusher.status.update_detail'),
                                            style: const TextStyle(color: Color(0x61FFFFFF), fontSize: 11)))),
                              ])),
                    ]),
                  ),
                ),
              ],
            ));
      },
    );
  }
}

class _LiveStatusMetricView extends StatelessWidget {
  const _LiveStatusMetricView({
    required this.title,
    required this.unit,
    required this.value,
  });

  final String title;
  final String unit;
  final int value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const unitStyle = TextStyle(color: Color(0x61FFFFFF), fontSize: 10);
      const valueStyle = TextStyle(color: _LiveStatusStyle.statValue, fontSize: 24, fontWeight: FontWeight.w600);
      final valueText = '${value < 0 ? 0 : value}';
      double textWidth(String text, TextStyle style) {
        final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1)
          ..layout();
        final width = painter.width.ceilToDouble();
        painter.dispose();
        return width;
      }

      // UIKit reserves the unit's intrinsic width and only shrinks the number
      // to 50%. Scaling a combined Row also shrinks the unit and its 5pt gap.
      final unitWidth = textWidth(unit, unitStyle);
      final naturalValueWidth = textWidth(valueText, valueStyle);
      final valueWidth = math.min(naturalValueWidth, math.max(0.0, constraints.maxWidth - unitWidth - 9));
      final scale = naturalValueWidth == 0 ? 1.0 : (valueWidth / naturalValueWidth).clamp(0.5, 1.0);
      return Stack(children: [
        Positioned(
            left: 0,
            right: 4,
            top: 0,
            height: 32,
            child: Text(title, maxLines: 2, style: const TextStyle(color: Color(0x7AFFFFFF), fontSize: 12))),
        Positioned(
            left: 0,
            top: 35,
            width: valueWidth,
            height: 28,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(valueText,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: valueStyle.copyWith(fontSize: 24 * scale)))),
        Positioned(
            left: valueWidth + 5,
            top: 47,
            width: unitWidth,
            height: 13,
            child: Align(
                alignment: Alignment.centerLeft, child: Text(unit, maxLines: 1, softWrap: false, style: unitStyle))),
      ]);
    });
  }
}
