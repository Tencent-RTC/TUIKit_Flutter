import 'package:flutter/widgets.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

/// Demo-only helper that pushes a one-off guidance message to the built-in
/// "administrator" conversation shortly after the user logs in, mirroring the
/// native demos' first-run hint.
class WelcomeMessageSender {
  WelcomeMessageSender._();

  static const String _administratorConversationID = 'c2c_administrator';
  static const Duration _sendDelay = Duration(seconds: 1);

  static const String _welcomeEn =
      'Welcome to Chat Demo! Send a message to try out the basic chat.\n'
      'To add friends, go to the Contacts page and tap the plus button.\n'
      'To make audio or video calls, tap the plus button below -> Voice Call/Video Call.';
  static const String _welcomeZh =
      '欢迎体验 Chat Demo！你可以先发送一条消息，体验基础聊天能力。\n'
      '如果想添加好友，可以前往联系人页面点击首页加号。\n'
      '如果想体验音视频通话，可以点击下方加号按钮 -> 语音通话/视频通话。';
  static const String _welcomeZhHant =
      '歡迎體驗 Chat Demo！你可以先發送一則訊息，體驗基礎聊天功能。\n'
      '如果想新增好友，可以前往聯絡人頁面點擊首頁加號。\n'
      '如果想體驗音視訊通話，可以點擊下方加號按鈕 -> 語音通話/視訊通話。';
  static const String _welcomeAr =
      'مرحبًا بك في Chat Demo! يمكنك أولاً إرسال رسالة لتجربة الدردشة الأساسية.\n'
      'لإضافة أصدقاء، انتقل إلى صفحة جهات الاتصال واضغط على زر الإضافة في الصفحة الرئيسية.\n'
      'لتجربة مكالمات الصوت والفيديو، اضغط على زر الإضافة أدناه -> مكالمة صوتية/مكالمة فيديو.';

  /// Schedules the welcome message to be sent after a short delay so it lands
  /// once the conversation list has settled post-login.
  static void scheduleWelcomeMessage() {
    Future.delayed(_sendDelay, _sendWelcomeMessage);
  }

  static Future<void> _sendWelcomeMessage() async {
    final message = _resolveMessage(await _currentLocale());
    final result = await MessageInputStore.create(conversationID: _administratorConversationID)
        .sendMessage(payload: TextSendMessagePayload(text: message));
    if (!result.isSuccess) {
      debugPrint('send welcome message failed: ${result.errorCode}, ${result.errorMessage}');
    }
  }

  /// Resolves the effective locale the same way [LocaleProvider] does: honour
  /// the in-app language override when set, otherwise fall back to the system
  /// locale.
  static Future<Locale> _currentLocale() async {
    final saved = await StorageUtil.get('locale');
    switch (saved) {
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
        return WidgetsBinding.instance.platformDispatcher.locale;
    }
  }

  static String _resolveMessage(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? _welcomeZhHant : _welcomeZh;
    }
    if (locale.languageCode == 'ar') {
      return _welcomeAr;
    }
    return _welcomeEn;
  }
}
