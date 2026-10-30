import 'ai_assistant_control_messages.dart';

/// Fixed parameters for the AI voice chat.
///
/// Audio parameters follow the IMSDK backend's ASR / TTS contract:
/// Opus / 16 kHz / mono / raw packets.
///
/// The support server mainly does knowledge-base text Q&A. It may not
/// recognize the enterVoiceCall / leaveVoiceCall signals, so replies during a
/// call can still be raw Markdown.
class AIConstants {
  AIConstants._();

  static const String voiceEnterAction =
      AIAssistantControlMessages.voiceEnterAction;
  static const String voiceLeaveAction =
      AIAssistantControlMessages.voiceLeaveAction;
  static const String voiceSessionDescription =
      AIAssistantControlMessages.voiceSessionDescription;

  /// Text the "transfer to agent" button sends. The backend recognizes the
  /// request by this text, so it does not follow the UI language.
  static const String transferToHumanText = '转人工';

  static const int sampleRate = 16000;
  static const int channelCount = 1;

  /// 20ms @ 16kHz.
  static const int frameSamples = 320;
  static const int frameBytes = frameSamples * 2;
  static const int frameDurationMs = 20;

  /// Audio is uploaded every 5 frames (100ms).
  static const int uploadBatchFrames = 5;

  static const String asrLanguage = 'zh';

  /// Continuous silence that ends the user's turn while listening.
  ///
  /// Natural pauses for breath or word-finding run 300~800ms, so anything
  /// shorter cuts sentences in half; energy-VAD turn-taking usually sits at
  /// 1.2~2.0s.
  static const int silenceHoldMs = 1500;

  /// Lower bound of the VAD noise floor. Raw calibrated floors are often only a
  /// few dozen; without this, fans and keyboards in a quiet room read as speech.
  static const double vadMinNoiseFloor = 100.0;

  /// Upper bound of the barge-in pre-roll buffer: 100 packets = 2 seconds.
  static const int preRollMaxPackets = 100;

  static const int noiseCalibrationMs = 300;

  static const int asrStartTimeoutMs = 8000;

  /// Upper bound of the window that waits for the trailing ASR result after the
  /// turn ends. Sending without it drops the last words; the bound adds the same
  /// amount of send latency when the backend stays silent.
  static const int asrDrainTimeoutMs = 700;

  /// Minimum letters / CJK characters in ASR text that count as a barge-in
  /// while thinking or speaking. Single characters are too easily triggered by
  /// echo leakage.
  static const int asrBargeInMinChars = 2;

  static const int streamReplyTimeoutMs = 30000;

  /// Speaking-state watchdog: time since the last TTS chunk before the downlink
  /// is considered broken. Once isFinished arrives no further chunks come, and
  /// the total queued audio duration must be added on top.
  static const int speakingIdleTimeoutMs = 10000;
}
