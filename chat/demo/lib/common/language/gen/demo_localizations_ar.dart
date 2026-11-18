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

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt =>
      'عرّفني بنفسك أولاً، ثم أخبرني بما يمكنك مساعدتي فيه.';

  @override
  String get customBotDialogTitle => 'مساعد ذكاء اصطناعي مخصص';

  @override
  String get customBotDialogDesc =>
      'بعد إنشاء مساعد ذكاء اصطناعي في منصة التجربة، أدخل الجزء الذي يلي @RBT# من معرّف IM للمساعد أدناه.';

  @override
  String get customBotDialogDocLink => 'عرض دليل الدمج ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound =>
      'لم يتم العثور على الروبوت. تأكد من تفعيل مساعد الذكاء الاصطناعي وربط روبوت IM في منصة العمل.';

  @override
  String get customBotNetworkError => 'خطأ في الشبكة، يرجى المحاولة لاحقًا';

  @override
  String get customBotCancel => 'إلغاء';

  @override
  String get customBotConfirm => 'موافق';

  @override
  String get aiQuickStartTitle => 'أعدّ مساعد الذكاء الاصطناعي الخاص بك';

  @override
  String get aiQuickStartIntro =>
      'يجيب مساعد الذكاء الاصطناعي عن أسئلة المستخدمين نصيًا أو صوتيًا في المحادثات الفردية استنادًا إلى المعرفة التي تستوردها، ويحوّل المحادثة إلى موظف خدمة عند الحاجة.';

  @override
  String get aiQuickStartStep1 =>
      'أنشئ مساعد ذكاء اصطناعي في منصة التجربة واربطه بتطبيق IM الخاص بك';

  @override
  String get aiQuickStartStep2 =>
      'أدخل عنوان رد الاستدعاء والرمز المميز من منصة التجربة في وحدة تحكم IM';

  @override
  String get aiQuickStartStep3 =>
      'انقر على اسم المساعد في الزاوية العلوية، وحدد \"مساعد ذكاء اصطناعي مخصص\"، ثم أدخل معرّف المساعد';

  @override
  String get aiQuickStartDocHint =>
      'لمزيد من التفاصيل، راجع قسم \"تجربة سريعة مع UIKit (بدون خادم)\" في الوثائق الرسمية';

  @override
  String get aiQuickStartDoc => 'عرض دليل الدمج';

  @override
  String get aiQuickStartCancel => 'حسنًا';

  @override
  String get aiAgentPickerTitle => 'اختر مساعد الذكاء الاصطناعي';

  @override
  String get aiAgentCustomTitle => 'مساعد ذكاء اصطناعي مخصص';

  @override
  String get aiAgentCustomDesc => 'أدخل معرّف المساعد';

  @override
  String get aiAgentCustomEdit => 'تعديل';

  @override
  String get aiAgentCustomGo => 'جرّب';

  @override
  String get aiAgentNewBadge => 'NEW';

  @override
  String get aiVoiceTitle => 'AI Assistant';

  @override
  String get aiVoiceHistory => 'History';

  @override
  String get aiVoiceHeadline => 'Talk to AI in real time';

  @override
  String get aiVoiceSubtitle =>
      'Knows all Tencent Cloud Chat docs · Interrupt anytime';

  @override
  String get aiVoiceSubtitleAircon =>
      'Knows air conditioner usage and after-sales guides · Interrupt anytime';

  @override
  String get aiVoiceSubtitleDefault => 'Just ask out loud · Interrupt anytime';

  @override
  String get aiVoiceTryLabel => 'Try asking';

  @override
  String get aiVoiceSamples =>
      'Why are group messages not received?\nHow do I configure message roaming?\nWhy are offline push notifications not arriving?\nHow do I recall a sent message?\nHow can I add an AI agent to my app?';

  @override
  String get aiVoiceSamplesAircon =>
      'My air conditioner is not cooling. How do I check it?\nIs white mist from the air outlet normal?\nWhat size unit fits a 20 square meter west-facing bedroom?\nWhat temperature does sleep mode reach at midnight?\nCan I still return the air conditioner after installation?';

  @override
  String get aiVoiceSamplesDefault =>
      'What can you help me with?\nWhat questions can you answer?\nHow do I reach a human agent?';

  @override
  String get aiQuickQuestions =>
      'Why does UserSig expire?\nHow long should ExpireTime be?\nGroup messages not received?\nHow to set up message roaming?';

  @override
  String get aiQuickQuestionsAircon =>
      'What does error code E4 mean?\nDo I need repair when H1 shows in winter?\nIs white mist from the air outlet normal?\nWhat size unit for a 20 m² west-facing bedroom?\nCan a 3 HP unit use a power strip?';

  @override
  String get aiVoiceStart => 'Tap to start a call';

  @override
  String get aiVoiceUseText => 'Ask by text instead ›';

  @override
  String get aiVoiceBack => '‹ Voice';

  @override
  String get aiVoiceUnavailable =>
      'AI assistant is not ready yet. Please try again later.';

  @override
  String get aiMicTitle => 'Microphone access needed';

  @override
  String get aiMicDesc =>
      'AI needs to hear you to answer.\nOnly used during the call and stops when you hang up.';

  @override
  String get aiMicTip => '● Works best in a quiet place or with earphones';

  @override
  String get aiMicAllow => 'Allow and start call';

  @override
  String get aiMicText => 'Ask by text first';

  @override
  String get aiMicDeniedDesc =>
      'Microphone access is turned off.\nTurn it on in Settings to talk to AI.';

  @override
  String get aiMicOpenSettings => 'Open Settings';

  @override
  String get aiCtaTitle => 'Bring the same AI agent to your app';

  @override
  String get aiCtaDesc => 'Built on Tencent Cloud Chat + Conversational AI';

  @override
  String get aiCtaAction => 'Learn more';

  @override
  String get aiCtaClose => 'Close';
}
