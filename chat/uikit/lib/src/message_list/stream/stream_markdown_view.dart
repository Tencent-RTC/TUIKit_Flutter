import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tencent_chat_uikit/src/message_list/stream/stream_markdown_sanitizer.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders the revealed part of a stream message as markdown.
///
/// Takes the raw revealed prefix rather than finished markdown: completing it
/// is part of rendering, and the caller has no reason to know that a prefix
/// needs completing at all.
class StreamMarkdownView extends StatelessWidget {
  const StreamMarkdownView({
    super.key,
    required this.revealed,
    required this.isRevealing,
    required this.isSelf,
  });

  /// The prefix the typewriter has revealed so far.
  final String revealed;

  /// Whether more is still to come. Drives both the cursor and the completion
  /// of half-typed syntax.
  final bool isRevealing;

  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final foreground = isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary;
    final base = FontScheme.caption1Regular.copyWith(color: foreground);

    final sanitized = sanitizeStreamMarkdown(
      revealed,
      isRevealing: isRevealing,
      withCursor: isRevealing,
    );

    return MarkdownBody(
      data: sanitized.source,
      // On an own bubble the accent link colour sits on its own accent
      // background, so links there stay in the foreground colour and rely on
      // the underline instead.
      styleSheet: _styleSheet(base, foreground, isSelf ? foreground : colors.textColorLink),
      inlineSyntaxes: <md.InlineSyntax>[_StreamCursorSyntax()],
      builders: <String, MarkdownElementBuilder>{
        _cursorTag: _StreamCursorBuilder(color: foreground),
      },
      // Selection is left to the bubble's own long-press menu; enabling it here
      // would swallow the gesture, and the tail is rebuilt every frame anyway.
      selectable: false,
      onTapLink: (_, href, __) => _openLink(href),
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('cannot open url: $href');
    }
  }

  /// Derives every style from the bubble's own text colour.
  ///
  /// Own and incoming bubbles have opposite backgrounds, so fills and rules are
  /// taken as a wash of the foreground rather than named theme colours — that
  /// way both sides stay legible without a second palette.
  MarkdownStyleSheet _styleSheet(TextStyle base, Color foreground, Color link) {
    final size = base.fontSize ?? 16;
    final wash = foreground.withValues(alpha: 0.12);
    final rule = foreground.withValues(alpha: 0.24);
    final mono = base.copyWith(fontFamily: 'monospace', fontSize: size * 0.9);

    return MarkdownStyleSheet(
      p: base,
      a: base.copyWith(color: link, decoration: TextDecoration.underline),
      em: base.copyWith(fontStyle: FontStyle.italic),
      strong: base.copyWith(fontWeight: FontWeight.bold),
      del: base.copyWith(decoration: TextDecoration.lineThrough),
      // Headings stay close to body size: a bubble is not a document, and the
      // design system's real heading sizes would dwarf the conversation.
      h1: base.copyWith(fontSize: size * 1.4, fontWeight: FontWeight.bold),
      h2: base.copyWith(fontSize: size * 1.25, fontWeight: FontWeight.bold),
      h3: base.copyWith(fontSize: size * 1.1, fontWeight: FontWeight.bold),
      h4: base.copyWith(fontWeight: FontWeight.bold),
      h5: base.copyWith(fontWeight: FontWeight.bold),
      h6: base.copyWith(fontWeight: FontWeight.bold),
      code: mono,
      codeblockDecoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(6),
      ),
      codeblockPadding: const EdgeInsets.all(8),
      blockquote: base,
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: rule, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: rule)),
      ),
      tableBody: base,
      tableHead: base.copyWith(fontWeight: FontWeight.bold),
      tableBorder: TableBorder.all(color: rule),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      listBullet: base,
      // Blocks sit tighter than the package defaults, which are tuned for a
      // full-page document rather than a chat bubble.
      blockSpacing: size * 0.5,
      pPadding: EdgeInsets.zero,
      h1Padding: EdgeInsets.zero,
      h2Padding: EdgeInsets.zero,
      h3Padding: EdgeInsets.zero,
    );
  }
}

const String _cursorTag = 'streamCursor';

/// Turns the sanitizer's marker into an element the builder can pick up.
class _StreamCursorSyntax extends md.InlineSyntax {
  _StreamCursorSyntax() : super(RegExp.escape(kStreamCursorMarker));

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty(_cursorTag));
    return true;
  }
}

/// Renders the marker as the blinking cursor.
///
/// Returns a [Text] rather than the cursor widget itself: the package merges
/// adjacent text widgets into one `RichText`, so wrapping the cursor in a span
/// keeps it inside the paragraph's text flow instead of pushing it into a
/// sibling widget that would land on its own line.
class _StreamCursorBuilder extends MarkdownElementBuilder {
  _StreamCursorBuilder({required this.color});

  final Color color;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final height = (preferredStyle?.fontSize ?? FontScheme.caption1Regular.fontSize ?? 16) * 1.1;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: StreamCursor(color: color, height: height),
          ),
        ],
      ),
    );
  }
}

/// The caret shown at the end of a message that is still arriving.
class StreamCursor extends StatefulWidget {
  const StreamCursor({super.key, required this.color, required this.height});

  final Color color;
  final double height;

  @override
  State<StreamCursor> createState() => _StreamCursorState();
}

class _StreamCursorState extends State<StreamCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Its own controller rather than the reveal ticker: FadeTransition only
    // repaints, so the blink never rebuilds the streaming text beside it.
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: widget.height,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
