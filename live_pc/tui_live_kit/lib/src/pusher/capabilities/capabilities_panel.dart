import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';
import 'scene/source/source_list_view.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'scene/source/dialog/source_add_dialog.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_store_view.dart';
import 'scene/scene_list/scene_list_view.dart';
import 'scene/source/source_add_control.dart';
import 'beauty/beauty_panel.dart';
import '../../common/widget/hover_clickable.dart';
import 'capability_list.dart';

class CapabilitiesPanel extends StatefulWidget {
  const CapabilitiesPanel({super.key, required this.store, required this.controller});

  final SceneStoreView store;
  final SceneController controller;

  @override
  State<CapabilitiesPanel> createState() => _CapabilitiesPanelState();
}

class _CapabilitiesPanelState extends State<CapabilitiesPanel> {
  CapabilityTab _tab = CapabilityTab.source;

  @override
  Widget build(BuildContext context) {
    return PusherAmbientPanel(
      radius: LiveKitStyle.panelRadius,
      width: 288,
      gradient: LiveKitStyle.ambientPanelGradient,
      child: Row(
        children: [
          CapabilityList(selected: _tab, onChanged: (tab) => setState(() => _tab = tab)),
          Expanded(
            child: switch (_tab) {
              CapabilityTab.source => _SourceTabContent(store: widget.store, controller: widget.controller),
              CapabilityTab.beauty => BeautyPanel(store: widget.store, controller: widget.controller),
              CapabilityTab.more => _TabPlaceholder(
                icon: RemixIcons.puzzle_line,
                title: LiveKitLocalizations.of(context).tabMore,
                subtitle: LiveKitLocalizations.of(context).featureComingSoon,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _SourceTabContent extends StatefulWidget {
  const _SourceTabContent({required this.store, required this.controller});

  final SceneStoreView store;
  final SceneController controller;

  @override
  State<_SourceTabContent> createState() => _SourceTabContentState();
}

class _SourceTabContentState extends State<_SourceTabContent> {
  /// Disabled while in flight so a fast second click cannot add twice.
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SceneListView(store: widget.store, controller: widget.controller),
        Container(height: 1, color: LiveKitStyle.white4),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.store.hasSources,
            builder:
                (context, hasSources, _) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: _AddSourceButton(enabled: !_adding, onTap: _addSource),
                    ),
                    const SizedBox(height: 4),
                    if (hasSources) Expanded(child: SourceListView(store: widget.store, controller: widget.controller)),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _addSource() async {
    if (_adding) {
      return;
    }
    setState(() => _adding = true);
    try {
      final kind = await showSourceAddDialog(context);
      if (kind == null || !mounted) {
        return;
      }
      await addSourceByKind(context, widget.controller, kind);
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }
}

class _AddSourceButton extends StatefulWidget {
  const _AddSourceButton({required this.onTap, this.enabled = true});

  final VoidCallback onTap;

  final bool enabled;

  @override
  State<_AddSourceButton> createState() => _AddSourceButtonState();
}

class _AddSourceButtonState extends State<_AddSourceButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color background = _hovering ? LiveKitStyle.addSourceBackgroundHover : LiveKitStyle.addSourceBackground;
    final Color border = _hovering ? LiveKitStyle.addSourceBorderHover : LiveKitStyle.addSourceBorder;
    final Color foreground = _hovering ? LiveKitStyle.addSourceForegroundHover : LiveKitStyle.addSourceForeground;
    return HoverClickable(
      enabled: widget.enabled,
      onTap: widget.onTap,
      onHover: (hovering) => setState(() => _hovering = hovering),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RemixIcons.add_line, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              LiveKitLocalizations.of(context).sourceAddTitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: LiveKitStyle.textDisabled),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textHint)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textTertiary)),
        ],
      ),
    );
  }
}
