// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'demo_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class DemoLocalizationsAr extends DemoLocalizations {
  DemoLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get customMessageMenuTitle => 'رسالة مخصصة';

  @override
  String get customMessageContent =>
      'مرحبًا بك في عائلة IM للاتصالات السحابية!';

  @override
  String get customMessageViewDetails => 'عرض التفاصيل';

  @override
  String get welcomeMessage =>
      'مرحبًا بك في Chat Demo! يمكنك أولاً إرسال رسالة لتجربة الدردشة الأساسية.\nلإضافة أصدقاء، انتقل إلى صفحة جهات الاتصال واضغط على زر الإضافة في الصفحة الرئيسية.\nلتجربة مكالمات الصوت والفيديو، اضغط على زر الإضافة أدناه -> مكالمة صوتية/مكالمة فيديو.';
}
