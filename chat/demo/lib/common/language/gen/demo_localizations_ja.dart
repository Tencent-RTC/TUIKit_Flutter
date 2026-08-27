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
}
