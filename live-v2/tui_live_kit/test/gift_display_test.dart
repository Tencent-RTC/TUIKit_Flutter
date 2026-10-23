import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_display_view.dart';
import 'package:tencent_live_uikit/src/common/gift/display/playback/gift_resource_loader.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_animation_view.dart';
import 'package:tencent_live_uikit/src/common/gift/display/playback/gift_player.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_notice_view.dart';

class GiftSDK implements GiftStore {
  final listeners = <GiftListener>[];
  @override
  void addGiftListener(GiftListener listener) => listeners.add(listener);
  @override
  void removeGiftListener(GiftListener listener) => listeners.remove(listener);
  @override
  void setLanguage(String language) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EffectProbe extends GiftAnimationController {
  final enqueued = <String>[];

  @override
  void enqueue(String resourceURL) => enqueued.add(resourceURL);
}

class _OverlayLoader extends GiftResourceLoader {
  int loads = 0;

  @override
  Future<String> load(String resourceURL) async {
    loads++;
    return '/overlay.svga';
  }
}

GiftDisplayItem _localGift(int count, {String senderID = 'u'}) => GiftDisplayItem(
      giftID: 'g',
      name: 'Rose',
      iconURL: '',
      resourceURL: 'https://example.com/rose.svga',
      coins: 1,
      count: count,
      senderID: senderID,
      senderName: 'Sender',
      senderAvatarURL: '',
    );

void _receive(GiftSDK sdk, int count, {String senderID = 'u', String room = 'r'}) {
  // Exercise the callback registered by the current SDK adapter.
  // ignore: deprecated_member_use
  sdk.listeners.single.onReceiveGift!(
    room,
    Gift(giftID: 'g', name: 'Rose', resourceURL: 'https://example.com/rose.svga'),
    count,
    LiveUserInfo(userID: senderID),
  );
}

Future<void> _mount(WidgetTester tester, GiftDisplayController controller) =>
    tester.pumpWidget(MaterialApp(home: GiftDisplayView(controller: controller)));

Future<void> _dispose(WidgetTester tester, GiftDisplayController controller) async {
  await tester.pumpWidget(const SizedBox());
  controller.dispose();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('mounting in any background state keeps gift presentation suspended', (tester) async {
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    for (final lifecycle in [
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      final sdk = GiftSDK();
      final effects = _EffectProbe();
      final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
      await _mount(tester, controller);
      // 后台停止常规帧；强制测试帧挂载 State，保持真实后台初始值不变。
      tester.binding.scheduleForcedFrame();
      await tester.pump();
      _receive(sdk, 1);
      expect(controller.notice.activeEntries, isEmpty);
      expect(effects.enqueued, isEmpty);
      final hiddenSend = controller.reserveLocalGift(_localGift(1))!;
      controller.confirmLocalGift(hiddenSend);
      _receive(sdk, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      _receive(sdk, 1);
      expect(controller.notice.activeEntries.single.count, 1);
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      expect(controller.notice.activeEntries, isEmpty);
      _receive(sdk, 1);
      expect(effects.enqueued.length, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _dispose(tester, controller);
    }
  });

  testWidgets('capsules follow message and welcome anchors above the safe area', (tester) async {
    final controller = GiftDisplayController(liveID: '', animationController: _EffectProbe());
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final sample in <(Size, double)>[
      (const Size(320, 568), 0),
      (const Size(375, 844), 34),
      (const Size(430, 932), 24),
    ]) {
      tester.view.physicalSize = sample.$1;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: sample.$2)),
          child: GiftDisplayView(controller: controller, noticeBottom: sample.$2 + 86 + 60 + 32),
        ),
      ));
      controller.resetPresentation();
      controller.show(_localGift(1));
      controller.show(_localGift(1, senderID: 'another'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 520));
      final rect = tester.getRect(find.byType(GiftNoticeView));
      expect(rect.left, 12);
      expect(rect.width, sample.$1.width - 24);
      expect(rect.height, 44 * 2 + 4);
      expect(rect.bottom, sample.$1.height - sample.$2 - 86 - 60 - 32);
      expect(tester.getRect(find.byType(GiftAnimationView)), Offset.zero & sample.$1);
      expect(tester.takeException(), isNull);
    }
    await _dispose(tester, controller);
  });

  testWidgets('subscription follows overlay mounting and drops late events', (tester) async {
    final sdk = GiftSDK();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk);
    expect(sdk.listeners, isEmpty);
    await tester.pumpWidget(MaterialApp(home: GiftDisplayView(controller: controller)));
    final listener = sdk.listeners.single;
    final gift = Gift(giftID: 'g', name: 'Rose');
    final user = LiveUserInfo(userID: 'u');
    listener.onReceiveGift!('r', gift, 1, user);
    await tester.pump();
    expect(controller.notice.activeEntries.single.count, 1);
    controller.setSuspended(true);
    listener.onReceiveGift!('r', gift, 5, user);
    expect(controller.notice.activeEntries, isEmpty);
    await tester.pumpWidget(const SizedBox());
    expect(sdk.listeners, isEmpty);
    expect(controller.notice.activeEntries, isEmpty);
    listener.onReceiveGift!('r', gift, 3, user);
    expect(controller.notice.activeEntries, isEmpty);
    controller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed reservations survive broadcasts delayed over ten seconds', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final id = controller.reserveLocalGift(_localGift(3))!;
    controller.confirmLocalGift(id);
    expect(effects.enqueued.length, 1);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(const Duration(milliseconds: 320));
    expect(controller.notice.activeEntries, isEmpty);

    _receive(sdk, 3);
    controller.confirmLocalGift(id);
    expect(controller.notice.activeEntries, isEmpty);
    expect(effects.enqueued.length, 1);
    await _dispose(tester, controller);
  });

  testWidgets('aggregated broadcast before completions preserves each local animation', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final ids = <int>[
      controller.reserveLocalGift(_localGift(1))!,
      controller.reserveLocalGift(_localGift(2))!,
      controller.reserveLocalGift(_localGift(1))!,
    ];
    _receive(sdk, 4);
    expect(controller.notice.activeEntries.single.count, 4);
    expect(effects.enqueued.length, 3);
    for (final id in ids.reversed) {
      controller.confirmLocalGift(id);
      controller.confirmLocalGift(id);
    }
    expect(controller.notice.activeEntries.single.count, 4);
    expect(effects.enqueued.length, 3);
    await _dispose(tester, controller);
  });

  testWidgets('mixed completed and pending sends consume only matched counts', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final first = controller.reserveLocalGift(_localGift(2))!;
    final second = controller.reserveLocalGift(_localGift(3))!;
    controller.confirmLocalGift(first);
    _receive(sdk, 6);
    controller.confirmLocalGift(second);
    expect(controller.notice.activeEntries.single.count, 6);
    expect(effects.enqueued.length, 3);
    await _dispose(tester, controller);
  });

  testWidgets('partial broadcast and later completion render the remaining count once', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final id = controller.reserveLocalGift(_localGift(5))!;
    _receive(sdk, 2);
    controller.confirmLocalGift(id);
    controller.confirmLocalGift(id);
    _receive(sdk, 3);
    expect(controller.notice.activeEntries.single.count, 5);
    expect(effects.enqueued.length, 2);
    await _dispose(tester, controller);
  });

  testWidgets('failed reservations are removed without hiding a later real event', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final id = controller.reserveLocalGift(_localGift(2))!;
    controller.cancelLocalGift(id);
    controller.cancelLocalGift(id);
    controller.confirmLocalGift(id);
    expect(effects.enqueued, isEmpty);
    _receive(sdk, 2);
    expect(controller.notice.activeEntries.single.count, 2);
    expect(effects.enqueued.length, 1);
    await _dispose(tester, controller);
  });

  testWidgets('presentation reset and background retain reconciliation without replay', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final first = controller.reserveLocalGift(_localGift(1))!;
    controller.confirmLocalGift(first);
    controller.resetPresentation();
    _receive(sdk, 1);
    expect(controller.notice.activeEntries, isEmpty);
    expect(effects.enqueued.length, 1);

    final second = controller.reserveLocalGift(_localGift(2))!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    _receive(sdk, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    controller.confirmLocalGift(second);
    expect(controller.notice.activeEntries, isEmpty);
    expect(effects.enqueued.length, 1);
    await _dispose(tester, controller);
  });

  testWidgets('interruption does not replay local sends reconciled while hidden', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final id = controller.reserveLocalGift(_localGift(1))!;
    controller.confirmLocalGift(id);
    controller.setSuspended(true);
    _receive(sdk, 1);
    controller.setSuspended(false);
    controller.confirmLocalGift(id);
    expect(controller.notice.activeEntries, isEmpty);
    expect(effects.enqueued.length, 1);
    await _dispose(tester, controller);
  });

  testWidgets('interruption discards the current advanced gift and accepts only new gifts', (tester) async {
    final loader = _OverlayLoader();
    var decodes = 0;
    final player = GiftPlayer(
      loader: loader,
      decodeSVGA: (_) async {
        decodes++;
        return MovieEntity(
          params: MovieParams(
            viewBoxWidth: 100,
            viewBoxHeight: 200,
            fps: 30,
            frames: 60,
          ),
        );
      },
    );
    final effects = GiftAnimationController(player: player);
    final controller = GiftDisplayController(liveID: '', animationController: effects);
    await _mount(tester, controller);
    controller.show(_localGift(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(player.currentLocalPath, '/overlay.svga');
    controller.setSuspended(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(player.currentLocalPath, isNull);
    expect(find.byType(SVGAImage), findsNothing);
    controller.setSuspended(false);
    await tester.pump();
    expect(player.currentLocalPath, isNull);
    expect(loader.loads, 1);
    expect(decodes, 1);
    controller.show(_localGift(1));
    await tester.pump();
    await tester.pump();
    expect(player.currentLocalPath, '/overlay.svga');
    expect(loader.loads, 2);
    expect(decodes, 2);
    await _dispose(tester, controller);
  });

  testWidgets('late send success after interruption consumes its echo without replay', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final id = controller.reserveLocalGift(_localGift(2))!;
    controller.setSuspended(true);
    controller.setSuspended(false);
    controller.confirmLocalGift(id);
    _receive(sdk, 2);
    expect(controller.notice.activeEntries, isEmpty);
    expect(effects.enqueued, isEmpty);
    _receive(sdk, 1, senderID: 'new-sender');
    expect(controller.notice.activeEntries.single.count, 1);
    expect(effects.enqueued.length, 1);
    await _dispose(tester, controller);
  });

  testWidgets('unmount clears reservations and rejects the old session callback', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final oldListener = sdk.listeners.single;
    final id = controller.reserveLocalGift(_localGift(1))!;
    controller.confirmLocalGift(id);
    await tester.pumpWidget(const SizedBox());
    await _mount(tester, controller);
    // Deliver through the old registered callback to verify session isolation.
    // ignore: deprecated_member_use
    oldListener.onReceiveGift!('r', Gift(giftID: 'g'), 9, LiveUserInfo(userID: 'u'));
    expect(controller.notice.activeEntries, isEmpty);
    controller.confirmLocalGift(id);
    _receive(sdk, 1);
    expect(controller.notice.activeEntries.single.count, 1);
    expect(effects.enqueued.length, 2);
    await _dispose(tester, controller);
  });

  testWidgets('room and sender identity separate reservations, SDK increments stay authoritative', (tester) async {
    final sdk = GiftSDK();
    final effects = _EffectProbe();
    final controller = GiftDisplayController(liveID: 'r', giftStore: sdk, animationController: effects);
    await _mount(tester, controller);
    final id = controller.reserveLocalGift(_localGift(1))!;
    _receive(sdk, 1, room: 'other');
    _receive(sdk, 0);
    expect(effects.enqueued, isEmpty);
    _receive(sdk, 1, senderID: 'remote');
    _receive(sdk, 1, senderID: 'remote');
    controller.confirmLocalGift(id);
    _receive(sdk, 1);
    expect(controller.notice.activeEntries.map((slot) => slot.count), [2, 1]);
    expect(effects.enqueued.length, 3);
    await _dispose(tester, controller);
  });
}
