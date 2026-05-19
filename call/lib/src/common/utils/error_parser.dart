import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';

class ErrorParser {
  static String? getErrorMessage(int errorCode, AtomicLocalizations? l10n) {
    if (l10n == null) return null;
    switch (errorCode) {
      case -1001:
        return l10n.callFeatureRequiresAudioVideoCallingPackage;
      case -1002:
        return l10n.callCurrentPackageDoesNotSupportFeature;
      case -1101:
        return l10n.callMicrophoneOrCameraPermissionNotEnabled;
      case -1316:
        return l10n.callCameraOccupiedBySystemCall;
      case -1319:
        return l10n.callMicrophoneOccupiedBySystemCall;
      case -1203:
        return l10n.callCurrentlyOnCallCannotInitiateAnother;
      case -1201:
        return l10n.callFailedToInitiateCallCheckLoginStatus;
      case -3301:
        return l10n.callFailedToInitiateOrJoinCall;
      case 101010:
        return l10n.callCurrentCallSupportsMax9Participants;
      case 101002:
        return l10n.callInviteUserErrorOrInvalidCallParameters;
    }
    return null;
  }
}