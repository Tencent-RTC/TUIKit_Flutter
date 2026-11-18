// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'demo_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DemoLocalizationsEn extends DemoLocalizations {
  DemoLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get customMessageMenuTitle => 'Custom Message';

  @override
  String get customMessageContent =>
      'Welcome to the Cloud Communication IM family!';

  @override
  String get customMessageViewDetails => 'View Details';

  @override
  String get welcomeMessage =>
      'Welcome to Chat Demo! Send a message to try out the basic chat.\nTo add friends, go to the Contacts page and tap the plus button.\nTo make audio or video calls, tap the plus button below -> Voice Call/Video Call.';

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt =>
      'First tell me who you are, then what you can help me with.';

  @override
  String get customBotDialogTitle => 'Custom AI assistant';

  @override
  String get customBotDialogDesc =>
      'After creating an AI assistant in the experience workbench, enter the part of its assistant IM ID after @RBT# below.';

  @override
  String get customBotDialogDocLink => 'View integration guide ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound =>
      'Bot not found. Make sure the AI assistant is enabled and the IM bot is connected in the workbench.';

  @override
  String get customBotNetworkError => 'Network error, please try again later';

  @override
  String get customBotCancel => 'Cancel';

  @override
  String get customBotConfirm => 'OK';

  @override
  String get aiQuickStartTitle => 'Set up your AI assistant';

  @override
  String get aiQuickStartIntro =>
      'The AI assistant answers your users\' questions by text or voice in one-to-one chats, based on the knowledge you import, and hands over to a human agent when needed.';

  @override
  String get aiQuickStartStep1 =>
      'Create an AI assistant in the experience workbench and connect it to your IM app';

  @override
  String get aiQuickStartStep2 =>
      'Enter the callback URL and token from the workbench in the IM console';

  @override
  String get aiQuickStartStep3 =>
      'Tap the assistant name in the upper-left corner, choose \"Custom AI assistant\", and enter the assistant ID';

  @override
  String get aiQuickStartDocHint =>
      'For details, see \"Quick start with UIKit (no server required)\" in the official documentation';

  @override
  String get aiQuickStartDoc => 'View integration guide';

  @override
  String get aiQuickStartCancel => 'Got it';

  @override
  String get aiAgentPickerTitle => 'Choose an AI assistant';

  @override
  String get aiAgentCustomTitle => 'Custom AI assistant';

  @override
  String get aiAgentCustomDesc => 'Enter your assistant ID';

  @override
  String get aiAgentCustomEdit => 'Edit';

  @override
  String get aiAgentCustomGo => 'Try it';

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
