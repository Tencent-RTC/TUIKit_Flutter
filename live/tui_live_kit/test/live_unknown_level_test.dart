import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_stream_view.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_ui_store.dart';
import 'package:tencent_live_uikit/src/common/gift/gift_barrage_store.dart';
import 'package:tencent_live_uikit/src/common/theme/level_badge_view.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';

void main() {
  testWidgets('comment levels use the SDK message snapshot, including zero', (tester) async {
    final source = _CommentSource();
    final store = BarrageUIStore(storeFactory: (_) => source);
    store.activate(liveID: 'room', hostUserID: 'host');
    addTearDown(() {
      store.deactivate();
      source.messageList.dispose();
    });
    BarrageComment comment(String sender, int level) {
      source.messageList.value = [Barrage(sender: LiveUserInfo(userID: sender, level: level), textContent: 'Hi')];
      return store.comments.single;
    }

    expect(comment('guest', 25).level, 25);
    expect(comment('', 0).level, 0);
    expect(comment('', 0).userName, LiveKitResources.localizedString('tuilivekit.common.viewer'));
    expect(comment('host', 0).level, 0);
    expect(comment('guest', 0).isHost, isFalse);
    Widget view(int level) {
      final host = comment('host', level);
      expect(host.isHost, isTrue);
      return MaterialApp(
          home: SizedBox(
        height: 184,
        child: BarrageStreamView(messages: [
          LiveMessage(
            id: host.id,
            userName: host.userName,
            content: host.content,
            level: host.level,
            isHost: host.isHost,
          )
        ]),
      ));
    }

    await tester.pumpWidget(view(25));
    await tester.pumpAndSettle();
    expect(find.byType(LevelBadgeView), findsOneWidget);
    expect(tester.widget<LevelBadgeView>(find.byType(LevelBadgeView)).level, 25);
    await tester.pumpWidget(view(26));
    await tester.pumpAndSettle();
    expect(tester.widget<LevelBadgeView>(find.byType(LevelBadgeView)).level, 26);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown SDK levels hide badges and known Player levels keep them', (tester) async {
    Widget view(int? level) => MaterialApp(
            home: Column(children: [
          GiftCommentRow(
              comment: LiveGiftBarrage(
                  giftID: 'g',
                  giftName: 'G',
                  giftIconURL: '',
                  count: 1,
                  senderID: 'u',
                  senderName: 'U',
                  senderLevel: level)),
          SizedBox(
              height: 184,
              child: BarrageStreamView(messages: [LiveMessage(id: 'm', userName: 'U', content: 'Hi', level: level)])),
        ]));
    await tester.pumpWidget(view(null));
    await tester.pumpAndSettle();
    expect(find.byType(LevelBadgeView), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(view(25));
    await tester.pumpAndSettle();
    expect(find.byType(LevelBadgeView), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

class _CommentSource implements BarrageStore, BarrageState {
  @override
  BarrageState get barrageState => this;

  @override
  final ValueNotifier<List<Barrage>> messageList = ValueNotifier<List<Barrage>>([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
