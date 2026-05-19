import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import 'package:tencent_live_uikit_example/generated/l10n.dart';
import 'package:tencent_live_uikit_example/src/view/index.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final ThemeState _themeState = ThemeState();

  @override
  void initState() {
    super.initState();
    _themeState.setThemeMode(ThemeType.dark);
  }

  @override
  Widget build(BuildContext context) {
    S.load(View.of(context).platformDispatcher.locale);
    return ComponentTheme(
      themeState: _themeState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorObservers: [TUILiveKitNavigatorObserver.instance],
        localizationsDelegates: const [
          ...LiveKitLocalizations.localizationsDelegates,
          ...BarrageLocalizations.localizationsDelegates,
          ...GiftLocalizations.localizationsDelegates,
          AtomicLocalizations.delegate,
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
        home: const LoginWidget(),
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
