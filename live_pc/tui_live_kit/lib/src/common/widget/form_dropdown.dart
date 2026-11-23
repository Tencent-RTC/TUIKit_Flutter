import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../style/constants.dart';
import '../style/live_kit_style.dart';
import 'hover_clickable.dart';

class FormDropdownItem<T> {
  const FormDropdownItem({required this.value, required this.label, this.enabled = true});

  final T value;
  final String label;

  final bool enabled;
}

enum FormDropdownMenuStyle { dialog, ambientMenu }

class FormDropdown<T> extends StatefulWidget {
  const FormDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.menuStyle = FormDropdownMenuStyle.dialog,
  });

  final List<FormDropdownItem<T>> items;
  final ValueChanged<T> onChanged;

  final T? value;
  final String? hint;

  final FormDropdownMenuStyle menuStyle;

  @override
  State<FormDropdown<T>> createState() => _FormDropdownState<T>();
}

const double _kDropdownItemHeight = 36;

class _FormDropdownState<T> extends State<FormDropdown<T>> {
  static const double _kFieldHeight = 36;
  static const double _kMenuGap = 4;
  static const double _kMenuMargin = 8;

  OverlayEntry? _menuEntry;

  bool get _open => _menuEntry != null;

  String? get _currentLabel {
    for (final item in widget.items) {
      if (item.value == widget.value) {
        return item.label;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _toggle() {
    if (_open || widget.items.isEmpty) {
      _removeMenu();
      return;
    }
    _openMenu();
  }

  void _openMenu() {
    final box = context.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero, ancestor: overlay);
    final overlaySize = overlay.size;
    final menuTop = anchor.dy + box.size.height + _kMenuGap;
    final maxMenuHeight = (overlaySize.height - menuTop - _kMenuMargin).clamp(0.0, double.infinity);
    final left = anchor.dx.clamp(0.0, (overlaySize.width - box.size.width).clamp(0.0, double.infinity));

    _menuEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _removeMenu,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: left,
                top: menuTop.clamp(0.0, double.infinity),
                width: box.size.width,
                child: Material(
                  color: Colors.transparent,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(fontFamilyFallback: getTargetPlatformTextFont),
                    child: Container(
                      decoration:
                          widget.menuStyle == FormDropdownMenuStyle.ambientMenu
                              ? LiveKitStyle.menuSurface()
                              : BoxDecoration(
                                color: const Color(0xFF2A2536),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: LiveKitStyle.white8),
                              ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.menuStyle == FormDropdownMenuStyle.ambientMenu ? 10 : 8,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxMenuHeight),
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            children: [
                              for (final item in widget.items)
                                _FormDropdownMenuItem<T>(
                                  item: item,
                                  selected: item.value == widget.value,
                                  onTap: () {
                                    _removeMenu();
                                    widget.onChanged(item.value);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
    Overlay.of(context).insert(_menuEntry!);
  }

  void _removeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _currentLabel != null;
    return HoverClickable(
      onTap: _toggle,
      enabled: widget.items.isNotEmpty,
      child: Container(
        height: _kFieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: LiveKitStyle.softPanel(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? _currentLabel! : (widget.hint ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: hasValue ? LiveKitStyle.textPrimary : LiveKitStyle.textDisabled),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _open ? RemixIcons.arrow_up_s_line : RemixIcons.arrow_down_s_line,
              size: 14,
              color: LiveKitStyle.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormDropdownMenuItem<T> extends StatefulWidget {
  const _FormDropdownMenuItem({required this.item, required this.selected, required this.onTap});

  final FormDropdownItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FormDropdownMenuItem<T>> createState() => _FormDropdownMenuItemState<T>();
}

class _FormDropdownMenuItemState<T> extends State<_FormDropdownMenuItem<T>> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.item.enabled;
    final highlighted = enabled && (widget.selected || _hovering);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _kDropdownItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: highlighted ? LiveKitStyle.white10 : Colors.transparent,
          child: Text(
            widget.item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color:
                  !enabled
                      ? LiveKitStyle.textDisabled
                      : highlighted
                      ? LiveKitStyle.textPrimary
                      : LiveKitStyle.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
