// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'demo_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class DemoLocalizationsKo extends DemoLocalizations {
  DemoLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get customMessageMenuTitle => '사용자 지정 메시지';

  @override
  String get customMessageContent => '클라우드 커뮤니케이션 IM 패밀리에 오신 것을 환영합니다!';

  @override
  String get customMessageViewDetails => '자세히 보기';

  @override
  String get welcomeMessage =>
      'Chat Demo에 오신 것을 환영합니다! 먼저 메시지를 보내 기본 채팅 기능을 사용해 보세요.\n친구를 추가하려면 연락처 페이지로 이동해 더하기 버튼을 탭하세요.\n음성 통화나 영상 통화를 사용해 보려면 아래 더하기 버튼을 탭한 후 음성 통화/영상 통화를 선택하세요.';

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt => '먼저 당신이 누구인지 소개하고, 무엇을 도와줄 수 있는지 알려 주세요.';

  @override
  String get customBotDialogTitle => '사용자 지정 AI 어시스턴트';

  @override
  String get customBotDialogDesc =>
      '체험 워크벤치에서 AI 어시스턴트를 만든 뒤, 어시스턴트 IM ID에서 @RBT# 뒤의 부분을 아래에 입력하세요.';

  @override
  String get customBotDialogDocLink => '연동 가이드 보기 ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound =>
      '봇을 찾을 수 없습니다. 워크벤치에서 AI 어시스턴트가 활성화되어 있고 IM 봇이 연결되었는지 확인하세요.';

  @override
  String get customBotNetworkError => '네트워크 오류입니다. 잠시 후 다시 시도하세요';

  @override
  String get customBotCancel => '취소';

  @override
  String get customBotConfirm => '확인';

  @override
  String get aiQuickStartTitle => 'AI 어시스턴트를 설정하세요';

  @override
  String get aiQuickStartIntro =>
      'AI 어시스턴트는 가져온 지식 자료를 바탕으로 1:1 채팅에서 텍스트나 음성으로 사용자 질문에 답하고, 해결하지 못하면 상담원에게 연결합니다.';

  @override
  String get aiQuickStartStep1 => '체험 워크벤치에서 AI 어시스턴트를 만들고 IM 앱에 연결하세요';

  @override
  String get aiQuickStartStep2 => 'IM 콘솔에 워크벤치에서 제공하는 콜백 URL과 Token을 입력하세요';

  @override
  String get aiQuickStartStep3 =>
      '왼쪽 위의 어시스턴트 이름을 탭하고 \'사용자 지정 AI 어시스턴트\'를 선택해 어시스턴트 ID를 입력하세요';

  @override
  String get aiQuickStartDocHint =>
      '자세한 단계는 공식 문서의 \'UIKit 빠른 체험(서버 불필요)\'을 참고하세요';

  @override
  String get aiQuickStartDoc => '연동 가이드 보기';

  @override
  String get aiQuickStartCancel => '확인';

  @override
  String get aiAgentPickerTitle => 'AI 어시스턴트 선택';

  @override
  String get aiAgentCustomTitle => '사용자 지정 AI 어시스턴트';

  @override
  String get aiAgentCustomDesc => '어시스턴트 ID 입력';

  @override
  String get aiAgentCustomEdit => '수정';

  @override
  String get aiAgentCustomGo => '체험하기';

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
