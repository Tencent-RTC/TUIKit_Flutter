/// Backend error classification for speech recognition. Realtime
/// transcription and one-shot voice-to-text share one resource package and
/// report the same codes.
class AsrServiceError {
  AsrServiceError._();

  /// No recognition service for this SDKAppID: not enabled, or the resource
  /// package is used up. The backend reports both as
  /// `This AppId has not yet enabled the ASR service`.
  static const int serviceUnavailable = 140008;

  /// Errors that retrying cannot fix; the service has to be enabled or
  /// renewed in the console first.
  static bool isServiceUnavailable(int code) => code == serviceUnavailable;
}
