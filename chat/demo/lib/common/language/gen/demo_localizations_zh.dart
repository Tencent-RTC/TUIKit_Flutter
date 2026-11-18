// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'demo_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class DemoLocalizationsZh extends DemoLocalizations {
  DemoLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get customMessageMenuTitle => '自定义消息';

  @override
  String get customMessageContent => '欢迎加入云通信IM大家庭！';

  @override
  String get customMessageViewDetails => '查看详情';

  @override
  String get welcomeMessage =>
      '欢迎体验 Chat Demo！你可以先发送一条消息，体验基础聊天能力。\n如果想添加好友，可以前往联系人页面点击首页加号。\n如果想体验音视频通话，可以点击下方加号按钮 -> 语音通话/视频通话。';

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt => '先介绍一下你是谁，再说说你能帮我做什么。';

  @override
  String get customBotDialogTitle => '自定义 AI 助手';

  @override
  String get customBotDialogDesc =>
      '在体验工作台创建 AI 助手后，将助手 IM ID 中 @RBT# 之后的部分填到下方。';

  @override
  String get customBotDialogDocLink => '查看接入文档 ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound => '未找到该机器人，请确认已在工作台启用 AI 助手并完成「连接 IM 机器人」';

  @override
  String get customBotNetworkError => '网络异常，请稍后重试';

  @override
  String get customBotCancel => '取消';

  @override
  String get customBotConfirm => '确定';

  @override
  String get aiQuickStartTitle => '配置您的 AI 助手';

  @override
  String get aiQuickStartIntro =>
      'AI 助手会根据您导入的知识资料，在单聊中用文字或语音解答用户问题，解决不了时可转人工。';

  @override
  String get aiQuickStartStep1 => '在体验工作台创建 AI 助手，并连接您的 IM 应用';

  @override
  String get aiQuickStartStep2 => '在 IM 控制台填写工作台提供的回调地址和 Token';

  @override
  String get aiQuickStartStep3 => '单击左上角的助手名称，选择“自定义 AI 助手”并填入助手 ID';

  @override
  String get aiQuickStartDocHint => '详细步骤见官网文档“接入 UIKit 快速体验（无需服务器）”';

  @override
  String get aiQuickStartDoc => '查看接入文档';

  @override
  String get aiQuickStartCancel => '知道了';

  @override
  String get aiAgentPickerTitle => '选择 AI 助手';

  @override
  String get aiAgentCustomTitle => '自定义 AI 助手';

  @override
  String get aiAgentCustomDesc => '填入工作台的助手 ID';

  @override
  String get aiAgentCustomEdit => '修改';

  @override
  String get aiAgentCustomGo => '去体验';

  @override
  String get aiAgentNewBadge => 'NEW';

  @override
  String get aiVoiceTitle => 'AI 助手';

  @override
  String get aiVoiceHistory => '记录';

  @override
  String get aiVoiceHeadline => '和 AI 实时语音对话';

  @override
  String get aiVoiceSubtitle => '已学习腾讯云 IM 全部文档 · 随时打断';

  @override
  String get aiVoiceSubtitleAircon => '已学习空调使用与售后资料 · 随时打断';

  @override
  String get aiVoiceSubtitleDefault => '有问题直接说 · 随时打断';

  @override
  String get aiVoiceTryLabel => '试着问它';

  @override
  String get aiVoiceSamples =>
      '群消息收不到是什么原因？\n消息漫游怎么配置？\n离线推送收不到怎么办？\n已发送的消息怎么撤回？\n怎么给自己的应用加上 AI 助手？';

  @override
  String get aiVoiceSamplesAircon =>
      '空调不制冷了怎么自查？\n空调出风口冒白烟正常吗？\n二十平米的西晒卧室买几匹空调？\n空调开睡眠模式半夜会变成多少度？\n空调装好了还能七天无理由退吗？';

  @override
  String get aiVoiceSamplesDefault => '你能帮我做什么？\n你可以回答哪些问题？\n怎么转人工？';

  @override
  String get aiQuickQuestions =>
      'UserSig 提示过期怎么排查？\nExpireTime 设多久合适？\n群消息收不到是什么原因？\n消息漫游怎么配置？';

  @override
  String get aiQuickQuestionsAircon =>
      '空调显示 E4 是什么意思？\n冬天空调显示 H1 要报修吗？\n空调出风口冒白烟正常吗？\n20 平米的西晒卧室买几匹？\n3 匹柜机能插插线板吗？';

  @override
  String get aiVoiceStart => '点击开始通话';

  @override
  String get aiVoiceUseText => '改用文字提问 ›';

  @override
  String get aiVoiceBack => '‹ 语音';

  @override
  String get aiVoiceUnavailable => 'AI 助手还没准备好，请稍后再试';

  @override
  String get aiMicTitle => '需要使用麦克风';

  @override
  String get aiMicDesc => 'AI 需要听到你的声音才能回答。\n仅在通话中使用，挂断即停止。';

  @override
  String get aiMicTip => '● 建议在安静环境或佩戴耳机';

  @override
  String get aiMicAllow => '允许并开始通话';

  @override
  String get aiMicText => '先用文字提问';

  @override
  String get aiMicDeniedDesc => '麦克风权限已关闭。\n请在系统设置中开启后，再和 AI 通话。';

  @override
  String get aiMicOpenSettings => '去设置开启麦克风';

  @override
  String get aiCtaTitle => '把同款 AI 助手接入你的 App';

  @override
  String get aiCtaDesc => '基于腾讯云 IM + 对话式 AI';

  @override
  String get aiCtaAction => '立即了解';

  @override
  String get aiCtaClose => '关闭';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class DemoLocalizationsZhHans extends DemoLocalizationsZh {
  DemoLocalizationsZhHans() : super('zh_Hans');

  @override
  String get customMessageMenuTitle => '自定义消息';

  @override
  String get customMessageContent => '欢迎加入云通信IM大家庭！';

  @override
  String get customMessageViewDetails => '查看详情';

  @override
  String get welcomeMessage =>
      '欢迎体验 Chat Demo！你可以先发送一条消息，体验基础聊天能力。\n如果想添加好友，可以前往联系人页面点击首页加号。\n如果想体验音视频通话，可以点击下方加号按钮 -> 语音通话/视频通话。';

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt => '先介绍一下你是谁，再说说你能帮我做什么。';

  @override
  String get customBotDialogTitle => '自定义 AI 助手';

  @override
  String get customBotDialogDesc =>
      '在体验工作台创建 AI 助手后，将助手 IM ID 中 @RBT# 之后的部分填到下方。';

  @override
  String get customBotDialogDocLink => '查看接入文档 ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound => '未找到该机器人，请确认已在工作台启用 AI 助手并完成「连接 IM 机器人」';

  @override
  String get customBotNetworkError => '网络异常，请稍后重试';

  @override
  String get customBotCancel => '取消';

  @override
  String get customBotConfirm => '确定';

  @override
  String get aiQuickStartTitle => '配置您的 AI 助手';

  @override
  String get aiQuickStartIntro =>
      'AI 助手会根据您导入的知识资料，在单聊中用文字或语音解答用户问题，解决不了时可转人工。';

  @override
  String get aiQuickStartStep1 => '在体验工作台创建 AI 助手，并连接您的 IM 应用';

  @override
  String get aiQuickStartStep2 => '在 IM 控制台填写工作台提供的回调地址和 Token';

  @override
  String get aiQuickStartStep3 => '单击左上角的助手名称，选择“自定义 AI 助手”并填入助手 ID';

  @override
  String get aiQuickStartDocHint => '详细步骤见官网文档“接入 UIKit 快速体验（无需服务器）”';

  @override
  String get aiQuickStartDoc => '查看接入文档';

  @override
  String get aiQuickStartCancel => '知道了';

  @override
  String get aiAgentPickerTitle => '选择 AI 助手';

  @override
  String get aiAgentCustomTitle => '自定义 AI 助手';

  @override
  String get aiAgentCustomDesc => '填入工作台的助手 ID';

  @override
  String get aiAgentCustomEdit => '修改';

  @override
  String get aiAgentCustomGo => '去体验';

  @override
  String get aiAgentNewBadge => 'NEW';

  @override
  String get aiVoiceTitle => 'AI 助手';

  @override
  String get aiVoiceHistory => '记录';

  @override
  String get aiVoiceHeadline => '和 AI 实时语音对话';

  @override
  String get aiVoiceSubtitle => '已学习腾讯云 IM 全部文档 · 随时打断';

  @override
  String get aiVoiceSubtitleAircon => '已学习空调使用与售后资料 · 随时打断';

  @override
  String get aiVoiceSubtitleDefault => '有问题直接说 · 随时打断';

  @override
  String get aiVoiceTryLabel => '试着问它';

  @override
  String get aiVoiceSamples =>
      '群消息收不到是什么原因？\n消息漫游怎么配置？\n离线推送收不到怎么办？\n已发送的消息怎么撤回？\n怎么给自己的应用加上 AI 助手？';

  @override
  String get aiVoiceSamplesAircon =>
      '空调不制冷了怎么自查？\n空调出风口冒白烟正常吗？\n二十平米的西晒卧室买几匹空调？\n空调开睡眠模式半夜会变成多少度？\n空调装好了还能七天无理由退吗？';

  @override
  String get aiVoiceSamplesDefault => '你能帮我做什么？\n你可以回答哪些问题？\n怎么转人工？';

  @override
  String get aiQuickQuestions =>
      'UserSig 提示过期怎么排查？\nExpireTime 设多久合适？\n群消息收不到是什么原因？\n消息漫游怎么配置？';

  @override
  String get aiQuickQuestionsAircon =>
      '空调显示 E4 是什么意思？\n冬天空调显示 H1 要报修吗？\n空调出风口冒白烟正常吗？\n20 平米的西晒卧室买几匹？\n3 匹柜机能插插线板吗？';

  @override
  String get aiVoiceStart => '点击开始通话';

  @override
  String get aiVoiceUseText => '改用文字提问 ›';

  @override
  String get aiVoiceBack => '‹ 语音';

  @override
  String get aiVoiceUnavailable => 'AI 助手还没准备好，请稍后再试';

  @override
  String get aiMicTitle => '需要使用麦克风';

  @override
  String get aiMicDesc => 'AI 需要听到你的声音才能回答。\n仅在通话中使用，挂断即停止。';

  @override
  String get aiMicTip => '● 建议在安静环境或佩戴耳机';

  @override
  String get aiMicAllow => '允许并开始通话';

  @override
  String get aiMicText => '先用文字提问';

  @override
  String get aiMicDeniedDesc => '麦克风权限已关闭。\n请在系统设置中开启后，再和 AI 通话。';

  @override
  String get aiMicOpenSettings => '去设置开启麦克风';

  @override
  String get aiCtaTitle => '把同款 AI 助手接入你的 App';

  @override
  String get aiCtaDesc => '基于腾讯云 IM + 对话式 AI';

  @override
  String get aiCtaAction => '立即了解';

  @override
  String get aiCtaClose => '关闭';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class DemoLocalizationsZhHant extends DemoLocalizationsZh {
  DemoLocalizationsZhHant() : super('zh_Hant');

  @override
  String get customMessageMenuTitle => '自訂訊息';

  @override
  String get customMessageContent => '歡迎加入雲通訊 IM 大家庭！';

  @override
  String get customMessageViewDetails => '查看詳情';

  @override
  String get welcomeMessage =>
      '歡迎體驗 Chat Demo！你可以先發送一則訊息，體驗基礎聊天功能。\n如果想新增好友，可以前往聯絡人頁面點擊首頁加號。\n如果想體驗音視訊通話，可以點擊下方加號按鈕 -> 語音通話/視訊通話。';

  @override
  String get aiTab => 'AI';

  @override
  String get aiHomeInputPrompt => '先介紹一下你是誰，再說說你能幫我做什麼。';

  @override
  String get customBotDialogTitle => '自訂 AI 助手';

  @override
  String get customBotDialogDesc =>
      '在體驗工作台建立 AI 助手後，將助手 IM ID 中 @RBT# 之後的部分填到下方。';

  @override
  String get customBotDialogDocLink => '查看接入文件 ›';

  @override
  String get customBotInputHint => 'AIAssistant';

  @override
  String get customBotNotFound => '未找到該機器人，請確認已在工作台啟用 AI 助手並完成「連接 IM 機器人」';

  @override
  String get customBotNetworkError => '網路異常，請稍後重試';

  @override
  String get customBotCancel => '取消';

  @override
  String get customBotConfirm => '確定';

  @override
  String get aiQuickStartTitle => '設定您的 AI 助手';

  @override
  String get aiQuickStartIntro =>
      'AI 助手會根據您匯入的知識資料，在單聊中以文字或語音解答用戶問題，無法解決時可轉人工。';

  @override
  String get aiQuickStartStep1 => '在體驗工作台建立 AI 助手，並連接您的 IM 應用';

  @override
  String get aiQuickStartStep2 => '在 IM 控制台填寫工作台提供的回調地址和 Token';

  @override
  String get aiQuickStartStep3 => '點擊左上角的助手名稱，選擇「自訂 AI 助手」並填入助手 ID';

  @override
  String get aiQuickStartDocHint => '詳細步驟請參閱官網文件「接入 UIKit 快速體驗（無需伺服器）」';

  @override
  String get aiQuickStartDoc => '查看接入文件';

  @override
  String get aiQuickStartCancel => '知道了';

  @override
  String get aiAgentPickerTitle => '選擇 AI 助手';

  @override
  String get aiAgentCustomTitle => '自訂 AI 助手';

  @override
  String get aiAgentCustomDesc => '填入工作台的助手 ID';

  @override
  String get aiAgentCustomEdit => '修改';

  @override
  String get aiAgentCustomGo => '去體驗';

  @override
  String get aiAgentNewBadge => 'NEW';
}
