import 'dart:math' as math;

/// Energy VAD at 20ms frame granularity.
///
/// The first [calibrationFrames] frames build a noise floor; afterwards frames
/// are judged as a multiple of that floor, so a quiet room and a noisy one do
/// not share one absolute threshold.
///
/// Two thresholds are tracked:
/// - the low one ([silenceThresholdFactor]) ends the turn on silence while
///   listening;
/// - the high one ([speechThresholdFactor]) detects speech. It is higher to
///   swallow echo the AEC left behind.
///
/// The two accumulators react asymmetrically to dropping below their
/// threshold: silence resets on the first frame above it, speech only enters a
/// [speechHangoverMs] grace period. Real silence is continuous; speech RMS
/// swings wildly frame to frame (loud vowels, weak consonants and gaps), so
/// requiring it to stay above the line would mean it never accumulates.
///
/// The floor is the **minimum** RMS seen during calibration, not the mean:
/// users often talk as soon as the page opens and the mean would be raised
/// several times by speech. [maxNoiseFloor] guards against even the minimum
/// being polluted.
///
/// A single zero frame would pin the minimum to 0, and the first frames after
/// the recorder starts are hardware warm-up returning all-zero PCM. So
/// calibration **skips** digital-silence frames (RMS below
/// [_minCalibrationRms]); they neither update the floor nor count towards
/// [calibrationFrames]. Skipping is capped at
/// `calibrationFrames * _calibrationAttemptFactor` frames, otherwise a broken
/// microphone would never finish calibrating and [isCalibrated] would stall
/// the state machine.
///
/// [reset] / [resetCalibration] only set a pending flag that takes effect on
/// the next [accept].
class EnergyVad {
  EnergyVad({
    this.frameDurationMs = 20,
    this.calibrationFrames = 15,
    this.silenceThresholdFactor = 2.0,
    this.speechThresholdFactor = 2.5,
    this.minNoiseFloor = 100.0,
    this.maxNoiseFloor = 2000.0,
    this.speechHangoverMs = 240,
  })  : assert(frameDurationMs > 0, 'frameDurationMs must be positive'),
        assert(calibrationFrames > 0, 'calibrationFrames must be positive'),
        assert(speechHangoverMs >= 0, 'speechHangoverMs must not be negative'),
        // Swapped factors remove the dead zone and let both accumulators grow
        // at once.
        assert(silenceThresholdFactor < speechThresholdFactor,
            'silenceThresholdFactor must be less than speechThresholdFactor'),
        assert(minNoiseFloor <= maxNoiseFloor,
            'minNoiseFloor must not exceed maxNoiseFloor');

  final int frameDurationMs;
  final int calibrationFrames;
  final double silenceThresholdFactor;
  final double speechThresholdFactor;
  final double minNoiseFloor;
  final double maxNoiseFloor;

  /// Grace period of the speech accumulator: dropping below the high
  /// threshold only clears it after this long in a row. The accumulator is
  /// held, not advanced, during the gap. 240ms (12 frames) was tuned on device
  /// readings: gaps inside continuous speech are on the order of 100~200ms,
  /// while a real pause shows up as a ~500ms window. 0 restores "clear on the
  /// first frame below".
  final int speechHangoverMs;

  /// Accumulators are capped so long sessions cannot overflow.
  static const int _maxAccumMs = 60000;

  /// Below this RMS a frame is digital silence (hardware warm-up) and is not
  /// used for calibration. Real ambient noise is far above 1.
  static const double _minCalibrationRms = 1.0;

  /// Calibration gives up after calibrationFrames times this many frames
  /// (15 * 4 = 60 frames, 1.2s by default).
  static const int _calibrationAttemptFactor = 4;

  double _noiseFloor = double.infinity;
  int _calibratedFrames = 0;
  int _calibrationAttempts = 0;
  int _silenceAccumMs = 0;
  int _speechAccumMs = 0;

  /// How long speech has currently stayed below the high threshold. Only
  /// advances while [_speechAccumMs] > 0.
  int _speechGapMs = 0;

  bool _pendingReset = false;
  bool _pendingRecalibrate = false;

  /// Enough valid measurements, or the attempt cap was hit.
  bool get isCalibrated =>
      _calibratedFrames >= calibrationFrames ||
      _calibrationAttempts >= calibrationFrames * _calibrationAttemptFactor;

  /// Raw calibrated floor, NaN when no valid measurement was taken. Logging
  /// only.
  double get rawNoiseFloor => _noiseFloor.isFinite ? _noiseFloor : double.nan;

  /// Floor used for decisions: [rawNoiseFloor] clamped to
  /// [minNoiseFloor]..[maxNoiseFloor], or [minNoiseFloor] without any
  /// measurement.
  double get effectiveNoiseFloor => _noiseFloor.isFinite
      ? _noiseFloor.clamp(minNoiseFloor, maxNoiseFloor).toDouble()
      : minNoiseFloor;

  double get silenceThreshold => effectiveNoiseFloor * silenceThresholdFactor;

  double get speechThreshold => effectiveNoiseFloor * speechThresholdFactor;

  int get speechAccumulationMs => _speechAccumMs;

  int get silenceAccumulationMs => _silenceAccumMs;

  /// Clears the accumulators but keeps the noise floor. Takes effect on the
  /// next frame.
  void reset() {
    _pendingReset = true;
  }

  /// Clears the noise floor as well, for when the environment changed. Takes
  /// effect on the next frame.
  void resetCalibration() {
    _pendingRecalibrate = true;
  }

  /// Feeds the RMS of one PCM16 frame. During calibration only the floor is
  /// updated. Returns [rms] for convenience.
  double accept(double rms) {
    if (_pendingRecalibrate) {
      _noiseFloor = double.infinity;
      _calibratedFrames = 0;
      _calibrationAttempts = 0;
      _pendingRecalibrate = false;
      _pendingReset = true;
    }
    if (_pendingReset) {
      _silenceAccumMs = 0;
      _speechAccumMs = 0;
      _speechGapMs = 0;
      _pendingReset = false;
    }

    if (!isCalibrated) {
      _calibrationAttempts++;
      if (rms >= _minCalibrationRms) {
        _noiseFloor = math.min(_noiseFloor, rms);
        _calibratedFrames++;
      }
      return rms;
    }
    final floor = effectiveNoiseFloor;
    // Between the two thresholds is a dead zone (closed on both ends) left for
    // residual echo. `<` / `>` are intentional.
    _silenceAccumMs = rms < floor * silenceThresholdFactor
        ? math.min(_silenceAccumMs + frameDurationMs, _maxAccumMs)
        : 0;
    if (rms > floor * speechThresholdFactor) {
      _speechGapMs = 0;
      _speechAccumMs = math.min(_speechAccumMs + frameDurationMs, _maxAccumMs);
    } else if (_speechAccumMs > 0) {
      _speechGapMs += frameDurationMs;
      if (_speechGapMs >= speechHangoverMs) {
        _speechAccumMs = 0;
        _speechGapMs = 0;
      }
    }
    return rms;
  }

  bool hasSilenceFor(int holdMs) => isCalibrated && _silenceAccumMs >= holdMs;

  bool hasSpeechFor(int holdMs) => isCalibrated && _speechAccumMs >= holdMs;
}
