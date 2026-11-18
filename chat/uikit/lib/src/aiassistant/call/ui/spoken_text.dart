/// Turns the AI's Markdown answer into plain text for call subtitles: drops
/// everything from the "references" heading on, keeps only link text, removes
/// bare URLs and strips emphasis / heading / quote / code marks.
class SpokenText {
  SpokenText._();

  static final RegExp _referenceHeader = RegExp(
    r'^\s*(?:#{1,6}\s*)?(?:\*\*|__)?\s*(?:参考资料|参考文档|参考链接|相关文档|References?|Sources?)\s*(?:\*\*|__)?\s*[:：]?\s*$',
    multiLine: true,
    caseSensitive: false,
  );
  static final RegExp _link = RegExp(r'!?\[([^\]]*)]\([^)]*\)');
  static final RegExp _bareUrl = RegExp(r'https?://\S+');
  static final RegExp _fence = RegExp(r'^```.*$', multiLine: true);
  static final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true);
  static final RegExp _quote = RegExp(r'^\s*>\s?', multiLine: true);
  static final RegExp _emphasis = RegExp(r'\*\*|__|~~|`');
  static final RegExp _bullet = RegExp(r'^(\s*)[-*+]\s+', multiLine: true);
  static final RegExp _extraBlankLines = RegExp(r'\n{3,}');
  static final RegExp _trailingSpaces = RegExp(r'[ \t]+\n');

  static String from(String markdown) {
    if (markdown.trim().isEmpty) return markdown;
    var text = markdown;
    final reference = _referenceHeader.firstMatch(text);
    if (reference != null) text = text.substring(0, reference.start);
    text = text.replaceAllMapped(_link, (m) => m[1] ?? '');
    text = text.replaceAll(_bareUrl, '');
    text = text.replaceAll(_fence, '');
    text = text.replaceAll(_heading, '');
    text = text.replaceAll(_quote, '');
    text = text.replaceAllMapped(_bullet, (m) => '${m[1]}• ');
    text = text.replaceAll(_emphasis, '');
    text = text.replaceAll(_trailingSpaces, '\n');
    text = text.replaceAll(_extraBlankLines, '\n\n');
    return text.trim();
  }
}
