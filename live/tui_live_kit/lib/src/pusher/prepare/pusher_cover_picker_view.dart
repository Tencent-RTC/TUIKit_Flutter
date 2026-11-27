import '../../common/theme/live_theme.dart';
import 'package:flutter/widgets.dart';

import '../../common/live_image_loader.dart';
import '../../common/live_kit_resources.dart';
import '../../common/theme/bottom_sheet_view.dart';

class PusherCoverPickerView extends StatefulWidget {
  const PusherCoverPickerView({
    super.key,
    required this.selectedCoverURL,
    required this.onDismiss,
    this.onSelect,
  });

  /// 当前封面。
  final String selectedCoverURL;

  final VoidCallback onDismiss;

  /// 回传选中的预置封面。
  final void Function(String coverURL)? onSelect;

  static const double sheetHeight = 190;

  static const double _horizontalInset = 20;

  static const double _optionSpacing = 8;

  @override
  State<PusherCoverPickerView> createState() => _PusherCoverPickerViewState();
}

class _PusherCoverPickerViewState extends State<PusherCoverPickerView> {
  final BottomSheetController _sheetController = BottomSheetController();

  @override
  Widget build(BuildContext context) {
    const List<String> urls = LiveKitResources.presetCoverURLs;

    return BottomSheetView(
      sheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.prepare.change_cover'),
      controller: _sheetController,
      sheetHeight: PusherCoverPickerView.sheetHeight,
      onDismiss: widget.onDismiss,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: PusherCoverPickerView._horizontalInset,
            right: PusherCoverPickerView._horizontalInset,
            top: 68,
            child: Row(
              children: <Widget>[
                for (int index = 0; index < urls.length; index++) ...<Widget>[
                  if (index > 0) const SizedBox(width: PusherCoverPickerView._optionSpacing),
                  Expanded(
                    child: _PusherCoverOptionView(
                      coverURL: urls[index],
                      index: index,
                      isSelected: urls[index] == widget.selectedCoverURL,
                      onSelect: () async {
                        widget.onSelect?.call(urls[index]);
                        await _sheetController.dismiss();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PusherCoverOptionView extends StatelessWidget {
  const _PusherCoverOptionView({
    required this.coverURL,
    required this.index,
    required this.isSelected,
    required this.onSelect,
  });

  final String coverURL;
  final int index;
  final bool isSelected;
  final VoidCallback onSelect;

  /// UIColor.white.withAlphaComponent(0.06)
  static const Color _backgroundColor = Color(0x0FFFFFFF);

  /// UIColor.white.withAlphaComponent(0.14)
  static const Color _borderColor = Color(0x24FFFFFF);

  /// UIColor(red: 0.29, green: 0.62, blue: 1, alpha: 1)
  static const Color _selectedBorderColor = LiveTheme.brandBlue;

  static const double _loadingOpacity = 0.55;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = LiveImageLoader.provider(coverURL);
    if (provider == null) {
      return _buildCandidate(isLoaded: false, child: const SizedBox.expand());
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, loaded) => _buildCandidate(
        isLoaded: loaded || frame != null,
        child: child,
      ),
      errorBuilder: (context, error, stackTrace) => _buildCandidate(isLoaded: false, child: const SizedBox.expand()),
    );
  }

  Widget _buildCandidate({required bool isLoaded, required Widget child}) {
    return Semantics(
      button: true,
      enabled: isLoaded,
      selected: isSelected,
      label: LiveKitResources.localizedFormat(
        'tuilivekit.pusher.prepare.cover_option',
        index + 1,
      ),
      child: Opacity(
        opacity: isLoaded ? 1 : _loadingOpacity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isLoaded ? onSelect : null,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: _backgroundColor, borderRadius: BorderRadius.circular(12)),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _selectedBorderColor : _borderColor, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
