import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:tencent_conference_uikit/base/widget/global.dart';
import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'common/index.dart';
import 'l10n/app_localizations.dart';
import 'pages/index.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = ThemeState();
    themeState.setThemeMode(ThemeType.dark);
    return ComponentTheme(
      themeState: themeState,
      child: MaterialApp(
        navigatorObservers: [RoomNavigatorObserver.instance],
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...RoomLocalizations.localizationsDelegates,
        ],
        supportedLocales: const [Locale('en'), Locale('zh')],
        builder: (context, child) => Scaffold(
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () {
              _hideKeyboard(context);
            },
            child: child,
          ),
        ),
        home: Navigator(
          key: Global.secondaryNavigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }

  void _hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
