import 'dart:async';
import 'dart:convert';
import 'package:atomic_x_core/atomicxcore.dart';
import 'common/platform/effect_license.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' as chat;
import 'login/login_store.dart';
import 'login/login_view.dart';
import 'register/register_view.dart';
import 'home/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferences = await SharedPreferences.getInstance();
  Map<String, dynamic> savedTheme = {};
  try {
    final decoded = jsonDecode(preferences.getString('BaseComponentThemeKey') ?? '{}');
    if (decoded is Map<String, dynamic>) savedTheme = decoded;
  } on FormatException {
    savedTheme = {};
  }
  savedTheme['mode'] = 1;
  await preferences.setString('BaseComponentThemeKey', jsonEncode(savedTheme));
  unawaited(AppEffectLicense.initialize());
  runApp(const AppUIKit());
}

class AppUIKit extends StatefulWidget {
  const AppUIKit({super.key});
  @override
  State<AppUIKit> createState() => _AppUIKitState();
}

class _AppUIKitState extends State<AppUIKit> {
  final auth = AppLoginStore();
  final theme = chat.ThemeState();
  final locale = chat.LocaleProvider();
  final navigator = GlobalKey<NavigatorState>();
  bool _lastReady = false;
  @override
  void initState() {
    super.initState();
    auth.addListener(_authChanged);
  }

  void _authChanged() {
    if (auth.sessionReady && !_lastReady) unawaited(AppEffectLicense.initialize());
    _lastReady = auth.sessionReady;
    if (!auth.sessionReady && !auth.pusherVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !auth.sessionReady && !auth.pusherVisible) {
          navigator.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  void dispose() {
    auth.removeListener(_authChanged);
    auth.dispose();
    theme.dispose();
    locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: locale,
    builder: (context, child) => chat.BaseThemeProvider(
      themeState: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigator,
        locale: locale.locale,
        theme: ThemeData(colorSchemeSeed: const Color(0xff006EFF), brightness: Brightness.light, useMaterial3: true),
        localizationsDelegates: const [
          chat.ChatLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: chat.ChatLocalizations.supportedLocales,
        home: AnimatedBuilder(
          animation: auth,
          builder: (context, _) {
            final state = LoginStore.shared.loginState;
            if (auth.pusherVisible) {
              return HomeView(key: ValueKey(locale.locale?.languageCode), auth: auth, locale: locale);
            }
            if (!auth.sessionReady || state.loginStatus != LoginStatus.logined || state.loginUserInfo == null) {
              return LoginView(store: auth);
            }
            if (state.loginUserInfo!.nickname?.isNotEmpty != true) return const RegisterView();
            return HomeView(key: ValueKey(locale.locale?.languageCode), auth: auth, locale: locale);
          },
        ),
      ),
    ),
  );
}
