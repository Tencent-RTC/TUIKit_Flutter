import 'package:flutter/cupertino.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

class LocaleProvider extends ChangeNotifier {
  String? _locale;

  Locale? get locale {
    _locale = (StorageUtil.get('locale') as String?) ?? "system";
    switch (_locale) {
      case 'ar':
        return const Locale('ar');
      case 'en':
        return const Locale('en');
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      case 'zh':
        return const Locale('zh');
      case 'zh_Hant':
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      default:
        return null;
    }
  }

  changeLanguage(String val) async {
    if (val == _locale) return;
    _locale = val;
    await StorageUtil.set('locale', val);
    notifyListeners();
  }
}
