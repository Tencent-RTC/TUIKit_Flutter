/// Optional look and guidance of the AI call page. Omitted, or with every
/// field at its default, the page stays as it was.
class AICallUiOptions {
  const AICallUiOptions({
    this.auroraStyle = false,
    this.plainTranscript = false,
    this.sampleHints = const [],
    this.showButtonLabels = false,
    this.showCallTimer = false,
  });

  /// Aurora orb on a dark gradient background.
  final bool auroraStyle;

  /// Subtitles drop Markdown marks, links and the "references" section,
  /// keeping only the spoken text.
  final bool plainTranscript;

  /// Sample questions rotated under the status text until the user speaks.
  final List<String> sampleHints;

  /// Text labels under the three bottom buttons.
  final bool showButtonLabels;

  /// The top pill shows the call duration instead of "free talk".
  final bool showCallTimer;
}
