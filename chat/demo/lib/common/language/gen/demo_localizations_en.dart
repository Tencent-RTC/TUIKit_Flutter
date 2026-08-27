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
}
