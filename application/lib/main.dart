import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_live_uikit/common/widget/global.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import 'src/login/index.dart';
import 'src/utils/index.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ThemeState();
    themeState.setThemeMode(ThemeType.dark);
    return ComponentTheme(
      themeState: themeState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorObservers: [
          TUILiveKitNavigatorObserver.instance,
          RoomNavigatorObserver.instance,
          TUICallKit.navigatorObserver
        ],
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...LiveKitLocalizations.localizationsDelegates,
          ...BarrageLocalizations.localizationsDelegates,
          ...GiftLocalizations.localizationsDelegates,
          ...RoomLocalizations.localizationsDelegates,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale('zh'),
        ],
        builder: (context, child) => Scaffold(
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () {
              hideKeyboard(context);
            },
            child: child,
          ),
        ),
        home: Navigator(
          key: Global.secondaryNavigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(
              settings: const RouteSettings(name: 'login_widget'),
              builder: (BuildContext context) {
                return const LoginWidget();
              }),
        ),
      ),
    );
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
