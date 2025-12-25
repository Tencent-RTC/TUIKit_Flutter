import 'package:flutter/material.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import 'debug/generate_test_user_sig.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(localizationsDelegates: const [
      ...GiftLocalizations.localizationsDelegates,
    ], supportedLocales: const [
      ...GiftLocalizations.supportedLocales,
    ], theme: ThemeData.dark(), home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const userId = '1001';
  static const roomId = 'live_$userId';
  final ValueNotifier<bool> enterRoomSuccess = ValueNotifier(false);
  bool isLogin = false;
  final LiveListStore _liveListStore = LiveListStore.shared;

  @override
  void initState() {
    super.initState();
    login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
            valueListenable: enterRoomSuccess,
            builder: (context, success, _) {
              return Visibility(
                visible: success,
                child: GiftWidget(roomId: roomId),
              );
            }),
      ),
    );
  }

  void login() async {
    if (isLogin) {
      return;
    }
    isLogin = true;

    final result = await LoginStore.shared
        .login(sdkAppID: GenerateTestUserSig.sdkAppId, userID: userId, userSig: GenerateTestUserSig.genTestSig(userId));
    debugPrint("login Result code:${result.errorCode}, message:${result.errorMessage}");
    await Future.delayed(const Duration(seconds: 3));
    final liveInfo = LiveInfo(liveID: roomId);
    final createLiveResult = await _liveListStore.createLive(liveInfo);
    debugPrint('createLive result code:${createLiveResult.errorCode}, message:${createLiveResult.errorMessage}');
    if (createLiveResult.isSuccess) {
      enterRoomSuccess.value = true;
    }
  }
}

class GiftWidget extends StatelessWidget {
  final String roomId;
  GiftListController? sendController;
  LikeSendController? likeController;
  GiftPlayController? displayController;

  GiftWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    likeController ??= LikeSendController(roomId: roomId);
    sendController ??= GiftListController(roomId: roomId);

    if (displayController == null) {
      displayController = GiftPlayController(roomId: roomId, enablePreloading: true);
      displayController?.onReceiveGiftCallback = _onReceiveGiftCallback;
    }

    return Stack(
      children: [
        Positioned(
          left: 20,
          bottom: 50,
          width: 40,
          height: 40,
          child: SizedBox(
            width: 40,
            height: 40,
            child: GiftSendWidget(
              controller: sendController!,
            ),
          ),
        ),
        Positioned(
          left: 80,
          bottom: 50,
          width: 40,
          height: 40,
          child: SizedBox(
            width: 40,
            height: 40,
            child: LikeSendWidget(
              controller: likeController!,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: GiftPlayWidget(giftPlayController: displayController!),
        ),
      ],
    );
  }

  void _onReceiveGiftCallback(Gift gift, int count, LiveUserInfo sender) {
    debugPrint("DemoOnReceiveGiftListener onReceiveGift gift:$gift, count:$count, sender:$sender");
  }
}
