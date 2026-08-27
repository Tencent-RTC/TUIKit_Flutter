import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import '../../../common/language/gen/chat_localizations.dart';

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
    final chatLocale = ChatLocalizations.of(context);
    final customMessage = (message.messagePayload as CustomMessagePayload?);

    final customContent = ChatUtil.jsonData2Dictionary(customMessage?.customData);
    if (customContent != null && customContent['businessID'] == 'group_create') {
      return _buildSystemMessage(context, colors, chatLocale, customContent);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: _buildDefaultCustomMessagePayload(context, colors, chatLocale),
    );
  }

  Widget _buildSystemMessage(BuildContext context, SemanticColorScheme colorsTheme, ChatLocalizations chatLocale,
      Map<String, dynamic> customContent) {
    String content = '';

    switch (customContent['businessID']) {
      case 'group_create':
        final sender = customContent['opUser'];
        final cmd = customContent['cmd'] as int? ?? 0;
        if (cmd >= 0) {
          if (cmd == 1) {
            content = '$sender ${chatLocale.createCommunity}';
          } else {
            content = '$sender ${chatLocale.createGroupTips}';
          }
        }
        break;
      default:
        content = customContent['content']?.toString() ?? chatLocale.messageTypeCustom;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.0),
      child: Center(
        child: Text(
          content,
          style: FontScheme.caption3Regular.copyWith(
            color: colorsTheme.textColorTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDefaultCustomMessagePayload(
    BuildContext context,
    SemanticColorScheme colorsTheme,
    ChatLocalizations chatLocale,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isSelf ? colorsTheme.bgColorBubbleOwn : colorsTheme.bgColorBubbleReciprocal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        chatLocale.messageTypeCustom,
        style: FontScheme.caption2Medium.copyWith(
          color: isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
        ),
      ),
    );
  }
}
