/// Filters ASR text before it counts as a barge-in. With the session always
/// open, text arriving while thinking / speaking may be the user talking, the
/// tail of the previous sentence, or TTS leaking into the microphone.
class AsrBargeIn {
  AsrBargeIn._();

  static const String _punctuation = '，。、；：？！,“”‘’"\'（）()[]【】…—-,:;?!.';

  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
  static final RegExp _whitespace = RegExp(r'\s', unicode: true);

  static int significantCharCount(String text) {
    var count = 0;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (_letterOrDigit.hasMatch(ch) || (rune >= 0x4E00 && rune <= 0x9FFF)) {
        count++;
      }
    }
    return count;
  }

  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (_whitespace.hasMatch(ch) || _punctuation.contains(ch)) continue;
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// The backend keeps sending tail updates for the sentence already sent to
  /// the robot. Equal text, or a prefix of the sent text, is that same
  /// sentence. Text that continues past it is handed to [extraBeyondCommitted].
  static bool looksLikeCommitted(String asrText, String committed) {
    final asr = normalize(asrText);
    final sent = normalize(committed);
    if (asr.isEmpty || sent.isEmpty) {
      return false;
    }
    return asr == sent || sent.startsWith(asr);
  }

  static String? extraBeyondCommitted(String asrText, String committed) {
    final asr = normalize(asrText);
    final sent = normalize(committed);
    if (sent.isEmpty || !asr.startsWith(sent) || asr.length <= sent.length) {
      return null;
    }
    return asr.substring(sent.length);
  }

  /// Recognized TTS leakage is usually a substring of the LLM text being read.
  static bool looksLikeTtsEcho(String asrText, String llmText) {
    final asr = normalize(asrText);
    final llm = normalize(llmText);
    if (asr.length < 2 || llm.isEmpty) {
      return false;
    }
    return llm.contains(asr);
  }

  static bool shouldBargeIn({
    required String asrText,
    required String committed,
    required String llmText,
    required int minChars,
  }) {
    final extra = extraBeyondCommitted(asrText, committed);
    final candidate = extra ?? asrText;
    if (extra == null && looksLikeCommitted(asrText, committed)) {
      return false;
    }
    if (significantCharCount(candidate) < minChars) {
      return false;
    }
    if (looksLikeTtsEcho(candidate, llmText)) {
      return false;
    }
    return true;
  }
}
