// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get userName => 'Your Name';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get userIdInputHint => 'Please input userId';

  @override
  String get userNameInputHint => 'Please input userName';

  @override
  String get userNameTips => 'Only Chinese, letters, numbers and underscores';

  @override
  String get userIdIsEmpty => 'userId is empty';

  @override
  String get userNameIsEmpty => 'userName is empty';

  @override
  String loginError(String code, String message) {
    return 'login error,code:$code,msg:$message';
  }

  @override
  String get custom_name_1 => 'Martijn';

  @override
  String get custom_name_2 => 'irfan';

  @override
  String get custom_name_3 => 'Rosanna';

  @override
  String get custom_name_4 => 'Franklyn';

  @override
  String get custom_name_5 => 'Maren';

  @override
  String get custom_name_6 => 'Bartel';

  @override
  String get custom_name_7 => 'Marianita';

  @override
  String get custom_name_8 => 'Anneke';

  @override
  String get custom_name_9 => 'Elmira';

  @override
  String get custom_name_10 => 'Ivet';

  @override
  String get custom_name_11 => 'Clinton';

  @override
  String get custom_name_12 => 'Virelai';
}
