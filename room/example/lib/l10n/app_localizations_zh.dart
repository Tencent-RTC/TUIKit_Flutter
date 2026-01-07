// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get userName => '您的姓名';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get userIdInputHint => '请输入UserId';

  @override
  String get userNameInputHint => '请输入用户名';

  @override
  String get userNameTips => '仅限中文、字母、数字和下划线';

  @override
  String get userIdIsEmpty => 'userId为空';

  @override
  String get userNameIsEmpty => 'userName为空';

  @override
  String loginError(String code, String message) {
    return '登录失败,code:$code,msg:$message';
  }

  @override
  String get custom_name_1 => '路飞';

  @override
  String get custom_name_2 => '山治';

  @override
  String get custom_name_3 => '娜美';

  @override
  String get custom_name_4 => '乌索普';

  @override
  String get custom_name_5 => '香克斯';

  @override
  String get custom_name_6 => '弗兰奇';

  @override
  String get custom_name_7 => '罗宾';

  @override
  String get custom_name_8 => '钢铁侠';

  @override
  String get custom_name_9 => '蜘蛛侠';

  @override
  String get custom_name_10 => '乔巴';

  @override
  String get custom_name_11 => '鸣人';

  @override
  String get custom_name_12 => '艾斯';
}
