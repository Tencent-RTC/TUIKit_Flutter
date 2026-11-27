/// 对应 iOS `LiveKitAccess/AppDelegate.swift`。
///
/// 只负责创建应用外壳并交给 `LiveKitAccessCoordinator` 调度流程。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'effect_license.dart';
import 'main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(initializeEffectLicense());
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const LiveKitAccessApp());
}

class LiveKitAccessApp extends StatelessWidget {
  const LiveKitAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveKitAccess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: false,
      ),
      home: const MainPage(),
    );
  }
}
