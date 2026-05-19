// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'tebeautykit_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TEBeautyKitLocalizationsEn extends TEBeautyKitLocalizations {
  TEBeautyKitLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get beauty_cancel => 'Cancel';

  @override
  String get beauty_reset_title =>
      'Are you sure you want to reset the effects?';

  @override
  String get beauty_reset_content =>
      'The action will reset all effects and cannot be undone';

  @override
  String get beauty_reset_confirm => 'Reset';

  @override
  String get beauty_import_image => 'Upload background image';

  @override
  String get beauty_import_image_tip =>
      'Please stand in front of a xxx and upload an image you want to use as the background';

  @override
  String get beauty_pick_image => 'Upload';

  @override
  String get beauty_green_screen => 'green screen';

  @override
  String get beauty_blue_screen => 'blue screen';
}
