import 'package:atomic_x_core_media_mixing/atomic_x_core_media_mixing.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../../l10n/language_store.dart';
import '../../../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../common/style/live_kit_style.dart';
import '../../../../../common/widget/hover_clickable.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import 'source_dialog_shell.dart';

Future<ScreenSourceConfig?> showScreenSourceDialog(
  BuildContext context, {
  ScreenSourceConfig? initial,
  Set<String> occupiedSourceIds = const <String>{},
}) {
  return showSourceConfigDialog<ScreenSourceConfig>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _ScreenSourceDialog(initial: initial, occupiedSourceIds: occupiedSourceIds),
  );
}

class _ScreenSourceDialog extends StatefulWidget {
  const _ScreenSourceDialog({this.initial, this.occupiedSourceIds = const <String>{}});

  final ScreenSourceConfig? initial;

  final Set<String> occupiedSourceIds;

  @override
  State<_ScreenSourceDialog> createState() => _ScreenSourceDialogState();
}

class _ScreenSourceDialogState extends State<_ScreenSourceDialog> {
  late bool _isScreenTab;

  /// Enumeration is expensive (a thumbnail per window): enumerate once on open, filter locally per tab.
  List<ShareSource>? _allSources;
  String? _selectedSourceId;
  String? _errorText;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _isScreenTab = widget.initial?.isScreen ?? true;
    _selectedSourceId = widget.initial?.sourceId;
    _loadSources();
  }

  List<ShareSource>? get _sources {
    final all = _allSources;
    if (all == null) {
      return null;
    }
    return all.where((source) => (source.type == ShareSourceType.screen) == _isScreenTab).toList();
  }

  Future<void> _loadSources() async {
    setState(() {
      _allSources = null;
      _errorText = null;
    });
    try {
      // The enumeration itself triggers the macOS "Screen Recording"
      // permission prompt (first time only).
      final sources = await MediaMixingStore.shared
          .getShareSources(thumbnailSize: const Size(320, 180), iconSize: const Size(48, 48))
          .timeout(const Duration(seconds: 15));
      if (!mounted) {
        return;
      }
      setState(() {
        _allSources = sources;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _allSources = const [];
        _errorText = currentLiveKitStrings().screenEnumFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return SourceDialogShell(
      icon: RemixIcons.computer_line,
      title: _isEdit ? strings.screenEditTitle : strings.screenAddTitle,
      width: 1000,
      height: 650,
      errorText: _errorText,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _selectedSourceId != null,
      onConfirm: _confirm,
      children: [_buildCategoryTabs(), const SizedBox(height: 12), Expanded(child: _buildSourceGrid())],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: LiveKitStyle.softPanel(radius: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _categoryTab(label: LiveKitLocalizations.of(context).sourceTypeScreen, isScreenTab: true),
          const SizedBox(width: 2),
          _categoryTab(label: LiveKitLocalizations.of(context).screenTabWindow, isScreenTab: false),
        ],
      ),
    );
  }

  Widget _categoryTab({required String label, required bool isScreenTab}) {
    final selected = _isScreenTab == isScreenTab;
    return HoverClickable(
      onTap: () {
        if (selected) {
          return;
        }
        setState(() {
          _isScreenTab = isScreenTab;
          _selectedSourceId = null;
        });
      },
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? LiveKitStyle.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            color: selected ? Colors.white : LiveKitStyle.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceGrid() {
    final sources = _sources;
    if (sources == null) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: LiveKitStyle.textTertiary),
        ),
      );
    }
    if (sources.isEmpty) {
      return Center(
        child: Text(
          LiveKitLocalizations.of(context).screenEmpty(
            _isScreenTab
                ? LiveKitLocalizations.of(context).sourceTypeScreen
                : LiveKitLocalizations.of(context).screenTabWindow,
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.6, color: LiveKitStyle.textDisabled),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return _ShareSourceCard(
          source: source,
          selected: source.sourceId == _selectedSourceId,
          // Occupied sources are unselectable like minimized windows (the
          // engine identifies screen sources by id; duplicates corrupt
          // both sources' rendering).
          onTap:
              source.isMinimizeWindow || widget.occupiedSourceIds.contains(source.sourceId)
                  ? null
                  : () => setState(() => _selectedSourceId = source.sourceId),
        );
      },
    );
  }

  void _confirm() {
    final source = _sources?.firstWhere((s) => s.sourceId == _selectedSourceId);
    if (source == null) {
      return;
    }
    Navigator.pop(
      context,
      ScreenSourceConfig(
        sourceId: source.sourceId,
        sourceName: source.sourceName,
        isScreen: source.type == ShareSourceType.screen,
        width: source.width > 0 ? source.width : null,
        height: source.height > 0 ? source.height : null,
      ),
    );
  }
}

class _ShareSourceCard extends StatefulWidget {
  const _ShareSourceCard({required this.source, required this.selected, required this.onTap});

  final ShareSource source;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_ShareSourceCard> createState() => _ShareSourceCardState();
}

class _ShareSourceCardState extends State<_ShareSourceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: disabled ? 0.4 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: _hovering && !disabled ? LiveKitStyle.white10 : LiveKitStyle.softPanelBase,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.selected ? LiveKitStyle.brand2 : LiveKitStyle.white8,
                width: widget.selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (source.thumbnail != null)
                          Image(
                            image: source.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _thumbnailFallback(),
                          )
                        else
                          _thumbnailFallback(),
                        if (widget.selected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(color: LiveKitStyle.brand2, shape: BoxShape.circle),
                              child: const Icon(RemixIcons.check_line, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      if (source.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Image(
                            image: source.icon!,
                            width: 12,
                            height: 12,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          source.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: LiveKitStyle.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return const Center(child: Icon(RemixIcons.computer_line, size: 20, color: LiveKitStyle.textDisabled));
  }
}
