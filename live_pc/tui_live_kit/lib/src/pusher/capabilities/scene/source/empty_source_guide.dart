import 'package:flutter/material.dart';

import '../../../../l10n/live_kit_localizations.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'source_add_control.dart';
import 'source_type_card_grid.dart';

class EmptySourceGuide extends StatefulWidget {
  const EmptySourceGuide({super.key, required this.controller, this.portrait = false});

  final SceneController controller;
  final bool portrait;

  @override
  State<EmptySourceGuide> createState() => _EmptySourceGuideState();
}

class _EmptySourceGuideState extends State<EmptySourceGuide> with SingleTickerProviderStateMixin {
  static const _totalMs = 800.0;
  static const _enterCurve = Cubic(0.22, 0.61, 0.36, 1.0);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs ~/ 1),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double startMs, double endMs) =>
      CurvedAnimation(parent: _controller, curve: Interval(startMs / _totalMs, endMs / _totalMs, curve: _enterCurve));

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    final cards = sourceTypeCards(strings);
    final portrait = widget.portrait;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SourceTypeCardGrid(
            cards: cards,
            variant: SourceTypeCardVariant.guide,
            portrait: portrait,
            onTap: (data) => addSourceByKind(context, widget.controller, data.kind),
            cardWrapper: _staggeredCard,
          ),
        ],
      ),
    );
  }

  Widget _staggeredCard(int index, Widget card) {
    final start = 90 + 55.0 * index;
    final anim = _interval(start, start + 440);
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder:
            (context, child) => Transform.translate(
              offset: Offset(0, 10 * (1 - anim.value)),
              child: Transform.scale(scale: 0.97 + 0.03 * anim.value, child: child),
            ),
        child: card,
      ),
    );
  }
}
