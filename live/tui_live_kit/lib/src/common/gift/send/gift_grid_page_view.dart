library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../live_image_loader.dart';
import '../../live_kit_resources.dart';
import 'gift_send_combo_button.dart';
import 'gift_send_panel_view.dart';

@immutable
class GiftGridSelectionState {
  const GiftGridSelectionState.none()
      : selectedID = null,
        comboID = null;

  const GiftGridSelectionState.selected(String id)
      : selectedID = id,
        comboID = null;

  const GiftGridSelectionState.combo(String id)
      : selectedID = null,
        comboID = id;

  final String? selectedID;
  final String? comboID;

  bool get isEmpty => selectedID == null && comboID == null;
}

class GiftGridPageView extends StatefulWidget {
  const GiftGridPageView({
    super.key,
    required this.gifts,
    required this.selection,
    required this.onCellTapped,
    required this.onComboSend,
    required this.onComboExpired,
  });

  final List<Gift> gifts;
  final GiftGridSelectionState selection;
  final ValueChanged<Gift> onCellTapped;
  final ValueChanged<Gift> onComboSend;
  final VoidCallback onComboExpired;

  @override
  State<GiftGridPageView> createState() => _GiftGridPageViewState();
}

class _GiftGridPageViewState extends State<GiftGridPageView> {
  static const int _columns = 4;
  static const double _cellSpacing = 4;
  static const double _rowSpacing = 2;
  static const double _horizontalPadding = 10;

  final GiftSendComboButtonController _comboController = GiftSendComboButtonController();
  String? _boundComboID;

  @override
  void initState() {
    super.initState();
    _comboController.onSendOnce = _handleComboSend;
    _comboController.onExpired = _handleComboExpired;
    _applyComboBinding();
  }

  @override
  void didUpdateWidget(covariant GiftGridPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyComboBinding();
  }

  @override
  void dispose() {
    _comboController.onSendOnce = null;
    _comboController.onExpired = null;
    _comboController.dispose();
    super.dispose();
  }

  void _applyComboBinding() {
    final String? comboID = widget.selection.comboID;
    if (comboID == null) {
      if (_boundComboID != null) {
        _boundComboID = null;
        _comboController.end();
      }
      return;
    }
    final Gift? gift = _findGift(comboID);
    if (gift == null) {
      if (_boundComboID != null) {
        _boundComboID = null;
        _comboController.end();
      }
      return;
    }
    if (_boundComboID == comboID) return;
    _boundComboID = comboID;
    _startComboWhenReady(gift);
  }

  void _startComboWhenReady(Gift gift) {
    // begin sends immediately. Defer that event until this selection has been
    // rendered, so an owner's send callback never runs during its build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_boundComboID != gift.giftID || widget.selection.comboID != gift.giftID) {
        return;
      }
      final currentGift = _findGift(gift.giftID);
      if (currentGift == null) return;
      _comboController.begin(currentGift);
    });
  }

  Gift? _findGift(String id) {
    for (final Gift gift in widget.gifts) {
      if (gift.giftID == id) return gift;
    }
    return null;
  }

  void _handleComboSend() {
    final Gift? gift = _comboController.gift;
    if (gift == null || widget.selection.comboID != gift.giftID) return;
    final currentGift = _findGift(gift.giftID);
    if (currentGift == null) return;
    widget.onComboSend(currentGift);
  }

  void _handleComboExpired() {
    _boundComboID = null;
    widget.onComboExpired();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        if (totalWidth <= 0) return const SizedBox.shrink();
        const double totalSpacing = _cellSpacing * (_columns - 1);
        final double availableWidth = totalWidth - _horizontalPadding * 2 - totalSpacing;
        final double cellWidth = (availableWidth / _columns).floorToDouble();
        final double rowHeight = GiftPanelStyle.rowHeight(context);
        final int itemCount = widget.gifts.length;
        final int rows = (itemCount / _columns).ceil();
        final double totalHeight = rows == 0 ? 0 : rows * rowHeight + (rows - 1) * _rowSpacing;

        final Rect? comboBounds = _comboBounds(itemCount, cellWidth, rowHeight);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              children: <Widget>[
                for (int index = 0; index < itemCount; index++)
                  _buildPositionedCell(
                    index: index,
                    cellWidth: cellWidth,
                    rowHeight: rowHeight,
                  ),
                Positioned.fromRect(
                  rect: comboBounds ?? Rect.fromLTWH(0, 0, cellWidth, rowHeight),
                  child: Offstage(
                    offstage: comboBounds == null,
                    child: GiftSendComboButton(controller: _comboController),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionedCell({
    required int index,
    required double cellWidth,
    required double rowHeight,
  }) {
    final Gift gift = widget.gifts[index];
    final int row = index ~/ _columns;
    final int column = index % _columns;
    final double x = _horizontalPadding + column * (cellWidth + _cellSpacing);
    final double y = row * (rowHeight + _rowSpacing);

    final String? selectedID = widget.selection.selectedID;
    final String? comboID = widget.selection.comboID;
    final _GiftItemState state;
    if (comboID == gift.giftID) {
      state = _GiftItemState.combo;
    } else if (selectedID == gift.giftID) {
      state = _GiftItemState.selected;
    } else {
      state = _GiftItemState.normal;
    }

    return Positioned(
      left: x,
      top: y,
      width: cellWidth,
      height: rowHeight,
      child: state == _GiftItemState.combo
          ? const SizedBox.shrink()
          : _GiftItemView(
              key: ValueKey(gift.giftID),
              gift: gift,
              state: state,
              onTap: () => widget.onCellTapped(gift),
            ),
    );
  }

  Rect? _comboBounds(int itemCount, double cellWidth, double rowHeight) {
    final String? comboID = widget.selection.comboID;
    if (comboID == null) return null;
    for (int index = 0; index < itemCount; index++) {
      if (widget.gifts[index].giftID != comboID) continue;
      final int row = index ~/ _columns;
      final int column = index % _columns;
      final double x = _horizontalPadding + column * (cellWidth + _cellSpacing);
      final double y = row * (rowHeight + _rowSpacing);
      return Rect.fromLTWH(x, y, cellWidth, rowHeight);
    }
    return null;
  }
}

enum _GiftItemState { normal, selected, combo }

class _GiftItemView extends StatelessWidget {
  const _GiftItemView({
    super.key,
    required this.gift,
    required this.state,
    required this.onTap,
  });

  final Gift gift;
  final _GiftItemState state;
  final VoidCallback onTap;

  static const Color _selectedBorder = Color(0xB34A9EFF);
  static const Color _selectedBackground = Color(0x264A9EFF);
  static const Color _coinColor = GiftPanelStyle.coin;
  static const List<Color> _sendGradient = <Color>[
    GiftPanelStyle.blue,
    GiftPanelStyle.deepBlue,
  ];

  @override
  Widget build(BuildContext context) {
    if (state == _GiftItemState.combo) {
      return const SizedBox.shrink();
    }
    final bool selected = state == _GiftItemState.selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? _selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _selectedBorder : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: 44,
              height: 44,
              child: _buildIcon(),
            ),
            const SizedBox(height: 4),
            if (!selected) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.94),
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              _buildPrice(selected: false),
              const Spacer(),
            ] else ...<Widget>[
              const Spacer(),
              _buildPrice(selected: true),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: _buildSendButton(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final ImageProvider? provider = LiveImageLoader.provider(gift.iconURL);
    if (provider == null) {
      return const SizedBox.shrink();
    }
    return Image(
      image: provider,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildPrice({required bool selected}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _coinColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${gift.coins}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.94),
              fontSize: 10,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return Container(
      height: GiftPanelStyle.sendButtonHeight(context),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _sendGradient,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        LiveKitResources.localizedString('tuilivekit.player.gift.send'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
