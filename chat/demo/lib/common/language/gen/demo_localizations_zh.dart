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
}
