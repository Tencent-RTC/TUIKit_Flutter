/// 主播最终统计：收益、礼物优先，时间与互动数据在同一内容列展示。
library;

import 'dart:math' as math;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../common/live_kit_resources.dart';

class PusherSummaryContext {
  const PusherSummaryContext(
      {required this.startTime, required this.endTime, required this.pausedSeconds, this.interruptionMessage});
  final DateTime? startTime;
  final DateTime endTime;
  final int pausedSeconds;
  final String? interruptionMessage;
}

class PusherSummaryView extends StatefulWidget {
  const PusherSummaryView(
      {super.key,
      required this.liveID,
      required this.summaryContext,
      this.summaryStore,
      this.finalSummary,
      this.onExit});
  final String liveID;
  final PusherSummaryContext summaryContext;
  // Retained for explicit test injection; production consumes the host's final event.
  final LiveSummaryStore? summaryStore;
  final PusherSummary? finalSummary;
  final VoidCallback? onExit;

  @override
  State<PusherSummaryView> createState() => _PusherSummaryViewState();
}

class _PusherSummaryViewState extends State<PusherSummaryView> {
  LiveSummaryStore? _summaryStore;
  bool _didRequestExit = false;
  bool get _hasData => widget.finalSummary != null || _summaryStore != null;
  LiveSummaryData? get _summary => _summaryStore?.liveSummaryState.summaryData.value;

  @override
  void initState() {
    super.initState();
    _summaryStore = widget.summaryStore;
    _summaryStore?.liveSummaryState.summaryData.addListener(_onSummaryChanged);
  }

  @override
  void didUpdateWidget(PusherSummaryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveID != widget.liveID) _didRequestExit = false;
    if (oldWidget.summaryStore != widget.summaryStore) {
      _summaryStore?.liveSummaryState.summaryData.removeListener(_onSummaryChanged);
      _summaryStore = widget.summaryStore;
      _summaryStore?.liveSummaryState.summaryData.addListener(_onSummaryChanged);
    }
  }

  void _onSummaryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _summaryStore?.liveSummaryState.summaryData.removeListener(_onSummaryChanged);
    super.dispose();
  }

  void _exit() {
    if (_didRequestExit || widget.onExit == null) return;
    _didRequestExit = true;
    widget.onExit?.call();
  }

  static String _formatClock(DateTime? time) =>
      time == null ? '--:--' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static String _durationText(int duration) {
    final seconds = math.max(0, duration);
    return <(int, String)>[(seconds ~/ 3600, 'hours'), (seconds ~/ 60 % 60, 'minutes'), (seconds % 60, 'seconds')]
        .where((part) => part.$1 > 0 || (seconds == 0 && part.$2 == 'seconds'))
        .map((part) => LiveKitResources.localizedFormat('tuilivekit.pusher.summary.duration.${part.$2}', part.$1))
        .join();
  }

  Widget _metric(String title, int? value,
      {_SummaryMetricStyle style = _SummaryMetricStyle.interaction, String? unit}) {
    return _SummaryMetricView(titleKey: title, unitKey: unit, style: style, value: _hasData ? value ?? 0 : null);
  }

  @override
  Widget build(BuildContext context) {
    final finalSummary = widget.finalSummary;
    final duration =
        _hasData ? _durationText(finalSummary?.liveDuration ?? (_summary?.totalDuration ?? 0) ~/ 1000) : '--';
    final total = LiveKitResources.localizedFormat('tuilivekit.pusher.summary.total_duration', duration);
    final presentation = widget.summaryContext;
    return ColoredBox(
      color: _PusherSummaryStyle.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                  height: 44,
                  child: Row(children: <Widget>[
                    Semantics(
                      button: true,
                      label: LiveKitResources.localizedString('tuilivekit.pusher.summary.back'),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _exit,
                        child: ExcludeSemantics(
                            child: Image(
                                image: LiveKitResources.image('livekit_summary_back'),
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain)),
                      ),
                    ),
                    Expanded(
                        child: _SummaryFittedText(
                      LiveKitResources.localizedString('tuilivekit.pusher.summary.ended'),
                      style: const TextStyle(
                          color: _PusherSummaryStyle.primaryText, fontSize: 24, fontWeight: FontWeight.w600),
                    )),
                  ])),
            ),
            const SizedBox(height: 8),
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                    Text('${_formatClock(presentation.startTime)} – ${_formatClock(presentation.endTime)}  ·  $total',
                        style: _PusherSummaryStyle.information),
                    if (presentation.pausedSeconds > 0) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                          LiveKitResources.localizedFormat(
                              'tuilivekit.pusher.summary.pause_details', _durationText(presentation.pausedSeconds)),
                          style: _PusherSummaryStyle.information),
                    ],
                    if (presentation.interruptionMessage?.isNotEmpty == true) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(presentation.interruptionMessage!, style: _PusherSummaryStyle.information),
                    ],
                  ]),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 280,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color.fromRGBO(38, 54, 77, 1), Color.fromRGBO(26, 38, 59, 1)],
                      )),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _metric('gift_value', finalSummary?.totalGiftCoins ?? _summary?.totalGiftCoins,
                            unit: 'coins', style: _SummaryMetricStyle.income),
                        const SizedBox(height: 1, child: ColoredBox(color: _PusherSummaryStyle.divider)),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Expanded(
                              child: _metric('gifts_received', finalSummary?.totalGiftsSent ?? _summary?.totalGiftsSent,
                                  unit: 'items', style: _SummaryMetricStyle.gift)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _metric('gift_senders',
                                  finalSummary?.totalUniqueGiftSenders ?? _summary?.totalGiftUniqueSenders,
                                  unit: 'people', style: _SummaryMetricStyle.gift)),
                        ]),
                      ]),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: _PusherSummaryStyle.interactionBackground, borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                    SizedBox(
                        height: 22,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              LiveKitResources.localizedString('tuilivekit.pusher.summary.interaction_data'),
                              style: const TextStyle(
                                  color: _PusherSummaryStyle.primaryText, fontSize: 15, fontWeight: FontWeight.w600),
                            ))),
                    const SizedBox(height: 20),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Expanded(child: _metric('viewers', finalSummary?.totalViewers ?? _summary?.totalViewers)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _metric('comments', finalSummary?.totalMessageCount ?? _summary?.totalMessageSent)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _metric('likes', finalSummary?.totalLikesReceived ?? _summary?.totalLikesReceived)),
                    ]),
                  ]),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

enum _SummaryMetricStyle {
  income(48, 62),
  gift(32, 40),
  interaction(26, 38);

  const _SummaryMetricStyle(this.valueSize, this.valueHeight);
  final double valueSize;
  final double valueHeight;
}

class _SummaryMetricView extends StatefulWidget {
  const _SummaryMetricView({required this.titleKey, required this.value, required this.style, this.unitKey});
  final String titleKey;
  final String? unitKey;
  final int? value;
  final _SummaryMetricStyle style;

  @override
  State<_SummaryMetricView> createState() => _SummaryMetricViewState();
}

class _SummaryMetricViewState extends State<_SummaryMetricView> {
  String _fullText = '--';
  List<(String, double)> _options = const [];
  TextStyle get _valueStyle => TextStyle(
        color: widget.style == _SummaryMetricStyle.income
            ? _PusherSummaryStyle.incomeValue
            : _PusherSummaryStyle.primaryText,
        fontSize: widget.style.valueSize,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateOptions();
  }

  @override
  void didUpdateWidget(_SummaryMetricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.style != widget.style) _updateOptions();
  }

  void _updateOptions() {
    final value = widget.value == null ? null : math.max(0, widget.value!);
    // Both supported UI languages use decimal groups of three with a comma.
    _fullText = value?.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},') ?? '--';
    final texts = <String>[_fullText];
    if (value != null) {
      final compact = _compactText(value);
      if (compact != null) texts.add(compact);
      texts.add(value.toDouble().toStringAsExponential(2));
    }
    _options = texts.toSet().map((text) {
      final painter = TextPainter(
          text: TextSpan(text: text, style: _valueStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context))
        ..layout();
      final minimumWidth = painter.width * .5;
      painter.dispose();
      return (text, minimumWidth);
    }).toList();
  }

  static String? _compactText(int value) {
    final chinese = LiveKitResources.giftLanguageCode.startsWith('zh');
    final units = chinese
        ? const <(double, String)>[(1e12, 'trillion'), (1e8, 'hundred_million'), (1e4, 'ten_thousand')]
        : const <(double, String)>[(1e12, 'trillion'), (1e9, 'billion'), (1e6, 'million'), (1e3, 'thousand')];
    for (final (index, (threshold, unit)) in units.indexed) {
      if (value < threshold) continue;
      final scaled = value / threshold;
      final digits = math.max(0, 2 - (math.log(scaled) / math.ln10).floor());
      var number = scaled.toStringAsFixed(digits);
      if (number.contains('.')) number = number.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
      var unitKey = unit;
      if (index > 0 && double.parse(number) * threshold >= units[index - 1].$1) {
        unitKey = units[index - 1].$2;
        number = '1';
      }
      return LiveKitResources.localizedFormat('tuilivekit.pusher.summary.compact.$unitKey', number);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var title = LiveKitResources.localizedString('tuilivekit.pusher.summary.${widget.titleKey}');
    if (widget.unitKey != null) {
      title = LiveKitResources.localizedString('tuilivekit.pusher.summary.metric_with_unit')
          .replaceFirst('%@', title)
          .replaceFirst('%@', LiveKitResources.localizedString('tuilivekit.pusher.summary.unit.${widget.unitKey}'));
    }
    final income = widget.style == _SummaryMetricStyle.income;
    return Semantics(
        label: title,
        value: _fullText,
        child: ExcludeSemantics(
          child: LayoutBuilder(builder: (context, constraints) {
            final option =
                _options.firstWhere((entry) => entry.$2 <= constraints.maxWidth, orElse: () => _options.last);
            final caption = SizedBox(
                height: income ? 20 : 24,
                child: _SummaryFittedText(title,
                    style: TextStyle(color: _PusherSummaryStyle.secondaryText, fontSize: income ? 14 : 13)));
            final value = SizedBox(
                height: widget.style.valueHeight,
                child: _SummaryFittedText(option.$1, style: _valueStyle, minimumScale: .5));
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (income) caption else value,
                  SizedBox(height: income ? 12 : 8),
                  if (income) value else caption,
                ]);
          }),
        ));
  }
}

/// UIKit shrinks a UILabel within its bounds; Flutter requires measuring before choosing the font size.
class _SummaryFittedText extends StatelessWidget {
  const _SummaryFittedText(this.text, {required this.style, this.minimumScale = .75});
  final String text;
  final TextStyle style;
  final double minimumScale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1)
          ..layout();
        final scale = math
            .min(painter.width == 0 ? 1.0 : constraints.maxWidth / painter.width,
                painter.height == 0 ? 1.0 : constraints.maxHeight / painter.height)
            .clamp(minimumScale, 1.0);
        painter.dispose();
        return Align(
            alignment: Alignment.centerLeft,
            child: Text(text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(fontSize: style.fontSize! * scale)));
      });
}

abstract final class _PusherSummaryStyle {
  static const primaryText = Color(0xFFF5F7FA);
  static const secondaryText = Color(0xFFA9B7CB);
  static const background = Color(0xFF12161F);
  static const interactionBackground = Color(0xFF1A2230);
  static const incomeValue = Color(0xFFF9D497);
  static const divider = Color(0xFF354255);
  static const information = TextStyle(color: secondaryText, fontSize: 14, height: 22 / 14);
}
