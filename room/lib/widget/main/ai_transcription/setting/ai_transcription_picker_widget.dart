import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

/// Single picker option item.
class AITranscriptionPickerItem {
  final String title;
  bool isSelected;

  AITranscriptionPickerItem({required this.title, this.isSelected = false});
}

/// Bottom sheet single-selection picker widget with mask overlay and slide animation.
class AITranscriptionPickerWidget extends StatelessWidget {
  final String title;
  final List<AITranscriptionPickerItem> items;
  final void Function(int index, AITranscriptionPickerItem item)? onSelect;

  const AITranscriptionPickerWidget({
    super.key,
    required this.title,
    required this.items,
    this.onSelect,
  });

  /// Show the picker as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<AITranscriptionPickerItem> items,
    void Function(int index, AITranscriptionPickerItem item)? onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AITranscriptionPickerWidget(
        title: title,
        items: items,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    const titleHeight = 56.0;
    const itemHeight = 56.0;
    final totalItemsHeight = items.length * itemHeight;
    final naturalHeight = titleHeight + totalItemsHeight + bottomPadding;
    final maxHeight = screenHeight * 0.7;
    final panelHeight =
        naturalHeight < maxHeight ? naturalHeight : maxHeight;

    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        color: RoomColors.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: titleHeight,
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: RoomColors.secondaryLabel,
                ),
              ),
            ),
          ),
          Divider(height: 0.5, thickness: 0.5, color: RoomColors.separator),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(bottom: bottomPadding),
              itemCount: items.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: RoomColors.separator),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _PickerCellWidget(
                  item: item,
                  onTap: () {
                    for (final i in items) {
                      i.isSelected = false;
                    }
                    item.isSelected = true;
                    Navigator.of(context).pop();
                    onSelect?.call(index, item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerCellWidget extends StatelessWidget {
  final AITranscriptionPickerItem item;
  final VoidCallback onTap;

  const _PickerCellWidget({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            item.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              color: item.isSelected ? RoomColors.tintBlue : RoomColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
