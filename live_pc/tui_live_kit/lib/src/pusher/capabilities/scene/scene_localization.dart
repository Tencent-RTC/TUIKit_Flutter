import 'package:atomic_x_core_media_mixing/api/scene/scene_strings.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_store_view.dart';
import 'package:flutter/widgets.dart';

import '../../../l10n/language_store.dart';
import '../../../l10n/live_kit_localizations.dart';

class LiveKitSceneStrings implements SceneStrings {
  const LiveKitSceneStrings();

  LiveKitLocalizations get _l => lookupLiveKitLocalizations(LanguageStore.locale.value);

  @override
  String get sceneDefault => _l.sceneDefault;
  @override
  String get sourceNameCamera => _l.sourceNameCamera;
  @override
  String get sourceNameScreen => _l.sourceNameScreen;
  @override
  String get sourceTypeImage => _l.sourceTypeImage;
  @override
  String get sourceTypeOnlineVideo => _l.sourceTypeOnlineVideo;
  @override
  String get sourceTypeVideoFile => _l.sourceTypeVideoFile;
  @override
  String get errorSourceDuplicated => _l.errorSourceDuplicated;
  @override
  String get errorSourceNotFound => _l.errorSourceNotFound;
  @override
  String get errorStartMixing => _l.errorStartMixing;
  @override
  String get imageSizeTooLarge => _l.imageSizeTooLarge;
  @override
  String get mixingStoppedSourceLost => _l.mixingStoppedSourceLost;
  @override
  String get errorImageLoadFailed => _l.errorImageLoadFailed;
  @override
  String get errorCameraNotAuthorized => _l.errorCameraNotAuthorized;
  @override
  String get errorCameraIsOccupied => _l.errorCameraIsOccupied;
  @override
  String get errorCameraDisconnected => _l.errorCameraDisconnected;
  @override
  String get errorVideoFileNotExist => _l.errorVideoFileNotExist;
  @override
  String get errorOnlineVideoProtocol => _l.errorOnlineVideoProtocol;
  @override
  String get errorLocalVideoFormat => _l.errorLocalVideoFormat;
  @override
  String get errorHevcDecoder => _l.errorHevcDecoder;
  @override
  String get errorInvalidParams => _l.errorInvalidParams;
  @override
  String get errorOnlineVideoConnectFailed => _l.errorOnlineVideoConnectFailed;
  @override
  String get errorOnlineVideoConnectionLost => _l.errorOnlineVideoConnectionLost;
  @override
  String get errorScreenSourceClosed => _l.errorScreenSourceClosed;
  @override
  String get errorScreenDisplayChanged => _l.errorScreenDisplayChanged;
  @override
  String get errorUnknown => _l.errorUnknown;
  @override
  String get errorCameraRunFailed => _l.errorCameraRunFailed;
  @override
  String get errorScreenRunFailed => _l.errorScreenRunFailed;
  @override
  String get errorImageRunFailed => _l.errorImageRunFailed;
  @override
  String get errorVideoFilePlayFailed => _l.errorVideoFilePlayFailed;
  @override
  String get errorOnlineVideoPlayFailed => _l.errorOnlineVideoPlayFailed;
  @override
  String sceneCustomSuggestion(int index) => _l.sceneCustomSuggestion(index);
  @override
  String sceneCopySuffix(String baseName, String index) => _l.sceneCopySuffix(baseName, index);
  @override
  String errorAddSource(Object errorCode) => _l.errorAddSource(errorCode);
  @override
  String runtimeSourceError(String sourceName, String message) => _l.runtimeSourceError(sourceName, message);
}

String sceneDisplayName(BuildContext context, SceneConfig scene) {
  if (scene.isCustomName) {
    return scene.name;
  }
  if (scene.key == kPresetLandscapeSceneKey || scene.key == kPresetPortraitSceneKey) {
    return LiveKitLocalizations.of(context).sceneDefault;
  }
  return scene.name;
}
