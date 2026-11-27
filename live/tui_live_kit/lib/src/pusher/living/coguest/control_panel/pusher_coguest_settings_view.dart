import 'package:atomic_x_core/atomicxcore.dart';
import '../../../../common/theme/live_theme.dart';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../common/live_kit_resources.dart';
import '../../../../common/theme/bottom_sheet_view.dart';
import '../pusher_coguest_store.dart';
import 'pusher_coguest_user_section_view.dart';

class PusherCoGuestSettingsView extends StatelessWidget {
  const PusherCoGuestSettingsView({
    super.key,
    required this.state,
    required this.actionHandler,
    required this.onDismiss,
  });

  final PusherCoGuestState state;
  final PusherCoGuestActionHandling actionHandler;

  /// 抽屉关闭。
  final VoidCallback onDismiss;

  static const double _scrollTopInset = 78;
  static const double _scrollBottomInset = 16;
  static const double _sectionSpacing = 12;
  static const double _layoutSectionHeight = 162;
  static const double _maximumSheetHeight = 654;
  static const double _minimumTopGap = 80;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingUserIDs;
    final connectedRows = _rows(state.connected, 'end', PusherCoGuestActionStyle.destructive);
    final applicantRows = _rows(state.applicants, 'accept', PusherCoGuestActionStyle.primary, enabled: !state.isFull);
    final candidateRows = [
      ..._rows(state.invitees, 'cancel_invitation', PusherCoGuestActionStyle.destructive),
      ..._rows(state.candidates, 'invite', PusherCoGuestActionStyle.primary, enabled: !state.isFull),
    ];
    // Only visible member sections contribute to the natural sheet height.
    final sections = <PusherCoGuestUserSectionView>[
      if (connectedRows.isNotEmpty)
        PusherCoGuestUserSectionView(
          title: LiveKitResources.localizedString('tuilivekit.pusher.coguest.connected'),
          emptyText: LiveKitResources.localizedString('tuilivekit.pusher.coguest.empty'),
          showsCount: true,
          rows: connectedRows,
          onAction: actionHandler.disconnect,
        ),
      if (applicantRows.isNotEmpty)
        PusherCoGuestUserSectionView(
          title: LiveKitResources.localizedString('tuilivekit.pusher.coguest.applicants'),
          emptyText: '',
          rows: applicantRows,
          onAction: actionHandler.acceptApplication,
        ),
      if (candidateRows.isNotEmpty)
        PusherCoGuestUserSectionView(
          title: LiveKitResources.localizedString('tuilivekit.pusher.coguest.candidates'),
          emptyText: '',
          rows: candidateRows,
          onAction: (String userID) {
            if (state.invitees.any((PusherCoGuestUser user) => user.userID == userID)) {
              actionHandler.cancelInvitation(userID);
            } else {
              actionHandler.invite(userID);
            }
          },
        ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final double sheetHeight = _preferredSheetHeight(
        screenHeight: constraints.maxHeight,
        bottomInset: mediaQuery.padding.bottom,
        sections: sections,
      );

      // 批量结束只在有人连麦时出现。
      final bool showsEndAll = connectedRows.isNotEmpty;
      final bool isEndAllEnabled = connectedRows.any((PusherCoGuestRow row) => !pending.contains(row.user.userID));

      final endAllTitle = LiveKitResources.localizedString('tuilivekit.pusher.coguest.end_all');
      final endAllStyle = LiveTheme.textStyle(LiveTextRole.action);
      final endAllPainter = TextPainter(
          text: TextSpan(text: endAllTitle, style: endAllStyle),
          textDirection: Directionality.of(context),
          textScaler: mediaQuery.textScaler)
        ..layout();
      final endAllWidth = math.max(88.0, endAllPainter.width.ceilToDouble());
      endAllPainter.dispose();
      final title = LiveKitResources.localizedString('tuilivekit.pusher.coguest.settings');
      final titlePainter = TextPainter(
          text: TextSpan(text: title, style: LiveTheme.textStyle(LiveTextRole.sheetTitle)),
          textDirection: Directionality.of(context),
          textScaler: mediaQuery.textScaler)
        ..layout();
      final titleRightLimit = constraints.maxWidth - (showsEndAll ? endAllWidth + 24 : 16);
      final titleWidth = math.min(titlePainter.width.ceilToDouble(), math.max(0.0, titleRightLimit - 16));
      final titleLeft = math.max(16.0, math.min((constraints.maxWidth - titleWidth) / 2, titleRightLimit - titleWidth));
      titlePainter.dispose();
      return BottomSheetView(
        sheetHeight: sheetHeight,
        onDismiss: onDismiss,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: titleLeft,
              width: titleWidth,
              top: 36,
              height: 20,
              child: _CoGuestFittedTitle(
                title: title,
                minimumScale: 0.8,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showsEndAll)
              Positioned(
                right: 16,
                top: 36,
                width: endAllWidth,
                height: 20,
                child: Opacity(
                  opacity: isEndAllEnabled ? 1 : 0.46,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isEndAllEnabled ? actionHandler.endAllConnections : null,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        endAllTitle,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          // UIColor(red: 0.898, green: 0.420, blue: 0.451, alpha: 1)
                          color: _PusherCoGuestSettingsStyle.endAllForeground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: _scrollTopInset,
              bottom: _scrollBottomInset + mediaQuery.padding.bottom,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      height: _layoutSectionHeight,
                      child: _buildLayoutSection(state),
                    ),
                    for (final section in sections) ...<Widget>[
                      const SizedBox(height: _sectionSpacing),
                      SizedBox(height: PusherCoGuestUserSectionView.preferredHeightOf(section.rows), child: section),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<PusherCoGuestRow> _rows(List<PusherCoGuestUser> users, String action, PusherCoGuestActionStyle style,
          {bool enabled = true}) =>
      users
          .map((user) => PusherCoGuestRow(
                user: user,
                actionTitle: LiveKitResources.localizedString('tuilivekit.pusher.coguest.$action'),
                actionStyle: style,
                isPending: state.pendingUserIDs.contains(user.userID),
                isEnabled: enabled,
              ))
          .toList();

  /// 按真实内容高度撑开，并限制不占满全屏。
  double _preferredSheetHeight({
    required double screenHeight,
    required double bottomInset,
    required List<PusherCoGuestUserSectionView> sections,
  }) {
    double contentHeight = _layoutSectionHeight;
    for (final section in sections) {
      contentHeight += _sectionSpacing + PusherCoGuestUserSectionView.preferredHeightOf(section.rows);
    }

    final double target = _scrollTopInset + contentHeight + _scrollBottomInset + bottomInset;
    final double available = screenHeight > 0 ? screenHeight - _minimumTopGap : _maximumSheetHeight;
    return math.min(math.min(_maximumSheetHeight, available), target);
  }

  Widget _buildLayoutSection(PusherCoGuestState state) {
    return _CoGuestSectionView(
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            height: 15,
            child: _CoGuestSectionTitle(LiveKitResources.localizedString('tuilivekit.pusher.coguest.layout')),
          ),
          Positioned(
            //
            // 两列等分可用宽度，不再用 390pt 下代入出的 159pt 固定宽。
            left: 16,
            right: 16,
            top: 42,
            height: 104,
            child: Column(
              children: [
                for (final (row, layouts) in const [
                  [CoGuestLayoutTemplate.floatLayout, CoGuestLayoutTemplate.dynamicLayout],
                  [CoGuestLayoutTemplate.columnLayout, CoGuestLayoutTemplate.gridLayout],
                ].indexed) ...[
                  if (row > 0) const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: Row(children: [
                      for (final (column, layout) in layouts.indexed) ...[
                        if (column > 0) const SizedBox(width: 8),
                        Expanded(child: _buildLayoutControl(state, layout)),
                      ],
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutControl(PusherCoGuestState state, CoGuestLayoutTemplate layout) {
    return _CoGuestLayoutControl(
      title: layout.title,
      assetName: layout.assetName,
      isActive: state.layout == layout,
      onPressed: state.isUpdatingLayout ? null : () => actionHandler.selectLayout(layout),
    );
  }
}

class _CoGuestSectionTitle extends StatelessWidget {
  const _CoGuestSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        // UIColor.white.withAlphaComponent(0.85)
        color: Color(0xBFFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CoGuestSectionView extends StatelessWidget {
  const _CoGuestSectionView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PusherCoGuestGroupStyle.cornerRadius),
      child: ColoredBox(
        // UIColor.black.withAlphaComponent(0.278)
        color: PusherCoGuestGroupStyle.background,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 16,
              right: 16,
              top: 0,
              height: 1 / MediaQuery.of(context).devicePixelRatio,
              child: const ColoredBox(
                color: Color(0x0DFFFFFF),
                child: SizedBox.expand(),
              ),
            ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

class _CoGuestLayoutControl extends StatelessWidget {
  const _CoGuestLayoutControl({
    required this.title,
    required this.assetName,
    required this.isActive,
    required this.onPressed,
  });

  final String title;
  final String assetName;
  final bool isActive;
  final VoidCallback? onPressed;

  /// UIColor(red: 0.557, green: 0.812, blue: 1, alpha: 1)
  static const Color _activeContentColor = Color(0xFF8ECFFF);

  /// UIColor.white.withAlphaComponent(0.72)
  static const Color _inactiveContentColor = Color(0xB8FFFFFF);

  @override
  Widget build(BuildContext context) {
    final Color contentColor = isActive ? _activeContentColor : _inactiveContentColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // UIColor.black.withAlphaComponent(0.22)
          color: _PusherCoGuestSettingsStyle.templateBackground,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? null
              // UIColor.white.withAlphaComponent(0.14)
              : Border.all(color: const Color(0x24FFFFFF), width: 1),
        ),
        child: Stack(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0x0DFFFFFF), Color(0x04FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                  if (isActive)
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[Color(0x424A9EFF), Color(0x290052D9)],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              const Positioned.fill(
                child: CustomPaint(painter: _CoGuestActiveBorderPainter()),
              ),
            Positioned.fill(
              child: Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Image(
                          image: LiveKitResources.image(assetName),
                          width: 20,
                          height: 20,
                          color: contentColor,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: SizedBox(
                                height: 40,
                                child: _CoGuestFittedTitle(
                                  title: title,
                                  maxLines: 2,
                                  minimumScale: 0.85,
                                  style: TextStyle(
                                    color: contentColor,
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ))),
                      ],
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// UILabel fits within its existing lines before truncating. Flutter requires
/// measuring both line wrapping and height to preserve that bounded shrink.
class _CoGuestFittedTitle extends StatelessWidget {
  const _CoGuestFittedTitle({
    required this.title,
    required this.style,
    required this.minimumScale,
    this.maxLines = 1,
    this.textAlign = TextAlign.left,
  });

  final String title;
  final TextStyle style;
  final double minimumScale;
  final int maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        bool fits(double scale) {
          final painter = TextPainter(
              text: TextSpan(text: title, style: style.copyWith(fontSize: style.fontSize! * scale)),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: maxLines)
            ..layout(maxWidth: constraints.maxWidth);
          final fits = !painter.didExceedMaxLines && painter.height <= constraints.maxHeight;
          painter.dispose();
          return fits;
        }

        var scale = 1.0;
        if (!fits(scale)) {
          var lower = minimumScale;
          var upper = 1.0;
          for (var iteration = 0; iteration < 10; iteration++) {
            final middle = (lower + upper) / 2;
            if (fits(middle)) {
              lower = middle;
            } else {
              upper = middle;
            }
          }
          scale = lower;
        }
        return Align(
            alignment: textAlign == TextAlign.center ? Alignment.center : Alignment.centerLeft,
            child: Text(title,
                maxLines: maxLines,
                softWrap: maxLines > 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: style.copyWith(fontSize: style.fontSize! * scale)));
      });
}

/// inset 0.75、圆角 11.25、线宽 1.5 的渐变描边。
class _CoGuestActiveBorderPainter extends CustomPainter {
  const _CoGuestActiveBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final RRect border = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      const Radius.circular(11.25),
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: <Color>[LiveTheme.brandDeepBlue, LiveTheme.brandBlue, LiveTheme.brandCyan],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(border, paint);
  }

  @override
  bool shouldRepaint(_CoGuestActiveBorderPainter oldDelegate) => false;
}

abstract final class _PusherCoGuestSettingsStyle {
  static const endAllForeground = Color(0xFFE56B73);
  static const templateBackground = Color(0x38000000);
}

abstract final class PusherCoGuestGroupStyle {
  static const background = Color(0x47000000);
  static const cornerRadius = 16.0;
}
