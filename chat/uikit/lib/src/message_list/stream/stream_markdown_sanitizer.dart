/// Completes a partially revealed markdown document so it renders the way the
/// finished document will.
///
/// The typewriter hands the renderer a *prefix* of the source, so most frames
/// carry syntax that is still open: `**` without its pair, a fence with no
/// closer, half a table row. Rendered as-is those markers appear as literal
/// text and then snap into styling once the pair arrives — one reflow per
/// marker, which reads as jitter.
///
/// Stateless on purpose: the same prefix always yields the same output, so this
/// is testable without a widget tree, the way `TypewriterController` is.
library;

/// Marks where the reveal stopped, so the caller can turn it into a cursor.
///
/// U+E000 is the first Unicode private use code point — it carries no meaning
/// of its own and cannot collide with anything a real message contains.
const String kStreamCursorMarker = '\uE000';

/// Result of completing one revealed prefix.
class SanitizedMarkdown {
  const SanitizedMarkdown({required this.source, required this.cursorPlaced});

  /// Markdown that parses to the structure the finished document will have.
  final String source;

  /// Whether [kStreamCursorMarker] made it into [source].
  ///
  /// False when the reveal stopped inside code, where the marker would either
  /// render as a stray glyph or land in a block of its own.
  final bool cursorPlaced;
}

/// Completes [revealed] into renderable markdown.
///
/// Set [isRevealing] to false once the reveal is over: a finished document
/// needs no completion, and passing it through untouched keeps a message that
/// genuinely ends in `*` from having that character trimmed forever.
///
/// Pass [withCursor] to have [kStreamCursorMarker] inserted at the reveal
/// point — inside whatever emphasis is still open, so the cursor stays in the
/// text flow rather than trailing the synthesized closers.
SanitizedMarkdown sanitizeStreamMarkdown(
  String revealed, {
  bool isRevealing = true,
  bool withCursor = false,
}) {
  if (!isRevealing) {
    return SanitizedMarkdown(source: revealed, cursorPlaced: false);
  }

  if (revealed.isEmpty) {
    return SanitizedMarkdown(
      source: withCursor ? kStreamCursorMarker : '',
      cursorPlaced: withCursor,
    );
  }

  final lines = revealed.split('\n');

  final fence = _openFenceOf(lines);
  if (fence != null) {
    // Inside a fence the content is literal, so there is nothing to complete
    // but the fence itself. The cursor is dropped: placed in the code it would
    // render as a stray glyph, and placed after the closer it would sit in a
    // block of its own.
    return SanitizedMarkdown(source: '$revealed\n$fence', cursorPlaced: false);
  }

  final kept = _dropUnstableTableRows(lines);
  final text = kept.join('\n');
  final splitAt = _tailStartOffset(kept);

  final head = text.substring(0, splitAt);
  final block = _trimDanglingDelimiters(_truncateOpenLink(text.substring(splitAt)));
  final open = _scanOpenInline(block);

  // With no block to sit in, the cursor would be glued onto the closing fence
  // above and stop it from closing. Skipping a frame costs nothing.
  final placeCursor = withCursor &&
      !open.insideCodeSpan &&
      (block.isNotEmpty || head.isEmpty || head.endsWith('\n'));

  final cursor = placeCursor ? kStreamCursorMarker : '';
  final body = _closeBeforeTrailingSpace(block, cursor, open.closers);

  return SanitizedMarkdown(source: '$head$body', cursorPlaced: placeCursor);
}

// ---------------------------------------------------------------------------
// Fenced code blocks
// ---------------------------------------------------------------------------

final RegExp _fenceLine = RegExp(r'^ {0,3}(`{3,}|~{3,})');

/// The closer needed if [lines] ends inside a fence, else null.
String? _openFenceOf(List<String> lines) {
  String? open;
  for (final line in lines) {
    final match = _fenceLine.firstMatch(line);
    if (match == null) continue;
    final marker = match.group(1)!;
    if (open == null) {
      open = marker;
    } else if (marker[0] == open[0] && marker.length >= open.length) {
      // A closer may be longer than its opener but never a different character.
      open = null;
    }
  }
  return open;
}

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

final RegExp _tableRow = RegExp(r'^ {0,3}\|');
final RegExp _tableDelimiter = RegExp(r'^ {0,3}\|?(\s*:?-+:?\s*\|)+\s*:?-*:?\s*$');

/// Hides trailing table lines that would render at the wrong width.
///
/// A header row on its own is just a paragraph full of pipes, and a row still
/// being typed has fewer cells than the finished one — both make the column
/// widths jump on the next frame. Held back until the row is whole.
List<String> _dropUnstableTableRows(List<String> lines) {
  // A single trailing empty entry is the newline that ended the last line, not
  // a blank line of its own.
  final end = lines.last.isEmpty ? lines.length - 1 : lines.length;

  var start = end;
  while (start > 0 && _tableRow.hasMatch(lines[start - 1])) {
    start--;
  }
  if (start == end) return lines;

  final rows = lines.sublist(start, end);
  final tail = lines.sublist(end);

  // Without its delimiter row the table has no column count yet.
  if (rows.length < 2 || !_tableDelimiter.hasMatch(rows[1])) {
    return [...lines.sublist(0, start), ...tail];
  }

  // No trailing newline means the last row is still being typed.
  final complete = end == lines.length ? rows.length - 1 : rows.length;
  return [...lines.sublist(0, start), ...rows.take(complete), ...tail];
}

// ---------------------------------------------------------------------------
// Block boundaries
// ---------------------------------------------------------------------------

/// Offset into `lines.join('\n')` where the block still being revealed starts.
///
/// Emphasis cannot span a blank line and means nothing inside a fence, so
/// everything above the last blank line or closed fence is settled. Scanning
/// only what follows keeps a stray asterisk in earlier text from reading as an
/// unclosed marker, and keeps a closed fence from being mistaken for one.
///
/// Offsets rather than line indices so the head can be sliced back off the
/// source verbatim, newlines and all.
int _tailStartOffset(List<String> lines) {
  var boundary = 0;
  var offset = 0;
  String? open;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final isLast = i == lines.length - 1;
    final match = _fenceLine.firstMatch(line);

    if (match != null) {
      final marker = match.group(1)!;
      if (open == null) {
        open = marker;
      } else if (marker[0] == open[0] && marker.length >= open.length) {
        open = null;
        boundary = offset + line.length + (isLast ? 0 : 1);
      }
    } else if (open == null && line.trim().isEmpty) {
      boundary = isLast ? offset : offset + line.length + 1;
    }

    offset += line.length + 1;
  }

  return boundary;
}

// ---------------------------------------------------------------------------
// Links
// ---------------------------------------------------------------------------

/// Reduces a half-typed link or image to the text it will end up showing.
///
/// `[label](htt` becomes `label`: the words are already on screen and must not
/// move when the URL lands, but a link to a truncated address should not be
/// tappable yet. An unfinished image has no text to keep, so it goes entirely.
String _truncateOpenLink(String block) {
  var depth = 0;
  var openAt = -1;

  for (var i = 0; i < block.length; i++) {
    final ch = block[i];
    if (ch == r'\') {
      i++;
    } else if (ch == '[') {
      if (depth == 0) openAt = i;
      depth++;
    } else if (ch == ']' && depth > 0) {
      depth--;
      if (depth > 0) continue;
      final rest = block.substring(i + 1);
      if (rest.startsWith('(') && !rest.contains(')')) {
        return _keepLabelOnly(block, openAt, block.substring(openAt + 1, i));
      }
      openAt = -1;
    }
  }

  // The label itself is still unfinished.
  return openAt < 0
      ? block
      : _keepLabelOnly(block, openAt, block.substring(openAt + 1));
}

/// Replaces the unfinished link at [openAt] with the text it will show.
///
/// An image contributes no text of its own — its alt text is a fallback, not
/// content — so it is dropped whole rather than leaving the description behind.
String _keepLabelOnly(String block, int openAt, String label) {
  final isImage = openAt > 0 && block[openAt - 1] == '!';
  final head = block.substring(0, isImage ? openAt - 1 : openAt);
  return isImage ? head : head + label;
}

// ---------------------------------------------------------------------------
// Inline emphasis and code spans
// ---------------------------------------------------------------------------

final RegExp _trailingSpace = RegExp(r'\s*$');

/// Tucks [cursor] and [closers] in ahead of any trailing whitespace.
///
/// A delimiter only closes when a non-space precedes it, so appending `**`
/// straight onto `**AI ` leaves both pairs on screen as literal text. Landing
/// the cursor there too keeps it against the last character rather than
/// floating after the space.
String _closeBeforeTrailingSpace(String block, String cursor, String closers) {
  if (cursor.isEmpty && closers.isEmpty) return block;
  final trailing = _trailingSpace.firstMatch(block)!.group(0)!;
  final core = block.substring(0, block.length - trailing.length);
  return '$core$cursor$closers$trailing';
}

final RegExp _danglingDelimiters = RegExp(r'[*_~`]+$');

/// Holds back a delimiter run that has not met the text it applies to.
///
/// A prefix ending in `**` cannot be told apart from a literal pair of
/// asterisks yet. Showing it and restyling it a frame later is the jitter this
/// file exists to prevent, whereas withholding it for one frame is
/// indistinguishable from the character simply not having been typed yet.
///
/// Anything the run would have closed is re-appended by [_scanOpenInline], so
/// a completed `**bold**` still round-trips unchanged.
String _trimDanglingDelimiters(String block) =>
    block.replaceFirst(_danglingDelimiters, '');

class _OpenInline {
  const _OpenInline({required this.closers, required this.insideCodeSpan});

  final String closers;
  final bool insideCodeSpan;
}

/// Finds the markers [block] leaves open, and what would close them.
///
/// Openers are recognised the way CommonMark defines left-flanking runs: a
/// delimiter only opens when a non-space follows it. That keeps arithmetic like
/// `5 * 3`, and a trailing `**` that has not met its text yet, from reading as
/// emphasis.
_OpenInline _scanOpenInline(String block) {
  final stack = <String>[];
  var i = 0;

  while (i < block.length) {
    final ch = block[i];

    if (ch == r'\') {
      i += 2;
      continue;
    }

    if (ch == '`') {
      final run = _runLengthAt(block, i, '`');
      final close = block.indexOf('`' * run, i + run);
      if (close < 0) {
        // Everything after an unmatched backtick run is code, so no emphasis
        // can open inside it.
        return _OpenInline(closers: '`' * run, insideCodeSpan: true);
      }
      i = close + run;
      continue;
    }

    if (ch == '*' || ch == '_' || ch == '~') {
      final run = _runLengthAt(block, i, ch);
      final token = ch == '~' ? (run >= 2 ? '~~' : null) : ch * (run >= 2 ? 2 : 1);
      if (token == null) {
        i += run;
        continue;
      }

      final before = i > 0 ? block[i - 1] : '';
      final after = i + token.length < block.length ? block[i + token.length] : '';

      if (stack.isNotEmpty && stack.last == token && !_isSpace(before)) {
        stack.removeLast();
      } else if (!_isSpace(after)) {
        stack.add(token);
      }
      i += token.length;
      continue;
    }

    i++;
  }

  return _OpenInline(closers: stack.reversed.join(), insideCodeSpan: false);
}

int _runLengthAt(String text, int start, String ch) {
  var end = start;
  while (end < text.length && text[end] == ch) {
    end++;
  }
  return end - start;
}

/// Treats end-of-string as whitespace: a delimiter with nothing after it has no
/// text to open emphasis on.
bool _isSpace(String ch) => ch.isEmpty || ch.trim().isEmpty;
