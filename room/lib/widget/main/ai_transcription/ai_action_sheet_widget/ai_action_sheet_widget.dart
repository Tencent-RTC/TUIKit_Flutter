import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

/// AI action sheet widget displayed as a bottom sheet for AI subtitle and minutes control.
class AIActionSheetWidget extends StatefulWidget {
  final bool isAISubtitleVisible;
  final VoidCallback onEnableAISubtitle;
  final VoidCallback onDisableAISubtitle;
  final VoidCallback onOpenMinutes;

  const AIActionSheetWidget({
    super.key,
    required this.isAISubtitleVisible,
    required this.onEnableAISubtitle,
    required this.onDisableAISubtitle,
    required this.onOpenMinutes,
  });

  @override
  State<AIActionSheetWidget> createState() => _AIActionSheetWidgetState();
}

class _AIActionSheetWidgetState extends State<AIActionSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDropDownButton(context),
        _buildActionList(),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildDropDownButton(BuildContext context) {
    return SizedBox(
      height: 35.height,
      width: double.infinity,
      child: IconButton(
        icon: Image.asset(RoomImages.roomLine, package: RoomConstants.pluginName, width: 24.width, height: 24.height),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildActionList() {
    final actions = <Widget>[];

    if (widget.isAISubtitleVisible) {
      actions.add(_buildActionItem(
        text: RoomLocalizations.of(context)!.roomkit_transcription_close_subtitle,
        iconPath: RoomImages.aiSubtitle,
        textColor: RoomColors.g6,
        onTap: widget.onDisableAISubtitle,
      ));
    } else {
      actions.add(_buildActionItem(
        text: RoomLocalizations.of(context)!.roomkit_transcription_open_subtitle,
        iconPath: RoomImages.aiSubtitle,
        onTap: widget.onEnableAISubtitle,
      ));
    }
    actions.add(Divider(thickness: 1.height, height: 0, color: RoomColors.dividerGrey));
    actions.add(_buildActionItem(
      text: RoomLocalizations.of(context)!.roomkit_transcription_open_minutes,
      iconPath: RoomImages.aiMinutes,
      onTap: widget.onOpenMinutes,
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _buildActionItem({
    required String text,
    required String iconPath,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: textColor ?? RoomColors.g6,
              package: RoomConstants.pluginName,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? RoomColors.g6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension AIActionSheetWidgetExtension on AIActionSheetWidget {
  void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => this,
    );
  }
}
