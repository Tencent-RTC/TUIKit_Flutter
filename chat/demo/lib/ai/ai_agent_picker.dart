import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import '../common/language/gen/demo_localizations.dart';
import 'custom_bot_dialog.dart';
import 'support_agent_catalog.dart';

/// Assistant picker in the AI home's top-left corner: the server's built-in
/// assistants plus a last "custom AI assistant" entry.
///
/// A solid gradient pill; the first time it shows a NEW badge and a breathing
/// pulse to draw a tap, both gone after the first tap. The choice is written
/// to [SupportAgentCatalog] and [onSelectionChanged] lets the page reload.
class AIAgentPicker extends StatefulWidget {
  const AIAgentPicker({
    super.key,
    required this.agent,
    required this.onSelectionChanged,
  });

  /// The assistant currently loaded; null shows "AI assistant".
  final AIAssistantAgent? agent;
  final VoidCallback onSelectionChanged;

  static const Color brandPurple = Color(0xFF7B5CFF);
  static const Color brandBlue = Color(0xFF2EC5FF);
  static const Color _purpleSoft = Color(0x267B5CFF);
  static const Color _badgeRed = Color(0xFFFF4D4F);

  @override
  State<AIAgentPicker> createState() => _AIAgentPickerState();
}

class _AIAgentPickerState extends State<AIAgentPicker>
    with SingleTickerProviderStateMixin {
  static const String _seenKey = 'ai_agent_picker_seen';

  final GlobalKey _pillKey = GlobalKey();
  late final AnimationController _attention = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  bool _badgeVisible = false;

  /// Shown right after a switch, before the reload brings the new assistant.
  String? _pendingLabel;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted || (prefs.getBool(_seenKey) ?? false)) return;
      setState(() => _badgeVisible = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _badgeVisible) _attention.repeat();
      });
    });
  }

  @override
  void didUpdateWidget(covariant AIAgentPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent != widget.agent) _pendingLabel = null;
  }

  @override
  void dispose() {
    _attention.dispose();
    super.dispose();
  }

  void _onPillTap() {
    if (_badgeVisible) {
      setState(() => _badgeVisible = false);
      _attention
        ..stop()
        ..value = 0;
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setBool(_seenKey, true));
    }
    _showMenu();
  }

  Future<void> _showMenu() async {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final colors = BaseThemeProvider.colorsOf(context);
    final l10n = DemoLocalizations.of(context);
    final action = await showGeneralDialog<_MenuAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, _, __) => CustomSingleChildLayout(
        delegate: _BelowAnchorLayout(anchor),
        child: _AgentMenu(
          colors: colors,
          l10n: l10n,
          onAction: (action) => Navigator.of(dialogContext).pop(action),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
    if (action == null || !mounted) return;
    switch (action.kind) {
      case _MenuKind.builtIn:
        final agent = action.agent!;
        await SupportAgentCatalog.setSelectedBotUserID(agent.imUserId);
        _changed(agent.displayName);
        break;
      case _MenuKind.custom:
        await _selectCustom();
        break;
      case _MenuKind.editCustom:
        if (await CustomBotDialog.show(context)) _changed(_customLabel());
        break;
    }
  }

  Future<void> _selectCustom() async {
    if (SupportAgentCatalog.customBotUserID.isEmpty) {
      if (await CustomBotDialog.show(context)) _changed(_customLabel());
      return;
    }
    await SupportAgentCatalog.setSelectedBotUserID(
        SupportAgentCatalog.customBotUserID);
    _changed(_customLabel());
  }

  String _customLabel() =>
      SupportAgentCatalog.customAgent?.displayName ??
      SupportAgentCatalog.customBotUserID;

  void _changed(String label) {
    if (!mounted) return;
    setState(() => _pendingLabel = label);
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DemoLocalizations.of(context);
    final label =
        _pendingLabel ?? widget.agent?.displayName ?? l10n.aiVoiceTitle;
    final pill = Semantics(
      button: true,
      label: l10n.aiAgentPickerTitle,
      child: GestureDetector(
        key: _pillKey,
        onTap: _onPillTap,
        child: Container(
          height: 36,
          padding: const EdgeInsetsDirectional.only(start: 12, end: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AIAgentPicker.brandPurple, AIAgentPicker.brandBlue]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x407B5CFF), blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✦',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                'chat_assets/icon/aiassistant/ai_title_dropdown.svg',
                package: 'tencent_chat_uikit',
                width: 18,
                height: 18,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 7, end: 12),
          child: AnimatedBuilder(
            animation: _attention,
            // 1 → 1.07 → 1 per cycle.
            builder: (_, child) => Transform.scale(
              scale: 1 + 0.07 * math.sin(_attention.value * math.pi),
              child: child,
            ),
            child: pill,
          ),
        ),
        if (_badgeVisible)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AIAgentPicker._badgeRed,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                l10n.aiAgentNewBadge,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

enum _MenuKind { builtIn, custom, editCustom }

class _MenuAction {
  const _MenuAction(this.kind, [this.agent]);

  final _MenuKind kind;
  final AIAssistantAgent? agent;
}

class _AgentMenu extends StatelessWidget {
  const _AgentMenu({
    required this.colors,
    required this.l10n,
    required this.onAction,
  });

  final SemanticColorScheme colors;
  final DemoLocalizations l10n;
  final ValueChanged<_MenuAction> onAction;

  @override
  Widget build(BuildContext context) {
    final customSelected = SupportAgentCatalog.isCustomSelected;
    final boundID = SupportAgentCatalog.agents.isEmpty
        ? null
        : SupportAgentCatalog.agents.first.imUserId;
    final customID = SupportAgentCatalog.customBotUserID;
    final configured = customID.isNotEmpty;
    return Material(
      color: colors.bgColorDialog,
      elevation: 12,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.strokeColorSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 292,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Text(l10n.aiAgentPickerTitle,
                    style: TextStyle(
                        fontSize: 12, color: colors.textColorSecondary)),
              ),
              for (final agent in SupportAgentCatalog.directory)
                _row(
                  icon: _builtInIcon(agent),
                  title: agent.displayName,
                  selected: !customSelected && agent.imUserId == boundID,
                  onTap: () => onAction(_MenuAction(_MenuKind.builtIn, agent)),
                ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: colors.strokeColorSecondary,
              ),
              _row(
                icon: const _CustomIcon(),
                title: l10n.aiAgentCustomTitle,
                subtitle: configured
                    ? (SupportAgentCatalog.customAgent?.displayName ?? customID)
                    : l10n.aiAgentCustomDesc,
                selected: customSelected,
                trailing: GestureDetector(
                  onTap: () =>
                      onAction(const _MenuAction(_MenuKind.editCustom)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AIAgentPicker._purpleSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      configured
                          ? l10n.aiAgentCustomEdit
                          : l10n.aiAgentCustomGo,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AIAgentPicker.brandPurple),
                    ),
                  ),
                ),
                onTap: () => onAction(const _MenuAction(_MenuKind.custom)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required Widget icon,
    required String title,
    String? subtitle,
    required bool selected,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AIAgentPicker._purpleSoft : null,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
        child: Row(
          children: [
            SizedBox.square(dimension: 34, child: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AIAgentPicker.brandPurple
                          : colors.textColorPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: colors.textColorSecondary),
                    ),
                ],
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 8),
                child: Text('✓',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AIAgentPicker.brandPurple)),
              ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  /// Built-in assistant: gradient circle with the first character.
  Widget _builtInIcon(AIAssistantAgent agent) {
    final name = agent.displayName.trim();
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AIAgentPicker.brandPurple, AIAgentPicker.brandBlue],
        ),
      ),
      child: Text(
        name.isEmpty ? '' : name.characters.first,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

/// Custom assistant: dashed circle with a plus, set apart from built-ins.
class _CustomIcon extends StatelessWidget {
  const _CustomIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(),
      child: const Center(
        child: Text('+',
            style: TextStyle(fontSize: 20, color: AIAgentPicker.brandPurple)),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 0.5;
    canvas.drawCircle(
        center, radius, Paint()..color = AIAgentPicker._purpleSoft);
    final stroke = Paint()
      ..color = AIAgentPicker.brandPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 3.0, gap = 2.0;
    final count = (2 * math.pi * radius / (dash + gap)).floor();
    final sweep = 2 * math.pi / count;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(
          rect, i * sweep, sweep * dash / (dash + gap), false, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Places the menu 8 pixels below the anchor, start-aligned with it.
class _BelowAnchorLayout extends SingleChildLayoutDelegate {
  _BelowAnchorLayout(this.anchor);

  static const double _margin = 8;

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(Size(constraints.maxWidth - _margin * 2,
          constraints.maxHeight - anchor.bottom - _margin * 2));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = math.max(_margin, size.width - childSize.width - _margin);
    return Offset(anchor.left.clamp(_margin, maxX), anchor.bottom + _margin);
  }

  @override
  bool shouldRelayout(_BelowAnchorLayout oldDelegate) =>
      anchor != oldDelegate.anchor;
}
