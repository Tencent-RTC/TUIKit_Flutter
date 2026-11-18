/// The prompt to place in an empty composer.
///
/// A saved draft wins. Blank or whitespace-only prompts are ignored, and
/// [enabled] is false once the host has already consumed the send-button hint.
String? messageInputTextToPrefill({
  required String currentText,
  required String? draft,
  required String? initialInputText,
  required bool enabled,
}) {
  if (!enabled || currentText.isNotEmpty) {
    return null;
  }
  if (draft != null && draft.isNotEmpty) {
    return null;
  }
  final prompt = initialInputText?.trim() ?? '';
  if (prompt.isEmpty) {
    return null;
  }
  return prompt;
}
