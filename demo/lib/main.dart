import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_cloud_chat_push/tencent_cloud_chat_push.dart';

import 'login_page.dart';
import 'splash_page.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  TencentCloudChatPush().registerOnAppWakeUpEvent(onAppWakeUpEvent: () async {
    debugPrint('onAppWakeUpEvent onAppWakeUpEvent');
    await _setTestEnvironment();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString(LoginScreen.DEV_LOGIN_USER_ID);
    final userSig = prefs.getString(LoginScreen.DEV_LOGIN_USER_SIG);
    TUICallKit.instance.login(
      SDKAPPID,
      userID ?? "",
      userSig ?? "",
    );
  });

  runApp(const MyApp());
}

Future<void> _setTestEnvironment() async {
  final prefs = await SharedPreferences.getInstance();
  final isTest = prefs.getBool("testEnvironment") ?? false;
  if (!isTest) return;
  try {
    Map<String, dynamic> param = {"request_set_env_param": true};
    await TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(api: "internal_operation_set_env", param: param);
    debugPrint("测试环境已启用");
  } catch (e) {
    debugPrint("设置测试环境失败: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await StorageUtil.init();
    await AppBuilder.init(path: 'assets/appConfig.json');

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        navigatorObservers: [TUICallKit.navigatorObserver],
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ComponentTheme(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => LoginInfoState()),
          ChangeNotifierProvider.value(value: LocaleProvider()),
        ],
        child: Builder(builder: (context) {
          final themeState = BaseThemeProvider.of(context);
          final isDarkMode = themeState.isDarkMode;
          final localeProvider = Provider.of<LocaleProvider>(context);

          return MaterialApp(
            title: 'TUIKit Next Demo',
            navigatorObservers: [TUICallKit.navigatorObserver],
            localizationsDelegates: const [
              AtomicLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AtomicLocalizations.supportedLocales,
            locale: localeProvider.locale,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C66E5)),
              primaryColor: const Color(0xFF1C66E5),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              scaffoldBackgroundColor: Colors.white,
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFF1C66E5).withOpacity(0.1),
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1C66E5),
                      fontWeight: FontWeight.w500,
                    );
                  }
                  return const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  );
                }),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1C66E5),
                brightness: Brightness.dark,
              ),
              primaryColor: const Color(0xFF1C66E5),
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: const Color(0xFF1C66E5).withOpacity(0.3),
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4086FF),
                      fontWeight: FontWeight.w500,
                    );
                  }
                  return const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  );
                }),
              ),
            ),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashPage(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/splash': (context) => const SplashPage(),
            },
          );
        }),
      ),
    );
  }
}