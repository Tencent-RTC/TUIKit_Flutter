import 'package:tencent_calls_uikit/src/common/i18n/i18n_utils.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';

class ErrorParser {
  static String? getErrorMessage(int errorCode) {
    switch (errorCode) {
      case -1001:
        return getI18nString('featureRequiresAudioVideoCallingPackage');
      case -1002:
        return getI18nString('currentPackageDoesNotSupportFeature');
      case -1101:
        return getI18nString('microphoneOrCameraPermissionNotEnabled');
      case -1316:
        return getI18nString('cameraOccupiedBySystemCall');
      case -1319:
        return getI18nString('microphoneOccupiedBySystemCall');
      case -1203:
        return getI18nString('currentlyOnCallCannotInitiateAnother');
      case -1201:
        return getI18nString('failedToInitiateCallCheckLoginStatus');
      case -3301:
        return getI18nString('failedToInitiateOrJoinCall');
      case 101010:
        return getI18nString('currentCallSupportsMax9Participants');
      case 101002:
        return getI18nString('inviteUserErrorOrInvalidCallParameters');
    }
    return null;
  }
}