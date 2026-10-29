/// Action to take when the recording gesture ends (PointerUp / PointerCancel).
///
/// The action is determined by the finger's position at release time:
/// - On the cancel button → [cancel]
/// - On the convert-to-text button → [convert]
/// - Anywhere else → [send] (release-to-send original voice), or [cancel]
///   when sending the recorded voice is disabled
enum RecordPointerUpAction { send, cancel, convert }

/// Pure dispatch helper used by [MessageInput] to translate hover flags into
/// the resulting action. Extracted to a top-level function so it can be unit
/// tested without standing up the full widget tree.
///
/// Defensive precedence: when both flags are accidentally true (which the
/// state machine in [AudioRecordOverlay] should prevent), [cancel] wins to
/// favor the safer "drop the recording" outcome over silently sending.
RecordPointerUpAction recordPointerUpAction({
  required bool overCancel,
  required bool overConvert,
  bool allowSendVoice = true,
}) {
  if (overCancel) return RecordPointerUpAction.cancel;
  if (overConvert) return RecordPointerUpAction.convert;
  return allowSendVoice ? RecordPointerUpAction.send : RecordPointerUpAction.cancel;
}
