import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../l10n/live_kit_localizations.dart';
import '../../../../../common/style/live_kit_style.dart';
import '../../../../../common/widget/panel_dialog.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import '../source_type_card_grid.dart';

Future<MediaSourceKind?> showSourceAddDialog(BuildContext context) {
  return showPanelDialog<MediaSourceKind>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: const _SourceAddDialog(),
  );
}

class _SourceAddDialog extends StatelessWidget {
  const _SourceAddDialog();

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    final cards = sourceTypeCards(strings);
    return PanelDialog(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelDialogHeader(icon: RemixIcons.add_box_line, title: strings.sourceAddTitle),
          Container(height: 1, color: LiveKitStyle.white6),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SourceTypeCardGrid(cards: cards, onTap: (card) => Navigator.pop(context, card.kind)),
          ),
        ],
      ),
    );
  }
}
