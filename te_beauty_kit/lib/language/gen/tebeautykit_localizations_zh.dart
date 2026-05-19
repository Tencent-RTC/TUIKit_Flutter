// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'tebeautykit_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class TEBeautyKitLocalizationsZh extends TEBeautyKitLocalizations {
  TEBeautyKitLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get beauty_cancel => '取消';

  @override
  String get beauty_reset_title => '确定重置吗';

  @override
  String get beauty_reset_content => '重置会将目前所有特效恢复至默认效果，不可撤回';

  @override
  String get beauty_reset_confirm => '重置';

  @override
  String get beauty_import_image => '导入图片';

  @override
  String get beauty_import_image_tip => '请您站在xxx前，选择一张图片，将xxx替换为所选图片';

  @override
  String get beauty_pick_image => '选择图片';

  @override
  String get beauty_green_screen => '绿幕';

  @override
  String get beauty_blue_screen => '蓝幕';
}
