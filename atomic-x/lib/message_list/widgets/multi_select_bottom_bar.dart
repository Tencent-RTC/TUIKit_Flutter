import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// Bottom action bar for multi-select mode
class MultiSelectBottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final bool isDeleteEnabled;
  final bool isForwardEnabled;

  const MultiSelectBottomBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
    required this.onForward,
    this.isDeleteEnabled = true,
    this.isForwardEnabled = true,
  });

  String _getSelectedCountText(AtomicLocalizations locale) {
    return locale.selectedCount(selectedCount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = AtomicLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 56 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.bgColorOperate,
        border: Border(
          top: BorderSide(
            color: colors.strokeColorPrimary,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left action buttons
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                _buildActionButton(
                  assetPath: 'chat_assets/icon/forward.svg',
                  onTap: isForwardEnabled && selectedCount > 0 ? onForward : null,
                  colors: colors,
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  assetPath: 'chat_assets/icon/delete.svg',
                  onTap: isDeleteEnabled && selectedCount > 0 ? onDelete : null,
                  colors: colors,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Selected count in center
          Text(
            _getSelectedCountText(locale),
            style: TextStyle(
              fontSize: 14,
              color: colors.textColorSecondary,
            ),
          ),

          const Spacer(),

          // Cancel button on right
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: onCancel,
              child: Text(
                locale.cancel,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textColorLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String assetPath,
    required VoidCallback? onTap,
    required SemanticColorScheme colors,
    bool isDestructive = false,
  }) {
    final isEnabled = onTap != null;
    final color = isEnabled
        ? (isDestructive ? colors.textColorError : colors.buttonColorPrimaryDefault)
        : colors.textColorDisable;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(
          assetPath,
          package: 'tuikit_atomic_x',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
