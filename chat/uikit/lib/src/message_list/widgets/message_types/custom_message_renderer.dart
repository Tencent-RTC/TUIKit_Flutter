import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// What the message list knows about the custom message being rendered, handed
/// to a [CustomMessageBuilder].
///
/// Custom messages paint their own container, so a builder may return any
/// layout. Use [defaultBubble] to opt into the standard chat bubble instead of
/// re-creating its decoration.
class CustomMessageRenderInfo {
  final MessageInfo message;
  final String conversationID;

  /// Whether the message was sent by the logged-in user.
  final bool isSelf;

  /// Maximum width the bubble may occupy. An avatar column is already reserved
  /// on both sides, so a renderer can fill this without colliding with the
  /// opposite party's avatar.
  final double maxWidth;

  /// True inside a merged-message detail page, which is read-only.
  final bool isInMergedDetailView;

  /// True while the list is in multi-select mode. The row-level tap toggles
  /// selection, so a builder must not install its own `onTap` handler — it
  /// would win the gesture arena and break selection.
  final bool isMultiSelectMode;

  /// Opens the built-in long-press action menu. Wire this to the root
  /// `onLongPress` to keep copy / forward / delete working.
  final VoidCallback? onLongPress;

  const CustomMessageRenderInfo({
    required this.message,
    required this.conversationID,
    required this.isSelf,
    required this.maxWidth,
    required this.isInMergedDetailView,
    required this.isMultiSelectMode,
    this.onLongPress,
  });

  /// The message's `customData` decoded as JSON, or null when it is absent or
  /// malformed.
  Map<String, dynamic>? get customData {
    final payload = message.messagePayload as CustomMessagePayload?;
    return ChatUtil.jsonData2Dictionary(payload?.customData);
  }

  /// Wraps [child] in the bubble the built-in custom message uses, so a host
  /// renderer blends in with the rest of the conversation.
  Widget defaultBubble(BuildContext context, {required Widget child}) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: isSelf ? colorsTheme.bgColorBubbleOwn : colorsTheme.bgColorBubbleReciprocal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Renders one kind of custom message. Register builders per `businessID` via
/// [ChatMessageListConfig.customMessageBuilders]; anything left unregistered
/// falls back to the UIKit's built-in custom message handling.
typedef CustomMessageBuilder = Widget Function(
  BuildContext context,
  CustomMessageRenderInfo info,
);
