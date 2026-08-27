import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

/// Builds the one-line preview shown for a custom message in the conversation
/// list. Return null to fall back to the UIKit default.
typedef MessageSummaryBuilder = String? Function(BuildContext context, MessageInfo message);

/// Process-wide registry of conversation list previews for custom messages,
/// keyed by the message's `businessID`.
///
/// This is global rather than a field on `ChatMessageListConfig` because the
/// conversation list renders outside any chat page and so has no access to that
/// page's config. Register during app start-up.
class MessageSummaryRegistry {
  MessageSummaryRegistry._();

  static final Map<String, MessageSummaryBuilder> _builders = {};

  /// Registers (or replaces) the preview builder for [businessID].
  static void register(String businessID, MessageSummaryBuilder builder) {
    _builders[businessID] = builder;
  }

  static void unregister(String businessID) => _builders.remove(businessID);

  /// Drops every registration. Intended for tests.
  static void clear() => _builders.clear();

  /// The preview for [businessID], or null when nothing is registered or the
  /// builder declines by returning null or an empty string.
  static String? summaryFor(String businessID, BuildContext context, MessageInfo message) {
    final summary = _builders[businessID]?.call(context, message);
    return (summary == null || summary.isEmpty) ? null : summary;
  }
}
