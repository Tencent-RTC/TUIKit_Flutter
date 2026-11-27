/// 结束确认抽屉：有观众与无观众两种文案与面板高度。
library;

import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../common/live_kit_resources.dart';

import '../../../common/theme/bottom_sheet_view.dart';

class PusherEndConfirmationView extends StatefulWidget {
  const PusherEndConfirmationView({
    super.key,
    required this.viewerCount,
    required this.onDismiss,
    this.onConfirmEnd,
  });

  final int viewerCount;

  /// 抽屉关闭。
  final VoidCallback onDismiss;

  final VoidCallback? onConfirmEnd;

  @override
  State<PusherEndConfirmationView> createState() => _PusherEndConfirmationViewState();
}

class _PusherEndConfirmationViewState extends State<PusherEndConfirmationView> {
  /// UIColor(red: 0.769, green: 0.267, blue: 0.314, alpha: 1)
  static const Color _endButtonColor = Color(0xFFC44450);

  /// UIColor(red: 0.557, green: 0.812, blue: 1, alpha: 1)
  static const Color _audienceCountColor = Color(0xFF8ECFFF);

  final BottomSheetController _sheetController = BottomSheetController();

  bool _confirmed = false;

  bool get _hasAudience => widget.viewerCount > 0;

  double get _sheetHeight => _hasAudience ? 250 : 210;

  double get _buttonTop => _hasAudience ? 153 : 118;

  /// 先隐藏再回调，不做收起动画。
  void _confirmEnd() {
    if (_confirmed) return;
    _confirmed = true;
    widget.onDismiss();
    widget.onConfirmEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetView(
      controller: _sheetController,
      sheetHeight: _sheetHeight,
      onDismiss: widget.onDismiss,
      child: Stack(
        children: <Widget>[
          if (_hasAudience) ...<Widget>[
            Positioned(
              left: 24,
              right: 24,
              top: 49,
              height: 31,
              child: Center(child: _buildAudienceStatus()),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 94,
              height: 24,
              child: Text(
                LiveKitResources.localizedString('tuilivekit.pusher.end.confirm'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            Positioned(
              left: 28,
              right: 28,
              top: 56,
              bottom: _sheetHeight - _buttonTop + 12,
              child: Text(
                LiveKitResources.localizedString('tuilivekit.pusher.end.empty_audience'),
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xBFFFFFFF),
                  fontSize: 14,
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: _buttonTop,
            height: 44,
            child: LayoutBuilder(builder: (context, constraints) {
              final continueTitle = LiveKitResources.localizedString('tuilivekit.pusher.end.continue');
              final painter = TextPainter(
                  text: TextSpan(text: continueTitle, style: const TextStyle(fontSize: 15)),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context))
                ..layout();
              // UIKit gives both buttons the continue title's intrinsic width
              // plus 24, and lets the 20-point outer edges limit that width.
              final width = math.min(math.max(108.0, painter.width.ceilToDouble() + 24),
                  math.max(0.0, (constraints.maxWidth - 40 - 24) / 2));
              painter.dispose();
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildButton(
                      width: width,
                      title: continueTitle,
                      backgroundColor: _EndConfirmationStyle.cancelBackground,
                      onPressed: _sheetController.dismiss,
                    ),
                    const SizedBox(width: 24),
                    _buildButton(
                      width: width,
                      title: LiveKitResources.localizedString('tuilivekit.pusher.end.end'),
                      backgroundColor: _endButtonColor,
                      hasShadow: true,
                      onPressed: _confirmEnd,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceStatus() {
    final text = LiveKitResources.localizedFormat('tuilivekit.pusher.end.audience_count', widget.viewerCount);
    final number = '${widget.viewerCount}';
    final start = text.indexOf(number);
    TextSpan span(double scale) => TextSpan(
          style: TextStyle(color: _EndConfirmationStyle.messageForeground, fontSize: 14 * scale),
          children: start < 0
              ? [TextSpan(text: text)]
              : [
                  TextSpan(text: text.substring(0, start)),
                  TextSpan(
                      text: number,
                      style: TextStyle(
                          color: _audienceCountColor,
                          fontSize: 23 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: const [Shadow(color: Color(0x734A9EFF), blurRadius: 14)])),
                  TextSpan(text: text.substring(start + number.length)),
                ],
        );
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
          text: span(1),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1)
        ..layout();
      final scale = painter.width == 0 ? 1.0 : (constraints.maxWidth / painter.width).clamp(0.8, 1.0);
      painter.dispose();
      return Text.rich(span(scale),
          textAlign: TextAlign.center, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis);
    });
  }

  Widget _buildButton({
    required double width,
    required String title,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool hasShadow = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: width,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: hasShadow
              ? const <BoxShadow>[
                  // UIColor.black.withAlphaComponent(0.28), offset (0, 4), radius 12
                  BoxShadow(color: Color(0x47000000), offset: Offset(0, 4), blurRadius: 12),
                ]
              : null,
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final painter = TextPainter(
              text: TextSpan(text: title, style: const TextStyle(fontSize: 15)),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1)
            ..layout();
          final scale = painter.width == 0 ? 1.0 : (constraints.maxWidth / painter.width).clamp(0.85, 1.0);
          painter.dispose();
          return Center(
              child: Text(title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _EndConfirmationStyle.buttonForeground, fontSize: 15 * scale)));
        }),
      ),
    );
  }
}

abstract final class _EndConfirmationStyle {
  static const cancelBackground = Color(0x1AFFFFFF);
  static const buttonForeground = Color(0xF0FFFFFF);
  static const messageForeground = Color(0xC2FFFFFF);
}
