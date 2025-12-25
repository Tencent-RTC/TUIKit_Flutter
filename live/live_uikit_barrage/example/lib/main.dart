import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:barrage_example/debug/generate_test_user_sig.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BarrageDisplayController displayController;
  late BarrageSendController sendController;
  final LiveListStore _liveListStore = LiveListStore.shared;
  late final LiveAudienceStore _liveAudienceStore;
  late final LiveAudienceListener _liveAudienceListener;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _liveAudienceStore.removeLiveAudienceListener(_liveAudienceListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        ...BarrageLocalizations.localizationsDelegates,
      ],
      supportedLocales: const [
        ...BarrageLocalizations.supportedLocales,
      ],
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Barrage example app'),
        ),
        backgroundColor: const Color(0x60C5CCDB),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              debugPrint(orientation.toString());
              const userId = '1001';
              const userName = 'Tom';
              const roomId = 'live_$userId';
              sendController =
                  BarrageSendController(roomId: roomId, ownerId: userId, selfUserId: userId, selfName: userName);
              displayController =
                  BarrageDisplayController(roomId: roomId, ownerId: userId, selfUserId: userId, selfName: userName);
              displayController.setCustomBarrageBuilder(GiftBarrageItemBuilder());
              return Stack(
                alignment: AlignmentDirectional.bottomStart,
                children: [
                  Center(
                    child: Container(
                        margin: const EdgeInsets.only(left: 16, right: 56),
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: BarrageDisplayWidget(controller: displayController)),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: SizedBox(width: 130, height: 36, child: BarrageSendWidget(controller: sendController)),
                  ),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: ElevatedButton(
                        onPressed: () {
                          Barrage barrage = Barrage();
                          barrage.textContent = "gift_item";
                          LiveUserInfo user = LiveUserInfo();

                          user.userID = "1002";
                          user.userName = "Lucy";
                          barrage.sender = user;
                          displayController.insertMessage(barrage);
                        },
                        child: const Text("send gift"),
                      )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    const userId = '1001';
    const roomId = 'live_$userId';

    final result = await LoginStore.shared
        .login(sdkAppID: GenerateTestUserSig.sdkAppId, userID: userId, userSig: GenerateTestUserSig.genTestSig(userId));

    debugPrint("LoginStore login code：${result.errorCode}, message:${result.errorMessage}");
    await Future.delayed(const Duration(seconds: 3));
    final liveInfo = LiveInfo(liveID: roomId);
    final startLiveResult = await _liveListStore.createLive(liveInfo);

    debugPrint("startLive result：${startLiveResult.errorCode}-${startLiveResult.errorMessage}");
    if (startLiveResult.isSuccess) {
      _liveAudienceStore = LiveAudienceStore.create(roomId);
      _addObserver();
    }
  }

  void _addObserver() {
    _liveAudienceListener = LiveAudienceListener(onAudienceJoined: (audience) {
      Barrage barrage = Barrage();
      barrage.sender = audience;
      barrage.textContent = "enter room";
      displayController.insertMessage(barrage);
    }, onAudienceLeft: (audience) {
      // leave room
    });

    _liveAudienceStore.addLiveAudienceListener(_liveAudienceListener);
  }
}

class GiftBarrageItemBuilder extends CustomBarrageBuilder {
  @override
  Widget buildWidget(BuildContext context, Barrage barrage) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Colors.white, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Text(
        'receive a gift',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  bool shouldCustomizeBarrageItem(Barrage barrage) {
    if (barrage.textContent == "gift_item") {
      return true;
    }
    return false;
  }
}
