import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

class CustomMessageWidget extends StatelessWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MessageListStore? messageListStore;

  const CustomMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    this.onTap,
    this.onLongPress,
    this.messageListStore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final atomicLocale = AtomicLocalizations.of(context);
    final customMessage = message.messageBody?.customMessage;

    final customContent = ChatUtil.jsonData2Dictionary(customMessage?.data);
    if (customContent != null && customContent['businessID'] == 'group_create') {
      return _buildSystemMessage(context, colors, atomicLocale, customContent);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: _buildDefaultCustomMessage(context, colors, atomicLocale),
    );
  }

  Widget _buildSystemMessage(BuildContext context, SemanticColorScheme colorsTheme, AtomicLocalizations atomicLocale,
      Map<String, dynamic> customContent) {
    String content = '';

    switch (customContent['businessID']) {
      case 'group_create':
        final sender = customContent['opUser'];
        final cmd = customContent['cmd'] as int? ?? 0;
        if (cmd >= 0) {
          if (cmd == 1) {
            content = '$sender ${atomicLocale.createCommunity}';
          } else {
            content = '$sender ${atomicLocale.createGroupTips}';
          }
        }
        break;
      default:
        content = customContent['content']?.toString() ?? atomicLocale.messageTypeCustom;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorsTheme.strokeColorPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: colorsTheme.textColorTertiary,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCustomMessage(
    BuildContext context,
    SemanticColorScheme colorsTheme,
    AtomicLocalizations atomicLocale,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isSelf ? colorsTheme.buttonColorPrimaryDefault : colorsTheme.bgColorDefault,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        atomicLocale.messageTypeCustom,
        style: TextStyle(
          color: isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
