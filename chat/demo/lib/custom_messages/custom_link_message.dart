import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/language/gen/demo_localizations.dart';

/// Demo custom message carrying a bit of text plus an external link, used to
/// show how a host app plugs its own message type into the Chat UIKit.
class CustomLinkMessage {
  static const String businessID = 'text_link';

  final String text;
  final String link;

  const CustomLinkMessage({required this.text, required this.link});

  /// Parses [customData]; returns null when it is absent or not our payload.
  static CustomLinkMessage? from(String? customData) {
    if (customData == null || customData.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(customData);
      if (decoded is! Map) return null;
      return CustomLinkMessage(
        text: decoded['text']?.toString() ?? '',
        link: decoded['link']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Reads the payload out of a message, or null when it is not one of ours.
  static CustomLinkMessage? fromMessage(MessageInfo message) {
    final payload = message.messagePayload as CustomMessagePayload?;
    return from(payload?.customData);
  }

  String toJsonString() => jsonEncode({
        'businessID': businessID,
        'text': text,
        'link': link,
      });
}

/// Bubble rendering a [CustomLinkMessage]: the text, plus a tappable
/// "view details" line when the payload carries a link.
class CustomLinkMessageWidget extends StatelessWidget {
  final CustomMessageRenderInfo info;

  const CustomLinkMessageWidget({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final demoLocale = DemoLocalizations.of(context);
    final linkMessage = CustomLinkMessage.fromMessage(info.message);
    final text = linkMessage?.text ?? '';
    final link = linkMessage?.link.trim() ?? '';
    final isSelf = info.isSelf;

    // In multi-select mode the row-level tap toggles selection, and the merged
    // detail view is read-only — leave the tap alone in both cases.
    final canOpenLink = link.isNotEmpty && !info.isMultiSelectMode && !info.isInMergedDetailView;

    return GestureDetector(
      onTap: canOpenLink ? () => _openLink(link) : null,
      onLongPress: info.onLongPress,
      child: info.defaultBubble(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: FontScheme.caption1Regular.copyWith(
                color: isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
              ),
            ),
            if (link.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                demoLocale.customMessageViewDetails,
                style: FontScheme.caption2Regular.copyWith(
                  color: colorsTheme.textColorLink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Wires the custom link message into the UIKit: the message list renderer,
/// the more panel entry that sends one, and the conversation list preview.
class CustomLinkMessageManager {
  CustomLinkMessageManager._();

  static const String _sampleLink = 'https://cloud.tencent.com/document/product/269/3794';

  /// Renders the custom link message in the message list. Pass this to every
  /// page that can open a chat, so the message renders no matter how the user
  /// reached the conversation.
  static ChatMessageListConfig get messageListConfig => ChatMessageListConfig(
        customMessageBuilders: {
          CustomLinkMessage.businessID: (context, info) => CustomLinkMessageWidget(info: info),
        },
      );

  /// Adds the "custom message" entry to the more panel. Takes the localizations
  /// because the title is resolved when the panel is built. Everything unrelated
  /// to the custom message is left to the host, which can layer it on with
  /// [ChatMessageInputConfig.copyWith].
  static ChatMessageInputConfig messageInputConfig(DemoLocalizations demoLocale) {
    return ChatMessageInputConfig(
      customMoreActions: [
        MessageInputMoreAction(
          id: 'demo.messageInput.customLink',
          title: demoLocale.customMessageMenuTitle,
          iconAssetName: 'assets/custom_message.svg',
          onTap: _sendSampleMessage,
        ),
      ],
    );
  }

  /// Shows the message text (instead of a generic "custom message") as the
  /// conversation list preview. Global, because the conversation list renders
  /// outside any chat page.
  static void registerMessageSummary() {
    MessageSummaryRegistry.register(
      CustomLinkMessage.businessID,
      (context, message) => CustomLinkMessage.fromMessage(message)?.text,
    );
  }

  static Future<void> _sendSampleMessage(BuildContext context, String conversationID) async {
    final message = CustomLinkMessage(
      text: DemoLocalizations.of(context).customMessageContent,
      link: _sampleLink,
    );
    final result = await MessageInputStore.create(conversationID: conversationID).sendMessage(
      payload: CustomSendMessagePayload(
        customData: message.toJsonString(),
        description: message.text,
      ),
    );
    if (!result.isSuccess) {
      debugPrint('send custom link message failed: ${result.errorCode}, ${result.errorMessage}');
    }
  }
}
