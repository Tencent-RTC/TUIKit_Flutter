import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_live_uikit/common/widget/global.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
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
  late final ThemeState _themeState;

  @override
  void initState() {
    super.initState();
    _themeState = ThemeState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    GlobalFloatWindowManager.instance.enableFloatWindowFeature(true);
    await AppBuilder.init(path: 'assets/appConfig.json');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: LocaleProvider()),
      ],
      child: Builder(builder: (context) {
        return ComponentTheme(
          themeState: _themeState,
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
              AtomicLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
              Locale('zh'),
            ],
            locale: Provider.of<LocaleProvider>(context).locale,
            builder: (context, child) => Scaffold(
              resizeToAvoidBottomInset: false,
              body: GestureDetector(
                onTap: () {
                  hideKeyboard(context);
                },
                child: child,
              ),
            ),
            home: PopScope(
              canPop: false,
              child: Navigator(
                key: Global.secondaryNavigatorKey,
                initialRoute: '/login_widget',
                onGenerateRoute: (settings) {
                  if (settings.name == '/login_widget') {
                    return MaterialPageRoute(builder: (BuildContext context) => const LoginWidget());
                  }
                  return null;
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
