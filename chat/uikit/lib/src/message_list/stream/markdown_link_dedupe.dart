final RegExp _linkOnlyLine =
    RegExp(r'^\s*(?:[-*+]|\d+[.)])?\s*\[[^\]]*]\(\s*([^)\s]+)[^)]*\)\s*$');

/// Knowledge-base answers often list the same document several times under
/// "references" (several chunks hit one page). Only lines holding nothing but
/// one link whose URL already appeared on an earlier line are removed; fenced
/// code is left untouched.
String dedupeLinkOnlyLines(String source) {
  if (!source.contains('](')) return source;
  final seen = <String>{};
  var inFence = false;
  var changed = false;
  final out = <String>[];
  for (final line in source.split('\n')) {
    if (line.trimLeft().startsWith('```')) inFence = !inFence;
    if (!inFence) {
      final url = _linkOnlyLine.firstMatch(line)?.group(1);
      if (url != null && !seen.add(url)) {
        changed = true;
        continue;
      }
    }
    out.add(line);
  }
  return changed ? out.join('\n') : source;
}
