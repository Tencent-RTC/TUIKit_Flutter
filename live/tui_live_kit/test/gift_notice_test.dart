import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_notice_view.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_display_view.dart';

GiftDisplayItem gift(String id, int count) => GiftDisplayItem(
    giftID: id,
    name: 'Gift',
    iconURL: '',
    resourceURL: '',
    coins: 1,
    count: count,
    senderID: 'sender',
    senderName: 'Name',
    senderAvatarURL: '');

void main() {
  testWidgets(
      'two channels merge queued combos and reset cancels scheduled work',
      (tester) async {
    final controller = GiftNoticeController();
    await tester.pumpWidget(MaterialApp(
        home: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
                width: 234, child: GiftNoticeView(controller: controller)))));
    controller.enqueue(gift('a', 1));
    controller.enqueue(gift('b', 1));
    controller.enqueue(gift('c', 2));
    controller.enqueue(gift('c', 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    controller.enqueue(gift('a', 999999999));
    await tester.pump();
    expect(controller.activeEntries.first.count, 1000000000);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 320));
    expect(controller.activeEntries.last.gift.giftID, 'c');
    expect(controller.activeEntries.last.count, 5);
    controller.reset();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    controller.enqueue(gift('late', 1));
    expect(controller.activeEntries, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
