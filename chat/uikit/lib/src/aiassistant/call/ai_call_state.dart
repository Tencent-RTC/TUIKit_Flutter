/// The four states of the call page.
///
/// The microphone and the ASR session stay open in listening / thinking /
/// speaking. Idle means muted, paused or not started yet.
enum AICallState {
  /// Not started or already ended.
  idle,

  /// ASR uplink running, the turn ends on silence.
  listening,

  /// Text sent, waiting for the AI's stream reply.
  thinking,

  /// TTS playing; ASR still uplinks and recognized text can barge in.
  speaking,
}

/// One line of the transcript. [isFailed] marks a user line that failed to
/// send.
class TranscriptEntry {
  const TranscriptEntry(
      {required this.isFromUser, required this.text, this.isFailed = false});

  final bool isFromUser;
  final String text;
  final bool isFailed;

  TranscriptEntry copyWith({bool? isFailed}) {
    return TranscriptEntry(
        isFromUser: isFromUser,
        text: text,
        isFailed: isFailed ?? this.isFailed);
  }
}
