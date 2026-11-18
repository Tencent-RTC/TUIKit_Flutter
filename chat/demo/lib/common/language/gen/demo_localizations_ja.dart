// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'demo_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class DemoLocalizationsJa extends DemoLocalizations {
  DemoLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get customMessageMenuTitle => 'カスタムメッセージ';

  @override
  String get customMessageContent => 'クラウドコミュニケーション IM ファミリーへようこそ！';

  @override
  String get customMessageViewDetails => '詳細を見る';

  @override
  String get welcomeMessage =>
      'Chat Demo へようこそ！まずはメッセージを送信して、基本的なチャット機能をお試しください。\n友だちを追加するには、連絡先ページに移動してプラスボタンをタップしてください。\n音声通話やビデオ通話を試すには、下部のプラスボタンをタップして「音声通話／ビデオ通話」を選択してください。';

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt => 'まずあなたが誰かを紹介してから、何を手伝えるか教えてください。';

  @override
  String get customBotDialogTitle => 'カスタム AI アシスタント';

  @override
  String get customBotDialogDesc =>
      '体験ワークベンチで AI アシスタントを作成したら、アシスタント IM ID の @RBT# 以降を下に入力してください。';

  @override
  String get customBotDialogDocLink => '接続ガイドを見る ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound =>
      'ボットが見つかりません。ワークベンチでAIアシスタントが有効で、IMボットが接続済みであることを確認してください。';

  @override
  String get customBotNetworkError => 'ネットワークエラーです。後でもう一度お試しください';

  @override
  String get customBotCancel => 'キャンセル';

  @override
  String get customBotConfirm => 'OK';

  @override
  String get aiQuickStartTitle => 'AI アシスタントを設定してください';

  @override
  String get aiQuickStartIntro =>
      'AI アシスタントは、インポートしたナレッジをもとに、1対1チャットでユーザーの質問にテキストまたは音声で回答します。解決できない場合は有人オペレーターに引き継げます。';

  @override
  String get aiQuickStartStep1 => '体験ワークベンチで AI アシスタントを作成し、IM アプリに接続します';

  @override
  String get aiQuickStartStep2 =>
      'IM コンソールで、ワークベンチに表示されたコールバック URL と Token を設定します';

  @override
  String get aiQuickStartStep3 =>
      '左上のアシスタント名をタップし、「カスタム AI アシスタント」を選んでアシスタント ID を入力します';

  @override
  String get aiQuickStartDocHint =>
      '詳しい手順は公式ドキュメントの「UIKit クイック体験（サーバー不要）」をご覧ください';

  @override
  String get aiQuickStartDoc => '接続ガイドを見る';

  @override
  String get aiQuickStartCancel => 'OK';

  @override
  String get aiAgentPickerTitle => 'AIアシスタントを選択';

  @override
  String get aiAgentCustomTitle => 'カスタムAIアシスタント';

  @override
  String get aiAgentCustomDesc => 'アシスタント ID を入力';

  @override
  String get aiAgentCustomEdit => '変更';

  @override
  String get aiAgentCustomGo => '試す';

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
