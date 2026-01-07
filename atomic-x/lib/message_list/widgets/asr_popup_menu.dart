import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// Menu action for ASR text bubble
class AsrPopupMenuAction {
  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  const AsrPopupMenuAction({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });
}

/// A popup menu widget for ASR text bubble, displayed above the target widget
/// Similar to Android's AuxiliaryTextPopupMenu
class AsrPopupMenu extends StatelessWidget {
  final List<AsrPopupMenuAction> actions;

  const AsrPopupMenu({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgColorOperate,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions.map((action) {
            return _AsrPopupMenuItem(
              label: action.label,
              iconAsset: action.iconAsset,
              onTap: action.onTap,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AsrPopupMenuItem extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  const _AsrPopupMenuItem({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20,
              height: 20,
              package: 'tuikit_atomic_x',
              colorFilter: ColorFilter.mode(
                colors.textColorLink,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colors.textColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show ASR popup menu above the target widget
/// Returns when the menu is dismissed
Future<void> showAsrPopupMenu({
  required BuildContext context,
  required GlobalKey targetKey,
  required List<AsrPopupMenuAction> actions,
  bool isSelf = false,
}) async {
  final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final Offset targetPosition = renderBox.localToGlobal(Offset.zero);
  final Size targetSize = renderBox.size;
  final Size screenSize = MediaQuery.of(context).size;

  // Calculate menu position (above the target)
  // Menu width estimation: ~3 items * 60px each = ~180px
  // Menu height: icon(20) + spacing(4) + text(~12) + padding(8*2) = ~52px
  const double menuWidth = 180;
  const double menuHeight = 52;
  const double verticalOffset = 4;

  double left;
  if (isSelf) {
    // For self messages, align to the right
    left = targetPosition.dx + targetSize.width - menuWidth;
  } else {
    // For other messages, align to the left
    left = targetPosition.dx;
  }

  // Ensure menu stays within screen bounds
  if (left < 8) left = 8;
  if (left + menuWidth > screenSize.width - 8) {
    left = screenSize.width - menuWidth - 8;
  }

  // Position above the target
  double top = targetPosition.dy - menuHeight - verticalOffset;
  // If not enough space above, show below
  if (top < MediaQuery.of(context).padding.top + 8) {
    top = targetPosition.dy + targetSize.height + verticalOffset;
  }

  final OverlayState overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Transparent barrier to dismiss menu
          Positioned.fill(
            child: GestureDetector(
              onTap: () => overlayEntry.remove(),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu
          Positioned(
            left: left,
            top: top,
            child: AsrPopupMenu(
              actions: actions.map((action) {
                return AsrPopupMenuAction(
                  label: action.label,
                  iconAsset: action.iconAsset,
                  onTap: () {
                    overlayEntry.remove();
                    action.onTap();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      );
    },
  );

  overlayState.insert(overlayEntry);
}
